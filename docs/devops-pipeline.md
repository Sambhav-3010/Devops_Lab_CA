# DevOps delivery pipeline

This project now covers the full assignment lifecycle:

```text
Git/GitHub
   ↓
Node.js automated tests
   ↓
Docker image build
   ↓
Trivy vulnerability scan
   ↓
GitHub Container Registry
   ↓
Kubernetes rollout
   ↓
Smoke test
   ↓
Prometheus + Grafana monitoring
```

## Requirement mapping

| Assignment requirement | Project implementation |
|---|---|
| Version control | Git repository and GitHub push workflow |
| Application build | Node.js application and Dockerfile |
| Automated testing | `app/server.test.js` with `node --test` |
| Containerization | Docker image `workload-demo` |
| CI/CD implementation | `.github/workflows/ci.yml`, `.github/workflows/cd-local.yml`, and `Jenkinsfile` |
| Deployment | Docker Desktop Kubernetes Deployment and Service |
| Documentation | README, RUNBOOK, architecture, and presentation content |
| Monitoring | Prometheus, Grafana, ServiceMonitor, PrometheusRule |
| AI-assisted failure explanation | Gemini 2.5 Flash reads sanitized pipeline errors and writes an archived explanation report |

## Git setup and GitHub push

Create an empty GitHub repository first. Do not add a README, license, or `.gitignore` there because this project already contains them. From this project directory run:

```powershell
.\scripts\publish-to-github.ps1 -RepositoryUrl "https://github.com/<your-username>/<your-repository>.git"
```

The script initializes Git, creates the first commit, adds `origin`, and pushes `main`. Git Credential Manager handles authentication. Never place a GitHub token in the repository or Jenkinsfile.

## Manual Git setup

Run once from the project folder:

```powershell
git init
git add .
git commit -m "Initial Kubernetes workload reliability project"
git branch -M main
git remote add origin https://github.com/<your-username>/<your-repository>.git
git push -u origin main
```

## What the GitHub Actions CI pipeline does

On every push or pull request to `main` or `master`:

1. Checks out the code.
2. Installs Node.js 20 dependencies.
3. Runs automated API and metrics tests.
4. Builds the Docker image.
5. Scans the image with Trivy.
6. On a push to the main branch, publishes SHA-tagged and `latest` images to GHCR.

## What the CD workflow does

`.github/workflows/cd-local.yml` is a manual deployment workflow for a self-hosted GitHub Actions runner installed on the same Windows machine as Docker Desktop Kubernetes.

It:

1. Selects the `docker-desktop` context.
2. Applies Kubernetes resources.
3. Sets the Deployment to the selected GHCR image tag.
4. Waits for a successful rollout.
5. Applies ServiceMonitor, PrometheusRule, and Grafana dashboard resources.
6. Prints a smoke-test status.

GitHub-hosted runners cannot directly reach a private local Docker Desktop cluster. Use the CI workflow alone for a secure cloud-hosted demonstration, or use the self-hosted CD workflow/Jenkins for full local CI/CD.

## Final Jenkins pipeline

`Jenkinsfile` is the final pipeline for the local demonstration. It uses a Jenkins agent that has Node.js, Docker, kubectl, and the `docker-desktop` context available.

Pipeline stages:

1. Checkout the GitHub repository.
2. Install Node.js dependencies and run automated tests.
3. Build `workload-demo:<Jenkins build number>`.
4. Apply Kubernetes manifests and update the Deployment image.
5. Wait for the Kubernetes rollout.
6. Apply Prometheus/Grafana monitoring resources.
7. Run a smoke test and print pods/services.

### Jenkins job setup

