####################################### STATIC VARIABLES ########################################

######################################### REQUIREMENTS ##########################################

######################################## ARGUMENTS CHECK ########################################

# Verify that the projects in the provided file all exist

########################################## MONITORING ###########################################

# Switch to the dedicated project for monitoring

# Enable Cloud Monitoring API
gcloud services enable monitoring --project=PROJECT_ID

# Add the specified projects to the metric scope

for n of specified projects
do
  gcloud beta monitoring metrics-scopes create proejcts/<PROJECT ID OF THE PROJECT TO ADD> --project=<MONITORING PROEJCT ID>
done

# Define a service to monitor all VM instances using labels

# Define a service to monitor all containers using labels

########################################## REFERENCES ###########################################

# Metrics Scope 
# - https://cloud.google.com/monitoring/settings/manage-api
