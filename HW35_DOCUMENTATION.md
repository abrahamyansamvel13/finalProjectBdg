# HW35: The Watchtower - Complete Technical Documentation

## Executive Summary

HW35 implements production-grade monitoring for the Gaming Stats API using Prometheus and Grafana on Kubernetes. The system provides real-time visibility into application performance, resource utilization, and error rates using the RED method (Rate, Errors, Duration).

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   MINIKUBE CLUSTER                      │
├─────────────────────────────────────────────────────────┤
│ DEFAULT NAMESPACE                                       │
│  ├─ genesis-deployment (3 replicas)                    │
│  │  ├─ Port 8000: HTTP API                            │
│  │  ├─ Port 8000: /metrics endpoint                   │
│  │  └─ Database: SQLite (local) / PostgreSQL (prod)   │
│  ├─ genesis-service (8000:8000)                        │
│  └─ ServiceMonitor (tells Prometheus where to scrape) │
│                                                         │
│ MONITORING NAMESPACE                                   │
│  ├─ prometheus-* (scrapes metrics every 15s)          │
│  ├─ grafana-* (visualizes metrics)                    │
│  ├─ alertmanager-* (alert management)                │
│  └─ grafana-dashboard-configmap (auto-provisioning)  │
└─────────────────────────────────────────────────────────┘
```

## Implementation Details

### 1. Application Instrumentation

**File:** `app/main.py`

Added Prometheus metrics collection:

```python
from prometheus_client import Counter, Histogram, generate_latest, REGISTRY

# Counter: Total requests
REQUESTS = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "path", "status_code"]
)

# Histogram: Request duration
LATENCY = Histogram(
    "http_request_duration_seconds",
    "Request latency",
    ["path"]
)

# HTTP middleware to track all requests
@app.middleware("http")
async def track_metrics(request, call_next):
    with LATENCY.labels(path=request.url.path).time():
        response = await call_next(request)
    REQUESTS.labels(
        method=request.method,
        path=request.url.path,
        status_code=response.status_code
    ).inc()
    return response

# Metrics endpoint for Prometheus
@app.get("/metrics")
async def get_metrics():
    return Response(
        content=generate_latest(REGISTRY),
        media_type="text/plain; charset=utf-8; version=0.0.4"
    )
```

**Configuration:**
- Database: SQLite for local development, PostgreSQL for production
- Environment variable: `DATABASE_URL`
- Default: `sqlite:///./gaming_stats.db`

### 2. Kubernetes Deployment

**File:** `k8s/deployment.yaml`

- Image: `gaming-stats-api:latest`
- Replicas: 3
- Port 8000: API and metrics
- Resources: 128Mi memory request, 256Mi limit
- Health checks: `/health` endpoint

**File:** `k8s/service.yaml`

- Type: NodePort
- Port 8000: API and metrics
- Label: `app: genesis`

### 3. ServiceMonitor Configuration

**File:** `k8s/servicemonitor.yaml`

Prometheus Operator resource for auto-discovery:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: gaming-stats-api
  namespace: monitoring
  labels:
    release: kps  # Must match helm release name
spec:
  namespaceSelector:
    matchNames:
    - default
  selector:
    matchLabels:
      app: genesis
  endpoints:
    - port: http
      interval: 15s
      path: /metrics
