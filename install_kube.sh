#Start minikube
kind create cluster --image kindest/node:v1.17.17 --config - <<EOY
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30778
    hostPort: 30778
  - containerPort: 80
    hostPort: 81
    listenAddress: "0.0.0.0" # Optional, defaults to "0.0.0.0"
- role: worker
EOY

#Add the metrics server to the kube cluster
kubectl apply -f - <<EOY
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
    k8s-app: metrics-server
    rbac.authorization.k8s.io/aggregate-to-admin: "true"
    rbac.authorization.k8s.io/aggregate-to-edit: "true"
    rbac.authorization.k8s.io/aggregate-to-view: "true"
  name: system:aggregated-metrics-reader
rules:
- apiGroups:
  - metrics.k8s.io
  resources:
  - pods
  - nodes
  verbs:
  - get
  - list
  - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
    k8s-app: metrics-server
  name: system:metrics-server
rules:
- apiGroups:
  - ""
  resources:
  - pods
  - nodes
  - nodes/stats
  - namespaces
  - configmaps
  verbs:
  - get
  - list
  - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server-auth-reader
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: extension-apiserver-authentication-reader
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server:system:auth-delegator
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  labels:
    k8s-app: metrics-server
  name: system:metrics-server
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:metrics-server
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system
---
apiVersion: v1
kind: Service
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server
  namespace: kube-system
spec:
  ports:
  - name: https
    port: 443
    protocol: TCP
    targetPort: https
  selector:
    k8s-app: metrics-server
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server
  namespace: kube-system
spec:
  selector:
    matchLabels:
      k8s-app: metrics-server
  strategy:
    rollingUpdate:
      maxUnavailable: 0
  template:
    metadata:
      labels:
        k8s-app: metrics-server
    spec:
      containers:
      - args:
        - --cert-dir=/tmp
        - --secure-port=443
        - --kubelet-insecure-tls
        - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
        - --kubelet-use-node-status-port
        - --metric-resolution=15s
        image: k8s.gcr.io/metrics-server/metrics-server:v0.5.0
        imagePullPolicy: IfNotPresent
        livenessProbe:
          failureThreshold: 3
          httpGet:
            path: /livez
            port: https
            scheme: HTTPS
          periodSeconds: 10
        name: metrics-server
        ports:
        - containerPort: 443
          name: https
          protocol: TCP
        readinessProbe:
          failureThreshold: 3
          httpGet:
            path: /readyz
            port: https
            scheme: HTTPS
          initialDelaySeconds: 20
          periodSeconds: 10
        resources:
          requests:
            cpu: 100m
            memory: 200Mi
        securityContext:
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1000
        volumeMounts:
        - mountPath: /tmp
          name: tmp-dir
      nodeSelector:
        kubernetes.io/os: linux
      priorityClassName: system-cluster-critical
      serviceAccountName: metrics-server
      volumes:
      - emptyDir: {}
        name: tmp-dir
---
apiVersion: apiregistration.k8s.io/v1
kind: APIService
metadata:
  labels:
    k8s-app: metrics-server
  name: v1beta1.metrics.k8s.io
spec:
  group: metrics.k8s.io
  groupPriorityMinimum: 100
  insecureSkipTLSVerify: true
  service:
    name: metrics-server
    namespace: kube-system
  version: v1beta1
  versionPriority: 100
EOY

kubectl apply -f - <<EOY
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
        image: portainerci/agent:develop
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

# Add Portainer Agent to the local kind Kubernetes cluster
# sleep 5
# wget  -O /tmp/portainer-agent-k8s.yaml https://downloads.portainer.io/portainer-agent-k8s-nodeport.yaml
# kubectl apply -f /tmp/portainer-agent-k8s.yaml --validate=false
# rm /tmp/portainer-agent-k8s.yaml

# Check if the Portainer Agent is running
while true
do
agent_state=`kubectl get pod -n portainer | awk '{ print $3 }' | tail -1`
if [ "$agent_state" != "Running" ]; then
        echo -ne '⚡ Portainer Agent Not Running yet\r'
else
        break
fi
sleep 1
done

# Add the Endpoint
sleep 5
jwt=`http POST :9000/api/auth Username="portainer" Password="portainer1234" | jq '.jwt' | sed 's/^.//' | sed 's/.$//'`
port=30778
ip=`ip a show eth0 | grep inet | head -1 | awk '{ print $2 }' | sed 's/.\{3\}$//'`
http --form POST :9000/api/endpoints "Authorization: Bearer $jwt" Name="kubernetes" URL="tcp://$ip:$port" EndpointCreationType=2 TLS="true" TLSSkipVerify="true" TLSSkipClientVerify="true"
