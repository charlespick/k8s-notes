#!/bin/bash
microk8s helm repo add awx-operator https://ansible-community.github.io/awx-operator-helm/
microk8s helm repo update
microk8s helm install my-awx-operator awx-operator/awx-operator -n awx-operator --create-namespace
