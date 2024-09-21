# INTERNAL NOTES
# Adjust the MIG health check to do a health check using private subnet
# Health checks only work on external IP addresses?

####################################### STATIC VARIABLES ########################################

# Text Color
WHITE="\033[0m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
GREEN="\033[0;32m"

######################################### REQUIREMENTS ##########################################

echo '''
 ________  ________  _______   ________  _________  _______   ___      ___ ________  ________
|\   ____\|\   __  \|\  ___ \ |\   __  \|\___   ___\\  ___ \ |\  \    /  /|\   __  \|\   ____\
\ \  \___|\ \  \|\  \ \   __/|\ \  \|\  \|___ \  \_\ \   __/|\ \  \  /  / | \  \|\  \ \  \___|
 \ \  \    \ \   _  _\ \  \_|/_\ \   __  \   \ \  \ \ \  \_|/_\ \  \/  / / \ \   ____\ \  \
  \ \  \____\ \  \\  \\ \  \_|\ \ \  \ \  \   \ \  \ \ \  \_|\ \ \    / /   \ \  \___|\ \  \____
   \ \_______\ \__\\ _\\ \_______\ \__\ \__\   \ \__\ \ \_______\ \__/ /     \ \__\    \ \_______\
    \|_______|\|__|\|__|\|_______|\|__|\|__|    \|__|  \|_______|\|__|/       \|__|     \|_______|

An interactive script written by Jonmar Corpuz to help GCP customers easily create and launch a basic load balanced VPC 
comprised of a MIG within a private subnet.
'''

echo "" && echo -e "${YELLOW}[REQUIRED]${WHITE} Basic understanding of how GCP products work and the resources needed to create certain resources." && echo ""

######################################## ARGUMENTS CHECK ########################################

#
while getopts ":p:" opt; do
    case $opt in
        f) file="$OPTARG"
        ;;
        \?) echo -e "${RED}[ERROR 1]${WHITE} Usage: ./CreateVPC.sh -p <PROJECT_ID>$" && echo "" &&  exit 1
        ;;
        :) echo -e "${RED}[ERROR 2]${WHITE} Usage: ./CreateVPC.sh -p <PROJECT_ID>." && echo "" && exit 1
        ;;
    esac
done

#
if [ $OPTIND -eq 1 ]; 
then
    echo -e "${RED}[ERROR 3]${WHITE} Usage: ./CreateVPC.sh -p <PROJECT_ID>" && echo "" &&  exit 1
fi

######################################### SET PROJECT ###########################################

# Verify that the provided Project ID exists
if gcloud projects describe $2 &> /dev/null; 
then
    # Set the project
    gcloud config set project $2
    echo -e "${GREEN}[SUCCESS]${WHITE} The project has been set."
else
    echo -e "${RED}[ERROR 4]${WHITE} The provided Project ID doesn't exist." && echo "" && exit 1
fi

#################################### VIRTUAL PRIVATE NETWORK ####################################

#
#read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the name that would you like to give your virtual private network:) " InstanceTemplateName

#
if gcloud compute networks describe "${2}-vpc" &> /dev/null ; 
then
    echo "" && echo -e "A Virtual Private Network called ${PrivateNetworkName} already exists in your project." && echo ""
fi

#
read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the region where you want your virtual private network to reside in:) " NetworkRegion

#
gcloud compute networks create "${2}-vpc" \
    --subnet-mode custom 

# 
gcloud compute networks subnets create "${2}-vpc-subnet" \
    --network $2-vpc \
    --region $NetworkRegion \
    --range 10.10.0.0/24 

######################################### FIREWALL RULES ########################################

#
if gcloud compute firewall-rules describe "${2}-vpc-allow"; 
then
    echo "" && echo -e "A Virtual Private Network called vpc-allow already exists in your project." && echo ""
else
    gcloud compute firewall-rules create ${2}-vpc-allow \
        --network $2-vpc \
        --allow tcp,udp,icmp \
        --direction ingress \
        --source-ranges 130.211.0.0/22,35.191.0.0/16 \
        --target-tags $2-vpc-allow \
#        --rules tcp:80
fi 

#
if gcloud compute firewall-rules describe "${2}-vpc-allow-test"; 
then
    echo "" && echo -e "A Virtual Private Network called vpc-allow already exists in your project." && echo ""
else
    gcloud compute firewall-rules create ${2}-vpc-allow-test \
        --network $2-vpc \
        --allow tcp,udp,icmp \
        --direction egress \
        --source-ranges 130.211.0.0/22,35.191.0.0/16 \
        --target-tags $2-vpc-allow \
#        --rules tcp:80
fi 

#
if gcloud compute firewall-rules describe "${2}-http-health-check"; 
then
    echo "" && echo -e "A Virtual Private Network called http-health-check already exists in your project." && echo ""
else
    gcloud compute firewall-rules create ${2}-http-health-check \
        --action allow \
        --direction ingress \
        --source-ranges 130.211.0.0/22,35.191.0.0/16 \
        --target-tags $2-http-health-check \
        --network $2-vpc \
        --rules tcp:80
fi 

#
if gcloud compute firewall-rules describe "${2}-http-public-access"; 
then
    echo "" && echo -e "A Virtual Private Network called already http-public-access exists in your project." && echo ""
else
    gcloud compute firewall-rules create ${2}-http-public-access \
        --action allow \
        --direction egress \
        --source-ranges 130.211.0.0/22,35.191.0.0/16 \
        --target-tags $2-http-public-access \
        --network $2-vpc \
        --rules tcp:80
fi 

#
if gcloud compute firewall-rules describe "${2}-lb-health-check"; 
then
    echo "" && echo -e "A Virtual Private Network called lb-health-check already exists in your project." && echo ""
