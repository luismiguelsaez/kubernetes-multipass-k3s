#!/usr/bin/env bash

NODES=3

for N in $(seq $NODES)
do
    NODE_STATUS=$( multipass list | grep k3s-node-${N} )

    if [ -z "$NODE_STATUS" ]
    then
        echo "Creating node ..."
        multipass launch -n k3s-node-${N} -c 1 -m 1024M
    else
        echo "Node already exists"
    fi
done

echo "Initializing node k3s-node-1 ..."
multipass exec  k3s-node-1 -- bash -c "curl -sfL https://get.k3s.io | sh -"

TOKEN=$(multipass exec k3s-node-1 sudo cat /var/lib/rancher/k3s/server/node-token)
IP=$(multipass info k3s-node-1 | grep IPv4 | awk '{print $2}')

for N in $(seq $NODES)
do
    if [ $N -gt 1 ]
    then
        echo "Initializing node k3s-node-${N} ..."
        multipass exec k3s-node-${N} -- \
            bash -c "curl -sfL https://get.k3s.io | K3S_URL=\"https://$IP:6443\" K3S_TOKEN=\"$TOKEN\" sh -"
    fi
done

echo "Getting kubeconfig"
multipass exec k3s-node-1 sudo cat /etc/rancher/k3s/k3s.yaml | sed "s/127.0.0.1/$IP/" > k3s.yml
