### README.md

# Angular Application

This repository contains an Angular application, Dockerized for local usage and deployable on Minikube. It also includes a CI/CD pipeline setup using GitHub Actions.

---

## Table of Contents

1. [Build and Run Locally Using Docker](#build-and-run-locally-using-docker)
2. [Deploy on Minikube](#deploy-on-minikube)
   - [Required Minikube Setup Commands](#required-minikube-setup-commands)
   - [Access the Application](#access-the-application)
3. [CI/CD Pipeline Explanation](#cicd-pipeline-explanation)
4. [Decisions, Assumptions, and Challenges](#decisions-assumptions-and-challenges)

---

## Build and Run Locally Using Docker

### Prerequisites

- Docker installed on your machine.

### Steps

1. **Build the Docker Image**:

   ```bash
   docker build -t kyosk-test:latest .
   ```

2. **Run the Application**:

   ```bash
   docker run -p 4000:4000 kyosk-test:latest
   ```

3. **Access the Application**:
   Open your browser and navigate to [http://localhost:4000](http://localhost:4000).

---

## Deploy on Minikube

### Prerequisites

- [Minikube](https://minikube.sigs.k8s.io/docs/start/) installed.
- `kubectl` CLI installed.

### Required Minikube Setup Commands

1. **Start Minikube**:

   ```bash
   minikube start
   ```

2. **Switch to Minikube Docker Daemon**:
   This ensures Docker images are built directly in the Minikube environment.

   ```bash
   eval $(minikube docker-env)
   ```

3. **Build the Docker Image**:

   ```bash
   docker build -t kyosk-test:latest .
   ```

4. **Create Deployment and Service**:
   Apply the following Kubernetes YAML files:

   - `deployment.yaml`:

     ```yaml
     apiVersion: apps/v1
     kind: Deployment
     metadata:
       name: kyosk-test-app
       labels:
         app: kyosk-test
     spec:
       replicas: 2
       selector:
         matchLabels:
           app: kyosk-test
       template:
         metadata:
           labels:
             app: kyosk-test
         spec:
           containers:
             - name: kyosk-test
               image: kyosk-test:latest
               ports:
                 - containerPort: 4000
               env:
                 - name: NODE_ENV
                   value: "production"
     ```

   - `service.yaml`:
     ```yaml
     apiVersion: v1
     kind: Service
     metadata:
       name: kyosk-test-service
     spec:
       type: NodePort
       selector:
         app: kyosk-test
       ports:
         - protocol: TCP
           port: 4000
           targetPort: 4000
           nodePort: 30080
     ```

   Deploy these files:

   ```bash
   kubectl apply -f deployment.yaml
   kubectl apply -f service.yaml
   ```

### Access the Application

1. **Get Minikube IP**:

   ```bash
   minikube ip
   ```

2. **Access via NodePort**:
   Combine the Minikube IP with the NodePort. For example:

   ```
   http://<MINIKUBE_IP>:30080
   ```

3. **Start minikube service**:
   Start minikube service to enable the app to be accessed locally:
   ```bash
   minikube service kyosk-test-service
   ```
   Access the app via the provided URL

---

## CI/CD Pipeline Explanation

The CI/CD pipeline is implemented using GitHub Actions and automates the following:

### Workflow

1. **Build and Test**:

   - Installs dependencies.

2. **Build Docker Image**:

   - Builds a Docker image for the Angular app.
   - Logs in to Docker Hub and pushes the image.

3. **Deploy (Optional)**:
   - Deploys to platforms like Netlify, Firebase, or Kubernetes (e.g., Minikube).

### Trigger

- On every `push` or `pull_request` to the `main` branch.

### Key Files

- **Workflow YAML**: `.github/workflows/angular.yml`

  ```yaml
  name: CI for Angular

  on:
    push:
      branches:
        - main
    pull_request:

  jobs:
    build-and-test:
      runs-on: ubuntu-latest

      steps:
        # Checkout the code
        - name: Checkout repository
          uses: actions/checkout@v3

        # Set up Node.js
        - name: Setup Node.js
          uses: actions/setup-node@v3
          with:
            node-version: 18

        # Install dependencies
        - name: Install dependencies
          run: npm install

        # Build the Angular application
        - name: Build Angular app
          run: npm run build

    docker-build:
      runs-on: ubuntu-latest
      needs: build-and-test

      steps:
        - name: Checkout repository
          uses: actions/checkout@v3

        - name: Login to Docker Hub
          uses: docker/login-action@v2
          with:
            username: ${{ secrets.DOCKER_USERNAME }}
            password: ${{ secrets.DOCKER_PASSWORD }}

        - name: Build Docker image
          run: docker build -t infinical/kyosk_test .

        - name: Push Docker image
          run: docker push infinical/kyosk_test
  ```

---

## Decisions, Assumptions, and Challenges

### Decisions

- Used Node.js 18 to ensure compatibility with Angular 18.
- Deployed using Minikube with NodePort for local testing.

### Assumptions

- The Minikube environment is available locally.
- Docker is installed and configured to communicate with Minikube’s Docker daemon.

### Challenges

- **Minikube Networking**: Accessing the application required understanding Minikube’s NodePort setup and IP configuration.
- **Image Compatibility**: Ensuring the Docker image is lightweight yet compatible with SSR functionality.
- **CI/CD Secrets**: Securely storing credentials for Docker Hub and deployment platforms in GitHub Actions.
