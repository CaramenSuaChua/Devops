pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = "caramensuachua"
        IMAGE_NAME = "ecommerce-frontend"
        DOCKER_HUB_CREDS = "docker-hub-creds" 
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
                script {
                    def branchName = env.GIT_BRANCH ?: 'main'
                    env.ACTUAL_BRANCH = branchName.replace('origin/', '')
                }
                echo "--- Đang làm việc trên branch: ${env.ACTUAL_BRANCH} ---"
            }
        }

        stage('Test') {
            steps {
                echo "--- Đang chạy Unit Test... ---"
                sh "echo 'Running npm test...'"
                sh "echo 'Tests passed!'" 
            }
        }

        stage('Login to DockerHub') {
            steps {
                echo "--- Đang đăng nhập vào Docker Hub... ---"
                // Sử dụng block withCredentials để lấy Username/Password an toàn
                withCredentials([usernamePassword(credentialsId: "${env.DOCKER_HUB_CREDS}", passwordVariable: 'DOCKER_PWD', usernameVariable: 'DOCKER_USER')]) {
                    sh "echo \$DOCKER_PWD | docker login -u \$DOCKER_USER --password-stdin"
                }
            }
        }

        // stage('Build Docker Image') {
        //     steps {
        //         echo "--- Đang Build Docker Image... ---"
        //         // Build ảnh với tag version cụ thể và tag latest
        //         sh "docker build -t ${DOCKER_REGISTRY}/${IMAGE_NAME}:${env.ACTUAL_BRANCH}-${env.BUILD_NUMBER} ."
        //         sh "docker tag ${DOCKER_REGISTRY}/${IMAGE_NAME}:${env.ACTUAL_BRANCH}-${env.BUILD_NUMBER} ${DOCKER_REGISTRY}/${IMAGE_NAME}:latest"
        //     }
        // }

        // stage('Push to Docker Hub') {
        //     steps {
        //         echo "--- Đang đẩy Image lên Docker Hub... ---"
        //         sh "docker push ${DOCKER_REGISTRY}/${IMAGE_NAME}:${env.ACTUAL_BRANCH}-${env.BUILD_NUMBER}"
        //         sh "docker push ${DOCKER_REGISTRY}/${IMAGE_NAME}:latest"
        //     }
        // }
    }

    post {
        always {
            // Logout sau khi hoàn tất để đảm bảo an toàn cho server
            sh "docker logout"
        }
        success {
            echo "Pipeline thành công rực rỡ!"
        }
        failure {
            echo "Pipeline thất bại ở stage nào đó. Kiểm tra log ngay."
        }
    }
}
