# Script that creates a k3s kubernetes cluster with multipass

## Create cluster
```
./run.sh
export KUBECONFIG=$PWD/k3s.yml 
```

## Test cluster
```
k create deploy nginx --image=nginx:1.20.1-alpine --replicas=6 --port=80
k expose deploy nginx --name=nginx --port=8080 --target-port=80
k run test-nginx --image=busybox --restart=Never --rm -it -- wget --server-response --timeout=2 http://nginx.default.svc.cluster.local:8080
```

