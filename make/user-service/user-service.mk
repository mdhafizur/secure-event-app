ifndef USER_SERVICE_MK
USER_SERVICE_MK := 1

include make/core/variables.mk

apply-user-service:
	kubectl apply -k k8s/overlays/dev

logs-user-service:
	kubectl logs -f -n $(NAMESPACE) deployment/user-service

port-forward-user-service:
	@echo "🧹 Cleaning up old user-service port-forward on 3000 (if any)..."
	-lsof -ti :3000 | xargs kill -9 2>/dev/null || true
	@echo "🚀 Starting user-service port-forward on localhost:3000"
	@nohup kubectl port-forward -n $(NAMESPACE) svc/user-service 3000:3000 > user-service.log 2>&1 &
	@echo "📁 Port-forwarding started in background. Logs: user-service.log"

recreate-user-service:
	@echo "🔄 Deleting existing user-service deployment..."
	-kubectl delete deployment user-service -n $(NAMESPACE)

	@echo "🚀 Applying new user-service deployment..."
	kubectl apply -f k8s/base/user-service-deployment.yaml

	@echo "⏳ Waiting for user-service pod to become ready (timeout: 60s)..."
	@timeout=60; \
	while [ $$timeout -gt 0 ]; do \
		status=$$(kubectl get pods -n $(NAMESPACE) -l app=user-service -o jsonpath="{.items[0].status.containerStatuses[0].ready}" 2>/dev/null); \
		if [ "$$status" = "true" ]; then \
			echo "✅ user-service is ready."; \
			break; \
		else \
			echo "Waiting... ($$timeout)"; \
			sleep 2; \
			timeout=$$((timeout - 2)); \
		fi; \
	done

	@echo "🧹 Cleaning up old port-forward on port 3000 (if any)..."
	-lsof -ti :3000 | xargs kill -9 2>/dev/null || true

	@echo "🌐 Starting user-service port-forward on http://localhost:3000"
	@nohup kubectl port-forward -n $(NAMESPACE) svc/user-service 3000:3000 > user-service.log 2>&1 &
	@echo "📁 Port-forwarding started in background. Logs: user-service.log"

stop-user-service:
	@echo "🛑 Stopping user-service deployment..."
	-kubectl delete deployment user-service -n $(NAMESPACE)

	@echo "🧹 Killing any existing port-forward on port 3000..."
	-lsof -ti :3000 | xargs kill -9 2>/dev/null || true

	@echo "✅ user-service stopped."

endif