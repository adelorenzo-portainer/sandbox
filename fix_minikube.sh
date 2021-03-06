#!/bin/ash

#Delete stale endpoint
jwt=`http POST :9000/api/auth Username="portainer" Password="portainer1234" | jq '.jwt' | sed 's/^.//' | sed 's/.$//'`
fix_minikube=`http GET :9000/api/endpoints "Authorization: Bearer $jwt" | jq -c '.[] | {Id, Name} | select(.Name == "kubernetes")' | grep -o ':.*' | cut -f2- -d: | cut -f1 -d","`
#del_e=`http GET :9000/api/endpoints "Authorization: Bearer $jwt" | jq -c '.[] | {Id, Name | select(.Name == "kubernetes")' | grep -o ':.*' | cut -f2- -d: | cut -f1 -d","`
http DELETE :9000/api/endpoints/$fix_minikube "Authorization: Bearer $jwt"

#Restart Minikube
sudo -u portainer minikube start

#Install Portainer Agent for Kube
sudo -u portainer kubectl apply -f - <<EOY
apiVersion: v1
kind: Namespace
metadata:
  name: portainer
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: portainer-sa-clusteradmin
  namespace: portainer
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: portainer-crb-clusteradmin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: portainer-sa-clusteradmin
  namespace: portainer
---
apiVersion: v1
kind: Service
metadata:
  name: portainer-agent
  namespace: portainer
spec:
  type: NodePort
  selector:
    app: portainer-agent
  ports:
    - name: http
      protocol: TCP
      port: 9001
      targetPort: 9001
      nodePort: 30778
---
apiVersion: v1
kind: Service
metadata:
  name: portainer-agent-headless
  namespace: portainer
spec:
  clusterIP: None
  selector:
    app: portainer-agent
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: portainer-agent
  namespace: portainer
spec:
  selector:
    matchLabels:
      app: portainer-agent
  template:
    metadata:
      labels:
        app: portainer-agent
    spec:
      serviceAccountName: portainer-sa-clusteradmin
      containers:
      - name: portainer-agent
        image: portainer/agent:latest
        imagePullPolicy: Always
        env:
        - name: LOG_LEVEL
          value: DEBUG
        - name: AGENT_CLUSTER_ADDR
          value: "portainer-agent-headless"
        - name: KUBERNETES_POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        ports:
        - containerPort: 9001
          protocol: TCP
EOY

#Get mapped 30778 port from control-plane
jwt=`http POST :9000/api/auth Username="portainer" Password="portainer1234" | jq '.jwt' | sed 's/^.//' | sed 's/.$//'`
port=`docker port minikube | grep 30778 | head -1 | awk '$1=$1' FS=":" OFS=" " |  awk '{ print $4 }'`
ip=`ip a show eth0 | grep inet | head -1 | awk '{ print $2 }' | sed 's/.\{3\}$//'`

#Add local Kubernetes endpoint
sleep 5
sudo -u portainer http --form POST :9000/api/endpoints "Authorization: Bearer $jwt" Name="kubernetes" URL="tcp://$ip:$port" EndpointCreationType=2 TLS="true" TLSSkipVerify="true" TLSSkipClientVerify="true"

