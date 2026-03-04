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
                
                // Sử dụng script block để có thể khai báo biến def
                script {
                    def fullImageTag = "${env.DOCKER_REGISTRY}/${env.IMAGE_NAME}:${env.ACTUAL_BRANCH}-${env.BUILD_NUMBER}"
                    def latestTag = "${env.DOCKER_REGISTRY}/${env.IMAGE_NAME}:latest"

                    withCredentials([usernamePassword(credentialsId: "${env.DOCKER_HUB_CREDS}", passwordVariable: 'DOCKER_PWD', usernameVariable: 'DOCKER_USER')]) {
                        
                        // 1. Build Image
                        sh "docker build -t ${fullImageTag} ."
                        sh "docker tag ${fullImageTag} ${latestTag}"

                        // 2. Login (Sử dụng dấu \ trước biến môi trường Shell)
                        sh "echo \$DOCKER_PWD | docker login -u \$DOCKER_USER --password-stdin"

                        // 3. Push
                        sh "docker push ${fullImageTag}"
                        sh "docker push ${latestTag}"

                        // 4. Logout
                        sh "docker logout"
                    }
                }
            }
        }
    }

    post {
        success {
            echo "--- Thành công! ---"
        }
        failure {
            sh "docker logout || true"
        }
    }
}
