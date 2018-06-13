#!/bin/bash
os=rhel
basename=${os}vmr
name=${basename}
startupscript="gce_vmr_startup_singleton.sh"
bootdisksize=500GB
machinetype="n1-standard-8"
datadisk="${name}-datadisk"
datadisksize=1000GB

gcloud compute disks create ${datadisk} \
--description="Data disk for VMR ${name}" \
--labels="usage=solace-vmr-${os}" \
--size=${datadisksize} \
--type=pd-ssd \
--zone=europe-west1-b

gcloud compute instances create ${name} \
--boot-disk-size=${bootdisksize} \
--boot-disk-type=pd-standard \
--labels="usage=solace-vmr-${os}" \
--machine-type=${machinetype} \
--zone=europe-west1-b \
--disk="name=${datadisk},device-name=sdb,auto-delete=yes,mode=rw" \
--image-project=${os}-cloud \
--image-family=${os}-7

sleep 60

gcloud compute scp ${startupscript} ${name}:~/install-vmr.sh
gcloud compute ssh ${name} --command="sudo ~/install-vmr.sh"
