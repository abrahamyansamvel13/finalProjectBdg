#!/bin/bash

echo "🚀 Starting HW35 - The Watchtower..."

cd ~/finalProjectBdg

# 1. Minikube
echo "1️⃣ Starting Minikube..."
minikube start --cpus=4 --memory=6144 --driver=docker

# 2. Prometheus stack
echo "2️⃣ Installing Prometheus stack..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kps prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace

# 3. Docker image
echo "3️⃣ Building Docker image..."
eval $(minikube docker-env)
docker build -t gaming-stats-api:latest .

# 4. Configure and deploy
echo "4️⃣ Configuring deployment..."
kubectl set env deployment/genesis-deployment DATABASE_URL="sqlite:///./gaming_stats.db" -n default
kubectl set image deployment/genesis-deployment genesis=gaming-stats-api:latest -n default
kubectl patch service genesis-service -n default -p '{"spec":{"ports":[{"name":"http","port":8000,"targetPort":8000}]}}'

# 5. ServiceMonitor
echo "5️⃣ Deploying ServiceMonitor..."
kubectl apply -f k8s/servicemonitor.yaml
kubectl apply -f k8s/grafana-dashboard-configmap.yaml

# 6. Wait for pods
echo "6️⃣ Waiting for pods to start (this may take 2-3 minutes)..."
kubectl get pods -n default -w &
kubectl get pods -n monitoring -w &
sleep 30

# 7. Port forwards
echo "7️⃣ Starting port forwards..."
kubectl port-forward svc/genesis-service -n default 8000:8000 &
kubectl port-forward svc/kps-kube-prometheus-stack-prometheus -n monitoring 9090:9090 &
kubectl port-forward svc/kps-grafana -n monitoring 3000:80 &

sleep 3

# 8. Generate traffic
echo "8️⃣ Generating traffic..."
for i in {1..50}; do
  curl http://localhost:8000/health > /dev/null 2>&1
  sleep 0.05
done

sleep 15

echo ""
echo "✅ HW35 Successfully Started!"
echo ""
echo "📊 Prometheus: http://localhost:9090"
echo "   Status → Targets (gaming-stats-api should be UP)"
echo ""
echo "📈 Grafana: http://localhost:3000"
echo "   Login: admin / (see: kubectl get secret -n monitoring kps-grafana -o jsonpath=\"{.data.admin-password}\" | base64 --decode)"
echo ""
echo "🎮 Your API: http://localhost:8000"
echo "   /health - Health check"
echo "   /metrics - Prometheus metrics"
echo "   /stats - Stats endpoint"
echo ""
