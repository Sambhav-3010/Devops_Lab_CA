# Excalidraw-ready architecture

Paste this Mermaid code into an Excalidraw Mermaid diagram importer, or use it as the drawing blueprint for the presentation.

```mermaid
flowchart LR
    U["User / PowerShell traffic"] --> S["Kubernetes Service\nworkload-lab/demo-app"]
    S --> P1["demo-app Pod 1\nNode.js + Express"]
    S --> P2["demo-app Pod 2\nNode.js + Express"]

    P1 --> M["/metrics\nPrometheus text format"]
    P2 --> M
    M --> SM["ServiceMonitor\n15 second scrape"]
    SM --> PR["Prometheus\nTSDB + PromQL + rules"]

    K["Kubernetes API / kube-state-metrics\nreplicas · restarts · deployments"] --> PR
    C["Container metrics\nCPU · memory"] --> PR
    PR --> G["Grafana dashboard\nSLI · SLO · latency · pressure"]
    PR --> A["Alertmanager\noptional notifications"]

    D["Deployment controller\ndesired replicas = 2"] --> P1
    D --> P2
    D -. "recreates deleted pod" .-> R["Replacement pod"]
```

## Namespace structure

```mermaid
flowchart TB
    C["Docker Desktop Kubernetes cluster"]
    C --> W["Namespace: workload-lab"]
    W --> D["Deployment: demo-app\nreplicas: 2"]
    W --> S["Service: demo-app\nport 8000"]
    W --> SM["ServiceMonitor"]
    W --> PR["PrometheusRule"]

    C --> M["Namespace: monitoring"]
    M --> P["Prometheus"]
    M --> G["Grafana"]
    M --> AM["Alertmanager"]
    M --> K["kube-state-metrics"]
```

## Failure interpretation

```text
HTTP /fail while pods exist
    -> Node.js returns HTTP 503
    -> demo_http_requests_total{status="503"} increases
    -> 5xx rate and availability SLI change

replicas scaled to zero
    -> Service has no endpoints
    -> client sees connection failure / no response, not an app-generated HTTP 5xx
    -> up, replica availability, and target-down signals change
```
