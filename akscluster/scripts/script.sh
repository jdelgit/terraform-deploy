#!/bin/bash

# Update repos
sudo apt update -y

# Install pip and azure-cli
sudo apt install python3-pip -y
sudo pip3 install azure-cli


# Download and Install Kubectl
curl -LO https://dl.k8s.io/release/v1.27.3/bin/linux/amd64/kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl


# Enable autocompletion
echo 'source <(kubectl completion bash)' >>~/.bashrc
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -o default -F __start_kubectl k' >>~/.bashrc