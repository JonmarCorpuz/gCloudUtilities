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

# Set the project
if gcloud projects describe $2 &> /dev/null; 
then
    gcloud config set project $2
    echo -e "${GREEN}[SUCCESS]${WHITE} The project has been set."
else
    echo -e "${RED}[ERROR 4]${WHITE} The provided Project ID doesn't exist." && echo "" && exit 1
fi

#################################### VIRTUAL PRIVATE NETWORK ####################################

# Ask the user what they want to name their VPC
while [[ $ALWAYS_TRUE=true ]];
do 
    read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the name that would you like to give your virtual private network:) " NetworkName
    if [[ $NetworkName =~ " " ]];
    then 
        echo "" && echo -e "${RED}[ERROR 8]${WHITE} Please ensure that the VPC's name contains no spaces or special characters." && echo ""
    else
        # Check if VPC with the provided name already exists in the current project
        if gcloud compute networks describe $NetworkName &> /dev/null; 
        then
            echo "" && echo -e "${RED}[ERROR 9]${WHITE} A Virtual Private Network called ${NetworkName} already exists in your project." && echo ""
        else 
            break
        fi
    fi 
done 

# Prompt the user for a name for their virtual private network
while [[ $ALWAYS_TRUE=true ]];
do 
    read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the region where you want your virtual private network to reside in:) " NetworkRegion

    if gcloud compute regions describe $NetworkRegion &> /dev/null;
    then
        break 
    else
        echo "" && echo -e "${RED}[ERROR 10]${WHITE} ${NetworkRegion} isn't a valid GCP region. Please enter an existing valid region." && echo ""
    fi
done

# Create their virtual private network
gcloud compute networks create $NetworkName \
    --subnet-mode custom 

echo "" && echo -e "${GREEN}[SUCCESS]${WHITE} The virtual private network was created successfully." && echo ""

# Create private subnet for the instances created from the instance group
gcloud compute networks subnets create "${NetworkName}-private-subnet" \
    --network $NetworkName \
    --region $NetworkRegion \
    --range 10.10.0.0/24 

echo "" && echo -e "${GREEN}[SUCCESS]${WHITE} The private subnet was created successfully within the virtual private network." && echo ""

# Create proxy only subnet for the load balancer
gcloud compute networks subnets create "${NetworkName}-proxy-subnet" \
    --network $NetworkName \
    --region $NetworkRegion \
    --range 10.10.1.0/24  \
    --role active \
    --purpose REGIONAL_MANAGED_PROXY

echo "" && echo -e "${GREEN}[SUCCESS]${WHITE} The proxy only subnet was created successfully within the virtual private network." && echo ""

# Reserve a public IP address for the load balancer
gcloud compute addresses create $NetworkName-lb-address \
    --ip-version=IPV4 \
    --global

lb_address=$(gcloud compute addresses describe $NetworkName-lb-address --format="get(address)" --global)

######################################### FIREWALL RULES ########################################

#
if gcloud compute firewall-rules describe "${NetworkName}-vpc-allow" &> /dev/null; 
then
    echo "" && echo -e "A Virtual Private Network called vpc-allow already exists in your project." && echo ""
else
    gcloud compute firewall-rules create ${NetworkName}-vpc-allow \
        --network $NetworkName \
        --allow tcp,udp,icmp \
        --direction ingress \
        --source-ranges 130.211.0.0/22,35.191.0.0/16,$lb_address \
        --target-tags $NetworkName-vpc-allow 
fi 

#
if gcloud compute firewall-rules describe "${NetworkName}-vpc-allow-test" &> /dev/null; 
then
    echo "" && echo -e "A Virtual Private Network called vpc-allow already exists in your project." && echo ""
else
    gcloud compute firewall-rules create ${NetworkName}-vpc-allow-test \
        --network $NetworkName \
        --allow tcp,udp,icmp \
        --direction egress \
        --source-ranges 130.211.0.0/22,35.191.0.0/16 \
        --target-tags $NetworkName-vpc-allow 
fi 

#
if gcloud compute firewall-rules describe "${NetworkName}-http-health-check" &> /dev/null; 
then
    echo "" && echo -e "A Virtual Private Network called http-health-check already exists in your project." && echo ""
else
    gcloud compute firewall-rules create ${NetworkName}-http-health-check \
        --action allow \
        --direction ingress \
        --source-ranges 130.211.0.0/22,35.191.0.0/16 \
        --target-tags $NetworkName-http-health-check \
        --network $NetworkName \
        --rules tcp:80
fi 

#
if gcloud compute firewall-rules describe "${NetworkName}-http-public-access" &> /dev/null; 
then
    echo "" && echo -e "A Virtual Private Network called already http-public-access exists in your project." && echo ""
