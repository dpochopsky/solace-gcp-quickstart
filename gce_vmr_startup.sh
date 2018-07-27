#!/bin/bash

echo "start-up script triggered..."

printUsage() {
   echo "Usage:  gce_vmr_startup.sh BASENAME ROLE CONN_SCALE ADMIN_PWD"
   echo "ARGUMENTS:"
   echo "   BASENAME"
   echo "      The prefix to be used for each VMRs hostname."
   echo "   ROLE"
   echo "      The VMR role, must be one of monitor, primary or backup."
   echo "   CONN_SCALE"
   echo "      VMR connection scaling size (100, 1000, 10000, 100000, 200000)"
   echo "   ADMIN_PWD"
   echo "      The admin password to set for all vmrs."
   echo ""
}

if [[ $# -ne 4 ]]; then
    echo "Error:  Invalid number of paramenters."
    printUsage
    exit -1
fi


export baseroutername=$1
export vmr_role=$2
export vmr_scaling=$3
export vmradminpass=$4
export monitor_ip=${baseroutername}0
export primary_ip=${baseroutername}1
export backup_ip=${baseroutername}2
export redundancy_enable=yes
export redundancy_group_password=mysolgrouppass
export redundancy_group_node_${baseroutername}0_connectvia=${monitor_ip}
export redundancy_group_node_${baseroutername}0_nodetype=monitoring
export redundancy_group_node_${baseroutername}1_connectvia=${primary_ip}
export redundancy_group_node_${baseroutername}1_nodetype=message_routing
export redundancy_group_node_${baseroutername}2_connectvia=${backup_ip}
export redundancy_group_node_${baseroutername}2_nodetype=message_routing

if [ "${vmr_role}" == "monitor" ]; then
##values for your monitor node
  export nodetype=monitoring
  export routername=${baseroutername}0
elif [ "${vmr_role}" == "primary" ]; then
##values for your primary node
  export nodetype=message_routing
  export routername=${baseroutername}1
  export system_scaling_maxconnectioncount=${vmr_scaling}
  export configsync_enable=yes
  export redundancy_activestandbyrole=primary
  export redundancy_matelink_connectvia=${backup_ip}
elif [ "${vmr_role}" == "backup" ]; then
##values for your backup node
  export nodetype=message_routing
  export routername=${baseroutername}2
  export configsync_enable=yes
  export redundancy_activestandbyrole=backup
  export system_scaling_maxconnectioncount=${vmr_scaling}
  export redundancy_matelink_connectvia=${primary_ip}
else
  echo "unknown role or singleton selected, disabling redundancy"
  export redundancy_enable=no
  export configsync_enable=no
  unset redundancy_group_node_${baseroutername}0_connectvia
  unset redundancy_group_node_${baseroutername}0_nodetype
  unset redundancy_group_node_${baseroutername}1_connectvia
  unset redundancy_group_node_${baseroutername}1_nodetype
  unset redundancy_group_node_${baseroutername}2_connectvia
  unset redundancy_group_node_${baseroutername}2_nodetype
fi
###

#
# Install and start the VMR installation script 
#
if [ ! -d /var/lib/solace ]; then
  echo "Done, starting install..."
  echo "creating directory..."
  mkdir /var/lib/solace
  cd /var/lib/solace
  service network status
  yum -y update
  yum install -y wget

  LOOP_COUNT=0
  echo "downloading VMR install script..."
  while [ $LOOP_COUNT -lt 3 ]; do
    wget https://raw.githubusercontent.com/dpochopsky/solace-gcp-quickstart/master/vmr-install.sh
    if [ 0 != `echo $?` ]; then
      ((LOOP_COUNT++))
    else
      break
    fi
  done
  if [ ${LOOP_COUNT} == 3 ]; then
    echo "`date` ERROR: Failed to download initial install script, exiting"
    exit 1
  fi

  chmod +x /var/lib/solace/vmr-install.sh
  bash /var/lib/solace/vmr-install.sh -i https://products.solace.com/download/PUBSUB_DOCKER_STAND -p ${vmradminpass}
fi
