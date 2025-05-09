ifndef KAFKA_MK
KAFKA_MK := 1

include make/core/variables.mk

# Kafka Management Targets
.PHONY: kafka-install kafka-client kafka-certs logs-kafka \
	kafka-list-topics kafka-create-topic kafka-delete-topic kafka-describe-topic \
	kafka-list-groups kafka-describe-group kafka-console-producer kafka-console-consumer \
	kafka-lag-check kafka-topics-under-replicated kafka-topics-unavailable \
	kafka-get-config kafka-alter-config port-forward-kafka recreate-kafka


kafka-client:
	kubectl run kafka-client --restart='Never' --rm -i -t --namespace $(NAMESPACE) \
		--image docker.io/bitnami/kafka:latest -- bash

kafka-certs:
	@echo "🔐 Generating Kafka certificates and creating Kubernetes secret..."
	chmod +x ./create-kafka-certs.sh
	./create-kafka-certs.sh
	@echo "✅ Kafka certificates generated and secret created"

logs-kafka:
	kubectl logs -f -n $(NAMESPACE) statefulset/kafka

# Topic Management
kafka-list-topics:
	@echo "📋 Listing Kafka topics..."
	kubectl exec -n $(NAMESPACE) kafka-0 -- /opt/bitnami/kafka/bin/kafka-topics.sh \
		--bootstrap-server localhost:9092 \
		--list

kafka-create-topic:
	@if [ -z "$(TOPIC)" ]; then \
		echo "❌ Error: TOPIC name is required. Usage: make kafka-create-topic TOPIC=your-topic [PARTITIONS=1] [REPLICATION=1]"; \
		exit 1; \
	fi
	@echo "🔨 Creating Kafka topic: $(TOPIC)"
	kubectl exec -n $(NAMESPACE) kafka-0 -- /opt/bitnami/kafka/bin/kafka-topics.sh \
		--bootstrap-server localhost:9092 \
		--create \
		--topic $(TOPIC) \
		--partitions $${PARTITIONS:-1} \
		--replication-factor $${REPLICATION:-1}

kafka-delete-topic:
	@if [ -z "$(TOPIC)" ]; then \
		echo "❌ Error: TOPIC name is required. Usage: make kafka-delete-topic TOPIC=your-topic"; \
		exit 1; \
	fi
	@echo "🗑️ Deleting Kafka topic: $(TOPIC)"
	kubectl exec -n $(NAMESPACE) kafka-0 -- /opt/bitnami/kafka/bin/kafka-topics.sh \
		--bootstrap-server localhost:9092 \
		--delete \
		--topic $(TOPIC)

kafka-describe-topic:
	@if [ -z "$(TOPIC)" ]; then \
		echo "❌ Error: TOPIC name is required. Usage: make kafka-describe-topic TOPIC=your-topic"; \
		exit 1; \
	fi
	@echo "📝 Describing Kafka topic: $(TOPIC)"
	kubectl exec -n $(NAMESPACE) kafka-0 -- /opt/bitnami/kafka/bin/kafka-topics.sh \
		--bootstrap-server localhost:9092 \
		--describe \
		--topic $(TOPIC)

# Consumer Group Management
kafka-list-groups:
	@echo "📋 Listing Kafka consumer groups..."
	kubectl exec -n $(NAMESPACE) kafka-0 -- /opt/bitnami/kafka/bin/kafka-consumer-groups.sh \
		--bootstrap-server localhost:9092 \
		--list

kafka-describe-group:
	@if [ -z "$(GROUP)" ]; then \
		echo "❌ Error: GROUP name is required. Usage: make kafka-describe-group GROUP=your-group"; \
		exit 1; \
	fi
	@echo "📝 Describing consumer group: $(GROUP)"
	kubectl exec -n $(NAMESPACE) kafka-0 -- /opt/bitnami/kafka/bin/kafka-consumer-groups.sh \
		--bootstrap-server localhost:9092 \
		--describe \
		--group $(GROUP)

# Message Management
kafka-console-producer:
	@if [ -z "$(TOPIC)" ]; then \
		echo "❌ Error: TOPIC name is required. Usage: make kafka-console-producer TOPIC=your-topic"; \
		exit 1; \
	fi
	@echo "📤 Starting Kafka console producer for topic: $(TOPIC)"
	kubectl exec -it -n $(NAMESPACE) kafka-0 -- /opt/bitnami/kafka/bin/kafka-console-producer.sh \
		--bootstrap-server localhost:9092 \
		--topic $(TOPIC)

