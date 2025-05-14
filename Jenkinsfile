pipeline {
    agent any
    
    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        AWS_REGION            = 'eu-north-1'
        TF_VAR_key_name       = 'gamestore'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }
        
        stage('Terraform Validate') {
            steps {
                bat 'terraform validate'
            }
        }
        
        stage('Terraform Plan') {
            steps {
                bat 'terraform plan -out=tfplan'
            }
        }
        
        stage('Approval') {
            steps {
                input message: 'Review the plan and approve to apply', ok: 'Apply'
            }
        }
        
        stage('Terraform Apply') {
            steps {
                bat 'terraform apply -auto-approve tfplan'
            }
        }
        
        stage('Output') {
            steps {
                bat 'terraform output -json > terraform_outputs.json'
                archiveArtifacts artifacts: 'terraform_outputs.json', fingerprint: true
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            echo 'Deployment completed successfully!'
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}