```

**Critical:** `release: kps` label must match the kube-prometheus-stack helm release name.

### 4. Grafana Dashboard

**File:** `monitoring/dashboards/genesis-dashboard.json`

5-panel dashboard following RED method:

#### Panel 1: Request Rate
- **Query:** `sum by (status_code) (rate(http_requests_total[5m]))`
- **Type:** Time series
- **Unit:** req/s
- **Purpose:** Track requests per second by HTTP status code

#### Panel 2: Error Rate
- **Query:** `sum(rate(http_requests_total{status_code=~"5.."}[5m]))`
- **Type:** Gauge
- **Unit:** req/s
- **Threshold:** Red if > 0.01 req/s
- **Purpose:** Monitor 5xx errors in real-time

#### Panel 3: Latency (p95/p99)
- **Query p95:** `histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))`
- **Query p99:** `histogram_quantile(0.99, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))`
- **Type:** Time series
- **Unit:** seconds
- **Purpose:** Monitor response time percentiles

#### Panel 4: CPU Usage
- **Query:** `sum(rate(container_cpu_usage_seconds_total{pod=~"genesis-deployment.*"}[5m])) * 100`
- **Type:** Gauge
- **Unit:** percent
- **Thresholds:** Green 0-50%, Yellow 50-80%, Red 80%+
- **Purpose:** Track CPU utilization

#### Panel 5: Memory Usage
- **Query:** `sum(container_memory_working_set_bytes{pod=~"genesis-deployment.*"}) / 1024 / 1024`
- **Type:** Time series
- **Unit:** MB
- **Purpose:** Monitor memory consumption and detect leaks

### 5. Auto-Provisioning

**File:** `k8s/grafana-dashboard-configmap.yaml`

ConfigMap with `grafana_dashboard: "1"` label enables automatic dashboard import on Grafana startup.

## Deployment Instructions

### Prerequisites
- Minikube with 4 CPUs and 6GB RAM
- Docker with WSL2 integration
- kubectl configured
- helm installed

### Step-by-Step Deployment

```bash
# 1. Start Minikube
minikube start --cpus=4 --memory=6144 --driver=docker

# 2. Add Prometheus Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 3. Install kube-prometheus-stack
helm install kps prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace

# 4. Build Docker image
eval $(minikube docker-env)
docker build -t gaming-stats-api:latest .

# 5. Configure deployment for SQLite
kubectl set env deployment/genesis-deployment \
  DATABASE_URL="sqlite:///./gaming_stats.db" -n default

# 6. Update image
kubectl set image deployment/genesis-deployment \
  genesis=gaming-stats-api:latest -n default

# 7. Configure service
kubectl patch service genesis-service -n default \
  -p '{"spec":{"ports":[{"name":"http","port":8000,"targetPort":8000}]}}'

# 8. Deploy ServiceMonitor
kubectl apply -f k8s/servicemonitor.yaml

# 9. Deploy Grafana ConfigMap
kubectl apply -f k8s/grafana-dashboard-configmap.yaml

# 10. Verify deployment
kubectl get pods -n default
kubectl get pods -n monitoring
```

## Access & Verification

### Port Forwarding

```bash
# Grafana (port 3000)
kubectl port-forward svc/kps-grafana -n monitoring 3000:80 &

# Prometheus (port 9090)
kubectl port-forward svc/kps-kube-prometheus-stack-prometheus -n monitoring 9090:9090 &

# API (port 8000)
kubectl port-forward svc/genesis-service -n default 8000:8000 &
```

### Verification Checklist

```bash
# 1. Check pods are running
kubectl get pods -n default      # Should show 3 genesis-deployment pods
kubectl get pods -n monitoring   # Should show Prometheus, Grafana, etc.

# 2. Check Prometheus targets
curl http://localhost:9090/api/v1/targets
# Should show gaming-stats-api with "status":"up"

# 3. Check metrics endpoint
curl http://localhost:8000/metrics | head -20
# Should return Prometheus format metrics

# 4. Check Grafana
curl http://localhost:3000
# Should return Grafana UI

