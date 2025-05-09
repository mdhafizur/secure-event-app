#!/bin/bash

# Exit on any error
set -e

# Create directory for certificates
mkdir -p kafka-certs
cd kafka-certs

echo "Generating keystore..."
# Generate a key pair for Kafka with RSA algorithm
keytool -genkey -keystore kafka.keystore.jks -validity 365 -storepass keystore123 -keypass key123 \
  -dname "CN=kafka,OU=SecureEvent,O=MyCompany,L=MyCity,S=MyState,C=US" \
  -alias kafka -storetype JKS -keyalg RSA -keysize 2048

echo "Exporting certificate..."
# Export the certificate
keytool -export -keystore kafka.keystore.jks -storepass keystore123 -alias kafka -file kafka.crt

echo "Creating truststore..."
# Create a truststore and import the Kafka certificate
keytool -import -file kafka.crt -keystore kafka.truststore.jks -storepass truststore123 -noprompt

echo "Creating Kubernetes secret..."
# Create Kubernetes secret
kubectl create secret generic kafka-certs \
  --from-file=kafka.keystore.jks \
  --from-file=kafka.truststore.jks \
  --namespace secureevent \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Cleaning up..."
cd ..
rm -rf kafka-certs

echo "Kafka certificates and secret created successfully!"
