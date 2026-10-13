pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        timeout(time: 20, unit: 'MINUTES')
    }

    triggers { githubPush() }

    environment {
        APP_NAME = 'demo-app'
        APP_NAMESPACE = 'workload-lab'
        IMAGE = "workload-demo:${env.BUILD_NUMBER}"
        KUBE_CONTEXT = 'docker-desktop'
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Install and Test') {
            steps {
                dir('app') {
                    powershell 'npm install --no-audit --no-fund'
                    powershell 'npm test'
                }
            }
        }

        stage('Build Docker Image') {
            steps { powershell 'docker build --tag $env:IMAGE .\\app' }
        }

        stage('Deploy Application') {
            steps {
                powershell '''
                    kubectl config use-context $env:KUBE_CONTEXT
                    kubectl apply -f .\\k8s\\app.yaml
                    kubectl -n $env:APP_NAMESPACE set image deployment/$env:APP_NAME $env:APP_NAME=$env:IMAGE
                    kubectl -n $env:APP_NAMESPACE rollout status deployment/$env:APP_NAME --timeout=180s
                '''
            }
        }

        stage('Apply Monitoring') {
            steps {
                powershell '''
                    kubectl apply -f .\\k8s\\servicemonitor.yaml
                    kubectl apply -f .\\k8s\\alerts.yaml
                    kubectl apply -f .\\k8s\\dashboard.yaml
                '''
            }
        }

        stage('Smoke Test') {
            steps {
                powershell '''
                    kubectl -n $env:APP_NAMESPACE get deployment,pods,svc
                    kubectl -n $env:APP_NAMESPACE wait --for=condition=available deployment/$env:APP_NAME --timeout=60s
                '''
            }
        }
    }

    post {
        always { powershell 'kubectl -n $env:APP_NAMESPACE get pods,svc 2>$null' }
        success { echo 'Deployment completed. Open Grafana to verify workload metrics.' }
    }
}
