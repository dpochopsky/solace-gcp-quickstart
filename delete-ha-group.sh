#!/bin/bash

default_zones=(us-east1-b us-east1-c us-east1-d)
default_basename=vmr

printUsage() {
   echo "Usage:  delete-ha-group.sh [OPTIONS]"
   echo "OPTIONS:"
   echo "   -n=BASENAME | --basename=BASENAME"
   echo "      The prefix to be used for each VMRs hostname, dashes and underscores not permitted."
   echo "      Default:  $default_basename"
   echo "   -z=ZONES | --zones=ZONES"
   echo "      Comma separated list of zones for each of the VMRs, all zones must be in the same region."
   echo "      Default:  ${default_zones[*]}"
   echo ""
}


zones=("${default_zones[@]}")
basename=$default_basename

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

region=$(echo ${zones[0]} |cut -d "-" -f1,2)
for i in ${zones[@]}; do
   if [ $region != $(echo $i |cut -d "-" -f1,2) ]; then
      echo "Invalid zones provided, all zones must be in the same region"
      printUsage
      exit -1
   fi
done


# check if routernames contain any dashes or underscores and abort execution, if that is the case.
if [[ $basename == *"-"* || $basename == *"_"* ]]; then
  echo "Invalid value for basename:  $basename"
  printUsage
  exit -1
fi

echo "basename:     $basename"
echo "zones:        ${zones[*]}"
echo "region:       $region"


for index in 0 1 2; do
  name=${basename}${index}
  zone=${zones[$(($index % $numzones))]}

  echo "Deleting VM ${name}..."
  gcloud compute instances delete ${name} \
  --zone=${zone} \
  --quiet

done

   # Delete firewall rules for external ports 
   echo "Deleting firewall rules gce-solace-ext-ports-${basename}..."
   gcloud compute firewall-rules delete gce-solace-ext-ports-${basename} --quiet

   # Delete firewall rules for internal ports used by the VMRs
   echo "Deleting firewall rules gce-solace-int-ports-${basename}..."
   gcloud compute firewall-rules delete gce-solace-int-ports-${basename} --quiet

   # Delete firewall rules for admin access
   echo "Deleting firewall rules gce-solace-admin-ports-${basename}..."
   gcloud compute firewall-rules delete gce-solace-admin-ports-${basename} --quiet

   # Delete load balancer
   echo "Deleting forewarding rules gce-solace-ext-ports-${basename}-forwarding-rule..."
   gcloud compute forwarding-rules delete gce-solace-ext-ports-${basename}-forwarding-rule \
   --region=${region} \
   --quiet
   echo "Deleting external address gce-solace-${basename}-lb-ip..."
   gcloud compute addresses delete gce-solace-${basename}-lb-ip \
   --region=${region} \
   --quiet

   # Delete target pool
   echo "Deleting target pool gce-solace-hc-pool-${basename}..."
   gcloud compute target-pools delete gce-solace-hc-pool-${basename} \
   --region=${region} \
   --quiet

   # Delete health check
   echo "Deleting http health check gce-solace-hc-${basename}..."
   gcloud compute http-health-checks delete gce-solace-hc-${basename} --quiet

   echo "Deletions complete."
