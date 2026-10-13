# Project flow and presentation guide

## 1. End-to-end flow

```text
User / test traffic
        |
        v
Kubernetes Service
        |
        v
Two Node.js + Express application pods
        |                         Kubernetes control plane
        | /metrics                         |
        v                                   v
Prometheus <----- kube-state-metrics / container metrics
        |
        +---- PromQL queries and alert rules
        |
        +---- Grafana dashboard
        |
        +---- Alertmanager notifications (optional future step)
```

1. The Deployment asks Kubernetes to keep two `demo-app` pods running.
2. The Service gives users one stable address and load-balances requests to ready pods.
3. Node.js + Express exposes `/health` for probes and `/metrics` for application metrics.
4. The ServiceMonitor tells the Prometheus Operator to scrape `/metrics` every 15 seconds.
5. Prometheus also receives Kubernetes state and container metrics from the monitoring stack.
6. Grafana queries Prometheus; Grafana does not collect metrics directly.
7. PrometheusRule resources evaluate CPU, memory, availability, latency, error rate, replica, and scrape-health conditions.
8. Kubernetes reconciles and replaces a deleted pod. Monitoring detects and presents the event.

## 2. What the dashboard should show

Organize the Grafana dashboard in this order:

### Service health row

- **Availability / SLO:** successful requests divided by total requests.
- **Error budget remaining:** `100 * (availability - 0.85) / 0.15`, capped at 100% for display.
- **p95 latency:** the 95th percentile from the request-duration histogram.
- **Scrape status:** `1` means Prometheus can scrape the app; `0` means the target is down.

### Workload pressure row

- CPU percentage of the configured limit.
- Memory working-set percentage of the configured limit.
- Available replicas compared with the desired two replicas.
- Container restarts over the selected time range.

### Traffic and failure row

- Requests per second grouped by HTTP status.
- 5xx requests per second.
- Availability over time.
- p95 latency over time.

## 3. SLA versus SLO versus SLI

- **SLI:** the measurement, such as request success ratio or p95 latency.
- **SLO:** the engineering target, such as 85% successful requests and p95 latency below 500 ms.
- **SLA:** the customer or business agreement that may include service credits, support commitments, and scope. This demo implements SLI/SLO monitoring; a real SLA also needs an agreed measurement window, exclusions, ownership, and notification/escalation policy.

For this project, present the following as demo objectives rather than contractual guarantees:

| Objective | SLI | Demo target |
|---|---|---:|
| Availability | 1 - HTTP 5xx / total requests | 85% |
| Latency | p95 request duration | < 500 ms |
| Capacity | CPU and memory versus limits | < 80% warning |
| Resilience | Available replicas | 2 of 2 |
| Observability | Prometheus scrape health | 1 / UP |

## 4. How to explain a service-down scenario

1. Stop or break the application path, or scale the Deployment to zero in a controlled lab.
2. Prometheus receives `up = 0` for the target after the next scrape.
3. `DemoAppMetricsTargetDown` becomes pending and then firing after one minute.
4. Grafana shows the scrape status dropping to zero, request rate falling, and availability becoming unavailable if no requests are arriving.
5. Kubernetes may show unavailable replicas and the `WorkloadReplicasUnavailable` alert.
6. Restore the Deployment or fix the Service/pod, then show the target returning to `UP` and replicas returning to two.

Do not say that Grafana repaired the service. Prometheus detected the condition, while Kubernetes or an operator performed the recovery.

## 5. A simple 7-minute presentation script

### Minute 1 — Problem

“A pod can be running while the service is still slow, returning errors, or using too many resources. This project combines Kubernetes state, container metrics, and application metrics.”

### Minute 2 — Architecture

Point from the Service to the two pods, then from `/metrics` to Prometheus, and finally to Grafana and PrometheusRule alerts.

### Minute 3 — Baseline

Show `kubectl get pods`, `/health`, Prometheus Targets, and the dashboard. Explain that `UP` means scrape success, not necessarily perfect user experience.

### Minute 4 — Pressure

Run the CPU and memory endpoints. Explain requests versus limits and show the corresponding panels.

### Minute 5 — Failure

Generate HTTP 500 responses. Show the 5xx graph, availability SLI, and error-rate alert.

### Minute 6 — Recovery

Delete one pod. Show Kubernetes creating a replacement and the available replica count returning to two.

### Minute 7 — SLA/SLO close

“The dashboard measures the SLI, the alert rules compare it with the SLO, and the SLA is the broader business agreement built on those measurements.”

## 6. Viva questions to prepare

- Prometheus collects and evaluates metrics; Grafana visualizes them.
- A Deployment replaces a deleted pod; Prometheus does not restart it.
- A CPU limit is not the same as a CPU request.
- A scrape target being `UP` only proves that Prometheus can collect metrics.
- Availability needs traffic. If there are no requests, the success ratio is not meaningful.
- A real 30-day SLA needs durable Prometheus storage and a defined reporting window; this local demo uses rolling five-minute windows for fast feedback.

