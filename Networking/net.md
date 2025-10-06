# Networking in K8s
```
metallb > ingress > service > backend
```
## MetalLB
Essentially ties a static IP to the Ingress so it's reachable no matter what host it's currently scheduled on. 

Normally, you select a static IP for the ingress and give it a DNS name like ingress01.domain. Then, configure that IP for the ingress controller. 

## Ingress
Reads the requested host as requests reach the cluster and routes them according to the rules defined in ingress resources. Ingress resources are defined with the service, not the ingress controller itself. Ingress resource definitions refer to the backend by their service and port number
