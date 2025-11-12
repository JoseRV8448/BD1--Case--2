#!/bin/bash
# test-kubernetes-deployment.sh
# Script para probar el deployment de Kubernetes

echo "=========================================="
echo "TESTING PROMPTSALES KUBERNETES DEPLOYMENT"
echo "=========================================="

# 1. Aplicar el deployment
echo "1. Aplicando deployment..."
kubectl apply -f kubernetes-deployment.yaml

# 2. Esperar que los pods estén listos
echo "2. Esperando pods (30 segundos)..."
sleep 30

# 3. Verificar estado de los pods
echo "3. Estado de los pods:"
kubectl get pods -n promptsales

# 4. Verificar servicios
echo "4. Servicios disponibles:"
kubectl get services -n promptsales

# 5. Test de conectividad
echo "5. Testing conectividad a las bases de datos:"

# SQL Server
echo "- SQL Server:"
kubectl run -it --rm --image=mcr.microsoft.com/mssql-tools --restart=Never test-sql -- \
  /opt/mssql-tools/bin/sqlcmd -S sqlserver.promptsales.svc.cluster.local -U sa -P "PromptSales2024!" \
  -Q "SELECT 'SQL Server OK' as Status"

# PostgreSQL
echo "- PostgreSQL:"
kubectl run -it --rm --image=postgres:15 --restart=Never test-pg -- \
  psql -h postgres-dw.promptsales.svc.cluster.local -U admin -d PromptSales_DW \
  -c "SELECT 'PostgreSQL OK' as Status"

# MongoDB
echo "- MongoDB:"
kubectl run -it --rm --image=mongo:6 --restart=Never test-mongo -- \
  mongosh mongodb://admin:PromptContent2024!@mongodb.promptsales.svc.cluster.local:27017/PromptContent \
  --eval "db.runCommand({ping: 1})"

# Redis
echo "- Redis:"
kubectl run -it --rm --image=redis:7-alpine --restart=Never test-redis -- \
  redis-cli -h redis-cache.promptsales.svc.cluster.local ping

echo ""
echo "=========================================="
echo "DEPLOYMENT TEST COMPLETADO"
echo "=========================================="
echo ""
echo "Para ver logs de un pod:"
echo "kubectl logs -n promptsales <nombre-del-pod>"
echo ""
echo "Para eliminar todo:"
echo "kubectl delete namespace promptsales"