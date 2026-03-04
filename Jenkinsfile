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

        // stage('Unit Test') {
        //     steps {
        //         echo "--- Đang chạy Unit Test bên trong Docker Container ---"
        //         // Sử dụng Docker để test giúp Jenkins server luôn sạch sẽ
        //         sh "docker build --target test -t ecommerce-test ."
        //     }
        // }

        // stage('Build & Push Docker Image') {
        //     steps {
        //         script {
        //             def repo = "${env.DOCKER_REGISTRY}/${env.IMAGE_NAME}"
        //             def vTag = "${repo}:${env.VERSION}"
        //             def latestTag = "${repo}:latest"

        //             withCredentials([usernamePassword(credentialsId: "${env.DOCKER_HUB_CREDS}", passwordVariable: 'DOCKER_PWD', usernameVariable: 'DOCKER_USER')]) {
                        
        //                 // Login một lần duy nhất
        //                 sh "echo \$DOCKER_PWD | docker login -u \$DOCKER_USER --password-stdin"
                        
        //                 // Kéo bản latest về làm mốc so sánh cache (Docker sẽ so sánh các layer cũ)
        //                 echo "--- Pulling latest image for caching ---"
        //                 sh "docker pull ${latestTag} || true"

        //                 echo "--- Building Image version: ${env.VERSION} ---"
        //                 // TỐI ƯU: Sử dụng --cache-from để không phải chạy lại npm install nếu không có thư viện mới
        //                 sh """
        //                     docker build \
        //                     --cache-from ${latestTag} \
        //                     -t ${vTag} \
        //                     -t ${latestTag} .
        //                 """

        //                 echo "--- Pushing Tags ---"
        //                 sh "docker push ${vTag}"

        //                 sh "docker logout"
        //             }
        //         }
        //     }
        // }

        stage('Update GitOps Manifest') {
            steps {
                script {
                    // Clone repo manifest về một thư mục tạm
                    sh "rm -rf ecommerce-gitops"
                    withCredentials([usernamePassword(credentialsId: 'github-token', passwordVariable: 'GIT_PWD', usernameVariable: 'GIT_USER')]) {
                        sh "git clone https://${GIT_USER}:${GIT_PWD}@github.com/CaramenSuaChua/ecommerce-gitops.git"
                        
                        dir('ecommerce-gitops') {
                            // Sử dụng lệnh sed để thay thế tag image cũ bằng tag version mới (v${BUILD_NUMBER})
                            // Sửa lại dòng này cho đúng tên file trong repo GitOps của bạn
                            sh "sed -i 's|image: caramensuachua/ecommerce-frontend:.*|image: caramensuachua/ecommerce-frontend:${env.VERSION}|g' deployment-fe.yaml"
                            
                            // Commit và push thay đổi lên repo GitOps
                            sh "git config user.email 'ngodungvb0304@gmail.com'"
                            sh "git config user.name 'CaramenSuaChua'"
                            sh "git add ."
                            sh "git commit -m 'Update image to ${env.VERSION} [skip ci]'"
                            sh "git push origin main"
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
