pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        timeout(time: 20, unit: 'MINUTES')
    }

    triggers { githubPush() }

    parameters {
        booleanParam(
            name: 'SIMULATE_FAILURE',
            defaultValue: false,
            description: 'Demo only: intentionally fail the policy stage and generate a Gemini explanation.'
        )
    }

    environment {
        APP_NAME = 'demo-app'
        APP_NAMESPACE = 'workload-lab'
        IMAGE = "workload-demo:${env.BUILD_NUMBER}"
        KUBE_CONTEXT = 'docker-desktop'
        // Docker Desktop created this kubeconfig for the Windows user running the project.
        // Change this path if Jenkins is installed under a different Windows username.
        KUBECONFIG = 'C:\\Users\\sambh\\.kube\\config'
        LLM_PROVIDER = 'gemini'
        GEMINI_API_KEY = credentials('gemini-api-key')
        GEMINI_MODEL = 'gemini-2.5-flash'
        GEMINI_BASE_URL = 'https://generativelanguage.googleapis.com/v1beta'
        LLM_MAX_TOKENS = '8192'
        LLM_TEMPERATURE = '0.2'
        LLM_TOP_P = '0.9'
        RAG_ENABLE_LLM = '1'
        // Set this in Jenkins global/job environment variables.
        NOTIFICATION_EMAIL = 'sambhavmani.tripathi@gmail.com'
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Policy Gate') {
            steps {
                powershell '''
                    $envFiles = Get-ChildItem -Path . -Recurse -Force -File -Filter '.env' -ErrorAction SilentlyContinue
                    if ($envFiles) {
                        $message = "Policy gate blocked the build: .env files are not allowed in the repository. Store configuration in Jenkins Credentials or Kubernetes Secrets. Found: $($envFiles.FullName -join ', ')"
                        .\\scripts\\explain-failure.ps1 -Stage 'Policy Gate' -FailureText $message
                        throw $message
                    }
                '''
            }
        }

        stage('Gemini Failure Demonstration') {
            when { expression { return params.SIMULATE_FAILURE } }
            steps {
                powershell '''
                    $message = @"
Demo failure injected by Jenkins parameter SIMULATE_FAILURE=true.
This represents a protected configuration or policy violation before deployment.
Expected action: stop the pipeline and explain the failure without exposing secrets.
"@
                    .\\scripts\\explain-failure.ps1 -Stage 'Gemini Failure Demonstration' -FailureText $message
                    throw $message
                '''
            }
        }

        stage('Install and Test') {
            steps {
                dir('app') {
                    powershell '''
                        try {
                            npm install --no-audit --no-fund
                            npm test
                            if ($LASTEXITCODE -ne 0) { throw 'Automated tests returned a non-zero exit code.' }
                        } catch {
                            $message = $_ | Out-String
                            ..\\scripts\\explain-failure.ps1 -Stage 'Install and Test' -FailureText $message
                            throw
                        }
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                powershell '''
                    try {
                        docker build --tag $env:IMAGE .\\app
                        if ($LASTEXITCODE -ne 0) { throw 'Docker image build returned a non-zero exit code.' }
                    } catch {
                        $message = $_ | Out-String
                        .\\scripts\\explain-failure.ps1 -Stage 'Build Docker Image' -FailureText $message
                        throw
                    }
                '''
            }
        }

        stage('Deploy Application') {
            steps {
                powershell '''
                    try {
                        kubectl config get-contexts
                        kubectl config use-context $env:KUBE_CONTEXT
                        if ($LASTEXITCODE -ne 0) {
                            throw "Kubernetes context '$env:KUBE_CONTEXT' is not available to the Jenkins service account."
                        }
                        kubectl apply -f .\\k8s\\app.yaml
                        kubectl -n $env:APP_NAMESPACE set image deployment/$env:APP_NAME $env:APP_NAME=$env:IMAGE
                        kubectl -n $env:APP_NAMESPACE rollout status deployment/$env:APP_NAME --timeout=180s
                    } catch {
                        $message = $_ | Out-String
                        .\\scripts\\explain-failure.ps1 -Stage 'Deploy Application' -FailureText $message
                        throw
                    }
                '''
            }
        }

        stage('Apply Monitoring') {
            steps {
                powershell '''
                    try {
                        kubectl apply -f .\\k8s\\servicemonitor.yaml
                        kubectl apply -f .\\k8s\\alerts.yaml
                        kubectl apply -f .\\k8s\\dashboard.yaml
                    } catch {
                        $message = $_ | Out-String
                        .\\scripts\\explain-failure.ps1 -Stage 'Apply Monitoring' -FailureText $message
                        throw
                    }
                '''
            }
        }

        stage('Smoke Test') {
            steps {
                powershell '''
                    try {
                        kubectl -n $env:APP_NAMESPACE get deployment,pods,svc
                        kubectl -n $env:APP_NAMESPACE wait --for=condition=available deployment/$env:APP_NAME --timeout=60s
                    } catch {
                        $message = $_ | Out-String
                        .\\scripts\\explain-failure.ps1 -Stage 'Smoke Test' -FailureText $message
                        throw
                    }
                '''
            }
        }
    }

    post {
        always {
            powershell 'kubectl -n $env:APP_NAMESPACE get pods,svc 2>$null; exit 0'
            archiveArtifacts artifacts: 'artifacts/**', allowEmptyArchive: true
        }
        failure {
            emailext(
                to: "${env.NOTIFICATION_EMAIL}",
                subject: "FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: '''The Jenkins build failed.

Gemini failure analysis:

${FILE,path="artifacts/gemini-failure-explanation.md"}

Jenkins build: ${BUILD_URL}
Console output: ${BUILD_URL}console
''',
                attachLog: true,
                compressLog: true
            )
        }
        success { echo 'Deployment completed. Open Grafana to verify workload metrics.' }
    }
}
