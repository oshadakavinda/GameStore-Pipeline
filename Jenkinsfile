pipeline {
    agent any
    
    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        AWS_REGION            = 'eu-north-1'
        TF_VAR_key_name       = 'gamestore'
    }
    
    // Helper function for using unique name approach
    def useUniqueNameApproach() {
        // Create a timestamp using Groovy
        def timestamp = new Date().getTime()
        
        // Try a more aggressive approach - update the main configuration
        writeFile file: 'sg_fix.tf', text: """
        # Override the original security group with a timestamp-based name
        resource "aws_security_group" "recovery_sg" {
          name = "game-store-sg-${timestamp}"
          description = "Recovery security group for game store"
          vpc_id = aws_vpc.devops_vpc.id
          
          # Copy the ingress/egress rules from your main.tf here
          ingress {
            from_port   = 22
            to_port     = 22
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
          }
          
          ingress {
            from_port   = 80
            to_port     = 80
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
          }
          
          egress {
            from_port   = 0
            to_port     = 0
            protocol    = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          
          tags = {
            Name = "game-store-recovery-sg"
          }
        }
        """
        
        // Try planning and applying again with the modified configuration
        bat 'terraform plan -out=tfplan_recovery'
        def recoveryResult = bat(script: 'terraform apply -auto-approve tfplan_recovery', returnStatus: true)
        
        if (recoveryResult != 0) {
            error "Both initial and recovery deployment attempts failed"
        }
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
                    // Check if security group already exists using AWS CLI
                    def sgCheckResult = bat(script: '''
                        aws ec2 describe-security-groups --filters "Name=group-name,Values=game-store-security-group" --query "SecurityGroups[*].GroupId" --output text
                    ''', returnStdout: true).trim()
                    
                    if (sgCheckResult) {
                        echo "Security group already exists with ID: ${sgCheckResult}"
                        // Create a local override that will import the existing security group
                        writeFile file: 'sg_import.tf', text: """
                        # Import existing security group
                        resource "aws_security_group" "devops_sg" {
                          name   = "game-store-security-group"
                          vpc_id = aws_vpc.devops_vpc.id
                          
                          # Security group rules should match existing ones
                          # or use lifecycle { ignore_changes = [ingress, egress] }
                          lifecycle {
                            ignore_changes = [ingress, egress]
                          }
                        }
                        """
                    } else {
                        echo "Security group does not exist yet, will be created by Terraform"
                    }
                }
            }
        }
        
        stage('Terraform Plan with Resource Check') {
            steps {
                script {
                    // Run terraform plan and capture the output
                    def planOutput = bat(script: 'terraform plan -no-color -out=tfplan', returnStdout: true).trim()
                    
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
                        
                        // Check if error is due to security group already existing
                        bat 'terraform plan -no-color > tf_error_plan.txt'
                        def errorPlanOutput = readFile('tf_error_plan.txt')
                        
                        if (errorPlanOutput.contains("already exists") && errorPlanOutput.contains("game-store-security-group")) {
                            echo "Security group already exists. Using import approach..."
                            
                            // Get the existing security group ID
                            def sgId = bat(script: '''
                                aws ec2 describe-security-groups --filters "Name=group-name,Values=game-store-security-group" --query "SecurityGroups[*].GroupId" --output text
                            ''', returnStdout: true).trim()
                            
                            if (sgId) {
                                // Import the existing security group
                                echo "Importing existing security group: ${sgId}"
                                bat "terraform import aws_security_group.devops_sg ${sgId}"
                                
                                // Continue with plan and apply
                                bat 'terraform plan -out=tfplan_import'
                                bat 'terraform apply -auto-approve tfplan_import'
                            } else {
                                // If can't import, try unique name approach
                                useUniqueNameApproach()
                            }
                        } else {
                            // For other errors, try the unique name approach
                            useUniqueNameApproach()
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
                bat 'if exist sg_import.tf del sg_import.tf'
                bat 'if exist existing_sg.txt del existing_sg.txt'
                bat 'if exist tf_error_plan.txt del tf_error_plan.txt'
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