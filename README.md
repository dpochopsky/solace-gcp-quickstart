# Install a Solace Message Router onto a Google Compute Engine Linux Virtual Machine

The Solace PubSub+ Software Broker (formerly known as VMR) provides enterprise-grade messaging capabilities deployable in any computing environment. The PubSub+ Software Broker provides the same rich feature set as Solace’s proven hardware appliances, with the same open protocol support, APIs and common management. The VMR can be deployed in the datacenter or natively within all popular private and public clouds.

# How to Deploy a VMR
This is a 2 step process:

* Download and install the Google SDK on your computer
See https://cloud.google.com/sdk/

* Clone this project, run the `create-centos-vmr-ha-group.sh` script for a full HA triplet with built-in redundancy.
This will create three GCE compute nodes with disks for your VMRs and download, install and initialize the latest Solace PubSub+ standard version on those nodes.  In addition, a load balancer and a default set of firewall rules will be created.

The `create-centos-vmr-ha-group.sh` script have a number of optional parameters that the user can define to customize their deployment:

Usage:  create-centos-ha-group.sh [OPTIONS]
OPTIONS:
   -n=BASENAME | --basename=BASENAME
   The prefix to be used for each VMRs hostname, dashes and underscores not permitted.
   Default:  vmr
   -z=ZONES | --zones=ZONES
   Comma separated list of zones for each of the VMRs, all zones must be in the same region.
   Default:  us-east1-b us-east1-c us-east1-d
   -c=CONNECTIONS | --connectionscale=CONNECTIONS
   VMR connection scaling size (100, 1000, 10000, 100000, 200000).
   Default:  1000
   -b=BOOTDISKSIZE | --bootdisksize=BOOTDISKSIZE
   The size of the VM boot disk, recommend 200GB or greater.
   Default:  200GB
   -d=DATADISKSIZE | --datadisksize=DATADISKSIZE
   The size of the VM message spool disk, recommend 200GB or greater.
   Default:  200GB
   -p=ADMINPWD | --adminpassword=ADMINPWD
   The admin password used for all VMRs.
   Default:  admin


# Set up network security to allow access
Now that the VMR is instantiated, the network security firewall rule should be reviewed and updated as required.  Certain messaging protocols require the user to choose ports, as these messaging services are provisioned, the user will need to update the firewall rules.

For more information on the ports required for the message router see the [configuration defaults](http://docs.solace.com/Solace-VMR-Set-Up/VMR-Configuration-Defaults.htm)
. For more information on Google Cloud Platform Firewall rules see [Networking and Firewalls](https://cloud.google.com/compute/docs/networks-and-firewalls)

# Gaining admin access to the VMR

For persons used to working with Solace message router console access, this is still available with the google compute engine instance.  Access the web ssh terminal window by clicking the [ssh] button next to your VMR instance,  then launch a SolOS cli session:

![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/images/gce_console.png "GCE console with SolOS cli")
`sudo docker exec -it solace /usr/sw/loads/currentload/bin/cli -A`

For persons who are unfamiliar with the Solace mesage router or would prefer an administration application the SolAdmin management application is available.  For more information on SolAdmin see the [SolAdmin page](http://dev.solace.com/tech/soladmin/).  To get SolAdmin, visit the Solace [download page](http://dev.solace.com/downloads/) and select OS version desired.  Management IP will be the Public IP associated with youe GCE instance and port will be 8080 by default.

![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/images/gce_soladmin.png "soladmin connection to gce")

# Testing data access to the VMR

To test data traffic though the newly created VMR instance, visit the Solace developer portal and and select your preferred programming langauge to [send and receive messages](http://dev.solace.com/get-started/send-receive-messages/). Under each language there is a Publish/Subscribe tutorial that will help you get started.

![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/images/solace_tutorial.png "getting started publish/subscribe")

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

See the list of [contributors](https://github.com/SolaceLabs/solace-gcp-quickstart/graphs/contributors) who participated in this project.

## License

This project is licensed under the Apache License, Version 2.0. - See the [LICENSE](LICENSE) file for details.

## Resources

For more information about Solace technology in general please visit these resources:

- The Solace Developer Portal website at: http://dev.solace.com
- Understanding [Solace technology.](http://dev.solace.com/tech/)
- Ask the [Solace community](http://dev.solace.com/community/).
