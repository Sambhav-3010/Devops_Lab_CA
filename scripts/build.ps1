$ErrorActionPreference = 'Stop'
docker build -t workload-demo:1.0 ./app
if ($LASTEXITCODE -ne 0) {
    throw 'Docker image build failed. Kubernetes deployment was not attempted.'
}
docker image inspect workload-demo:1.0 | Select-Object -First 1

