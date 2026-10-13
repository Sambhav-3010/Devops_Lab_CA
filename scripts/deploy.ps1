$ErrorActionPreference = 'Stop'
kubectl apply -f k8s/app.yaml
kubectl apply -f k8s/servicemonitor.yaml
kubectl apply -f k8s/alerts.yaml
kubectl apply -f k8s/dashboard.yaml
kubectl -n workload-lab rollout status deployment/demo-app
kubectl -n workload-lab get pods,svc,servicemonitor,prometheusrule

