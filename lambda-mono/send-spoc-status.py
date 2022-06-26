# Gather and send health-checks from different services and send to SPoC (Single Point of Contact) 
# dashboard. The health-checks are gathered using the API, based on the API described here:

import os
import sys
import logging
import json
from datetime import date
from dataclasses import dataclass
import urllib3
http = urllib3.PoolManager()

spoc_aws_region = os.environ.get("AWS_REGION", "eu-central-1")
assert spoc_aws_region

environment = os.environ.get("ENVIRONMENT", "nonlive")
if environment == "live":
    spoc_account_id = "787821785757"
elif environment == "nonlive":
    spoc_account_id = "925522540492"
else:
    raise Exception(
        "environment has to match the spoc live or nonlive AWS accountIDs!")
assert environment

application_endpoint = os.environ.get("APPLICATION_ENDPOINT", "https://www.google.com")
spoc_team = "BigFin"
spoc_vertical = os.environ.get("SPOC_VERTICAL", "API-Gateway")
spoc_service  = os.environ.get("SPOC_SERVICE", "Internal")

LOGGER = logging.getLogger()
logging.getLogger().setLevel(logging.INFO)


@dataclass
class Config:
    year: str = str(date.today().year)
    last_year: str = str(date.today().year-1)
    client_key_filename: str = f"status-api-client-{year}.key.pem"
    client_key_filename_last_year: str = f"status-api-client-{last_year}.key.pem"
    client_cert_filename: str = f"status-api-client-{year}.crt.pem"
    client_cert_filename_last_year: str = f"status-api-client-{last_year}.crt.pem"
    dest_dir: str = "/tmp"
    secrets_arn: str = f"arn:aws:secretsmanager:{spoc_aws_region}:{spoc_account_id}:secret:/status-api/client_credential/api-quality-1"
    cognito_url: str = f"https://status-api-{environment}-{spoc_account_id}.auth.{spoc_aws_region}.amazoncognito.com/token"
    metadata_endpoint: str = "/v1/metadata"
    status_endpoint: str = "/v1/status"
    metadata_file_path: str = "./ci/register.json"
    status_file_path: str = "./ci/status-example-service.json"
    access_token: str = ""
    client_id: str = ""
    client_secret: str = ""


def get_status_json(status):
    return json.dumps({
        "type": "status",
        "environment": environment,
        "team": spoc_team,
        "vertical": spoc_vertical,
        "service": spoc_service,
        "status": status,
    })

def get_metadata_json(spoc_alert_definition):
    return json.dumps({
        "type": "metadata",
        "environment": environment,
        "team": spoc_team,
        "vertical": spoc_vertical,
        "service": spoc_service,
        "service_description": spoc_alert_definition["service_description"],
        "heartbeat_minutes": int(spoc_alert_definition["heartbeat_minutes"]),
        "customer_impact": spoc_alert_definition["customer_impact"],
        "required_action": spoc_alert_definition["required_action"],
        "in_house_impact": spoc_alert_definition["in_house_impact"],
        "critical_damage_hours": {
            "image": int(spoc_alert_definition["critical_damage_hours.image"]),
            "legal": int(spoc_alert_definition["critical_damage_hours.legal"]),
            "monetary": int(spoc_alert_definition["critical_damage_hours.monetary"])
        }
    })

def get_application_status():
    application_status = "Unreachable"
    try:
        response = http.request('GET', application_endpoint)
        if response.status == 200:
            application_status = "ok"
            logging.info(f"Endpoint {application_endpoint} OK!")
    except urllib3.exceptions.HTTPError as e:
        logging.warning(f"Request failed. Reason: {e.reason}")
    
    if application_status == "Unreachable":
        logging.warning(f"Warning! Endpoint {application_endpoint} UNREACHABLE!")
    
    return application_status


def send_message(spoc_endpoint, message_file):
    # Send a message to the spoc status API
    logging.debug(f"Starting Sending message to API {spoc_endpoint} ...")
    
    application_status = get_application_status()
    json_string_to_send = get_status_json(application_status)
    logging.info(f"Sending to: {spoc_endpoint}. JSON: {json_string_to_send}")
    logging.debug(f"Finished sending message to API {spoc_endpoint} ...")


def get_client_cert():
    # getting the client certificates from the s3 bucket
    logging.debug("Getting client certs ...")


def cleanup_cert():
    # removing the client certificates again
    logging.debug("Cleaning up certs ...")


def get_client_credentials():
    # Get secrets (client_credentials) from spoc account in order to get Oauth tokens from spoc cognito instance
    logging.debug("Getting client credentials ...")


def get_access_token():
    # get an Oauth token for the API endpoints call
    logging.debug("Getting access token ...")


def lambda_handler(event, context):
    logging.debug("Starting sending message ...")
    config = Config()
    get_client_cert()
    get_client_credentials()
    get_access_token()
    send_message(config.metadata_endpoint, config.metadata_file_path)
    send_message(config.status_endpoint, config.status_file_path)
    args = "\n".join(sys.argv)
    if "--clean-certs" in args:
        cleanup_cert()
    logging.debug("Sending message finished !")
    
    return {
        'statusCode': 200,
        'body': json.dumps('Successfully exited from Lambda!')
    }


if __name__ == "__main__":
    lambda_handler(None, None)
