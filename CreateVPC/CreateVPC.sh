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
if [ $OPTIND -eq 1 ]; then
    echo -e "${RED}[ERROR 3]${WHITE} Usage: ./CreateVPC.sh -p <PROJECT_ID>" && echo "" &&  exit 1
fi

######################################### SET PROJECT ###########################################

# Verify that the provided Project ID exists
if gcloud projects describe $2 &> /dev/null; then
    # Set the project
    gcloud config set project $2
    echo -e "${GREEN}[SUCCESS]${WHITE} The project has been set."
else
    echo -e "${RED}[ERROR 4]${WHITE} The provided Project ID doesn't exist." && echo "" && exit 1
fi

#################################### VIRTUAL PRIVATE NETWORK ####################################

#
read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the name that would you like to give your Virtaul Private Network:) " PrivateNetworkName

if gcloud compute networks describe $PrivateNetworkName &> /dev/null ; then
    echo "" && echo -e "${RED}[ERROR 7]${WHITE} A Virtual Private Network called ${PrivateNetworkName} already exists in your project." && echo "" && exit 1
fi

#
#gcloud compute networks create $PrivateNetworkName \
#    --bgp-routing-mode=regional

# 
#gcloud compute networks subnets create \
#    --network=$PrivateNetworkName \
#    --region=

####################################### INSTANCE TEMPLATE #######################################

echo ""

#
read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the name that would you like to give your instance template:) " InstanceTemplateName

if gcloud compute instance-templates describe $InstanceTemplateName &> /dev/null ; then
    echo "" && echo -e "${RED}[ERROR 6]${WHITE} An instance template called ${InstanceTemplateName} already exists in your project." && echo "" && exit 1
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
    --image-project $InstanceTemplateImageProject

echo ""
echo -e "${GREEN}[SUCCESS]${WHITE} The instance template was created successfully."
echo ""

##################################### MANAGED INSTANCE GROUP ####################################

#
read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the name you want to give your Managed Instance Group:) " InstanceGroupName

#
read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the region where you want your Managed Instance Group to reside in:) " InstanceGroupRegion

if gcloud compute instance-groups managed describe $InstanceGroupName --zone $InstanceGroupRegion &> /dev/null; then
    echo "" && echo -e "${RED}[ERROR 7]${WHITE} A Managed Instance Group called ${InstanceGroupName} already exists in ${InstanceTemplateRegion}." && exit 1
fi

#
read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the name of the instance template that you want your Managed Instance Group to use:) " InstanceGroupTemplate

#
read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the minimum number of instances that you would want your Managed Instance Group to run:) " InstanceGroupMinScaling

#
read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the maximum number of instances that you would want your Managed Instance Group to scale up to:) " InstanceGroupMaxScaling

# Create Instance Managed Group
gcloud compute instance-groups managed create $InstanceGroupName \
    --region $InstanceGroupRegion \
    --template $InstanceGroupTemplate \
    --size $InstanceGroupMinScaling

echo ""
echo -e "${GREEN}[SUCCESS]${WHITE} Your Managed Instance Group was created successfully."
echo ""

# Configure Autoscaling
gcloud compute instance-groups managed set-autoscaling $InstanceGroupName \
    --region $InstanceGroupRegion \
    --max-num-replicas $InstanceGroupMaxScaling \
    --target-cpu-utilization 0.60 \
    --cool-down-period 90

echo ""
echo -e "${GREEN}[SUCCESS]${WHITE} Autoscaling was successfully configured for your Managed Instance Group."
echo ""

# Configure Health Checks
#gcloud compute health-checks create http example-check --port 80 \
#   --check-interval 30s \
#   --healthy-threshold 1 \
#   --timeout 10s \
#   --unhealthy-threshold 3 \
#   --global

echo ""
echo -e "${GREEN}[SUCCESS]${WHITE} A health check was successfully created and configured for your Managed Instance Group."
echo ""

######################################### LOAD BALANCER #########################################

########################################## REFERENCES ###########################################

# Instance Template - https://cloud.google.com/compute/docs/instance-templates/create-instance-templates#gcloud
# MIG               - https://cloud.google.com/compute/docs/instance-groups/create-zonal-mig#gcloud
# MIG Autoscaling   - https://cloud.google.com/compute/docs/instance-groups/create-mig-with-basic-autoscaling
# MIG Health Check  - https://cloud.google.com/compute/docs/instance-groups/autohealing-instances-in-migs
# Compute Networks  - https://cloud.google.com/sdk/gcloud/reference/compute/networks/create