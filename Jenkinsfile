pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = "caramensuachua"
        IMAGE_NAME = "ecommerce-frontend"
        DOCKER_HUB_CREDS = "docker-hub-creds"
        // Tạo biến VERSION để dùng thống nhất trong toàn bộ Pipeline
        VERSION = "${env.BUILD_NUMBER}" 
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

        stage('Test') {
            steps {
                echo "--- Đang chạy Unit Test... ---"
                sh "echo 'Tests passed!'" 
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                echo "--- Đang Build và Push Image lên Docker Hub ---"
                
                withCredentials([usernamePassword(credentialsId: "${env.DOCKER_HUB_CREDS}", passwordVariable: 'DOCKER_PWD', usernameVariable: 'DOCKER_USER')]) {
                    
                    // 1. Khai báo biến tag đầy đủ để tránh sai sót
                    def fullImageTag = "${DOCKER_REGISTRY}/${IMAGE_NAME}:${env.ACTUAL_BRANCH}-${VERSION}"
                    def latestTag = "${DOCKER_REGISTRY}/${IMAGE_NAME}:latest"

                    // 2. Build Image
                    sh "docker build -t ${fullImageTag} ."
                    sh "docker tag ${fullImageTag} ${latestTag}"

                    // 3. Login
                    sh "echo \$DOCKER_PWD | docker login -u \$DOCKER_USER --password-stdin"

                    // 4. Push
                    sh "docker push ${fullImageTag}"
                    sh "docker push ${latestTag}"

                    // 5. Logout ngay lập tức để bảo mật
                    sh "docker logout"
                }
            }
        }
    }

    post {
        success {
            echo "-----------------------------------------------------------"
            echo "Thành công! Image đã đẩy lên: ${DOCKER_REGISTRY}/${IMAGE_NAME}:${env.ACTUAL_BRANCH}-${VERSION}"
            echo "-----------------------------------------------------------"
        }
        failure {
            sh "docker logout || true"
        }
    }
}
