# Install a Solace Message Router onto a Google Compute Engine Linux Virtual Machine

The Solace PubSub+ Software Broker (formerly known as VMR) provides enterprise-grade messaging capabilities deployable in any computing environment. The PubSub+ Software Broker provides the same rich feature set as Solace’s proven hardware appliances, with the same open protocol support, APIs and common management. The VMR can be deployed in the datacenter or natively within all popular private and public clouds.

# How to Deploy a VMR
This is a 2 step process:

* Download and install the Google SDK on your computer
See https://cloud.google.com/sdk/

* Clone this project, edit the gce_vmr_startup... scripts as appropriate to change passwords and run either the create-...-vmr-singleton.sh for a standalone VMR or create...-vmr-ha-group.sh script for a full HA 
triplet with built-in redundancy.
This will create 1 or two GCE compute nodes with disks for your VMRs and download, install and initialize the latest Solace PubSub+ evaluation version on those nodes.

# Set up network security to allow acces

Now that the VMR is instantiated, the network security firewall rule needs to be set up to allow access to both the admin application and data traffic.  Under the "Networking -> VPC network -> Firewall rules" tab add a new rule to your project exposing the required ports


![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/images/gce_network.png "GCE Firewall rules"

`tcp:80;tcp:8080;tcp:1883;tcp:8000;tcp:9000;tcp:55003;tcp:55555


For more information on the ports required for the message router see the [configuration defaults](http://docs.solace.com/Solace-VMR-Set-Up/VMR-Configuration-Defaults.htm

. For more information on Google Cloud Platform Firewall rules see [Networking and Firewalls](https://cloud.google.com/compute/docs/networks-and-firewalls


# Gaining admin access to the VM


For persons used to working with Solace message router console access, this is still available with the google compute engine instance.  Access the web ssh terminal window by clicking the [ssh] button next to your VMR instance,  then launch a SolOS cli session


![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/images/gce_console.png "GCE console with SolOS cli"

`sudo docker exec -it solace /usr/sw/loads/currentload/bin/cli -A


For persons who are unfamiliar with the Solace mesage router or would prefer an administration application the SolAdmin management application is available.  For more information on SolAdmin see the [SolAdmin page](http://dev.solace.com/tech/soladmin/).  To get SolAdmin, visit the Solace [download page](http://dev.solace.com/downloads/) and select OS version desired.  Management IP will be the Public IP associated with youe GCE instance and port will be 8080 by default


![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/images/gce_soladmin.png "soladmin connection to gce"


# Testing data access to the VM


To test data traffic though the newly created VMR instance, visit the Solace developer portal and and select your preferred programming langauge to [send and receive messages](http://dev.solace.com/get-started/send-receive-messages/). Under each language there is a Publish/Subscribe tutorial that will help you get started


![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/images/solace_tutorial.png "getting started publish/subscribe"


## Contributin


Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us


## Author


See the list of [contributors](https://github.com/SolaceLabs/solace-gcp-quickstart/graphs/contributors) who participated in this project


## Licens


This project is licensed under the Apache License, Version 2.0. - See the [LICENSE](LICENSE) file for details


## Resource


For more information about Solace technology in general please visit these resources


- The Solace Developer Portal website at: http://dev.solace.co

- Understanding [Solace technology.](http://dev.solace.com/tech/

- Ask the [Solace community](http://dev.solace.com/community/)
