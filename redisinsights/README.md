# redisinsight

install redisinsight.  because it has absolutely no authentication, put it behind IAP so i'd feel better about putting this on the internet.  

Check the following link for more information:
[https://cloud.google.com/kubernetes-engine/docs/how-to/configure-gateway-resources#configure_iap](https://cloud.google.com/kubernetes-engine/docs/how-to/configure-gateway-resources#configure_iap)

run the following after you set up IAP and the oauth consent screen, to create the iap secret:

```
kubectl create secret generic my-secret --from-literal=client_id=client_id_key \
    --from-literal=client_secret=client_secret_key
```

then use kustomize to generate yourself some yamls and apply them:

```
kustomize build | kubectl apply -f -
```

Since we used a wildcard cert, you will need to make sure the allowed domains is checked on the backend settings and you add the full wildcard domain to the allowed domain.