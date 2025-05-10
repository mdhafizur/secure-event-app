ifndef DATABASE_MK
DATABASE_MK := 1

include make/core/variables.mk

# Database Management Targets
.PHONY: logs-mongo logs-redis mongo-client port-forward-mongodb port-forward-redis \
	recreate-mongodb recreate-redis

# Logs
logs-mongodb:
	kubectl logs -f -n $(NAMESPACE) deployment/mongodb

logs-redis:
	kubectl logs -f -n $(NAMESPACE) deployment/redis

# Clients
mongo-client:
	kubectl run mongo-client -n $(NAMESPACE) --rm -it --restart=Never \
		--image=mongo:6.0 -- bash

# Recreation with Health Checks
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

# Port Forwarding
port-forward-mongodb:
	@echo "🧹 Cleaning up old MongoDB port-forward on 27017 (if any)..."
	-lsof -ti :27017 | xargs kill -9 2>/dev/null || true
	@echo "🚀 Starting MongoDB port-forward on localhost:27017"
	@nohup kubectl port-forward -n $(NAMESPACE) svc/mongodb 27017:27017 > mongodb.log 2>&1 &
	@echo "📁 Port-forwarding started in background. Logs: mongodb.log"

port-forward-redis:
	@echo "🧹 Cleaning up old Redis port-forward on 6379 (if any)..."
	-lsof -ti :6379 | xargs kill -9 2>/dev/null || true
	@echo "🚀 Starting Redis port-forward on localhost:6379"
	@nohup kubectl port-forward -n $(NAMESPACE) svc/redis 6379:6379 > redis.log 2>&1 &
	@echo "📁 Port-forwarding started in background. Logs: redis.log"

endif