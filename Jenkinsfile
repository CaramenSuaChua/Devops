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

        stage('Build & Push Fast') {
            steps {
                script {
                    def fullTag = "${DOCKER_REGISTRY}/${IMAGE_NAME}:${env.ACTUAL_BRANCH}-${VERSION}"
                    
                    withCredentials([usernamePassword(credentialsId: "${DOCKER_HUB_CREDS}", passwordVariable: 'PWD', usernameVariable: 'USER')]) {
                        sh "echo \$PWD | docker login -u \$USER --password-stdin"
                        
                        // Sử dụng Buildx với cache nội bộ (inline cache)
                        // Nếu layer npm install không đổi, nó sẽ bỏ qua trong 1 giây
                        sh """
                            docker buildx build \
                            --cache-from type=registry,ref=${DOCKER_REGISTRY}/${IMAGE_NAME}:cache \
                            --cache-to type=registry,ref=${DOCKER_REGISTRY}/${IMAGE_NAME}:cache,mode=max \
                            -t ${fullTag} \
                            -t ${DOCKER_REGISTRY}/${IMAGE_NAME}:${VERSION} \
                            --push .
                        """
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
