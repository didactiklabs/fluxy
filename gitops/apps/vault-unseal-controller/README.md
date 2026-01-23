# Add unseal secrets

- threshold keys secret
```sh
kubectl create secret generic internal-unseal-keys -n vault \
  --from-literal key1=YOUR_KEY_1 \
  --from-literal key2=YOUR_KEY_2 \
  --from-literal key3=YOUR_KEY_3
```
