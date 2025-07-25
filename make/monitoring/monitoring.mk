ifndef MONITORING_MK
MONITORING_MK := 1

include make/core/variables.mk

# Monitoring Management Targets
.PHONY: logs-grafana logs-prometheus logs-loki apply-prometheus apply-loki apply-grafana \
	delete-grafana reapply-grafana delete-loki reapply-loki port-forward-grafana \
	port-forward-prometheus port-forward-loki recreate-grafana recreate-prometheus \
	recreate-loki grafana-password

# Logs
logs-grafana:
	kubectl logs -f -n $(NAMESPACE) deployment/grafana

logs-prometheus:
	kubectl logs -f -n $(NAMESPACE) deployment/prometheus

logs-promtail:
	kubectl logs -f -n $(NAMESPACE) deployment/promtail

logs-loki:
	kubectl logs -f -n $(NAMESPACE) statefulset/loki

# Application
apply-prometheus:
	kubectl apply -f k8s/base/prometheus-deployment.yaml

apply-loki:
	kubectl apply -f k8s/base/loki-deployment.yaml

apply-grafana:
	kubectl apply -f k8s/base/grafana-deployment.yaml

apply-promtail:
	kubectl apply -f k8s/base/promtail-deployment.yaml

# Deletion and Reapplication
delete-grafana:
	kubectl delete deployment grafana -n $(NAMESPACE)

delete-loki:
	kubectl delete statefulset loki -n $(NAMESPACE)

delete-prometheus:
	kubectl delete deployment prometheus -n $(NAMESPACE)

# Port Forwarding
port-forward-grafana:
	@echo "🧹 Cleaning up old Grafana port-forward on 3002 (if any)..."
	-lsof -ti :3002 | xargs kill -9 2>/dev/null || true
	@echo "🚀 Starting Grafana port-forward on localhost:3002"
	@nohup kubectl port-forward -n $(NAMESPACE) svc/grafana 3000:3002 > grafana.log 2>&1 &
	@echo "📁 Port-forwarding started in background. Logs: grafana.log"

port-forward-prometheus:
	@echo "🧹 Cleaning up old Prometheus port-forward on 9090 (if any)..."
	-lsof -ti :9090 | xargs kill -9 2>/dev/null || true
	@echo "🚀 Starting Prometheus port-forward on localhost:9090"
	@nohup kubectl port-forward -n $(NAMESPACE) svc/prometheus 9090:9090 > prometheus.log 2>&1 &
	@echo "📁 Port-forwarding started in background. Logs: prometheus.log"

port-forward-loki:
	@echo "🧹 Cleaning up old Loki port-forward on 3100 (if any)..."
	-lsof -ti :3100 | xargs kill -9 2>/dev/null || true
	@echo "🚀 Starting Loki port-forward on localhost:3100"
	@nohup kubectl port-forward -n $(NAMESPACE) svc/loki 3100:3100 > loki.log 2>&1 &
	@echo "📁 Port-forwarding started in background. Logs: loki.log"

port-forward-promtail:
	@echo "🧹 Cleaning up old Promtail port-forward on 9080 (if any)..."
	-lsof -ti :9080 | xargs kill -9 2>/dev/null || true
	@echo "🚀 Starting Promtail port-forward on localhost:9080"
	@nohup kubectl port-forward -n $(NAMESPACE) svc/promtail 9080:9080 > promtail.log 2>&1 &
	@echo "📁 Port-forwarding started in background. Logs: promtail.log"


# Recreation with Health Checks
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

	@echo "🧹 Cleaning up old port-forward on port 3002 (if any)..."
	-lsof -ti :3002 | xargs kill -9 2>/dev/null || true

	@echo "🌐 Starting Grafana port-forward on http://localhost:3002"
	@nohup kubectl port-forward -n $(NAMESPACE) svc/grafana 3002:3000 > grafana.log 2>&1 &
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
	@timeout=60; \
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

recreate-promtail:
	@echo "Deleting Promtail Deployment..."
	-kubectl delete deployment promtail -n $(NAMESPACE)

	@echo "Deleting Promtail ConfigMap..."
	-kubectl delete configmap promtail-config -n $(NAMESPACE)

	@echo "Re-applying Promtail stack from k8s/base/promtail-deployment.yaml..."
	kubectl apply -f k8s/base/promtail-deployment.yaml

	@echo "Waiting for Promtail pod to become ready (timeout: 60s)..."
	@timeout=60; \
	while [ $$timeout -gt 0 ]; do \
		if kubectl get pods -n $(NAMESPACE) -l app=promtail -o jsonpath="{.items[0].status.containerStatuses[0].ready}" 2>/dev/null | grep -q "true"; then \
			echo "Promtail is ready."; \
			break; \
		else \
			echo "Waiting... ($$timeout)"; \
			sleep 2; \
			timeout=$$((timeout - 2)); \
		fi; \
	done

	@echo "Promtail deployment completed."


# Utilities
grafana-password:
	kubectl get secret --namespace secureevent grafana-admin-secret -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

endif