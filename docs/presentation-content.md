# Presentation content and speaking notes

## Slide 1 — Title

Kubernetes Workload Reliability and Resource Pressure Analysis Using Node.js, Prometheus, and Grafana.

Say: “This project demonstrates how a Kubernetes workload can be deployed, observed, stressed, failed, and recovered in a local Docker Desktop cluster.”

## Slide 2 — Problem statement

- A pod can be running while the application is slow or returning errors.
- Uptime alone does not explain resource pressure.
- Operators need infrastructure, Kubernetes, and application signals together.

Say: “The goal is not only to know whether a container exists; the goal is to understand whether the service is reliable for users.”

## Slide 3 — Objectives

- Deploy two Node.js replicas.
- Expose `/health`, `/metrics`, `/load`, and `/fail`.
- Collect HTTP, latency, CPU, memory, replica, and restart metrics.
- Show p95 and p99 latency.
- Demonstrate 2xx traffic, HTTP 503 errors, pod self-healing, and outage recovery.

## Slide 4 — Architecture

Explain: “The Service routes traffic to ready pods. The ServiceMonitor tells Prometheus where `/metrics` is. Grafana queries Prometheus. Kubernetes controllers maintain the desired replica state.”

## Slide 5 — Namespaces

- `workload-lab`: application, Service, ServiceMonitor, PrometheusRule.
- `monitoring`: Prometheus, Grafana, Alertmanager, kube-state-metrics.

Explain that namespaces provide logical isolation and make ownership easier to inspect.

## Slide 6 — Metrics pipeline

1. Node.js increments request counters and observes request-duration buckets.
2. Prometheus scrapes `/metrics` every 15 seconds.
3. Prometheus stores time series.
4. PromQL calculates rates, availability, error budget, p95, and p99.
5. Grafana visualizes those queries.

## Slide 7 — Baseline

Show two healthy pods, `up = 1`, two available replicas, continuous HTTP 200 traffic, and a stable latency line.

## Slide 8 — CPU and memory pressure

Run `/load?mode=cpu&seconds=10` and `/load?mode=memory&mb=15`.

Explain: CPU work creates long request durations and should increase p95/p99. Memory allocation increases the Node.js resident-memory metric. Resource limits are configured in the Deployment.

## Slide 9 — p95 versus p99

- p95: 95% of observed requests are at or below this latency.
- p99: 99% of observed requests are at or below this latency.
- p99 exposes tail latency that p95 can hide.

PromQL:

```promql
histogram_quantile(0.95, sum by (le) (rate(demo_http_request_duration_seconds_bucket{namespace="workload-lab"}[5m])))
```

```promql
histogram_quantile(0.99, sum by (le) (rate(demo_http_request_duration_seconds_bucket{namespace="workload-lab"}[5m])))
```

## Slide 10 — Deterministic 5xx failures

Call `/fail`. It always returns HTTP 503 while the pods are alive.

Explain: “This is an application-level failure. The request reaches Node.js, Node.js returns 503, and Prometheus records the status.”

## Slide 11 — Service outage

Scale the Deployment to zero.

The dashboard’s **Application Service State** card changes from green `UP` to red `DOWN` because available replicas become zero.

Explain: “This is different from an application 5xx. There is no backend pod to return a response, so the client may receive connection failure. We detect this through the application state card, replica availability, target health, and request absence.”

## Slide 12 — Self-healing

Delete one pod. Kubernetes creates a replacement because the Deployment desired state remains two replicas.

## Slide 13 — SLI, SLO, SLA

- SLI: measured success ratio, p95/p99 latency, scrape status.
- SLO: internal target, such as 85% availability and p95 below 500 ms.
- SLA: separate business/legal agreement with measurement window, exclusions, support terms, and remedies.

## Slide 14 — Results

Use actual Grafana screenshots. Do not invent percentages. Record the time each alert became pending/firing and the time recovery completed.

## Slide 15 — Limitations

- Local single-node cluster.
- Synthetic workload.
- Metrics are process-local and reset when pods restart.
- A production SLA needs durable long-term storage and an agreed reporting window.
- Node-exporter is optional on Docker Desktop.

## Slide 16 — Conclusion

“The project connects deploy, observe, simulate, detect, and recover into one repeatable reliability workflow.”

## Slide 17 — Demo command card

```powershell
.\scripts\live-reliability-demo.ps1 -DurationMinutes 7
```

Watch Grafana refresh every 5 seconds while the script moves through baseline, pressure, failures, self-healing, outage, and recovery.
