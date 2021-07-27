#!/bin/ash

#Install Docker in Docker
echo 10 | dialog --title "Portainer Sandbox Setup" --gauge "Installing Docker" 10 80 0
/root/install_standalone.sh > /dev/null 2>&1
sleep 1

#Install Docker Swarm in Docker
echo 30 | dialog --title "Portainer Sandbox Setup" --gauge "Installing Docker Swarm" 10 80 0
/root/install_swarm.sh > /dev/null 2>&1
sleep 1

#Install Minkube
echo 50 | dialog --title "Portainer Sandbox Setup" --gauge "Installing Kubernetes" 10 80 0
/root/install_minikube.sh > /dev/null 2>&1
sleep 1

#Add Docker Endpoint
echo 60 | dialog --title "Portainer Sandbox Setup" --gauge "Adding Docker Endpoint" 10 80 0
/root/endpoint_standalone.sh > /dev/null 2>&1
sleep 1

#Add Docker Swarm Endpoint
echo 70 | dialog --title "Portainer Sandbox Setup" --gauge "Adding Docker Swarm Endpoint" 10 80 0
/root/endpoint_swarm.sh > /dev/null 2>&1
sleep 1

#Add Minikube Endpoint
echo 80 | dialog --title "Portainer Sandbox Setup" --gauge "Adding Kubernetes Endpoint" 10 80 0
/root/endpoint_minikube.sh > /dev/null 2>&1
sleep 1

#Housekeeping
echo 100 | dialog --title "Portainer Sandbox Setup" --gauge "Final settings..." 10 80 0
echo '#!/bin/ash'> /root/.profile
echo '/root/fix.sh' >> /root/.profile
echo 'exec startx  > /dev/null 2>&1' >> /root/.profile
sleep 1

dialog --title "Portainer Sandbox Installed" --textbox .success 10 100
startx > /dev/null 2>&1
