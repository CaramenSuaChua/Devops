pipeline {
    agent any

    environment {
        // AWS INFORMATION
        AWS_ACCOUNT_ID    = "573051981771"
        AWS_CREDS_ID      = "aws-creds"
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
                    env.IMAGE_TAG = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                }
            }
        }

        stage('PR Verification') {
            // when { 
            //     expression { env.action == 'opened' || env.action == 'synchronize' } 
            // }
            parallel {
                stage('PR Validation (Scan & Dry-run)') {
                    steps {
                        script {
                            echo "--- Running Trivy and Docker Build Check ---"
                            sh "trivy config --severity HIGH,CRITICAL --exit-code 1 Dockerfile"
                            sh "docker build --target build -t ${env.IMAGE_NAME}-build-check:${env.IMAGE_TAG} . "
                        }
                    }
                    post {
                        always {
                            sh "docker rmi ${env.IMAGE_NAME}-build-check:${env.IMAGE_TAG} || true"
                        }
                    }
                }

                stage('Code Quality (SonarQube)') {
                    steps {
                        script {
                            echo "--- Running SonarScan ---"
                            def scannerHome = tool 'sonar-scanner'
                            withSonarQubeEnv("${env.SONAR_SERVER_NAME}") {
                                sh "${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=Ecommerce-Frontend"
                            }
                        }
                    }
                }
            }
        }

        stage ("Build & Push to ECR") {
            // when {
            //     expression { env.action == 'closed'}
            // }
            steps {
                script {
                    def ecrTag = "${env.ECR_REGISTRY}/${env.AWS_ECR_REPO_NAME}:${env.IMAGE_TAG}"
                    def buildTimestamp = new Date().format("yyyyMMddHHmmss")

                    withCredentials([aws(credentialsId: "${env.AWS_CREDS_ID}", secretKeyVariable: 'AWS_SECRET_KEY', accessKeyVariable: 'AWS_ACCESS_KEY')]) {
                        sh '''
                            aws configure set aws_access_key_id $AWS_ACCESS_KEY --profile jenkins
                            aws configure set aws_secret_access_key $AWS_SECRET_KEY --profile jenkins
                            aws configure set default.region ''' + env.AWS_REGION + ''' --profile jenkins
        
                            aws ecr get-login-password --region ''' + env.AWS_REGION + ''' --profile jenkins | docker login --username AWS --password-stdin ''' + env.ECR_REGISTRY + '''
        
                            echo "--- Building Production Image ---"
                            docker build --target production --build-arg BUILD_DATE=''' + buildTimestamp + ''' -t ''' + ecrTag + ''' .
        
                            docker push ''' + ecrTag + '''
                            docker logout ''' + env.ECR_REGISTRY + '''
                        '''
                    }
                }
            }
        }

        stage('Setup ECR Secret for K8s') {
            // when {
            //     expression { env.action == 'closed'}
            // }
            steps {
                script {
                    withCredentials([aws(credentialsId: "${env.AWS_CREDS_ID}", secretKeyVariable: 'AWS_SECRET_KEY', accessKeyVariable: 'AWS_ACCESS_KEY')]) {
                        sh '''
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_KEY
                            export AWS_DEFAULT_REGION=''' + env.AWS_REGION + '''
        
                            # Khong dung dau gach cheo o day vi dang dung nhay don
                            TOKEN=$(aws ecr get-login-password --region ''' + env.AWS_REGION + ''')
                            export KUBECONFIG=/var/lib/jenkins/.kube/config
        
                            kubectl delete secret ecr-registry-helper -n ecommerce --ignore-not-found=true
                            
                            kubectl create secret docker-registry ecr-registry-helper \
                                --docker-server=''' + env.ECR_REGISTRY + ''' \
                                --docker-username=AWS \
                                --docker-password=$TOKEN \
                                --namespace ecommerce \
                                --validate=false
                        '''
                    }
                }
            }
        }

        stage('Update GitOps Manifest') {
            // when {
            //     expression { env.action == 'closed'}
            // }
            steps {
                script {
                    sh "rm -rf ecommerce-gitops"
                    withCredentials([usernamePassword(credentialsId: "${env.GITOPS_CREDS}", passwordVariable: 'GIT_PWD', usernameVariable: 'GIT_USER')]) {
                        sh "git clone https://${GIT_USER}:${GIT_PWD}@${env.GITOPS_REPO}"
                        dir('ecommerce-gitops') {
                            sh '''
                                git config user.email 'ngodungvb0304@gmail.com'
                                git config user.name 'CaramenSuaChua'
                                
                                sed -i '/frontend:/,/tag:/ s|tag: .*|tag: ''' + env.IMAGE_TAG + '''|' ecommerce-chart/values.yaml
                                
                                git add .
                                git commit -m 'Update Frontend tag' || echo 'No changes'
                                git push https://''' + GIT_USER + ''':''' + GIT_PWD + '''@''' + env.GITOPS_REPO + ''' HEAD:main
                            '''
                        }
                    }
                }
            }
        }
    }
}
