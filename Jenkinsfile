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
                    // Use AWS CLI to check for existing security group instead of Terraform data source
                    // This avoids the limitations with Terraform data sources
                    bat '''
                        aws ec2 describe-security-groups --region %AWS_REGION% ^
                        --filters "Name=group-name,Values=game-store-security-group" ^
                        --query "SecurityGroups[*].GroupId" ^
                        --output text > existing_sg.txt || echo "Security group check failed but continuing"
                    '''
                    
                    // Read the result
                    def sgId = readFile('existing_sg.txt').trim()
                    
                    if (sgId) {
                        echo "Security group exists with ID: ${sgId}"
                        
                        // Modify the Terraform configuration to handle existing security group
                        writeFile file: 'security_group_override.tf', text: """
                        # Override the security group name to avoid conflicts
                        resource "aws_security_group" "devops_sg" {
                          name = "game-store-security-group-new-\${System.currentTimeMillis()}"
                        }
                        """
                        
                        echo "Created override configuration to use a new security group name"
                    } else {
                        echo "No existing security group found with that name"
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
                script {
                    def applyResult = bat(script: 'terraform apply -auto-approve tfplan', returnStatus: true)
                    
                    if (applyResult != 0) {
                        echo "Initial apply failed. Attempting recovery..."
                        
                        // Try a more aggressive approach - update the main configuration
                        writeFile file: 'sg_fix.tf', text: """
                        # Override the original security group with a timestamp-based name
                        resource "aws_security_group" "devops_sg" {
                          name = "game-store-sg-\${System.currentTimeMillis()}"
                        }
                        """
                        
                        // Try planning and applying again with the modified configuration
                        bat 'terraform plan -out=tfplan_recovery'
                        def recoveryResult = bat(script: 'terraform apply -auto-approve tfplan_recovery', returnStatus: true)
                        
                        if (recoveryResult != 0) {
                            error "Both initial and recovery deployment attempts failed"
                        }
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
            script {
                // Clean up any temporary files we created
                bat 'if exist security_group_override.tf del security_group_override.tf'
                bat 'if exist sg_fix.tf del sg_fix.tf'
                bat 'if exist existing_sg.txt del existing_sg.txt'
            }
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
            
            // Send notification if email plugin is configured
            script {
                try {
                    emailext (
                        subject: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                        body: """<p>FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]':</p>
                        <p>Check console output at &QUOT;<a href='${env.BUILD_URL}'>${env.JOB_NAME} [${env.BUILD_NUMBER}]</a>&QUOT;</p>""",
                        recipientProviders: [[$class: 'DevelopersRecipientProvider']]
                    )
                } catch (e) {
                    echo "Email notification failed but continuing: ${e.message}"
                }
            }
        }
    }
}