#!/bin/bash

# AWX Secrets Creation Script
# This script prompts for sensitive values and creates the required secrets for AWX
# Run this script before applying the awx-pgsql.yaml file

set -e

echo "======================================="
echo "AWX Secrets Creation Script"
echo "======================================="
echo ""

# Function to prompt for input with default value and hint
prompt_with_hint() {
    local var_name="$1"
    local prompt_text="$2"
    local hint="$3"
    local default_value="$4"
    local is_password="$5"
    
    echo "--- $prompt_text ---"
    if [ -n "$hint" ]; then
        echo "Hint: $hint"
    fi
    
    if [ "$is_password" = "true" ]; then
        echo -n "Enter value: "
        read -s value
        echo ""
    else
        if [ -n "$default_value" ]; then
            echo -n "Enter value [$default_value]: "
        else
            echo -n "Enter value: "
        fi
        read value
        if [ -z "$value" ] && [ -n "$default_value" ]; then
            value="$default_value"
        fi
    fi
    
    if [ -z "$value" ]; then
        echo "Error: Value cannot be empty"
        exit 1
    fi
    
    eval "$var_name='$value'"
    echo ""
}

# Check if namespace exists, create if not
echo "Checking if namespace 'awx-prod' exists..."
if ! kubectl get namespace awx-prod >/dev/null 2>&1; then
    echo "Creating namespace 'awx-prod'..."
    kubectl create namespace awx-prod
else
    echo "Namespace 'awx-prod' already exists."
fi
echo ""

# PostgreSQL Configuration
echo "==============================================="
echo "PostgreSQL Database Configuration"
echo "==============================================="

prompt_with_hint "POSTGRES_HOST" \
    "PostgreSQL Host/Service" \
    "For external DB: use IP or FQDN. For in-cluster service: use format 'service-name.namespace.svc.cluster.local'. To find existing services: kubectl get svc -A | grep -i postgres" \
    ""

prompt_with_hint "POSTGRES_PORT" \
    "PostgreSQL Port" \
    "Default PostgreSQL port is 5432" \
    "5432"

prompt_with_hint "DATABASE_NAME" \
    "Database Name" \
    "You can specify any database name if you haven't created it yet, otherwise use the name of the database you've pre-created. AWX will create tables automatically." \
    "awx"

prompt_with_hint "DB_USERNAME" \
    "Database Username" \
    "This user should have CREATE/DROP privileges on the specified database" \
    ""

prompt_with_hint "DB_PASSWORD" \
    "Database Password" \
    "Password for the database user" \
    "" \
    "true"

prompt_with_hint "SSL_MODE" \
    "SSL Mode" \
    "Options: disable, allow, prefer, require, verify-ca, verify-full. 'prefer' tries SSL but falls back to non-SSL if needed." \
    "prefer"

# AWX Admin Configuration
echo "==============================================="
echo "AWX Admin User Configuration"
echo "==============================================="

prompt_with_hint "AWX_ADMIN_PASSWORD" \
    "AWX Admin Password" \
    "This will be the password for the AWX admin user (username: admin)" \
    "" \
    "true"

# AWX Secret Key
echo "==============================================="
echo "AWX Secret Key Configuration"
echo "==============================================="

prompt_with_hint "SECRET_KEY" \
    "Django Secret Key" \
    "A long random string for Django encryption. You can generate one with: python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'" \
    ""

# Create the secrets
echo "==============================================="
echo "Creating Kubernetes Secrets..."
echo "==============================================="

# Delete existing secrets if they exist (to update them)
echo "Removing existing secrets if they exist..."
kubectl delete secret awx-postgres-configuration -n awx-prod --ignore-not-found=true
kubectl delete secret awx-admin-password -n awx-prod --ignore-not-found=true
kubectl delete secret awx-secret-key -n awx-prod --ignore-not-found=true

echo ""
echo "Creating PostgreSQL configuration secret..."
kubectl create secret generic awx-postgres-configuration -n awx-prod \
    --from-literal=host="$POSTGRES_HOST" \
    --from-literal=port="$POSTGRES_PORT" \
    --from-literal=database="$DATABASE_NAME" \
    --from-literal=username="$DB_USERNAME" \
    --from-literal=password="$DB_PASSWORD" \
    --from-literal=sslmode="$SSL_MODE" \
    --from-literal=target_session_attrs="read-write" \
    --from-literal=type="unmanaged"

echo "Creating AWX admin password secret..."
kubectl create secret generic awx-admin-password -n awx-prod \
    --from-literal=password="$AWX_ADMIN_PASSWORD"

echo "Creating AWX secret key..."
kubectl create secret generic awx-secret-key -n awx-prod \
    --from-literal=secret_key="$SECRET_KEY"

echo ""
echo "==============================================="
echo "Secrets created successfully!"
echo "==============================================="
echo ""
echo "You can now apply the AWX configuration with:"
echo "  kubectl apply -f awx-pgsql.yaml"
echo ""
echo "To verify the secrets were created:"
echo "  kubectl get secrets -n awx-prod"
echo ""
echo "To check AWX deployment status after applying:"
echo "  kubectl get awx -n awx-prod"
echo "  kubectl get pods -n awx-prod"
echo ""