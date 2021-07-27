#!/bin/ash

#Fix Docker Endpoint
echo 30  | dialog --title "Fixing Endpoints" --gauge "Docker" 10 80 0
/root/fix_standalone.sh > /dev/null 2>&1
sleep 1

#Fix Swarm Docker Endpoint
echo 50  | dialog --title "Fixing Endpoints" --gauge "Docker Swarm" 10 80 0
/root/fix_swarm.sh > /dev/null 2>&1
sleep 1

#Fix Minikube Endpoint
echo 70  | dialog --title "Fixing Endpoints" --gauge "Kubernetes" 10 80 0
/root/fix_minikube.sh > /dev/null 2>&1
sleep 1

#Finished
echo 100 | dialog --title "Fixing Endpoints" --gauge "Done" 10 80 0
sleep 2

startx > /dev/null 2>&1