# 5. Get Grafana admin password
kubectl get secret -n monitoring kps-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode
```

## Metrics Reference

### Counter: http_requests_total

Cumulative count of HTTP requests.

**Labels:**
- `method`: HTTP method (GET, POST, PUT, DELETE)
- `path`: Request path (/health, /stats, /metrics, etc.)
- `status_code`: HTTP response code (200, 404, 500, etc.)

**Example query:**
```promql
rate(http_requests_total[5m])  # Requests per second over 5 minutes
sum by (status_code) (rate(http_requests_total[5m]))  # By status code
```

### Histogram: http_request_duration_seconds

Distribution of request latencies in seconds.

**Buckets:** Automatically generated at 0.005s, 0.01s, 0.1s, 0.5s, 1s, 5s, etc.

**Example queries:**
```promql
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))  # p95
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))  # p99
rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m])  # Average
```

### Container Metrics

Kubernetes provides container-level metrics via kubelet.

**CPU:** `container_cpu_usage_seconds_total`
**Memory:** `container_memory_working_set_bytes`

## RED Method

Rate, Errors, Duration (RED) is the recommended approach for monitoring request-driven services.

- **Rate:** How many requests per second? `sum by (status_code) (rate(http_requests_total[5m]))`
- **Errors:** What percentage are failing? `sum(rate(http_requests_total{status_code=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))`
- **Duration:** What is the latency? `histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))`

## Troubleshooting

### Prometheus shows gaming-stats-api as DOWN

**Check ServiceMonitor label:**
```bash
kubectl describe servicemonitor gaming-stats-api -n monitoring
# Verify: label release: kps is present
```

**Restart Prometheus:**
```bash
kubectl rollout restart statefulset/prometheus-kps-kube-prometheus-stack-prometheus -n monitoring
```

### Grafana dashboard shows no data

**Generate traffic:**
```bash
for i in {1..100}; do
  curl http://localhost:8000/health > /dev/null 2>&1
  sleep 0.05
done

# Wait 15 seconds for Prometheus scrape interval
sleep 15
```

**Check Prometheus has data:**
```bash
curl http://localhost:9090/api/v1/query?query=http_requests_total
```

### Pods not starting

**Check logs:**
```bash
kubectl logs -n default genesis-deployment-xxxxx
kubectl logs -n monitoring prometheus-kps-kube-prometheus-stack-prometheus-0
```

**Check resources:**
```bash
minikube status
# If not Running, restart: minikube start --cpus=4 --memory=6144
```

## Files Modified/Created

| File | Type | Purpose |
|------|------|---------|
| app/main.py | Modified | Added Prometheus instrumentation |
| requirements.txt | Modified | Added prometheus-client |
| k8s/servicemonitor.yaml | Created | Prometheus auto-discovery |
| k8s/grafana-dashboard-configmap.yaml | Created | Dashboard auto-provisioning |
| monitoring/dashboards/genesis-dashboard.json | Created | Grafana dashboard definition |

## Git Workflow

```bash
# Create hw35 branch
git checkout -b hw35

# Make changes and commit
git add .
git commit -m "hw35: implement prometheus monitoring and grafana dashboard

Implements complete monitoring system:
- Prometheus instrumentation in FastAPI app
- Deployed kube-prometheus-stack via Helm
- ServiceMonitor for auto-discovery
- 5-panel Grafana dashboard (RED method)
- Auto-provisioning via ConfigMap"

# Push to GitHub
git push origin hw35

# Create PR (via GitHub UI)
# Base: main, Compare: hw35
```

## Performance Baselines

Expected metrics under normal operation:

- **Request Rate:** 0-100 req/s (depends on load)
- **Error Rate:** 0-0.1 req/s (should be minimal)
- **Latency p95:** 10-100ms (depends on database)
- **CPU Usage:** 5-30%
- **Memory Usage:** 100-300MB

## Security Considerations

- **Metric Labels:** Use bounded labels only (method, path, status_code). Avoid user IDs, request IDs, or other PII that could cause cardinality explosion.
- **Secrets:** Credentials stored in Kubernetes Secrets, not in ConfigMaps.
- **RBAC:** ServiceMonitor uses Prometheus Operator's built-in RBAC.
- **Network:** All services internal to Minikube. Port forwarding only for development.

## References

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Kubernetes Monitoring](https://kubernetes.io/docs/tasks/debug-application-cluster/resource-metrics-pipeline/)
- [RED Method](https://www.weave.works/blog/the-red-method-key-metrics-for-microservices-architecture/)

## Status

✅ Completed: HW35 - The Watchtower

All phases implemented:
1. ✅ Application instrumentation with Prometheus
2. ✅ kube-prometheus-stack deployment via Helm
3. ✅ ServiceMonitor for auto-discovery
4. ✅ Grafana dashboard with RED method (5 panels)
5. ✅ Dashboard JSON export and versioning
6. ✅ Auto-provisioning via ConfigMap
7. ✅ Complete documentation and git workflow
