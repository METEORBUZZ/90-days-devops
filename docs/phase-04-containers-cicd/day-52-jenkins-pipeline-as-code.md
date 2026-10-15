# Day 52: Jenkins Declarative Pipeline as Code (`Jenkinsfile`)

## 1. Theoretical Foundation

### Scripted vs. Declarative Pipelines
- **Scripted Pipeline (Legacy)**: Uses imperative Groovy code. Highly flexible, but lacks structure, error-handling uniformity, and is difficult to maintain.
- **Declarative Pipeline (Modern Standard)**: Enforces a strict, opinionated, structured hierarchy (`pipeline { ... }`). Easier to read, offers built-in syntax validation, and standardizes stages, error conditions, and post-build actions.

---

## 2. Complete Enterprise Declarative `Jenkinsfile`

Save this file in the root of your Git repository:

```groovy
pipeline {
    // 1. Specify where the pipeline executes
    agent {
        docker {
            image 'node:20-alpine'
            args '-u root:root'
        }
    }

    // 2. Global Pipeline Options
    options {
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '20'))
        disableConcurrentBuilds()
    }

    // 3. Environment Variables & Secret Injections
    environment {
        APP_NAME    = 'order-processing-api'
        IMAGE_TAG   = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"
        AWS_REGION  = 'ap-south-1'
        SONAR_TOKEN = credentials('sonarqube-api-token')
    }

    // 4. Sequential Pipeline Stages
    stages {
        stage('Checkout & Lint') {
            steps {
                echo "Checking out Git commit: ${env.GIT_COMMIT}"
                sh 'npm ci'
                sh 'npm run lint'
            }
        }

        stage('Unit & Integration Tests') {
            steps {
                echo "Executing automated test suite..."
                sh 'npm test -- --coverage'
            }
        }

        stage('Static Code Analysis') {
            steps {
                echo "Running SonarQube quality gate scan..."
                // Example Sonar scanner invocation
                sh 'echo "SonarQube Scan Complete"'
            }
        }

        stage('Docker Build & Package') {
            steps {
                echo "Packaging Docker image: ${APP_NAME}:${IMAGE_TAG}"
                sh "docker build -t ${APP_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Deploy to Staging') {
            when {
                branch 'main'
            }
            steps {
                echo "Deploying to Kubernetes Staging Namespace..."
                sh 'kubectl set image deployment/order-api order-api=${APP_NAME}:${IMAGE_TAG} -n staging'
            }
        }

        stage('Production Approval Gate') {
            when {
                branch 'main'
            }
            steps {
                // Interactive manual approval gate
                input message: "Approve deployment of ${IMAGE_TAG} to Production?", ok: "Deploy Now"
                echo "Deployment approved by Release Manager."
            }
        }

        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                echo "Deploying to Production Cluster..."
                sh 'kubectl set image deployment/order-api order-api=${APP_NAME}:${IMAGE_TAG} -n production'
            }
        }
    }

    // 5. Post-Build Handlers (Guaranteed Execution)
    post {
        always {
            cleanWs() // Purge agent workspace to prevent disk leaks
        }
        success {
            echo "Pipeline succeeded! Sending notification to Slack..."
        }
        failure {
            echo "ALERT: Pipeline failed on stage: ${STAGE_NAME}!"
        }
    }
}
```

---

## 3. Key Directives Explained

### `when` Conditions
Restricts stages to specific conditions (e.g. only run deployment when building the `main` branch or when a specific environment variable is present):
```groovy
when {
    branch 'main'
    environment name: 'DEPLOY_FLAG', value: 'true'
}
```

### `input` (Manual Approval Gate)
Pauses pipeline execution and renders an interactive "Approve / Abort" prompt in the Jenkins UI, preventing unintended production releases without managerial sign-off.

### `cleanWs()` in `post { always { ... } }`
Purges temporary checkout folders, node_modules, and build binaries from the agent disk after every build, preventing agent disk exhaustion.

---

## 4. Interview & Review Questions
1. **What is the difference between Declarative and Scripted Pipelines in Jenkins?**
   - *Answer*: Declarative pipelines provide a strict, predefined syntax block (`pipeline { agent { ... } stages { ... } }`) with built-in validation, structured stage views in Blue Ocean, and standardized error handling. Scripted pipelines use free-form, imperative Groovy scripts without structural restrictions, making them harder to maintain and audit.
2. **What does the `cleanWs()` step do in a `post { always { ... } }` block?**
   - *Answer*: It completely deletes the checked-out workspace directory on the worker agent upon job completion (whether successful or failed), preventing stale build artifacts from polluting future jobs and preventing agent disks from filling up.
