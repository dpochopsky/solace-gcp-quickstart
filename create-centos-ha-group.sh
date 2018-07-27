#!/bin/bash

default_zones=(us-east1-b us-east1-c us-east1-d)
default_basename=vmr
default_connections=1000
default_bootdisksize=200GB
default_datadisksize=200GB
default_adminpwd=admin

printUsage() {
   echo "Usage:  create-centos-ha-group.sh [OPTIONS]"
   echo "OPTIONS:"
   echo "   -n=BASENAME | --basename=BASENAME"
   echo "      The prefix to be used for each VMRs hostname, dashes and underscores not permitted."
   echo "      Default:  $default_basename"
   echo "   -z=ZONES | --zones=ZONES"
   echo "      Comma separated list of zones for each of the VMRs, all zones must be in the same region."
   echo "      Default:  ${default_zones[*]}"
   echo "   -c=CONNECTIONS | --connectionscale=CONNECTIONS"
   echo "      VMR connection scaling size (100, 1000, 10000, 100000, 200000)."
   echo "      Default:  $default_connections"
   echo "   -b=BOOTDISKSIZE | --bootdisksize=BOOTDISKSIZE"
   echo "      The size of the VM boot disk, recommend 200GB or greater."
   echo "      Default:  $default_bootdisksize"
   echo "   -d=DATADISKSIZE | --datadisksize=DATADISKSIZE"
   echo "      The size of the VM message spool disk, recommend 200GB or greater."
   echo "      Default:  $default_datadisksize"
   echo "   -p=ADMINPWD | --adminpassword=ADMINPWD"
   echo "      The admin password used for all VMRs."
   echo "      Default:  $default_adminpwd"
   echo ""
}


zones=("${default_zones[@]}")
basename=$default_basename
connections=$default_connections
bootdisksize=$default_bootdisksize
datadisksize=$default_datadisksize
adminpwd=$default_adminpwd

for i in "$@"
do
case $i in
    -n=*|--basename=*)
    basename="${i#*=}"
    shift # past argument=value
    ;;
    -z=*|--zones=*)
    zonelist="${i#*=}"
    shift # past argument=value
    ;;
    -c=*|--connectionscale=*)
    connections="${i#*=}"
    shift # past argument=value
    ;;
    -b=*|--bootdisksize=*)
    bootdisksize="${i#*=}"
    shift # past argument=value
    ;;
    -d=*|--datadisksize=*)
    datadisksize="${i#*=}"
    shift # past argument=value
    ;;
    -p=*|--adminpassword=*)
    adminpwd="${i#*=}"
    shift # past argument=value
    ;;
    -h|--help)
    printUsage
    exit
    ;;
    *)
          # unknown option
          echo "Unexpected option: $i"
          printUsage
          exit -1
    ;;
esac
done

