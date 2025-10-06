#!/bin/bash

# patch for microk8s needed for some reason
# must run after longhorn is mostly deployed (but not working yet)

microk8s kubectl -n longhorn-system patch deployment longhorn-driver-deployer \
 --type='json' \
 -p='[{"op":"add","path":"/spec/template/spec/containers/0/command/-","value":"--kubelet-root-dir=/var/snap/microk8s/common/var/lib/kubelet"}]'
microk8s kubectl -n longhorn-system rollout restart deployment/longhorn-driver-deployer
