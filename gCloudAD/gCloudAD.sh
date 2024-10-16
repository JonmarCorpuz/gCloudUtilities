
# Create AD domain

gcloud active-directory domains create <FQDN> \
    --reserved-ip-range=<CIDR_RANGE> --region=<REGION> \
    --authorized-networks=projects/<PROJECT_ID>/global/networks/<VPC_NETWORK_NAME>

# Join Linux VM to domain (Execute commands through SSH)
