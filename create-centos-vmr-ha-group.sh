#!/bin/bash
basename=centosvmr
for index in 0 1 2; do
  name=${basename}${index}
  if [ "${index}" == "0" ]; then
    startupscript="gce_vmr_startup_monitor.sh"
    bootdisksize=50GB
    machinetype="n1-standard-2"
    datadisk="${name}-datadisk"
    datadisksize=100GB
  elif [ "${index}" == "1" ]; then
    startupscript="test.sh"
    bootdisksize=500GB
    machinetype="n1-standard-8"
    datadisk="${name}-datadisk"
    datadisksize=1000GB
  else
    startupscript="gce_vmr_startup_backup.sh"
    bootdisksize=500GB
    machinetype="n1-standard-8"
    datadisk="${name}-datadisk"
    datadisksize=1000GB
  fi

    gcloud compute disks create ${datadisk} \
    --description="Data disk for VMR ${name}" \
    --labels="usage=solace-vmr-centos" \
    --size=${datadisksize} \
    --type=pd-ssd \
    --zone=europe-west1-b

    gcloud compute instances create ${name} \
    --boot-disk-size=${bootdisksize} \
    --boot-disk-type=pd-standard \
    --labels="usage=solace-vmr-centos" \
    --machine-type=${machinetype} \
    --zone=europe-west1-b \
    --disk="name=${datadisk},device-name=sdb,auto-delete=yes,mode=rw" \
    --image-project=centos-cloud \
    --image-family=centos-7
done
sleep 60

for index in 0 1 2; do
  name=${basename}${index}
  if [ "${index}" == "0" ]; then
    startupscript="gce_vmr_startup_monitor.sh"
  elif [ "${index}" == "1" ]; then
    startupscript="gce_vmr_startup_primary.sh"
  else
    startupscript="gce_vmr_startup_backup.sh"
  fi
  gcloud compute scp ${startupscript} ${name}:~/install-vmr.sh
  gcloud compute ssh ${name} --command="sudo ~/install-vmr.sh"
done