1. Install Jenkins on the same Windows machine as Docker Desktop, or use a Windows Jenkins agent on that machine.
2. Ensure the Jenkins service account can run `node`, `npm`, `docker`, `kubectl`, and `git`.
3. Create **New Item → Pipeline**.
4. Select **Pipeline script from SCM**, choose Git, enter the GitHub repository URL, and set branch to `*/main`.
5. Set script path to `Jenkinsfile`.
6. Add a GitHub webhook at `http://<jenkins-host>:8080/github-webhook/` if Jenkins is reachable from GitHub. Otherwise use **Build Now**.
7. Keep Docker Desktop Kubernetes running and confirm `kubectl config get-contexts` contains `docker-desktop`.

The pipeline deploys to the local Docker Desktop cluster. A remote Jenkins agent cannot reach that private local cluster unless it is hosted on the same machine/network.

## Gemini failure explanation

The Jenkinsfile includes a policy gate and failure-analysis hooks. If a `.env` file is committed, the policy gate stops the pipeline before testing or deployment. If testing, Docker build, Kubernetes rollout, monitoring application, or the smoke test fails, the pipeline calls `scripts/explain-failure.ps1`.

The script sends only sanitized stage/error text to Gemini and creates:

```text
artifacts/gemini-failure-explanation.md
```

The report is archived in Jenkins, while the original failure remains the build result. Gemini explains the failure; it does not override a failed gate or deploy a broken build.

### Email notification on failure

The `failure` post-action uses the Jenkins **Email Extension Plugin** (`emailext`) to send an email containing:

- The Gemini explanation from `artifacts/gemini-failure-explanation.md`.
- The Jenkins build URL.
- The console output as a compressed attachment.

Configure this once:

1. Install **Email Extension Plugin** from **Manage Jenkins → Plugins**.
2. Configure SMTP under **Manage Jenkins → System → Extended E-mail Notification**.
3. Replace `NOTIFICATION_EMAIL` in the Jenkinsfile with your email, or define a Jenkins job/global environment variable with that name.
4. Push the Jenkinsfile and run a controlled failure with `SIMULATE_FAILURE=true`.

For Gmail SMTP, use an App Password rather than your normal Gmail password. The SMTP account/password belongs in Jenkins configuration, never in Git.

### How to demonstrate Gemini during the presentation

1. In Jenkins click **Build with Parameters**.
2. Set `SIMULATE_FAILURE` to `true` and run the build.
3. Show that the **Gemini Failure Demonstration** stage fails intentionally.
4. Open the build page and show the archived `artifacts/gemini-failure-explanation.md` report.
5. Explain that the pipeline stopped before application deployment.
6. Run **Build with Parameters** again with `SIMULATE_FAILURE=false`.
7. Show the green Jenkins pipeline, Kubernetes rollout, and finally Grafana metrics.

This creates a clear two-run demonstration: AI-assisted failure diagnosis followed by a successful delivery and runtime observability.

### Configure the Gemini secret in Jenkins

1. Open **Manage Jenkins → Credentials → System → Global credentials → Add Credentials**.
2. Kind: **Secret text**.
3. ID: `gemini-api-key`.
4. Secret: paste a newly generated Gemini API key.
5. Save the credential.

The Jenkinsfile reads the key through `credentials('gemini-api-key')`. It does not store the key in Git. The configured model is `gemini-2.5-flash`, using the official Gemini `models.generateContent` REST API. The model endpoint and generation settings are configurable through Jenkins environment variables.

## Demonstration script

Explain the pipeline in this order:

1. Change `app/server.js` and commit the change.
2. Push to GitHub.
3. Show Jenkins checking out the commit.
4. Show automated tests passing.
5. Show the Docker image build.
6. Show Kubernetes rollout and smoke-test output.
7. Open Grafana and show the deployed workload metrics.

## Evidence to submit

- GitHub repository URL and commit history.
- Successful Actions or Jenkins pipeline screenshot.
- Docker image/build output.
- Test output showing passing tests.
- Kubernetes rollout output.
- Grafana dashboard screenshot.
- Prometheus target and alert screenshots.
- Short explanation of failure simulation and recovery.

