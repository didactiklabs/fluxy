## Bootstrap vault for the first time

In the pod shell :
```
VAULT_ADDR=http://localhost:8200 vault operator init -key-shares=3 -key-threshold=2
```