else
    gcloud compute firewall-rules create ${NetworkName}-http-public-access \
        --action allow \
        --direction egress \
        --source-ranges 130.211.0.0/22,35.191.0.0/16 \
        --target-tags $NetworkName-http-public-access \
        --network $NetworkName \
        --rules tcp:80
fi 

#
if gcloud compute firewall-rules describe "${NetworkName}-lb-health-check" &> /dev/null; 
then
    echo "" && echo -e "A Virtual Private Network called lb-health-check already exists in your project." && echo ""
else
    gcloud compute firewall-rules create ${NetworkName}-lb-health-check \
        --action allow \
        --direction ingress \
        --source-ranges 130.211.0.0/22,35.191.0.0/16 \
        --target-tags $NetworkName-lb-health-check \
        --network $NetworkName \
        --rules tcp:80
fi 

#
gcloud compute firewall-rules create test-fw-allow-health-check \
    --network $NetworkName \
    --action=allow \
    --direction=ingress \
    --source-ranges=130.211.0.0/22,35.191.0.0/16 \
    --target-tags=load-balanced-backend \
    --rules=tcp
#
gcloud compute firewall-rules create test-fw-allow-proxies \
    --network $NetworkName \
    --action=allow \
    --direction=ingress \
    --source-ranges 10.10.1.0/24 \
    --target-tags=load-balanced-backend \
    --rules=tcp:80,tcp:443,tcp:8080

echo "" && echo -e "${GREEN}[SUCCESS]${WHITE} The firewall policies were created successfully." && echo ""

####################################### INSTANCE TEMPLATE #######################################

echo ""

#
while [[ $ALWAYS_TRUE=true ]];
do 
    read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the name that would you like to give your instance template:) " InstanceTemplateName

    if gcloud compute instance-templates describe $InstanceTemplateName &> /dev/null; 
    then
        echo "" && echo -e "${RED}[ERROR 6]${WHITE} An instance template called ${NetworkName}-vpc already exists in your project." && echo ""
    else
        break 
    fi
done 

#
while [[ $ALWAYS_TRUE=true ]];
do
    read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the desired machine type for your instance template:) " InstanceTemplateMachineType

    if gcloud compute machine-types describe $InstanceTemplateMachineType --zone us-east1-b &> /dev/null; 
    then
        echo "" && echo -e "${RED}[ERROR 11]${WHITE} ${InstanceTemplateMachineType} isn't a valid machine type." && echo ""
    else
        break 
    fi
done 

#
while [[ $ALWAYS_TRUE=true ]];
do
    read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the family image for your instance template:) " InstanceTemplateImageFamily
    read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the project that contains the image that you want to use for your instance template:) " InstanceTemplateImageProject
    
    if gcloud compute images describe-from-family $InstanceTemplateImageFamily --project $InstanceTemplateImageProject &> /dev/null; 
    then
        echo "" && echo -e "${RED}[ERROR 12]${WHITE} Couldn't find the ${InstanceTemplateImageFamily} image within the ${InstanceTemplateImageProject} project." && echo ""
    else
        break 
    fi
done

# Create Instance Template
gcloud compute instance-templates create $InstanceTemplateName \
    --machine-type $InstanceTemplateMachineType \
    --image-family $InstanceTemplateImageFamily \
    --image-project $InstanceTemplateImageProject \
    --metadata-from-file=startup-script=StartupScript.sh \
    --tags $NetworkName-http-health-check,$NetworkName-http-public-access,$NetworkName-vpc-allow,${NetworkName}-vpc-allow-test,load-balanced-backend \
    --region $NetworkRegion \
    --network-interface network=$NetworkName,subnet="${NetworkName}-private-subnet" #,no-address

echo "" && echo -e "${GREEN}[SUCCESS]${WHITE} The instance template was created successfully." && echo ""

##################################### MANAGED INSTANCE GROUP ####################################

# Prompt the user for a name for their instance group
while [[ $ALWAYS_TRUE=true ]];
do 
    read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the name you want to give your managed instance group:) " InstanceGroupName

    if [[ $InstanceGroupName =~ " " ]];
    then 
        echo "" && echo -e "${RED}[ERROR 13]${WHITE} Please ensure that the instance group's name contains no spaces or special characters." && echo ""
    else
        if gcloud compute instance-groups managed describe $InstanceGroupName --region $NetworkRegion &> /dev/null; then
            echo "" && echo -e "${RED}[ERROR 7]${WHITE} A managed instance group called ${InstanceGroupName} already exists in ${InstanceTemplateRegion}." && echo ""
        else 
            break
        fi 
    fi 
done 

