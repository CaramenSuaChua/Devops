pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = "caramensuachua"
        IMAGE_NAME = "ecommerce-frontend"
        DOCKER_HUB_CREDS = "docker-hub-creds"
        // IMAGE_TAG được lấy từ commit hash ngắn
        IMAGE_TAG = "" 
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
                script {
                    env.IMAGE_TAG = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    echo "Frontend Image Tag: ${env.IMAGE_TAG}"
                    echo "Action: ${env.action} | Merged: ${env.merged}"
                }
            }
        }

        stage('Unit Test') {
            // Chạy Test khi có Pull Request (opened/synchronize)
            when {
                expression { env.action == 'opened' || env.action == 'synchronize' }
            }
            steps {
                echo "--- Chạy Unit Test bên trong Docker ---"
                // Build stage 'test' từ Dockerfile. 
                // Nếu lệnh RUN npm run test bên trong Dockerfile fail, bước này sẽ báo lỗi và dừng pipeline.
                sh "docker build --target test -t ecommerce-frontend-test:${env.IMAGE_TAG} ."
            }
        }

        stage('Code Quality (SonarQube)') {
            // Chỉ chạy nếu Unit Test ở trên pass
            when {
                expression { env.action == 'opened' || env.action == 'synchronize' }
            }
            steps {
                script {
                    def scannerHome = tool 'sonar-scanner'
                    withSonarQubeEnv('SonarQube') {
                        sh "${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=Ecommerce-Frontend \
                            -Dsonar.sources=. \
                            -Dsonar.host.url=http://18.139.185.108:9000 \
                            -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info" 
                    }
                    
                    timeout(time: 10, unit: 'MINUTES') {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            error "Pipeline fail do Quality Gate báo lỗi: ${qg.status}"
                        }
                    }
                }
            }
        }

        stage('Build & Push Docker Image') {
            // Chỉ chạy khi Merge (action closed và merged true)
            when {
                expression { env.action == 'closed'}
            }
            steps {
                script {
                    def repo = "${env.DOCKER_REGISTRY}/${env.IMAGE_NAME}"
                    def vTag = "${repo}:${env.IMAGE_TAG}"

                    withCredentials([usernamePassword(credentialsId: "${env.DOCKER_HUB_CREDS}", passwordVariable: 'DOCKER_PWD', usernameVariable: 'DOCKER_USER')]) {
                        sh "echo \$DOCKER_PWD | docker login -u \$DOCKER_USER --password-stdin"
                        
                        echo "--- Building Production Image ---"
                        // Build image cuối cùng (Stage Production trong Dockerfile)
                        sh "docker build -t ${vTag} ."

                        echo "--- Pushing Image ---"
                        sh "docker push ${vTag}"

                        sh "docker logout"
                    }
                }
            }
        }

        stage('Update GitOps Manifest') {
            when {
                expression { env.action == 'closed' }
            }
            steps {
                script {
                    sh "rm -rf ecommerce-gitops"
                    withCredentials([usernamePassword(credentialsId: 'github-token', passwordVariable: 'GIT_PWD', usernameVariable: 'GIT_USER')]) {
                        sh "git clone https://${GIT_USER}:${GIT_PWD}@github.com/CaramenSuaChua/ecommerce-gitops.git"
                        dir('ecommerce-gitops') {
                            sh "git config user.email 'ngodungvb0304@gmail.com'"
                            sh "git config user.name 'CaramenSuaChua'"
                            
                            // Sửa tag trong file values.yaml của frontend
                            // Dùng sed chính xác để tránh sửa nhầm tag của backend
                            sh "sed -i '/frontend:/,/tag:/ s|tag: .*|tag: ${env.IMAGE_TAG}|' values.yaml"
                            
                            sh "git add values.yaml"
                            sh "git commit -m 'Update Frontend image to ${env.IMAGE_TAG} [skip ci]' || echo 'No changes'"
                            sh "git push https://${GIT_USER}:${GIT_PWD}@github.com/CaramenSuaChua/ecommerce-gitops.git HEAD:main"
                        }
                    }
                }
            }
        }
    }

    post {
        failure {
            echo "Frontend Pipeline FAILED!"
            sh "docker logout || true"
        }
    }
}
