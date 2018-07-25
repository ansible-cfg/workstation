#!/bin/bash

function log {
  message=$1
  white=$(tput setaf 7)
  normal=$(tput sgr0)
  printf "\n###\n# %s\n###\n\n" "${white}${message}${normal}"
}


set -e

# can be docker or crio
CONTAINER_RUNTIME=${1:-docker}
KUBERNETES_FOLDER=/home/fedora/opt/kubernetes
CERT_FOLDER=$KUBERNETES_FOLDER/certs


log "Setting up Kubernetes Cluster with $CONTAINER_RUNTIME"
START_TIME=$SECONDS


sudo rm -rf /tmp/kubeadmin.log


# use default kubeconfig``
export KUBECONFIG=/home/fedora/.kube/config_minikube
KUBEADM_VERSION=$(kubeadm version -o short)

log "TODO #enable kubeadm update again"

log "kubeadm version $KUBEADM_VERSION"

# reset both because we don't know what is currently running
# with Docker
log "kubeadm reset (with docker)"
if [[ ${KUBEADM_VERSION} = "v1.10"* ]] || [[ ${KUBEADM_VERSION} = "v1.9"* ]]
then
  sudo kubeadm reset | tee /tmp/kubeadmin.log
else
  sudo kubeadm reset -f | tee /tmp/kubeadmin.log
fi

# with CRIO
log "kubeadm reset (with crio)"
if [[ ${KUBEADM_VERSION} = "v1.10"* ]] || [[ ${KUBEADM_VERSION} = "v1.9"* ]]
then
  sudo kubeadm reset --cri-socket=/var/run/crio/crio.sock | tee /tmp/kubeadmin.log
else
  sudo kubeadm reset -f --cri-socket=/var/run/crio/crio.sock | tee /tmp/kubeadmin.log
fi

# admissionregistration.k8s.io/v1alpha1 Initializer
# admissionregistration.k8s.io/v1beta1 Mutating/ValidationWebHooks
if [[ ${KUBEADM_VERSION} = "v1.10"* ]] || [[ ${KUBEADM_VERSION} = "v1.9"* ]]
then
cat << EOF > $KUBERNETES_FOLDER/config.yaml
apiVersion: kubeadm.k8s.io/v1alpha1
kind: MasterConfiguration
networking:
  podSubnet: 172.18.0.0/16
apiServerExtraArgs:
  runtime-config: admissionregistration.k8s.io/v1alpha1,admissionregistration.k8s.io/v1beta1,scheduling.k8s.io/v1alpha1=true
  admission-control: Initializers,MutatingAdmissionWebhook,NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,ValidatingAdmissionWebhook,ResourceQuota,Priority
  feature-gates: PersistentLocalVolumes=true,VolumeScheduling=true,MountPropagation=true,PodPriority=true
EOF
else
cat << EOF > $KUBERNETES_FOLDER/config.yaml
apiVersion: kubeadm.k8s.io/v1alpha2
kind: MasterConfiguration
kubernetesVersion: v1.11.0
networking:
  podSubnet: 172.18.0.0/16
apiServerExtraArgs:
  runtime-config: admissionregistration.k8s.io/v1alpha1,admissionregistration.k8s.io/v1beta1
  enable-admission-plugins: Initializers,MutatingAdmissionWebhook,NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,ValidatingAdmissionWebhook,ResourceQuota,Priority
  feature-gates: PersistentLocalVolumes=true,VolumeScheduling=true,MountPropagation=true
EOF
fi

sudo sed -i 's#Environment="KUBELET_CADVISOR_ARGS=-.*#Environment="KUBELET_CADVISOR_ARGS=--cadvisor-port=4194"#' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf || true
sudo sed -i 's#Environment="KUBELET_CGROUP_ARGS=-.*#Environment="KUBELET_CGROUP_ARGS=#' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf || true
if [ "$CONTAINER_RUNTIME" == "docker" ]
then
  sudo sed -i 's#Environment="KUBELET_CGROUP_ARGS=#Environment="KUBELET_CGROUP_ARGS=--kube-reserved=cpu=500m,memory=500Mi --system-reserved=cpu=3500m,memory=10Gi"#g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
else
  sudo sed -i 's#Environment="KUBELET_CGROUP_ARGS=#Environment="KUBELET_CGROUP_ARGS=--kube-reserved=cpu=500m,memory=500Mi --system-reserved=cpu=3500m,memory=10Gi --container-runtime=remote --container-runtime-endpoint=unix:///var/run/crio/crio.sock"#g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
fi
sudo systemctl daemon-reload


if [ "$CONTAINER_RUNTIME" == "docker" ] 
then
  # Either with configuration file
  log "kubeadm init (with docker)"
  sudo kubeadm init --config $KUBERNETES_FOLDER/config.yaml --ignore-preflight-errors cri | tee /tmp/kubeadmin.log
