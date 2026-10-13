# Kubernetes Workload Reliability and Resource Pressure Analysis

A local DevOps mini-project for Docker Desktop Kubernetes. It demonstrates the complete loop:

**Deploy → Monitor → Simulate a problem → Detect it → Observe recovery**

The project deploys a Node.js + Express application with two replicas, application metrics, bounded CPU/memory experiments, Prometheus alert rules, and a Grafana dashboard.

## Repository layout

```text
kubernetes-workload-monitoring/
├── app/
│   ├── server.js
│   ├── package.json
│   └── Dockerfile
├── k8s/
│   ├── app.yaml
│   ├── servicemonitor.yaml
│   ├── alerts.yaml
│   └── dashboard.yaml
├── scripts/
│   ├── build.ps1
│   ├── deploy.ps1
│   ├── install-monitoring.ps1
│   ├── port-forward.ps1
│   ├── run-experiments.ps1
│   ├── generate-traffic.ps1
│   ├── live-demo.ps1
│   ├── preflight.ps1
│   ├── setup.ps1
│   └── validate.ps1
└── README.md
```

## Prerequisites

- Docker Desktop with Kubernetes enabled
- `kubectl` configured for `docker-desktop`
- Helm 3
- PowerShell

Install Helm on Windows if it is missing:

```powershell
winget install --id Helm.Helm --exact --source winget
```

Close and reopen PowerShell after installation, then verify:

```powershell
helm version
```

Check the local environment:

```powershell
docker --version
kubectl version --client
kubectl config current-context
kubectl get nodes
helm version
```

If needed:

```powershell
kubectl config use-context docker-desktop
```

If that command says `no context exists with the name docker-desktop`, Kubernetes is not enabled in Docker Desktop or the current kubeconfig is not the one Docker Desktop manages. Open Docker Desktop → Settings → Kubernetes, enable the Kubernetes cluster, choose **Apply & Restart**, and wait until the Kubernetes status is **Running**. Then reopen PowerShell and run:

```powershell
docker desktop kubernetes status
kubectl config get-contexts
kubectl config use-context docker-desktop
kubectl get nodes
```

If `KUBECONFIG` prints a custom path, temporarily clear it so kubectl uses the default Docker Desktop kubeconfig:

```powershell
$env:KUBECONFIG
Remove-Item Env:KUBECONFIG -ErrorAction SilentlyContinue
kubectl config get-contexts
```

## Build and deploy

Run these commands from this folder:

```powershell
.\scripts\validate.ps1
.\scripts\build.ps1
.\scripts\install-monitoring.ps1
kubectl apply -f k8s/app.yaml
kubectl -n workload-lab rollout status deployment/demo-app
```

`validate.ps1` now checks Docker Engine, Helm, the `docker-desktop` kubectl context, and node readiness before validating manifests. If Docker reports that the engine is unavailable, start Docker Desktop and wait until Kubernetes shows **Running**. If `docker-desktop` is missing, enable Kubernetes in Docker Desktop and reopen PowerShell. If Docker Desktop itself exits with an access-denied error, repair or reinstall Docker Desktop with administrator rights and confirm WSL 2/virtualization is enabled; that is a Windows host permission issue, not a project manifest issue.

Run the commands from the same Windows user session that started Docker Desktop. If Docker reports named-pipe permission denied, add the signed-in user to the `docker-users` group, sign out and sign back in, then reopen PowerShell.

Install monitoring before applying the monitoring custom resources, then apply the remaining files:

```powershell
kubectl apply -f k8s/servicemonitor.yaml
kubectl apply -f k8s/alerts.yaml
kubectl apply -f k8s/dashboard.yaml
```

Or use the deployment helper after the monitoring stack is installed:

```powershell
.\scripts\deploy.ps1
```

For a complete first-time setup, run this single command after Docker Desktop Kubernetes and Helm are ready:

```powershell
.\scripts\setup.ps1
```

After the port-forward windows are running, generate normal traffic:

```powershell
.\scripts\generate-traffic.ps1 -Minutes 5 -IntervalSeconds 2
```

For a complete live demonstration with traffic, HTTP failures, pod self-healing, a temporary outage, and recovery:

```powershell
.\scripts\live-demo.ps1 -Minutes 5
```

To make only the HTTP 5xx graph visibly rise while you watch Grafana:

```powershell
.\scripts\generate-errors.ps1 -Seconds 90 -IntervalSeconds 2
```

The application also exposes `GET /fail`, a deterministic route that always returns HTTP 503 for alert demonstrations.

