#!/bin/bash
docker build . -t dimetron/devops-cli:2.9

docker rm -f devops-cli 
docker run -d --net=host -v /var/run/docker.sock:/var/run/docker.sock --name devops-cli dimetron/devops-cli:2.9 -- /usr/sbin/sshd -D -e -p 2221



docker exec -t devops-cli kind delete cluster --name dev-local 2>/dev/null || :
docker exec -t devops-cli kind create cluster --name dev-local --wait 2m
docker exec -t devops-cli zsh -c 'kind get kubeconfig   --name dev-local  > ~/.kube/config'
docker exec -t devops-cli zsh -c 'kind get kubeconfig   --name dev-local' > ~/.kube/config

docker exec -it devops-cli k9s

