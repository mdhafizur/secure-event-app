# Makefile for SecureEvent Kubernetes Project

KUSTOMIZE_BASE=./k8s/base
KUSTOMIZE_OVERLAY_DEV=./k8s/overlays/dev
NAMESPACE=secureevent

.PHONY: all apply-base apply-dev logs-mongo get-pods kafka-install mongo-client kafka-client prometheus-install loki-install grafana grafana-install get-services apply-prometheus apply-loki apply-grafana delete-grafana reapply-grafana delete-loki reapply-loki port-forward-mongodb port-forward-redis port-forward-grafana port-forward-prometheus port-forward-loki recreate-grafana

all: apply-base

apply-base:
	kubectl apply -k $(KUSTOMIZE_BASE)

apply-dev:
	kubectl apply -k $(KUSTOMIZE_OVERLAY_DEV)

logs-mongo:
	kubectl logs -f -n $(NAMESPACE) deployment/mongodb

logs-redis:
	kubectl logs -f -n $(NAMESPACE) deployment/redis

logs-grafana:
	kubectl logs -f -n $(NAMESPACE) deployment/grafana

logs-prometheus:
	kubectl logs -f -n $(NAMESPACE) deployment/prometheus

logs-loki:
	kubectl logs -f -n $(NAMESPACE) statefulset/loki

get-pods:
	kubectl get pods -n $(NAMESPACE)

get-services:
	kubectl get svc -n $(NAMESPACE)

mongo-client:
	kubectl run mongo-client -n $(NAMESPACE) --rm -it --restart=Never \
		--image=mongo:6.0 -- bash

kafka-client:
	kubectl run kafka-client --restart='Never' --rm -i -t --namespace $(NAMESPACE) \
		--image docker.io/bitnami/kafka:latest -- bash

kafka-install:
	helm repo add bitnami https://charts.bitnami.com/bitnami
	helm repo update
	kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	helm install kafka bitnami/kafka --namespace $(NAMESPACE) \
		--set replicaCount=1 \
		--set auth.clientProtocol=plaintext \
		--set auth.interBrokerProtocol=plaintext \
		--set zookeeper.replicaCount=1 \
		--set persistence.enabled=false \
		--set externalAccess.enabled=false

apply-prometheus:
	kubectl apply -f k8s/base/prometheus-deployment.yaml

apply-loki:
	kubectl apply -f k8s/base/loki-deployment.yaml

apply-grafana:
	kubectl apply -f k8s/base/grafana-deployment.yaml

delete-grafana:
	kubectl delete deployment grafana -n $(NAMESPACE)

reapply-grafana:
	kubectl apply -f k8s/base/grafana-deployment.yaml

recreate-grafana:
	@echo "🔄 Deleting existing Grafana deployment..."
	-kubectl delete deployment grafana -n $(NAMESPACE)

	@echo "🚀 Applying new Grafana deployment..."
	kubectl apply -f k8s/base/grafana-deployment.yaml

	@echo "⏳ Waiting for Grafana pod to become ready (timeout: 60s)..."
	@timeout=60; \
	while [ $$timeout -gt 0 ]; do \
		status=$$(kubectl get pods -n $(NAMESPACE) -l app=grafana -o jsonpath="{.items[0].status.containerStatuses[0].ready}" 2>/dev/null); \
		if [ "$$status" = "true" ]; then \
			echo "✅ Grafana is ready."; \
			break; \
		else \
			echo "Waiting... ($$timeout)"; \
			sleep 2; \
			timeout=$$((timeout - 2)); \
		fi; \
	done

	@echo "🧹 Cleaning up old port-forward on port 3000 (if any)..."
	-lsof -ti :3000 | xargs kill -9 2>/dev/null || true

	@echo "🌐 Starting Grafana port-forward on http://localhost:3000"
	@nohup kubectl port-forward -n $(NAMESPACE) svc/grafana 3000:80 > grafana.log 2>&1 &
	@echo "📁 Port-forwarding started in background. Logs: grafana.log"


recreate-prometheus:
	@echo "🔄 Deleting existing Prometheus deployment..."
	-kubectl delete deployment prometheus -n $(NAMESPACE) --ignore-not-found

	@echo "🚀 Applying new Prometheus deployment..."
	kubectl apply -f k8s/base/prometheus-deployment.yaml

	@echo "⏳ Waiting for Prometheus pod to become ready (timeout: 30s)..."
	@timeout=30; \
	while [ $$timeout -gt 0 ]; do \
		status=$$(kubectl get pods -n $(NAMESPACE) -l app=prometheus -o jsonpath="{.items[0].status.containerStatuses[0].ready}" 2>/dev/null); \
		if [ "$$status" = "true" ]; then \
			echo "✅ Prometheus is ready."; \
			break; \
		else \
			echo "⏳ Waiting... ($$timeout seconds left)"; \
			sleep 2; \
			timeout=$$((timeout - 2)); \
		fi; \
	done

	@echo "🧹 Cleaning up old port-forward on port 9090 (if any)..."
	-lsof -ti :9090 | xargs kill -9 2>/dev/null || true

	@echo "🌐 Starting Prometheus port-forward on http://localhost:9090"
	@nohup kubectl port-forward -n $(NAMESPACE) svc/prometheus 9090:9090 > prometheus.log 2>&1 &
	@echo "📁 Port-forwarding started in background. Logs: prometheus.log"



