# Presentation assets

The generated PowerPoint is `Kubernetes_Workload_Reliability.pptx`.

The deck contains 17 concise slides covering the problem, architecture, implementation, metrics, experiments, limitations, conclusion, and references. It deliberately uses expected-result language until the local cluster has been run and screenshots have been captured.

Recommended screenshots to add after running the project:

1. `kubectl -n workload-lab get pods`
2. Prometheus `/targets` showing `demo-app` as `UP`
3. Grafana dashboard during CPU/memory load
4. Prometheus alert state after HTTP 500 generation
5. Pod replacement after a Deployment-managed pod is deleted

