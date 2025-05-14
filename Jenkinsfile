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
                    // Create a helper script to check for existing security group
                    writeFile file: 'check_sg.tf', text: '''
                    data "aws_security_group" "existing" {
                      count = 1
                      name = "game-store-security-group"
                      
                      # This will fail gracefully if the SG doesn't exist
                      lifecycle {
                        ignore_changes = all
                      }
                    }
                    
                    output "existing_sg_id" {
                      value = try(data.aws_security_group.existing[0].id, "")
                    }
                    '''
                    
                    // Run terraform refresh to check existing resources
                    bat 'terraform refresh'
                    
                    // Try to get the output and store it
                    def sgCheckResult = bat(script: 'terraform output existing_sg_id', returnStatus: true)
                    
                    if (sgCheckResult == 0) {
                        echo "Security group already exists. Will try to import it."
                        def sgId = bat(script: 'terraform output -raw existing_sg_id', returnStdout: true).trim()
                        
                        // Check if we can import the security group
                        if (sgId) {
                            echo "Attempting to import security group: ${sgId}"
                            bat "terraform import aws_security_group.devops_sg ${sgId} || echo Import failed but continuing"
                        }
                    }
                    
                    // Clean up the helper file
                    bat 'del check_sg.tf'
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                // Use -replace flag to handle conflicts if import failed
                bat 'terraform plan -out=tfplan -replace="aws_security_group.devops_sg"'
            }
        }
        
        stage('Terraform Apply') {
            steps {
                script {
                    def applyResult = bat(script: 'terraform apply -auto-approve tfplan', returnStatus: true)
                    
                    if (applyResult != 0) {
                        echo "Initial apply failed. Attempting recovery..."
                        
                        // Update security group name to avoid conflict
                        writeFile file: 'sg_fix.tf', text: '''
                        // Temporarily modify the security group name to avoid conflicts
                        resource "aws_security_group" "devops_sg" {
                          name = "game-store-security-group-${formatdate("YYYYMMDD-hhmmss", timestamp())}"
                          // Rest of the configuration is pulled from main.tf
                        }
                        '''
                        
                        // Try planning and applying again with the modified configuration
                        bat 'terraform plan -out=tfplan_recovery'
                        bat 'terraform apply -auto-approve tfplan_recovery'
                        
                        // Clean up
                        bat 'del sg_fix.tf'
                    }
                }
            }
        }
        
        stage('Output') {
            steps {
                script {
                    def outputResult = bat(script: 'terraform output -json > terraform_outputs.json', returnStatus: true)
                    if (outputResult == 0) {
                        archiveArtifacts artifacts: 'terraform_outputs.json', fingerprint: true
                        echo "Terraform outputs successfully saved"
                    } else {
                        echo "Failed to save Terraform outputs, but continuing pipeline"
                    }
                }
            }
        }
    }
    
    post {
        always {
            cleanWs(cleanWhenNotBuilt: false,
                   deleteDirs: true,
                   disableDeferredWipeout: true,
                   notFailBuild: true)
        }
        success {
            echo 'Deployment completed successfully!'
        }
        failure {
            echo 'Deployment failed!'
        
        }
    }
}