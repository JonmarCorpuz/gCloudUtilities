```Text
 _________  ________ ________  ________  _____ ______   ___       __   ________     
|\___   ___\\  _____\\   __  \|\   __  \|\   _ \  _   \|\  \     |\  \|\   __  \    
\|___ \  \_\ \  \__/\ \  \|\  \ \  \|\  \ \  \\\__\ \  \ \  \    \ \  \ \  \|\ /_   
     \ \  \ \ \   __\\ \  \\\  \ \   _  _\ \  \\|__| \  \ \  \  __\ \  \ \   __  \  
      \ \  \ \ \  \_| \ \  \\\  \ \  \\  \\ \  \    \ \  \ \  \|\__\_\  \ \  \|\  \ 
       \ \__\ \ \__\   \ \_______\ \__\\ _\\ \__\    \ \__\ \____________\ \_______\
        \|__|  \|__|    \|_______|\|__|\|__|\|__|     \|__|\|____________|\|_______|
```

TerraformWB is the equivalent of Jonmar's gCloudWB but uses Terraform to create and manage the underlying infrastructure rather than Google Cloud's Cloud SDK.


# References

* https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template
* https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_health_check
* https://mihaibojin.medium.com/deploy-and-configure-google-compute-engine-vms-with-terraform-f6b708b226c1
* https://medium.com/@jojoooo/terraforming-shared-vpc-host-services-gcp-private-service-access-and-firewall-rules-5-17-585143bca208
* https://cloud.google.com/load-balancing/docs/https/ext-http-lb-tf-module-examples#with_managed_instance_group_mig_backends
* https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_target_http_proxy
* https://stackoverflow.com/questions/59568970/why-terraform-created-load-balancer-cannot-connect-my-backend

