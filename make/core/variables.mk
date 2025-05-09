ifndef VARIABLES_MK
VARIABLES_MK := 1

KUSTOMIZE_BASE=./k8s/base
KUSTOMIZE_OVERLAY_DEV=./k8s/overlays/dev
NAMESPACE=secureevent

.PHONY: all apply-base apply-dev get-pods get-services

all: apply-base

apply-base:
	kubectl apply -k $(KUSTOMIZE_BASE)

apply-dev:
	kubectl apply -k $(KUSTOMIZE_OVERLAY_DEV)

get-pods:
	kubectl get pods -n $(NAMESPACE)

get-services:
	kubectl get svc -n $(NAMESPACE)

endif