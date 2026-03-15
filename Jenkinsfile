pipeline {
    agent any

    environment {
        // AWS INFORMATION
        AWS_ACCOUNT_ID    = "573051981771"
        AWS_CREDS_ID      = "aws-creds"    // ID credentials AWS trong Jenkins, chứa Access Key và Secret Key
        AWS_REGION        = "ap-southeast-1"
        AWS_ECR_REPO_NAME = "de150/ecommerce-frontend"
        ECR_REGISTRY      = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        
        // DOCKER & METADATA
        IMAGE_NAME        = "ecommerce-frontend"
        
        // GITOPS
        GITOPS_CREDS      = "github-token"
        GITOPS_REPO       = "github.com/CaramenSuaChua/ecommerce-gitops.git"
        
        // SONARQUBE
        SONAR_SERVER_NAME = "SonarQube"
    }

    stages {
        stage('Checkout & Metadata') {
            steps {
                checkout scm
                script {
                    // Lấy mã hash ngắn của commit
                    env.IMAGE_TAG = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    echo "Frontend Image Tag: ${env.IMAGE_TAG}"
                }
            }
        }

        // stage('Unit Test') {
        //     when {
        //         expression { env.action == 'opened' || env.action == 'synchronize' }
        //     }
        //     steps {
        //         echo "--- Running Unit Test inside Docker ---"
        //         // Lưu ý: Dockerfile của bạn phải có stage 'test'
        //         sh "docker build --target test -t ${env.IMAGE_NAME}-test:${env.IMAGE_TAG} ."
        //     }
        // }

        stage('Code Quality (SonarQube)') {
            when {
                expression { env.action == 'opened' || env.action == 'synchronize' }
            }
            steps {
                script {
                    def scannerHome = tool 'sonar-scanner'
                    withSonarQubeEnv("${env.SONAR_SERVER_NAME}") {
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

        stage ("Build & Push to ECR") {
            // Chạy khi có PR hoặc Merge tùy theo workflow của bạn. 
            // Ở đây tôi giữ theo logic back-end của bạn (PR opened/sync)
            when {
                expression { env.action == 'opened' || env.action == 'synchronize' }
            }
            steps {
                script {
                    def ecrRepo = "${env.ECR_REGISTRY}/${env.AWS_ECR_REPO_NAME}"
                    def ecrTag = "${ecrRepo}:${env.IMAGE_TAG}"
                    def buildTimestamp = new Date().format("yyyyMMddHHmmss")

                    withCredentials([aws(credentialsId: "${env.AWS_CREDS_ID}", secretKeyVariable: 'AWS_SECRET_KEY', accessKeyVariable: 'AWS_ACCESS_KEY')]) {
                        sh '''
                            aws configure set aws_access_key_id $AWS_ACCESS_KEY --profile jenkins
                            aws configure set aws_secret_access_key $AWS_SECRET_KEY --profile jenkins
                            aws configure set default.region ''' + AWS_REGION + ''' --profile jenkins
        
                            # Đăng nhập ECR
                            aws ecr get-login-password --region ''' + AWS_REGION + ''' --profile jenkins | docker login --username AWS --password-stdin ''' + env.ECR_REGISTRY + '''
        
                            echo "--- Building Frontend Production Image ---"
                            # Sử dụng build-arg BUILD_DATE để tách dòng trên ECR (như Back-end)
                            docker build --build-arg BUILD_DATE=''' + buildTimestamp + ''' -t ''' + ecrTag + ''' .
        
                            echo "--- Pushing Frontend Image to ECR ---"
                            docker push ''' + ecrTag + '''
                            
                            docker logout ''' + env.ECR_REGISTRY + '''
                        '''
                    }
                }
            }
        }

        stage('Update GitOps Manifest') {
            when {
                // Thường stage này nên chạy khi PR đã closed và merged: true
                expression { env.action == 'opened' || env.action == 'synchronize' }
            }
            steps {
                script {
                    sh "rm -rf ecommerce-gitops"
                    withCredentials([usernamePassword(credentialsId: "${env.GITOPS_CREDS}", passwordVariable: 'GIT_PWD', usernameVariable: 'GIT_USER')]) {
                        sh "git clone https://${GIT_USER}:${GIT_PWD}@${env.GITOPS_REPO}"
                        
                        dir('ecommerce-gitops') {
                            sh """
                                git config user.email 'ngodungvb0304@gmail.com'
                                git config user.name 'CaramenSuaChua'
                            """

                            def valuesPath = "ecommerce-chart/values.yaml"
                            
                            sh """
                                # Cập nhật cả repository (trỏ sang ECR) và tag mới
                                sed -i '/frontend:/,/repository:/ s|repository: .*|repository: ${env.ECR_REGISTRY}/${env.AWS_ECR_REPO_NAME}|' ${valuesPath}
                                sed -i '/frontend:/,/tag:/ s|tag: .*|tag: ${env.IMAGE_TAG}|' ${valuesPath}
                            """

                            sh """
                                git add ${valuesPath}
                                git commit -m 'Update Frontend to ECR Image ${env.IMAGE_TAG} [skip ci]' || echo 'No changes'
                                git push https://${GIT_USER}:${GIT_PWD}@${env.GITOPS_REPO} HEAD:main
                            """
                        }
                    }
                }
            }
        }
    }

    post {
        failure {
            echo "Frontend Pipeline FAILED!"
            sh "docker logout ${env.ECR_REGISTRY} || true"
        }
    }
}