else
  # Configure CRIO: cni-plugin
  if ! sudo grep -q cni-config-dir /etc/sysconfig/crio-network
  then
    sudo sed -i 's#CRIO_NETWORK_OPTIONS=.*#CRIO_NETWORK_OPTIONS=--cni-config-dir=/etc/cni/net.d --cni-plugin-dir=/opt/cni/bin --registry docker.io --insecure-registry reg-dhc.app.corpintra.net#g' /etc/sysconfig/crio-network
    sudo systemctl restart crio
  fi

  # or with cri-socket
  log "kubeadm init (with crio)"
  sudo kubeadm init --pod-network-cidr=172.18.0.0/16 --cri-socket=/var/run/crio/crio.sock | tee /tmp/kubeadmin.log

  # Add ValidationAdmissionWebhook because for now we can not set cri-socket and config file at the same time
  if  ! sudo grep -q ValidatingAdmissionWebhook /etc/kubernetes/manifests/kube-apiserver.yaml 
  then
    sudo sed -i 's#,ResourceQuota#,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota#g' /etc/kubernetes/manifests/kube-apiserver.yaml
  fi
  # Add runtime-config because for now we can not set cri-socket and config file at the same time
  if  ! sudo grep -q admissionregistration.k8s.io /etc/kubernetes/manifests/kube-apiserver.yaml 
  then
    sudo sed -i 's#- kube-apiserver#- kube-apiserver\n    - --runtime-config=admissionregistration.k8s.io/v1alpha1#g' /etc/kubernetes/manifests/kube-apiserver.yaml
  fi
fi

cat /tmp/kubeadmin.log | grep token | grep -o '".*"' | sed 's/"//g' | tee /home/fedora/opt/kubernetes/token.secret


log "Copy kubeconfig to $HOME/.kube/config_minikube"
mkdir -p /home/fedora/.kube
sudo /bin/cp /etc/kubernetes/admin.conf $HOME/.kube/config_minikube
sudo chown $(id -u):$(id -g) $HOME/.kube/config_minikube
sudo chown $(id -u):$(id -g) -R /etc/kubernetes

log "Wait until kube-apiserver is running"
until kubectl get po
do
  echo "Trying kubectl get po until kube-apiserver responds"
done


log "Remove taint on Kubernetes master"
kubectl taint nodes --all node-role.kubernetes.io/master-


log "Creating Minikube context"
kubectl config set-context minikube --cluster=kubernetes --user=kubernetes-admin


log "Deploy calico"
# Changed pod CIDR to 172.18.0.0/16 because of clash with VMWare nat
#kubectl apply -f https://docs.projectcalico.org/v3.0/getting-started/kubernetes/installation/hosted/kubeadm/1.7/calico.yaml
kubectl apply -f /home/fedora/opt/kubernetes/calico.yaml

# Debug Calico with:
#  cd /tmp
#  curl -O -L https://github.com/projectcalico/calicoctl/releases/download/v2.0.0/calicoctl
#  chmod +x calicoctl
#  export ETCD_ENDPOINTS=http://192.168.40.133:6666
#  ./calicoctl get ipPool
#

if [[ ${KUBEADM_VERSION} = "v1.10"* ]] || [[ ${KUBEADM_VERSION} = "v1.11"* ]]
then
  log "Deploy local-storage storageclass"
  kubectl apply -f /home/fedora/opt/kubernetes/storage.yaml
fi

log "Add cluster-admin role to system:serviceaccounts"
kubectl apply -f - << EOF
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: serviceaccounts-cluster-admin
subjects:
- kind: Group
  name: system:serviceaccounts
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF


log "Deploy Kubernetes Dashboard"
kubectl -n kube-system delete secret kubernetes-dashboard-certs --ignore-not-found
kubectl -n kube-system create secret generic kubernetes-dashboard-certs --from-file=dashboard.crt=$CERT_FOLDER/kube/kubernetes-dashboard.crt --from-file=dashboard.key=$CERT_FOLDER/kube/kubernetes-dashboard.key
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
kubectl apply -f - << EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kube-system
spec:
  type: NodePort
  ports:
  - nodePort: 32000
    port: 443
    targetPort: 8443
  selector:
    k8s-app: kubernetes-dashboard
EOF

log "Deploy Weave Scope"
kubectl apply --namespace weave -f "https://cloud.weave.works/k8s/scope.yaml?k8s-version=$(kubectl version | base64 | tr -d '\n')"
kubectl apply -f - << EOF
apiVersion: v1
kind: Service
metadata:
  name: weave-scope-app
  namespace: weave
  labels:
    name: weave-scope-app
    app: weave-scope
    weave-cloud-component: scope
    weave-scope-component: app
spec:
  type: NodePort
  ports:
    - name: app
      port: 80
      protocol: TCP
      targetPort: 4040
      nodePort: 32001
  selector:
    name: weave-scope-app
    app: weave-scope
    weave-cloud-component: scope
    weave-scope-component: app
EOF


log "Deploy freshpods"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/minikube/ec1b443722227428bd2b23967e1b48d94350a5ac/deploy/addons/freshpod/freshpod-rc.yaml


log "Deploy kube-service-etc-hosts-operator"
pushd /home/fedora/code/gopath/src/github.com/sbueringer/kube-service-etc-hosts-operator/kube-service-etc-hosts-operator
ks apply default
popd


ELAPSED_TIME=$(($SECONDS - $START_TIME))
log "Setting up Kubernetes Cluster took $ELAPSED_TIME seconds"