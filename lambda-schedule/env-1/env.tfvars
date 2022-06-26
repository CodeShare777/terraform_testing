central_services_list = [
    {
      lambda_func_name  = "func-internal"
      endpoint_to_probe = "https://google.com"
      spoc_service_name = "internal_xyz_service"
    },
    {
      lambda_func_name  = "func-external"
      endpoint_to_probe = "https://msn.com"
      spoc_service_name = "external_xyz_service"
    },
    {
      lambda_func_name  = "func-idl"
      endpoint_to_probe = "https://idl.com"
      spoc_service_name = "idl_xyz_service"
    }
  ]
