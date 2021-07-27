#!/bin/ash

echo 0 | dialog --title "Wiping environment" --gauge "Removing minikube" 10 80 0
sudo -u portainer minikube delete > /dev/null 2>&1
minikube delete > /dev/null 2>&1
sleep 1

echo 25 | dialog --title "Wiping environment" --gauge "Removing docker & swarm" 10 80 0
docker container kill $(docker ps -q) > /dev/null 2>&1
docker container rm $(docker ps -a -q) > /dev/null 2>&1
docker volume rm $(docker volume ls -q) > /dev/null 2>&1
sleep 1

echo 50 | dialog --title "Wiping environment" --gauge "Re-installing Portainer" 10 80 0
docker volume create portainer_data > /dev/null 2>&1
docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce > /dev/null 2>&1
http POST http://localhost:9000/api/users/admin/init Username="portainer" Password="portainer1234" > /dev/null 2>&1
sleep 1

echo 75 | dialog --title "Wiping environment" --gauge "Final settings" 10 80 0
echo '#!/bin/ash' > /root/.profile
echo '/root/boot-test.sh' >> /root/.profile
sleep 1

echo "100" | dialog --title "Wiping environment" --gauge "Finished!!!" 10 80 0
sleep 1