recreate-loki:
	@echo "Deleting Loki StatefulSet..."
	-kubectl delete statefulset loki -n $(NAMESPACE)
	@echo "Deleting Loki Service..."
	-kubectl delete svc loki -n $(NAMESPACE)
	@echo "Deleting Loki PVCs (if any)..."
	-kubectl delete pvc -l app=loki -n $(NAMESPACE)
	@echo "Re-applying Loki stack from k8s/base/loki-deployment.yaml..."
	kubectl apply -f k8s/base/loki-deployment.yaml

	@echo "Waiting for Loki pod to become ready (timeout: 60s)..."
	@timeout=10; \
	while [ $$timeout -gt 0 ]; do \
		if kubectl get pods -n $(NAMESPACE) -l app=loki -o jsonpath="{.items[0].status.containerStatuses[0].ready}" 2>/dev/null | grep -q "true"; then \
			echo "Loki is ready."; \
			break; \
		else \
			echo "Waiting... ($$timeout)"; \
			sleep 2; \
			timeout=$$((timeout - 2)); \
		fi; \
	done

	@echo "Cleaning up old port-forward on 3100 (if any)..."
	-lsof -ti :3100 | xargs kill -9 2>/dev/null || true

	@echo "Starting Loki port-forward on localhost:3100"
	@nohup kubectl port-forward -n $(NAMESPACE) svc/loki 3100:3100 > loki.log 2>&1 &
	@echo "Port-forwarding started in background. Logs: loki.log"


recreate-redis:
	@echo "Deleting Redis Deployment..."
	-kubectl delete deployment redis -n $(NAMESPACE)
	@echo "Deleting Redis Service..."
	-kubectl delete svc redis -n $(NAMESPACE)
	@echo "Re-applying Redis from k8s/base/redis-deployment.yaml..."
	kubectl apply -f k8s/base/redis-deployment.yaml

	@echo "Waiting for Redis pod to become ready (timeout: 60s)..."
	@timeout=60; \
	while [ $$timeout -gt 0 ]; do \
		if kubectl get pods -n $(NAMESPACE) -l app=redis -o jsonpath="{.items[0].status.containerStatuses[0].ready}" 2>/dev/null | grep -q "true"; then \
			echo "Redis is ready."; \
			break; \
		else \
			echo "Waiting... ($$timeout)"; \
			sleep 2; \
			timeout=$$((timeout - 2)); \
		fi; \
	done

	@echo "Cleaning up old port-forward on 6379 (if any)..."
	-lsof -ti :6379 | xargs kill -9 2>/dev/null || true

	@echo "Starting Redis port-forward on localhost:6379"
	@nohup kubectl port-forward -n $(NAMESPACE) svc/redis 6379:6379 > redis.log 2>&1 &
	@echo "Port-forwarding started in background. Logs: redis.log"

recreate-mongodb:
	@echo "Deleting MongoDB Deployment..."
	-kubectl delete deployment mongodb -n $(NAMESPACE)
	@echo "Deleting MongoDB Service..."
	-kubectl delete svc mongodb -n $(NAMESPACE)
	@echo "Re-applying MongoDB from k8s/base/mongodb-deployment.yaml..."
	kubectl apply -f k8s/base/mongodb-deployment.yaml

	@echo "Waiting for MongoDB pod to become ready (timeout: 60s)..."
	@timeout=60; \
	while [ $$timeout -gt 0 ]; do \
		if kubectl get pods -n $(NAMESPACE) -l app=mongodb -o jsonpath="{.items[0].status.containerStatuses[0].ready}" 2>/dev/null | grep -q "true"; then \
			echo "MongoDB is ready."; \
			break; \
		else \
			echo "Waiting... ($$timeout)"; \
			sleep 2; \
			timeout=$$((timeout - 2)); \
		fi; \
	done

	@echo "Cleaning up old port-forward on 27017 (if any)..."
	-lsof -ti :27017 | xargs kill -9 2>/dev/null || true

	@echo "Starting MongoDB port-forward on localhost:27017"
	@nohup kubectl port-forward -n $(NAMESPACE) svc/mongodb 27017:27017 > mongodb.log 2>&1 &
	@echo "Port-forwarding started in background. Logs: mongodb.log"



delete-loki:
	kubectl delete statefulset loki -n $(NAMESPACE)

reapply-loki:
	kubectl apply -f k8s/base/loki-deployment.yaml

grafana:
	@echo "Starting Grafana port-forward on http://localhost:3000"
	@nohup kubectl port-forward -n $(NAMESPACE) svc/grafana 3000:80 > grafana.log 2>&1 &
	@echo "Port-forwarding started in background. Logs: grafana.log"

grafana-password:
	kubectl get secret --namespace secureevent grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

port-forward-mongodb:
	@echo "Starting MongoDB port-forward on localhost:27017"
	@nohup kubectl port-forward -n $(NAMESPACE) svc/mongodb 27017:27017 > mongodb.log 2>&1 &
	@echo "Port-forwarding started in background. Logs: mongodb.log"

port-forward-redis:
	@echo "Starting Redis port-forward on localhost:6379"
	@nohup kubectl port-forward -n $(NAMESPACE) svc/redis 6379:6379 > redis.log 2>&1 &
	@echo "Port-forwarding started in background. Logs: redis.log"

port-forward-grafana:
	@echo "Starting Grafana port-forward on localhost:3000"
	@nohup kubectl port-forward -n $(NAMESPACE) svc/grafana 3000:80 > grafana.log 2>&1 &
	@echo "Port-forwarding started in background. Logs: grafana.log"

port-forward-prometheus:
	@echo "Starting Prometheus port-forward on localhost:9090"
	@nohup kubectl port-forward -n $(NAMESPACE) svc/prometheus-server 9090:80 > prometheus.log 2>&1 &
	@echo "Port-forwarding started in background. Logs: prometheus.log"

port-forward-loki:
	@echo "Starting Loki port-forward on localhost:3100"
	@nohup kubectl port-forward -n $(NAMESPACE) svc/loki 3100:3100 > loki.log 2>&1 &
	@echo "Port-forwarding started in background. Logs: loki.log"