if [[ -n $zonelist ]]; then
   unset zones
   zones=(${zonelist//,/ })
fi
numzones=${#zones[@]}

#
# Extract region from the zone & confirm all zones are in same region
#
region=$(echo ${zones[0]} |cut -d "-" -f1,2)
for i in ${zones[@]}; do
   if [ $region != $(echo $i |cut -d "-" -f1,2) ]; then
      echo "Invalid zones provided, all zones must be in the same region"
      printUsage
      exit -1
   fi
done

#
# check if routernames contain any dashes or underscores and abort execution, if that is the case.
#
if [[ $basename == *"-"* || $basename == *"_"* ]]; then
  echo "Invalid value for basename:  $basename"
  printUsage
  exit -1
fi


#
# Choose machine type based on connection scale
#
if [ ${connections} == "100" ]; then
  machinetype="n1-standard-2" 
elif [ ${connections} == "1000" ]; then
  machinetype="n1-standard-2" 
elif [ ${connections} == "10000" ]; then
  machinetype="n1-standard-4" 
elif [ ${connections} == "100000" ]; then
  machinetype="n1-standard-8" 
elif [ ${connections} == "200000" ]; then
  machinetype="n1-standard-16" 
else
   echo "Invalid value for connections:  $connections"
   printUsage
   exit -1
fi


echo "basename:     $basename"
echo "zones:        ${zones[*]}"
echo "region:       $region"
echo "connections:  $connections"
echo "bootdisksize: $bootdisksize"
echo "datadisksize: $datadisksize"
echo "adminpwd:     $adminpwd"
echo "machinetype:  $machinetype"

#
# Create three VMs and their message spool disks
#
#os=rhel
os=centos
networktag=gce-solace-cluster-${basename}
for index in 0 1 2; do
  name=${basename}${index}
  zone=${zones[$(($index % $numzones))]}
  datadisk="${name}-datadisk"

  ## TODO:  Don't need tocreate a data disk for the monitor
  
  if [ "${index}" == "0" ]; then
    vmtype="n1-standard-1"
  else
    vmtype=$machinetype
  fi

    # Create message spool disk
    gcloud compute disks create ${datadisk} \
    --description="Data disk for VMR ${name}" \
    --labels="usage=solace-vmr-${os}" \
    --size=${datadisksize} \
    --type=pd-ssd \
    --zone=${zone}

    # Create VM
    gcloud compute instances create ${name} \
    --boot-disk-size=${bootdisksize} \
    --boot-disk-type=pd-standard \
    --labels="usage=solace-vmr-${os}" \
    --machine-type=${vmtype} \
    --zone=${zone} \
    --disk="name=${datadisk},device-name=sdb,auto-delete=yes,mode=rw" \
    --image-project=${os}-cloud \
    --image-family=${os}-7 \
    --tags=${networktag}

done

   # Create firewall rules for external ports 
   gcloud compute firewall-rules create gce-solace-ext-ports-${basename} \
   --allow=tcp:5550,tcp:55555,tcp:55003,tcp:55556,tcp:55443,tcp:80,tcp:443

   # Create firewall rules for internal ports used by the VMRs
   gcloud compute firewall-rules create gce-solace-int-ports-${basename} \
   --target-tags=${networktag} \
   --allow=tcp:8741,tcp:8300,tcp:8301,tcp:8302,udp:8301,udp:8302

   # Create firewall rules for admin access
   gcloud compute firewall-rules create gce-solace-admin-ports-${basename} \
   --target-tags=${networktag} \
   --allow=tcp:22,tcp:8080,tcp:943


   # Create health check
   gcloud compute http-health-checks create gce-solace-hc-${basename} \
   --check-interval=2 \
   --healthy-threshold=1 \
   --unhealthy-threshold=5 \
   --timeout=1 \
   --port=5550 \
   --request-path=/health-check/guaranteed-active

   # Create target pool
   gcloud compute target-pools create gce-solace-hc-pool-${basename} \
   --region=${region} \
   --http-health-check=gce-solace-hc-${basename}
   gcloud compute target-pools add-instances gce-solace-hc-pool-${basename} \
   --instances=${basename}0 \
   --instances-zone=${zones[0]}
   gcloud compute target-pools add-instances gce-solace-hc-pool-${basename} \
   --instances=${basename}1 \
   --instances-zone=${zones[$((1 % $numzones))]}
   gcloud compute target-pools add-instances gce-solace-hc-pool-${basename} \
   --instances=${basename}2 \
   --instances-zone=${zones[$((2 % $numzones))]}


   # Create load balancer
   gcloud compute addresses create gce-solace-${basename}-lb-ip \
   --region=${region}
   gcloud compute forwarding-rules create gce-solace-ext-ports-${basename}-forwarding-rule \
   --region=${region} \
   --ports=1-65535 \
   --address=gce-solace-${basename}-lb-ip \
   --target-pool=gce-solace-hc-pool-${basename}

sleep 60

#
# Start the VMR installation & configuration for each VM
#
for index in 0 1 2; do
  name=${basename}${index}
  if [ "${index}" == "0" ]; then
    role=monitor 
  elif [ "${index}" == "1" ]; then
    role=primary 
  else
    role=backup 
  fi
  gcloud compute scp gce_vmr_startup.sh ${name}:~/install-vmr.sh
  gcloud compute ssh ${name} --command="sudo ~/install-vmr.sh ${basename} ${role} ${connections} ${adminpwd}"
done
