#!/usr/bin/env bash

NODES_NUM=3
NODES_NAME_PREFFIX="k3s-node"

for N in $(seq $NODES_NUM)
do
    NODE_STATUS=$( multipass list | grep ${NODES_NAME_PREFFIX}-${N} )

    if [ -z "$NODE_STATUS" ]
    then
        echo -e "\e[32mCreating node ${NODES_NAME_PREFFIX}-${N} ...\e[0m"
        multipass launch -n ${NODES_NAME_PREFFIX}-${N} -c 1 -m 1024M >/dev/null 2>&1
    else
        if [ "$( echo $NODE_STATUS | awk '{print $2;}' )" == "Stopped" ]
        then
            echo -e "\e[32mNode ${NODES_NAME_PREFFIX}-${N} already exists. Starting ...\e[32m"
            multipass start ${NODES_NAME_PREFFIX}-${N} >/dev/null 2>&1
        else
            echo -e "\e[32mNode ${NODES_NAME_PREFFIX}-${N} already exists\e[0m"
        fi
    fi
done

echo -e "\e[32mInitializing node ${NODES_NAME_PREFFIX}-1 ...\e[0m"
multipass exec ${NODES_NAME_PREFFIX}-1 -- bash -c "curl -sfL https://get.k3s.io | sh -" #>/dev/null 2>&1

TOKEN=$(multipass exec ${NODES_NAME_PREFFIX}-1 sudo cat /var/lib/rancher/k3s/server/node-token)
IP=$(multipass info ${NODES_NAME_PREFFIX}-1 | grep IPv4 | awk '{print $2}')

for N in $(seq $NODES_NUM)
do
    if [ $N -gt 1 ]
    then
        echo -e "\e[32mInitializing node ${NODES_NAME_PREFFIX}-${N} ...\e[0m"
        multipass exec ${NODES_NAME_PREFFIX}-${N} -- \
            bash -c "curl -sfL https://get.k3s.io | K3S_URL=\"https://$IP:6443\" K3S_TOKEN=\"$TOKEN\" sh -" #>/dev/null 2>&1
    fi
done

echo -e "\e[32mGetting kubeconfig\e[0m"
multipass exec ${NODES_NAME_PREFFIX}-1 sudo cat /etc/rancher/k3s/k3s.yaml | sed "s/127.0.0.1/$IP/" > k3s.yml