kafka-console-consumer:
	@if [ -z "$(TOPIC)" ]; then \
		echo "❌ Error: TOPIC name is required. Usage: make kafka-console-consumer TOPIC=your-topic [FROM_BEGINNING=true]"; \
		exit 1; \
	fi
	@echo "📥 Starting Kafka console consumer for topic: $(TOPIC)"
	kubectl exec -it -n $(NAMESPACE) kafka-0 -- /opt/bitnami/kafka/bin/kafka-console-consumer.sh \
		--bootstrap-server localhost:9092 \
		--topic $(TOPIC) \
		$(if $(FROM_BEGINNING),--from-beginning,)

# Monitoring
kafka-lag-check:
	@if [ -z "$(GROUP)" ]; then \
		echo "❌ Error: GROUP name is required. Usage: make kafka-lag-check GROUP=your-group"; \
		exit 1; \
	fi
	@echo "📊 Checking consumer group lag: $(GROUP)"
	kubectl exec -n $(NAMESPACE) kafka-0 -- /opt/bitnami/kafka/bin/kafka-consumer-groups.sh \
		--bootstrap-server localhost:9092 \
		--describe \
		--group $(GROUP)

kafka-topics-under-replicated:
	@echo "🔍 Checking for under-replicated partitions..."
	kubectl exec -n $(NAMESPACE) kafka-0 -- /opt/bitnami/kafka/bin/kafka-topics.sh \
		--bootstrap-server localhost:9092 \
		--describe \
		--under-replicated-partitions

kafka-topics-unavailable:
	@echo "🔍 Checking for unavailable partitions..."
	kubectl exec -n $(NAMESPACE) kafka-0 -- /opt/bitnami/kafka/bin/kafka-topics.sh \
		--bootstrap-server localhost:9092 \
		--describe \
		--unavailable-partitions

# Configuration
kafka-get-config:
	@if [ -z "$(TOPIC)" ]; then \
		echo "❌ Error: TOPIC name is required. Usage: make kafka-get-config TOPIC=your-topic"; \
		exit 1; \
	fi
	@echo "⚙️ Getting configuration for topic: $(TOPIC)"
	kubectl exec -n $(NAMESPACE) kafka-0 -- /opt/bitnami/kafka/bin/kafka-configs.sh \
		--bootstrap-server localhost:9092 \
		--describe \
		--topic $(TOPIC)

kafka-alter-config:
	@if [ -z "$(TOPIC)" ] || [ -z "$(CONFIG_NAME)" ] || [ -z "$(CONFIG_VALUE)" ]; then \
		echo "❌ Error: Required parameters missing. Usage: make kafka-alter-config TOPIC=your-topic CONFIG_NAME=retention.ms CONFIG_VALUE=86400000"; \
		exit 1; \
	fi
	@echo "⚙️ Altering configuration for topic: $(TOPIC)"
	kubectl exec -n $(NAMESPACE) kafka-0 -- /opt/bitnami/kafka/bin/kafka-configs.sh \
		--bootstrap-server localhost:9092 \
		--alter \
		--topic $(TOPIC) \
		--add-config $(CONFIG_NAME)=$(CONFIG_VALUE)

# Port Forwarding and Recreation
port-forward-kafka:
	@echo "🧹 Cleaning up old Kafka port-forward on 9092 (if any)..."
	-lsof -ti :9092 | xargs kill -9 2>/dev/null || true
	@echo "🚀 Starting Kafka port-forward on localhost:9092"
	@nohup kubectl port-forward -n $(NAMESPACE) svc/kafka 9092:9092 > kafka.log 2>&1 &
	@echo "📁 Port-forwarding started in background. Logs: kafka.log"


recreate-kafka:
	@echo "🔄 Deleting Kafka StatefulSet..."
	-kubectl delete statefulset kafka -n $(NAMESPACE)
	@echo "🔄 Deleting Kafka Service..."
	-kubectl delete svc kafka -n $(NAMESPACE)
	@echo "📦 Re-applying from k8s/base/kafka-deployment.yaml..."
	kubectl apply -f k8s/base/kafka-deployment.yaml
	@echo "⏳ Waiting for Kafka pod to become ready (timeout: 60s)..."
	@timeout=60; \
	while [ $$timeout -gt 0 ]; do \
		if kubectl get pods -n $(NAMESPACE) -l app=kafka -o jsonpath="{.items[0].status.containerStatuses[0].ready}" 2>/dev/null | grep -q "true"; then \
			echo "✅ Kafka is ready."; \
			break; \
		else \
			echo "Waiting for Kafka... ($$timeout)"; \
			sleep 2; \
			timeout=$$((timeout - 2)); \
		fi; \
	done

endif