The image is local and uses `imagePullPolicy: Never`, so it is intended for Docker Desktop’s local Kubernetes cluster.

## Access the services

Use separate PowerShell windows:

```powershell
.\scripts\port-forward.ps1
kubectl -n monitoring port-forward service/monitoring-grafana 3000:80
kubectl -n monitoring port-forward service/monitoring-kube-prometheus-prometheus 9090:9090
```

Open:

- App: <http://localhost:8000/>
- App health: <http://localhost:8000/health>
- App metrics: <http://localhost:8000/metrics>
- Grafana: <http://localhost:3000> (`admin` / `DevOpsDemo123!`)
- Prometheus: <http://localhost:9090>

The Grafana password is for this local demo only.

## Reliability flow and SLA/SLO view

The full flow is documented in [docs/flow-and-presentation.md](docs/flow-and-presentation.md). In short: the Service routes traffic to two pods, Node.js + Express exposes `/metrics`, the ServiceMonitor configures Prometheus scraping, Prometheus evaluates PromQL and alert rules, and Grafana presents the signals.

The project now includes demo service objectives for 85% request availability and p95 latency below 500 ms, plus alerts for scrape target down, low availability, high latency, replica loss, CPU, memory, restarts, and HTTP errors. These are SLO-style engineering objectives, not contractual SLA guarantees. A real SLA also needs an agreed measurement period, exclusions, ownership, escalation, and notification policy.

For Docker Desktop Kubernetes, the setup disables the optional node-exporter component by default. Docker Desktop runs Kubernetes inside a Linux VM, and node-exporter can fail on host-level mounts even while the application, Prometheus, Grafana, and kube-state-metrics work correctly. The workload dashboard uses container and Kubernetes object metrics, so node-exporter is not required. To enable it on a Linux host, remove `--set nodeExporter.enabled=false` from `scripts/install-monitoring.ps1`.

## Experiments

Once the app port-forward is running:

```powershell
.\scripts\run-experiments.ps1
```

The script exercises CPU load, six bounded memory allocations, twenty intentional HTTP 500 responses, and a memory reset. For the self-healing demo, delete one Deployment-managed pod:

```powershell
kubectl -n workload-lab get pods
kubectl -n workload-lab delete pod <actual-pod-name>
kubectl -n workload-lab get pods -w
```

Kubernetes recreates the deleted pod because the Deployment reconciles the desired replica count. Prometheus detects conditions; it does not restart the pod.

## Useful PromQL

```promql
up{namespace="workload-lab"}
rate(container_cpu_usage_seconds_total{namespace="workload-lab",container="demo-app",image!=""}[2m])
container_memory_working_set_bytes{namespace="workload-lab",container="demo-app",image!=""}
kube_pod_container_status_restarts_total{namespace="workload-lab",container="demo-app"}
sum by (status) (rate(demo_http_requests_total{namespace="workload-lab"}[2m]))
histogram_quantile(0.95, sum by (le) (rate(demo_http_request_duration_seconds_bucket{namespace="workload-lab"}[5m])))
```

## Troubleshooting

```powershell
kubectl -n workload-lab get pods,svc,servicemonitor,prometheusrule
kubectl -n workload-lab describe pods
kubectl -n workload-lab get events --sort-by=.lastTimestamp
kubectl -n monitoring get pods
```

If the Prometheus target is missing, confirm the ServiceMonitor has `release: monitoring`, the Service exposes the named `metrics` port, and the target namespace is `workload-lab`. If the Grafana dashboard is missing, confirm the ConfigMap label `grafana_dashboard: "1"` and the Grafana sidecar namespace setting.

## Presentation

`presentation/Kubernetes_Workload_Reliability.pptx` is a ready-to-edit college-level deck. It labels results as planned/expected until the live demo is run. Replace the marked screenshot placeholders with actual Grafana, Prometheus, and terminal captures after validation.

For the complete command sequence, use [RUNBOOK.md](RUNBOOK.md).


The assignment pipeline is documented in [docs/devops-pipeline.md](docs/devops-pipeline.md). The repository includes GitHub Actions CI, optional self-hosted local CD, a Jenkinsfile alternative, automated Node.js tests, Docker image scanning, Kubernetes rollout verification, and monitoring evidence guidance.

## Accuracy notes

- Resource requests influence scheduling; limits cap container resource usage.
- CPU pressure is a signal, not proof of user-visible failure.
- Memory over the limit can lead to OOM termination.
- Prometheus alert rules only evaluate when the required metric series exist.
- Alertmanager notification receivers are not configured by this demo.
- The project intentionally uses a synthetic app and a local single-node cluster.

