#!/bin/ash

response=$(zenity --height=250 --list --checklist \
   --text='Please select the orchestrator(s)' --column=Check --column=Orchestrator \
   TRUE Docker TRUE Docker-Swarm TRUE Kubernetes --separator=':')

if [ -z "$response" ] ; then
   echo "No selection"
   exit 1
fi

IFS=":" ; for word in $response ; do 
   case $word in
      Docker) /usr/local/bin/.install_standalone.sh | zenity --text "Installing Docker" --progress --auto-close --pulsate ;;
      Docker-Swarm) echo install_swarm.sh  | zenity --title "Installing Docker Swarm" --progress --auto-close --pulsate ;;
      Kubernetes) echo install_kube.sh  | zenity --title "Installing Kubernetes" --progress --auto-close --pulsate ;;
   esac
done
