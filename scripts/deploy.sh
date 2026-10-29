#!/usr/bin/env bash
set -euo pipefail
ENV=$1; TAG=$2
REGION=ap-south-1
CLUSTER=solo-ops-$ENV; SERVICE=orders-$ENV
IMAGE="$(aws sts get-caller-identity --query Account --output text).dkr.ecr.$REGION.amazonaws.com/solo-ops-orders:$TAG"

TD=$(aws ecs describe-task-definition --task-definition "$SERVICE" --query taskDefinition)
NEW=$(echo "$TD" | jq --arg I "$IMAGE" '.containerDefinitions[0].image=$I
  | del(.taskDefinitionArn,.revision,.status,.requiresAttributes,.compatibilities,.registeredAt,.registeredBy)')
ARN=$(aws ecs register-task-definition --cli-input-json "$NEW" --query taskDefinition.taskDefinitionArn --output text)

aws ecs update-service --cluster "$CLUSTER" --service "$SERVICE" --task-definition "$ARN" >/dev/null
aws ecs wait services-stable --cluster "$CLUSTER" --services "$SERVICE" \
  || { echo "Deploy failed, rolling back"; aws ecs update-service --cluster "$CLUSTER" --service "$SERVICE" --task-definition "$(echo "$TD" | jq -r .taskDefinitionArn)"; exit 1; }
echo "Deployed $TAG to $ENV"
