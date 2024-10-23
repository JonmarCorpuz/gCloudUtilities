#!/bin/bash

####################################### STATIC VARIABLES ########################################

# Text Color
WHITE="\033[0m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
GREEN="\033[0;32m"

# Infinte Loop
ALWAYS_TRUE=true

######################################### REQUIREMENTS ##########################################

echo '''

'''

####################################### GATHER USER INPUT #######################################


####################################### KUBERNETES ENGINE #######################################

# Ensure that the API is enabled
if ! gcloud services list | grep "container.googleapis.com";
then
    gcloud services enable container.googleapis.com
fi

# Ensure that kubectl is installed
if ! kubectl version --client;
then 
    gcloud components install kubectl
fi

# Ensure that the required plugin is installed
if ! gke-gcloud-auth-plugin --version;
then
    gcloud components install gke-cloud-auth-plugin
