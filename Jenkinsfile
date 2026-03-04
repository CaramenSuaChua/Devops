pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = "caramensuachua"
        IMAGE_NAME = "ecommerce-frontend"
        DOCKER_HUB_CREDS = "docker-hub-creds"
        // Tạo biến Version khớp với số Build (ví dụ: v49)
        VERSION = "v${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
                script {
                    def branchName = env.GIT_BRANCH ?: 'main'
                    env.ACTUAL_BRANCH = branchName.replace('origin/', '')
                }
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                script {
                    // Tag đầy đủ: caramensuachua/ecommerce-frontend:main-v49
                    def fullImageTag = "${env.DOCKER_REGISTRY}/${env.IMAGE_NAME}:${env.ACTUAL_BRANCH}-${env.VERSION}"
                    def latestTag = "${env.DOCKER_REGISTRY}/${env.IMAGE_NAME}:${env.VERSION}"

                    withCredentials([usernamePassword(credentialsId: "${env.DOCKER_HUB_CREDS}", passwordVariable: 'DOCKER_PWD', usernameVariable: 'DOCKER_USER')]) {
                        
                        // TỐI ƯU: Login trước để kéo bản latest về làm cache
                        sh "echo \$DOCKER_PWD | docker login -u \$DOCKER_USER --password-stdin"
                        
                        echo "--- Đang kéo bản latest để tối ưu Cache ---"
                        sh "docker pull ${latestTag} || true"

                        echo "--- Đang Build Image ${env.VERSION} ---"
                        // Sử dụng --cache-from để tiết kiệm thời gian install npm
                        sh """
                            docker build \
                            --cache-from ${latestTag} \
                            -t ${fullImageTag} \
                            -t ${latestTag} .
                        """

                        echo "--- Đang Push Image ---"
                        sh "docker push ${fullImageTag}"
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
