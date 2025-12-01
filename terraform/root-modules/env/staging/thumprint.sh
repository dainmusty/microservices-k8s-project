#!/bin/bash

eks_cluster_name="effulgencetech-dev"
aws_region="us-east-1"

issuer_url=$(aws eks describe-cluster \
  --name "$eks_cluster_name" \
  --region "$aws_region" \
  --query "cluster.identity.oidc.issuer" \
  --output text)

# Strip the https:// prefix
host=$(echo "$issuer_url" | sed 's~https://~~')

# Get the root CA thumbprint
echo | openssl s_client -servername "$host" -showcerts -connect "$host:443" 2>/dev/null \
  | openssl x509 -fingerprint -noout -sha1 \
  | sed 's/.*=//;s/://g'