else
    gcloud compute firewall-rules create ${2}-lb-health-check \
        --action allow \
        --direction ingress \
        --source-ranges 130.211.0.0/22,35.191.0.0/16 \
        --target-tags $2-lb-health-check \
        --network $2-vpc \
        --rules tcp:80
fi 

####################################### INSTANCE TEMPLATE #######################################

echo ""

#
read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the name that would you like to give your instance template:) " InstanceTemplateName

if gcloud compute instance-templates describe $InstanceTemplateName &> /dev/null ; then
    echo "" && echo -e "${RED}[ERROR 6]${WHITE} An instance template called ${2}-vpc already exists in your project." && echo "" && exit 1
fi

#
read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the desired machine type for your instance template:) " InstanceTemplateMachineType

#
read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the family image for your instance template:) " InstanceTemplateImageFamily

#
read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the project that contains the image that you want to use for your instance template:) " InstanceTemplateImageProject

# Create Instance Template
gcloud compute instance-templates create $InstanceTemplateName \
    --machine-type $InstanceTemplateMachineType \
    --image-family $InstanceTemplateImageFamily \
    --image-project $InstanceTemplateImageProject \
    --metadata-from-file=startup-script=StartupScript.sh \
    --tags $2-http-health-check,$2-http-public-access,$2-vpc-allow,${2}-vpc-allow-test \
    --region $NetworkRegion \
    --network-interface network=$2-vpc,subnet="$2-vpc-subnet" #,no-address

echo ""
echo -e "${GREEN}[SUCCESS]${WHITE} The instance template was created successfully."
echo ""

##################################### MANAGED INSTANCE GROUP ####################################

#
read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the name you want to give your managed instance group:) " InstanceGroupName

#
if gcloud compute instance-groups managed describe $InstanceGroupName --region $NetworkRegion &> /dev/null; then
    echo "" && echo -e "${RED}[ERROR 7]${WHITE} A managed instance group called ${InstanceGroupName} already exists in ${InstanceTemplateRegion}." && exit 1
fi

#
read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the name of the instance template that you want your managed instance group to use:) " InstanceGroupTemplate

#
read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the minimum number of instances that you would want your managed instance group to run:) " InstanceGroupMinScaling

#
read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the maximum number of instances that you would want your managed instance group to scale up to:) " InstanceGroupMaxScaling

# Create Health Checks
if gcloud compute health-checks describe http-mig-health-check; 
then
    echo "" && echo -e "A health check named http-health-check already exists in your project." && echo ""
else
    gcloud compute health-checks create http http-mig-health-check \
        --port 80 \
        --check-interval 30s \
        --healthy-threshold 1 \
        --timeout 10s \
        --unhealthy-threshold 3 \
        --global \
        --port-name HTTP 
fi 

echo ""
echo -e "${GREEN}[SUCCESS]${WHITE} A health check was successfully created and configured for your managed instance group."
echo ""

# Create Instance Managed Group
gcloud compute instance-groups managed create $InstanceGroupName \
    --region $NetworkRegion \
    --template $InstanceGroupTemplate \
    --size $InstanceGroupMinScaling \
    --health-check http-mig-health-check

echo ""
echo -e "${GREEN}[SUCCESS]${WHITE} Your managed instance group was created successfully."
echo ""

# Configure Autoscaling
gcloud compute instance-groups managed set-autoscaling $InstanceGroupName \
    --region $NetworkRegion \
    --max-num-replicas $InstanceGroupMaxScaling \
    --target-cpu-utilization 0.60 \
    --cool-down-period 90

gcloud compute instance-groups set-named-ports $InstanceGroupName \
    --named-ports http:80 \
    --region $NetworkRegion

echo ""
echo -e "${GREEN}[SUCCESS]${WHITE} Autoscaling was successfully configured for your managed instance group."
echo ""

######################################### LOAD BALANCER #########################################

#
gcloud compute health-checks create http $2-http-lb-health-check \
     --port 80 \

# Reserve an External IP Address
gcloud compute addresses create $2-lb-address \
    --ip-version=IPV4 \
    --global

# Create Backend Service
gcloud compute backend-services create $2-lb-backend-service \
    --load-balancing-scheme EXTERNAL \
    --protocol HTTP \
    --port-name http \
    --health-checks $2-http-lb-health-check \
    --global

gcloud beta compute backend-services add-backend $2-lb-backend-service \
  --instance-group $InstanceGroupName \
  --instance-group-region $NetworkRegion \
  --global

gcloud beta compute url-maps create web-map-http \
  --default-service $2-lb-backend-service

gcloud compute target-http-proxies create http-lb-proxy \
  --url-map web-map-http \

gcloud compute forwarding-rules create http-content-rule \
  --load-balancing-scheme EXTERNAL \
  --address $2-lb-address \
  --global \
  --target-http-proxy http-lb-proxy \
  --ports 80

########################################## REFERENCES ###########################################

# Instance Template                   - https://cloud.google.com/compute/docs/instance-templates/create-instance-templates#gcloud
# Managed Instance Group              - https://cloud.google.com/compute/docs/instance-groups/create-zonal-mig#gcloud
# Managed Instance Group Autoscaling  - https://cloud.google.com/compute/docs/instance-groups/create-mig-with-basic-autoscaling
# Managed Instance Group Health Check - https://cloud.google.com/compute/docs/instance-groups/autohealing-instances-in-migs
# Compute Networks                    - https://cloud.google.com/sdk/gcloud/reference/compute/networks/create
# Application Load Balancer           - https://cloud.google.com/load-balancing/docs/application-load-balancer
#                                     - https://cloud.google.com/iap/docs/load-balancer-howto#gcloud
# Backend                             - https://cloud.google.com/sdk/gcloud/reference/compute/backend-services/create
