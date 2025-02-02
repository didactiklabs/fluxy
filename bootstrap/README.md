# Bootstraping Manual

## Cluster init

Configure the first control plane (with root user):

```bash
# You need to copy the file on the remote control-plane
kubeadm init --config kubernetes/config.yaml
```

## CNI (Cilium)

```bash
kubectl apply -f cilium/
```

## Remove control-plane taint

```bash
kubectl taint nodes <NODE_NAME> node-role.kubernetes.io/control-plane:NoSchedule-
```

## Flucd (GitOps)

Deploy fluxcd and gitops resources in the cluster

```bash
kustomize build fluxcd/upstream | kubectl apply -f -
kustomize build fluxcd/setup | kubectl apply -f -
kustomize build fluxcd/ | kubectl apply -f -
```

## DNS

Deploy fluxcd and gitops resources in the cluster

```bash
kubectl apply -f kubernetes/coredns-config.yaml
```
