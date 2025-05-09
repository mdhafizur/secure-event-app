# Secure Event App - Makefile Documentation

## Makefile Structure

The project uses a modular Makefile structure organized by functionality:

```
make/
├── core/
│   └── variables.mk    # Core variables and basic commands
├── kafka/
│   └── kafka.mk        # Kafka-related commands
├── monitoring/
│   └── monitoring.mk   # Monitoring stack commands (Grafana, Prometheus, Loki)
└── database/
    └── database.mk     # Database commands (MongoDB, Redis)
```

## Quick Start

1. View all available commands:
```bash
make help
```

2. Apply base configuration:
```bash
make apply-base
```

3. Apply development overlay:
```bash
make apply-dev
```

## Available Commands

### Core Commands

- `make all` - Apply base Kubernetes configurations
- `make apply-base` - Apply base Kubernetes configurations
- `make apply-dev` - Apply development overlay configurations
- `make get-pods` - List all pods in the namespace
- `make get-services` - List all services in the namespace

### Kafka Management

#### Installation and Setup
- `make kafka-client` - Start a Kafka client pod
- `make logs-kafka` - Show Kafka logs
- `make port-forward-kafka` - Port forward Kafka to localhost:9092
- `make recreate-kafka` - Recreate Kafka deployment

#### Topic Management
- `make kafka-list-topics` - List all Kafka topics
- `make kafka-create-topic TOPIC=name [PARTITIONS=1] [REPLICATION=1]` - Create a new topic
- `make kafka-delete-topic TOPIC=name` - Delete a topic
- `make kafka-describe-topic TOPIC=name` - Show topic details

#### Consumer Groups
- `make kafka-list-groups` - List all consumer groups
- `make kafka-describe-group GROUP=name` - Show consumer group details
- `make kafka-lag-check GROUP=name` - Check consumer group lag

#### Message Operations
- `make kafka-console-producer TOPIC=name` - Start a console producer
- `make kafka-console-consumer TOPIC=name [FROM_BEGINNING=true]` - Start a console consumer

#### Configuration
- `make kafka-get-config TOPIC=name` - Show topic configuration
- `make kafka-alter-config TOPIC=name CONFIG_NAME=x CONFIG_VALUE=y` - Modify topic configuration

### Monitoring Stack

#### Grafana
- `make apply-grafana` - Apply Grafana deployment
- `make logs-grafana` - Show Grafana logs
- `make port-forward-grafana` - Port forward Grafana to localhost:3000
- `make grafana-password` - Get Grafana admin password
- `make recreate-grafana` - Recreate Grafana deployment

#### Prometheus
- `make apply-prometheus` - Apply Prometheus deployment
- `make logs-prometheus` - Show Prometheus logs
- `make port-forward-prometheus` - Port forward Prometheus to localhost:9090
- `make recreate-prometheus` - Recreate Prometheus deployment

#### Loki
- `make apply-loki` - Apply Loki deployment
- `make logs-loki` - Show Loki logs
- `make port-forward-loki` - Port forward Loki to localhost:3100
- `make recreate-loki` - Recreate Loki deployment

### Database Management

#### MongoDB
- `make logs-mongo` - Show MongoDB logs
- `make mongo-client` - Start MongoDB client pod
- `make port-forward-mongodb` - Port forward MongoDB to localhost:27017
- `make recreate-mongodb` - Recreate MongoDB deployment

#### Redis
- `make logs-redis` - Show Redis logs
- `make port-forward-redis` - Port forward Redis to localhost:6379
- `make recreate-redis` - Recreate Redis deployment

## Examples

1. Create a Kafka topic with custom partitions:
```bash
make kafka-create-topic TOPIC=user-events PARTITIONS=3
```

2. Monitor consumer lag:
```bash
make kafka-lag-check GROUP=user-service-group
```

3. Modify topic retention:
```bash
make kafka-alter-config TOPIC=user-events CONFIG_NAME=retention.ms CONFIG_VALUE=86400000
```

4. Access monitoring dashboards:
```bash
make port-forward-grafana    # Access Grafana at http://localhost:3000
make port-forward-prometheus # Access Prometheus at http://localhost:9090
make port-forward-loki      # Access Loki at http://localhost:3100
```

## Tips

1. Use `make help` to see all available commands with descriptions.
2. Port forwards run in the background and create log files (e.g., `grafana.log`, `kafka.log`).
3. The `recreate-*` commands handle proper cleanup and health checks.
4. Run `make get-pods` to check the status of all components.

## Environment Variables

- `NAMESPACE`: Kubernetes namespace (default: secureevent)
- `TOPIC`: Kafka topic name (required for Kafka topic operations)
- `GROUP`: Consumer group name (required for consumer group operations)
- `PARTITIONS`: Number of partitions for new topics (default: 1)
- `REPLICATION`: Replication factor for new topics (default: 1)
- `CONFIG_NAME`: Topic configuration parameter name
- `CONFIG_VALUE`: Topic configuration parameter value

## Common Workflows

### Initial Setup
```bash
make apply-base
make kafka-install
make port-forward-kafka
make kafka-create-topic TOPIC=user-events
```

### Monitoring Setup
```bash
make apply-prometheus
make apply-loki
make apply-grafana
make port-forward-grafana
make grafana-password  # Get the admin password
```

### Troubleshooting
```bash
make get-pods         # Check pod status
make logs-kafka       # Check Kafka logs
make kafka-describe-topic TOPIC=user-events  # Check topic status
```