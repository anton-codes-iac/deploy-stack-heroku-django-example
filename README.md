# deploy-stack-heroku-django-example ☁️🚀

> A classic Heroku-style Django monolith migrated to AWS ECS Fargate via **[deploy-stack's](https://github.com/anton-codes-iac/deploy-stack)** Procfile Importer.

This repository demonstrates how `deploy-stack` automatically parses a `Procfile` and translates it into a highly available, multi-container AWS architecture—spinning up both a public **Web Service** and an isolated **Worker Service** from a single Docker image.

---

## 🎮 The Migration Topology (Dry Run)

Run the Trust Engine to preview how the `Procfile` maps to AWS infrastructure:

```bash
npx deploy-stack apply --dry-run
```
*Notice how the CLI automatically detects the Celery worker and provisions a separate, private Fargate cluster for background tasks while routing the Gunicorn web process through the ALB.*

---

## 💰 Architecture & Cost Estimate

This configuration provisions an Application Load Balancer (ALB), an RDS PostgreSQL database, and **two** ECS Fargate services (Web + Worker: **Micro: 0.25 vCPU, 512MB RAM**).

* **Estimated Baseline:** ~$54.27 / month 
* **Hourly Rate:** ~$0.074 / hour
* *Testing for an afternoon costs less than $0.30 before tearing down.*

> **⚠️ Note:** You are solely responsible for all AWS charges incurred. Always set up AWS Budget Alerts for active workloads.

---

## 🚀 Deployment Guide

### 1. Provision AWS Infrastructure
Generate and apply the cloud stack directly from your project root. The CLI will automatically parse `Procfile` and detect `core.wsgi`:
```bash
npx deploy-stack apply
```

### 2. Push Secrets (Optional)
Push your local `.env` variables (like `DJANGO_SECRET_KEY`) directly to encrypted AWS Secrets Manager vaults:
```bash
npx deploy-stack secrets push .env
```

### 3. Automated CI/CD (OIDC)
Commit and push your repository to GitHub:
```bash
git add .
git commit -m "feat: migrate to aws via deploy-stack"
git push origin main
```
The GitHub Actions workflow uses **AWS IAM OpenID Connect (OIDC)** to securely build the container once and deploy it across both the Web and Worker services simultaneously.

---

## ⚠️ Critical Application Prerequisites

### 1. The Gunicorn Binding Trap
By default, Gunicorn binds to `127.0.0.1:8000` (localhost). Inside a Docker container on AWS, this causes the Load Balancer to fail with a `502 Bad Gateway`. 

You **must** update your `Procfile` to bind to all network interfaces (`0.0.0.0`):
```text
web: gunicorn core.wsgi -b 0.0.0.0:8000 --log-file -
```

### 2. The Health Check Route
AWS constantly pings your container to ensure it is alive. Ensure your `urls.py` returns a `200 OK` at your configured path (e.g., `/up`).

---

## 🛑 Safe Teardown

To tear down all provisioned resources (ALB, ECS Web/Worker, RDS, networking, and S3 state bucket) and halt AWS billing:

```bash
npx deploy-stack destroy --yes
```