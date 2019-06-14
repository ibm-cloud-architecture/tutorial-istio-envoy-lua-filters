#!/bin/sh


# Download Istio ref https://istio.io/docs/setup/kubernetes/download/
VERSION=1.1.8
if [[ ! -d istio-${VERSION} ]]; then
 curl -L https://git.io/getLatestIstio | ISTIO_VERSION=${VERSION} sh -
fi

cd istio-${VERSION}

export PATH=$PWD/bin:$PATH

# availbale on 1.2 and up
# istioctl verify-install 

#Install Istio CRDs
for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl apply -f $i; done


# Install Istio Evaluation
kubectl apply -f install/kubernetes/istio-demo.yaml



