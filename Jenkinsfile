pipeline {
    agent any
    
    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        TF_IN_AUTOMATION      = 'true'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Terraform Init') {
            steps {
                bat 'terraform init'
            }
        }
        
        stage('Terraform Validate') {
            steps {
                bat 'terraform validate'
            }
        }
        
        stage('Check Existing Resources') {
            steps {
                script {
                    try {
                        def sgExists = bat(script: 'terraform state list | findstr security_group || echo "No existing security group"', returnStdout: true).trim()
                        if (sgExists.contains("aws_security_group")) {
                            echo "Security group exists in state"
                            bat 'terraform state show $(terraform state list | findstr security_group | head -1) > existing_sg.txt'
                        } else {
                            echo "No existing security group found in state"
                        }
                    } catch (Exception e) {
                        echo "Warning: Could not check state. This might be the first deployment. Continuing anyway."
                    }
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                bat 'terraform plan -out=tfplan'
            }
        }
        
        stage('Terraform Apply') {
            steps {
                bat 'terraform apply -auto-approve tfplan'
            }
        }
        
        stage('Output') {
            steps {
                bat 'terraform output'
            }
        }
    }
    
    post {
        always {
            script {
                bat 'if exist security_group_override.tf del security_group_override.tf'
                bat 'if exist sg_fix.tf del sg_fix.tf'
                bat 'if exist existing_sg.txt del existing_sg.txt'
            }
            cleanWs()
        }
        success {
            echo 'Deployment successful!'
        }
        failure {
            echo 'Deployment failed!'
            script {
                emailext (
                    subject: "Failed Pipeline: ${currentBuild.fullDisplayName}",
                    body: "Something is wrong with ${env.BUILD_URL}",
                    to: 'oshadakavinda2@gmail.com'
                )
            }
        }
    }
}