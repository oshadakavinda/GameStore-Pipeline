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
        
        stage('Terraform Plan with Resource Check') {
    steps {
        script {
            // Run terraform plan and capture the output
            def planOutput = bat(script: 'terraform plan -no-color', returnStdout: true).trim()
            
            // Check if the security group already exists based on plan output
            if (planOutput.contains("game-store-security-group") && planOutput.contains("will be created")) {
                echo "Security group will be created according to the plan"
            } else if (planOutput.contains("game-store-security-group") && planOutput.contains("will be destroyed")) {
                echo "Warning: Security group will be destroyed according to the plan"
            } else if (planOutput.contains("game-store-security-group") && planOutput.contains("will be updated")) {
                echo "Security group will be updated according to the plan"
            } else {
                echo "No changes to security group detected in plan"
            }
        }
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