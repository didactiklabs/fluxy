# Cilium Update

```
helm repo add cilium https://helm.cilium.io/
helm repo update
API_SERVER_IP=10.254.0.5
API_SERVER_PORT=6443
helm template cilium cilium/cilium --version 1.16.1 \
    --namespace kube-system \
    --set l2announcements.enabled=true \
    --set socketLB.hostNamespaceOnly=true \
    --set kubeProxyReplacement=true \
    --set k8sServiceHost=${API_SERVER_IP} \
    --set k8sServicePort=${API_SERVER_PORT} \
    --set envoy.enabled=false > bundle.yaml
```
