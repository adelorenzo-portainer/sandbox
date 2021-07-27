#!/bin/ash

#Check if the Portainer Agent is running
echo ""
echo ""
while true
do
agent_state=`sudo -u portainer kubectl get pod -n portainer | awk '{ print $3 }' | tail -1`
if [ "$agent_state" != "Running" ]; then
	echo -ne '⚡ Portainer Agent Not Running yet\r'
else
	break
fi
sleep 1
done

echo "DONE!!!"
sleep 10
