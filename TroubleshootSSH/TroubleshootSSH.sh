# Query for VM instance information

# Check if user has necessary permmissions

gcloud asset search-all-iam-policies --scope=projects/<PROJECT_ID> --query="policy:<USER_EMAIL>" | grep "role"

# Check if service account has necessary permissions

gcloud asset search-all-iam-policies --scope=projects/<PROJECT_ID> --query="policy:<SERVICE_ACCOUNT_EMAIL>" | grep "role"

# Test in-browser SSH ?

gcloud compute ssh <INSTANCE_NAME> --zone <INSTANCE_ZONE> --command exit

# Test SSH through IAP ?

gcloud compute ssh <INSTANCE_NAME> --tunnel-through-iap --zone <INSTANCE_ZONE> --command exit

# Test domain SSH ?

