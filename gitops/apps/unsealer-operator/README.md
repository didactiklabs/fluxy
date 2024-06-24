# Add unseal secrets

- threshold keys secret
```sh
kubectl create secret generic thresholdkeys -n vault-unsealer-operator-system --from-literal key1=YOUR_KEY \
  --from-literal key2=YOUR_KEY \
  --from-literal key3=YOUR_KEY
```