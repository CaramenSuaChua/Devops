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
                    env.IMAGE_TAG = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    echo "${env.IMAGE_TAG}"
                }
            }
        }

        // stage('Unit Test') {
        //     steps {
        //         echo "--- Đang chạy Unit Test bên trong Docker Container ---"
        //         // Sử dụng Docker để test giúp Jenkins server luôn sạch sẽ
        //         sh "docker build --target test -t ecommerce-test ."
        //     }
        // }

        stage('Build & Push Docker Image') {
            steps {
                script {
                    def repo = "${env.DOCKER_REGISTRY}/${env.IMAGE_NAME}"
                    def vTag = "${repo}:${env.IMAGE_TAG}"
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
                            -t ${vTag} .
                        """

                        echo "--- Pushing Tags ---"
                        sh "docker push ${vTag}"

                        sh "docker logout"
                    }
                }
            }
        }

        stage('Update GitOps Manifest') {
            steps {
                script {
                    // Xóa thư mục cũ để đảm bảo không bị cache config Git
                    sh "rm -rf ecommerce-gitops"
                    
                    withCredentials([usernamePassword(credentialsId: 'github-token', passwordVariable: 'GIT_PWD', usernameVariable: 'GIT_USER')]) {
                        // 1. Clone repo bằng URL chứa Token trực tiếp
                        sh "git clone https://${GIT_USER}:${GIT_PWD}@github.com/CaramenSuaChua/ecommerce-gitops.git"
                        
                        dir('ecommerce-gitops') {
                            // 2. Cấu hình User để commit
                            sh "git config user.email 'ngodungvb0304@gmail.com'"
                            sh "git config user.name 'CaramenSuaChua'"
                            
                            // 3. Sửa file (Lưu ý: Đảm bảo đúng tên file deployment-fe.yaml)
                            // Sửa tag của frontend trong file values.yaml
                            sh "sed -i '/frontend:/,/backend:/ s|tag: .*|tag: ${env.IMAGE_TAG}|' values.yaml"
                            
                            // 4. Kiểm tra xem có thay đổi không trước khi commit
                            sh "git add ."
                            
                            // Lệnh commit này sẽ không làm fail pipeline nếu không có gì thay đổi
                            sh "git commit -m 'Update image to ${env.IMAGE_TAG} [skip ci]' || echo 'No changes to commit'"
                            
                            // 5. ĐẶC BIỆT: Push bằng cách truyền Token vào URL để ghi đè mọi cache 403
                            sh "git push https://${GIT_USER}:${GIT_PWD}@github.com/CaramenSuaChua/ecommerce-gitops.git HEAD:main"
                        }
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





