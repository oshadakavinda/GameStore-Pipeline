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
        
        stage('Terraform Plan and Apply') {
            steps {
                withCredentials([file(credentialsId: 'aws-ssh-key-pem', variable: 'SSH_KEY')]) {
                    // Use the same credentials context for both plan and apply
                    bat "terraform plan -var=\"ssh_private_key_path=${SSH_KEY}\" -out=tfplan"
                    bat "terraform apply -auto-approve tfplan"
                }
            }
        }
        
        stage('Get Instance IP') {
            steps {
                script {
                    // Extract IP address from Terraform output
                    def tfOutput = bat(script: 'terraform output -raw instance_public_ip', returnStdout: true).trim()
                    def publicIp = tfOutput.replaceAll("\\r", "").replaceAll("\\n", "").trim()
                    
                    // Debug output to see what we're getting
                    echo "Public IP extracted: ${publicIp}"
                    
                    // Create Ansible inventory file with SSH key reference from Jenkins credentials
                    writeFile file: 'inventory.ini', text: """[game_store_servers]
${publicIp} ansible_user=ec2-user ansible_ssh_common_args='-o StrictHostKeyChecking=no'
"""
                    
                    // Copy docker-compose.yml to workspace for Ansible if needed
                    if (fileExists('docker-compose.yml')) {
                        writeFile file: 'docker-compose.yml', text: readFile('docker-compose.yml')
                    } else {
                        echo "Warning: docker-compose-template.yml file not found."
                    }
                }
            }
        }
        
        stage('Wait for SSH') {
            steps {
                echo "Waiting for EC2 instance to become available for SSH..."
                // Give EC2 instance time to initialize
                sleep(time: 60, unit: 'SECONDS')
            }
        }
        
        stage('Ansible Deploy') {
            steps {
                withCredentials([file(credentialsId: 'aws-ssh-key-pem', variable: 'SSH_KEY')]) {
                    // Run Ansible playbook with the SSH key from Jenkins credentials
                    bat "wsl ansible-playbook -i inventory.ini --private-key=\"${SSH_KEY}\" deploy_game_store.yml"
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    try {
                        def tfOutput = bat(script: 'terraform output -raw application_urls', returnStdout: true).trim()
                        echo "Application deployed successfully!"
                        echo "Application URLs: ${tfOutput}"
                    } catch (Exception e) {
                        echo "Error retrieving application URLs: ${e.message}"
                        echo "Using direct output from previous Terraform apply step"
                    }
                }
            }
        }
    }
    
    post {
        always {
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