# Prompt the user for the instance template for their instance group
while [[ $ALWAYS_TRUE=true ]];
do 
    read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the name of the instance template that you want your managed instance group to use:) " InstanceGroupTemplate

    if gcloud compute instance-templates describe InstanceGroupTemplate &> /dev/null;
    then
        break
    else 
        echo "" && echo -e "${RED}[ERROR 14]${WHITE} ${InstanceGroupTemplate} does not exist or can't be found." && echo ""
    fi 
done

# Prompt the user for the minimum number of instances in their instance group
while [[ $ALWAYS_TRUE=true ]];
do 
    read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the minimum number of instances that you would want your managed instance group to run:) " InstanceGroupMinScaling

    if [[ "$InstanceGroupMinScaling" =~ ^[0-9]+$ && "$InstanceGroupMinScaling" -gt 0 ]];
    then
        break
    else 
        echo "" && echo -e "${RED}[ERROR 15]${WHITE} Please enter a number greater than 0." && echo ""
    fi
done 

# Prompt the user for the maximum number of instances for their instance group
while [[ $ALWAYS_TRUE=true ]];
do 
    read -p "$(echo -e ${YELLOW}[REQUIRED]${WHITE} Please enter the maximum number of instances that you would want your managed instance group to scale up to:) " InstanceGroupMaxScaling

    if [[ "$InstanceGroupMaxScaling" =~ ^[0-9]+$ && "$InstanceGroupMaxScaling" -gt 0 ]];
    then
        break
    else 
        echo "" && echo -e "${RED}[ERROR 16]${WHITE} Please enter a number greater than 0." && echo ""
    fi
done 

# Create instance group health check
if gcloud compute health-checks describe http-mig-health-check &> /dev/null; 
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

    echo "" && echo -e "${GREEN}[SUCCESS]${WHITE} A health check was successfully created and configured for your managed instance group." && echo ""

fi 

# Create Instance Managed Group
gcloud compute instance-groups managed create $InstanceGroupName \
    --region $NetworkRegion \
    --template $InstanceGroupTemplate \
    --size $InstanceGroupMinScaling \
    --health-check http-mig-health-check

echo "" && echo -e "${GREEN}[SUCCESS]${WHITE} Your managed instance group was created successfully." && echo ""

# Configure autoscaling for the instance group
gcloud compute instance-groups managed set-autoscaling $InstanceGroupName \
    --region $NetworkRegion \
    --max-num-replicas $InstanceGroupMaxScaling \
    --target-cpu-utilization 0.60 \
    --cool-down-period 90

gcloud compute instance-groups set-named-ports $InstanceGroupName \
    --named-ports http:80 \
    --region $NetworkRegion

echo "" && echo -e "${GREEN}[SUCCESS]${WHITE} Autoscaling was successfully configured for your managed instance group." && echo ""

######################################### LOAD BALANCER #########################################

#
gcloud compute health-checks create http $NetworkName-http-lb-health-check \
     --port 80 \

# Create a backend service for the load-balancer
gcloud compute backend-services create $NetworkName-lb-backend-service \
    --load-balancing-scheme EXTERNAL \
    --protocol HTTP \
    --port-name http \
    --health-checks $NetworkName-http-lb-health-check \
    --global

#
gcloud beta compute backend-services add-backend $NetworkName-lb-backend-service \
    --instance-group $InstanceGroupName \
    --instance-group-region $NetworkRegion \
    --global

#
gcloud beta compute url-maps create web-map-http \
    --default-service $NetworkName-lb-backend-service

#
gcloud compute target-http-proxies create http-lb-proxy \
    --url-map web-map-http \

#
gcloud compute forwarding-rules create http-content-rule \
    --load-balancing-scheme EXTERNAL \
    --address $NetworkName-lb-address \
    --global \
    --target-http-proxy http-lb-proxy \
    --ports 80

########################################## REFERENCES ###########################################
:'

Instance Template                   
- https://cloud.google.com/compute/docs/instance-templates/create-instance-templates#gcloud

Managed Instance Group              
- https://cloud.google.com/compute/docs/instance-groups/create-zonal-mig#gcloud

Managed Instance Group Autoscaling  
- https://cloud.google.com/compute/docs/instance-groups/create-mig-with-basic-autoscaling

Managed Instance Group Health Check 
- https://cloud.google.com/compute/docs/instance-groups/autohealing-instances-in-migs

Compute Networks
- https://cloud.google.com/sdk/gcloud/reference/compute/networks/create

Application Load Balancer           
- https://cloud.google.com/load-balancing/docs/application-load-balancer
- https://cloud.google.com/iap/docs/load-balancer-howto#gcloud

Backend                            
- https://cloud.google.com/sdk/gcloud/reference/compute/backend-services/create

'
######################################## INTERNAL NOTES #########################################
:'

- Adjust the MIG health check to do a health check using private subnet
- Health checks only work on external IP addresses?

'
