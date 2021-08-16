#!/bin/bash

response=$(zenity --height=250 --list --checklist \
   --title='Selection' --column=Boxes --column=Selections \
   TRUE Docker TRUE Docker-Swarm TRUE Kubernetes --separator=':')

if [ -z "$response" ] ; then
   echo "No selection"
   exit 1
fi

IFS=":" ; for word in $response ; do 
   case $word in
      Docker) echo install_standalone.sh ;;
      Docker-Swarm) echo install_swarm.sh ;;
      Kubernetes) echo install_kube.sh ;;
   esac
done
