# Secure Event App - Main Makefile
# Include all modular makefiles
include make/core/variables.mk
include make/kafka/kafka.mk
include make/monitoring/monitoring.mk
include make/database/database.mk

.PHONY: help

# Default target
.DEFAULT_GOAL := help

# Help target that lists all available commands
help:
	@echo "Secure Event App - Available Commands:"
	@echo ""
	@echo "Core Commands:"
	@echo "  make all                   - Apply base Kubernetes configurations"
	@echo "  make apply-base            - Apply base Kubernetes configurations"
	@echo "  make apply-dev             - Apply development overlay configurations"
	@echo "  make get-pods              - List all pods in the namespace"
	@echo "  make get-services          - List all services in the namespace"
	@echo "  make delete-all            - Delete all resources in the namespace"
	@echo ""
	@echo "Kafka Commands:"
	@echo "  make kafka-install         - Install Kafka using Helm"
	@echo "  make kafka-client          - Start a Kafka client pod"
	@echo "  make kafka-list-topics     - List all Kafka topics"
	@echo "  make kafka-create-topic    - Create a new topic (TOPIC=name PARTITIONS=1 REPLICATION=1)"
	@echo "  make kafka-delete-topic    - Delete a topic (TOPIC=name)"
	@echo "  make kafka-describe-topic  - Show topic details (TOPIC=name)"
	@echo "  make kafka-console-producer - Start console producer (TOPIC=name)"
	@echo "  make kafka-console-consumer - Start console consumer (TOPIC=name [FROM_BEGINNING=true])"
	@echo "  make kafka-list-groups     - List all consumer groups"
	@echo "  make kafka-describe-group  - Show consumer group details (GROUP=name)"
	@echo "  make kafka-lag-check       - Check consumer group lag (GROUP=name)"
	@echo "  make kafka-get-config      - Show topic configuration (TOPIC=name)"
	@echo "  make kafka-alter-config    - Modify topic config (TOPIC=name CONFIG_NAME=x CONFIG_VALUE=y)"
	@echo "  make logs-kafka            - Show Kafka logs"
	@echo "  make port-forward-kafka    - Port forward Kafka to localhost:9092"
	@echo "  make recreate-kafka        - Recreate Kafka deployment"
	@echo ""
	@echo "Monitoring Commands:"
	@echo "  make apply-prometheus      - Apply Prometheus deployment"
	@echo "  make apply-loki           - Apply Loki deployment"
	@echo "  make apply-grafana        - Apply Grafana deployment"
	@echo "  make logs-grafana         - Show Grafana logs"
	@echo "  make logs-prometheus      - Show Prometheus logs"
	@echo "  make logs-loki           - Show Loki logs"
	@echo "  make port-forward-grafana  - Port forward Grafana to localhost:3000"
	@echo "  make port-forward-prometheus - Port forward Prometheus to localhost:9090"
	@echo "  make port-forward-loki    - Port forward Loki to localhost:3100"
	@echo "  make grafana-password     - Get Grafana admin password"
	@echo "  make recreate-grafana     - Recreate Grafana deployment"
	@echo "  make recreate-prometheus  - Recreate Prometheus deployment"
	@echo "  make recreate-loki       - Recreate Loki deployment"
	@echo ""
	@echo "Database Commands:"
	@echo "  make logs-mongo           - Show MongoDB logs"
	@echo "  make logs-redis           - Show Redis logs"
	@echo "  make mongo-client         - Start MongoDB client pod"
	@echo "  make port-forward-mongodb - Port forward MongoDB to localhost:27017"
	@echo "  make port-forward-redis   - Port forward Redis to localhost:6379"
	@echo "  make recreate-mongodb     - Recreate MongoDB deployment"
	@echo "  make recreate-redis       - Recreate Redis deployment"

# Delete all resources in the namespace
delete-all:
	@echo "🚨 Deleting all resources in the namespace $(NAMESPACE)..."
	kubectl delete all --all -n $(NAMESPACE)
	kubectl delete namespace $(NAMESPACE) --ignore-not-found
	@echo "✅ All resources in the namespace $(NAMESPACE) have been deleted."

make port-forward-all: port-forward-grafana port-forward-prometheus port-forward-loki port-forward-mongodb port-forward-redis port-forward-kafka
	@echo "All port-forwards are now running in the background. Check the respective log files for details."

logs-user-service:
	kubectl logs -f -n $(NAMESPACE) deployment/user-service
