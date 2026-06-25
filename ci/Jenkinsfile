// ──────────────────────────────────────────────────────────────────
// Jenkinsfile — GoLabs CI/CD Pipeline
// Stages: Lint → Test → Build Docker → Push Docker Hub → Update Infra
// ──────────────────────────────────────────────────────────────────

pipeline {
    agent any

    environment {
        // Docker Hub
        DOCKERHUB_CREDS = credentials('dockerhub-id')
        DOCKERHUB_USER  = 'gutsnet'
        API_IMAGE       = "${DOCKERHUB_USER}/golabs-api"
        UI_IMAGE        = "${DOCKERHUB_USER}/golabs-ui"

        // Git — repo de infraestructura
        GITHUB_CREDS    = credentials('github-token-id')
        INFRA_REPO      = 'https://github.com/BadByte-Team/golabs-infra.git'
        INFRA_BRANCH    = 'main'

        // Tag dinámico: BUILD_NUMBER + short commit hash
        GIT_SHORT       = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        IMAGE_TAG       = "${BUILD_NUMBER}-${GIT_SHORT}"
    }

    options {
        timeout(time: 15, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {

        // ── Stage 1: Lint & Vet (API) ──
        stage('API — Lint & Vet') {
            steps {
                dir('golabs-api') {
                    sh '''
                        echo "🔍 Running go vet..."
                        go vet ./...
                    '''
                }
            }
        }

        // ── Stage 2: Tests (API) ──
        stage('API — Test') {
            steps {
                dir('golabs-api') {
                    sh '''
                        echo "🧪 Running tests..."
                        go test -v -race -coverprofile=coverage.out ./...
                    '''
                }
            }
            post {
                always {
                    dir('golabs-api') {
                        archiveArtifacts artifacts: 'coverage.out', allowEmptyArchive: true
                    }
                }
            }
        }

        // ── Stage 3: Build Docker Images ──
        stage('Build Docker Images') {
            parallel {
                stage('Build API') {
                    steps {
                        dir('golabs-api') {
                            sh "docker build -t ${API_IMAGE}:${IMAGE_TAG} -t ${API_IMAGE}:latest ."
                        }
                    }
                }
                stage('Build UI') {
                    steps {
                        dir('golabs-ui') {
                            sh "docker build -t ${UI_IMAGE}:${IMAGE_TAG} -t ${UI_IMAGE}:latest ."
                        }
                    }
                }
            }
        }

        // ── Stage 4: Push to Docker Hub ──
        stage('Push Docker Images') {
            steps {
                sh '''
                    echo "${DOCKERHUB_CREDS_PSW}" | docker login -u "${DOCKERHUB_CREDS_USR}" --password-stdin

                    docker push ${API_IMAGE}:${IMAGE_TAG}
                    docker push ${API_IMAGE}:latest

                    docker push ${UI_IMAGE}:${IMAGE_TAG}
                    docker push ${UI_IMAGE}:latest

                    docker logout
                '''
            }
        }

        // ── Stage 5: Update golabs-infra (GitOps trigger) ──
        stage('Update Infra Repo') {
            steps {
                sh '''
                    echo "📦 Clonando golabs-infra..."
                    rm -rf golabs-infra-update
                    git clone https://${GITHUB_CREDS_USR}:${GITHUB_CREDS_PSW}@github.com/BadByte-Team/golabs-infra.git golabs-infra-update

                    cd golabs-infra-update

                    # Actualizar tag de la API en el overlay dev
                    sed -i "s|newTag:.*# golabs-api|newTag: ${IMAGE_TAG} # golabs-api|g" k8s/overlays/dev/kustomization.yaml

                    # Actualizar tag de la UI en el overlay dev
                    sed -i "s|newTag:.*# golabs-ui|newTag: ${IMAGE_TAG} # golabs-ui|g" k8s/overlays/dev/kustomization.yaml

                    git config user.email "jenkins@golabs.local"
                    git config user.name "Jenkins CI"
                    git add .
                    git diff --cached --quiet && echo "No changes to commit" && exit 0
                    git commit -m "ci: update images to ${IMAGE_TAG} [skip ci]"
                    git push origin ${INFRA_BRANCH}

                    echo "✅ golabs-infra actualizado → ArgoCD sincronizará automáticamente"
                '''
            }
        }
    }

    post {
        always {
            // Limpiar imágenes locales para ahorrar disco
            sh '''
                docker rmi ${API_IMAGE}:${IMAGE_TAG} || true
                docker rmi ${UI_IMAGE}:${IMAGE_TAG} || true
            '''
            cleanWs()
        }
        success {
            echo "✅ Pipeline completado — Tag: ${IMAGE_TAG}"
        }
        failure {
            echo "❌ Pipeline falló — Revisar logs"
        }
    }
}
