pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = "caramensuachua"
        IMAGE_NAME = "ecommerce-frontend"
        DOCKER_HUB_CREDS = "docker-hub-creds"
        VERSION = "v${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
                script {
                    def branchName = env.GIT_BRANCH ?: 'main'
                    env.ACTUAL_BRANCH = branchName.replace('origin/', '')
                    echo "${env.ACTUAL_BRANCH}"
                }
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                script {
                    def repo = "${env.DOCKER_REGISTRY}/${env.IMAGE_NAME}"
                    def vTag = "${repo}:${env.VERSION}"
                    def latestTag = "${repo}:latest"

                    withCredentials([usernamePassword(credentialsId: "${env.DOCKER_HUB_CREDS}", passwordVariable: 'DOCKER_PWD', usernameVariable: 'DOCKER_USER')]) {
                        
                        // Login một lần duy nhất
                        sh "echo \$DOCKER_PWD | docker login -u \$DOCKER_USER --password-stdin"
                        
                        // Kéo bản latest về làm mốc so sánh cache (Docker sẽ so sánh các layer cũ)
                        echo "--- Pulling latest image for caching ---"
                        sh "docker pull ${latestTag} || true"

                        echo "--- Building Image version: ${env.VERSION} ---"
                        // TỐI ƯU: Sử dụng --cache-from để không phải chạy lại npm install nếu không có thư viện mới
                        sh """
                            docker build \
                            --cache-from ${latestTag} \
                            -t ${vTag} \
                            -t ${latestTag} .
                        """

                        echo "--- Pushing Tags ---"
                        sh "docker push ${vTag}"
                        sh "docker push ${latestTag}"

                        sh "docker logout"
                    }
                }
            }
        }
    }

    post {
        failure {
            sh "docker logout || true"
        }
    }
}
