pipeline {
    agent any
    
    environment {
        // Tự động lấy tên branch từ Webhook, nếu không có thì mặc định là main
        BRANCH = "${env.BRANCH_NAME ?: 'main'}"
        DOCKER_IMAGE = 'caramensuachua/ecommerce-frontend'
        VERSION = "v${env.BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
                echo "--- Testing Connectivity ---"
                echo "Successfully triggered by Webhook!"
                echo "Running on branch: ${env.BRANCH}"
                echo "Build Version: ${env.VERSION}"
            }
        }
        
    }
    
    post {
        success {
            echo "Pipeline finished successfully!"
        }
        failure {
            echo "Pipeline failed. Please check the logs."
        }
    }
}