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
        
        stage('Terraform Plan') {
            steps {
                withCredentials([file(credentialsId: 'aws-ssh-key-pem', variable: 'SSH_KEY')]) {
                    bat "terraform plan -var=\"ssh_private_key_path=${SSH_KEY}\" -out=tfplan"
                }
            }
        }
        
        stage('Terraform Apply') {
            steps {
                withCredentials([file(credentialsId: 'aws-ssh-key-pem', variable: 'SSH_KEY')]) {
                    bat "terraform apply -var=\"ssh_private_key_path=${SSH_KEY}\" -auto-approve tfplan"
                }
            }
        }
        
        stage('Get Instance IP') {
            steps {
                script {
                    // Extract IP address from Terraform output and save it for Ansible
                    def tfOutput = bat(script: 'terraform output -json instance_public_ip', returnStdout: true).trim()
                    def publicIp = readJSON(text: tfOutput).value
                    
                    // Create Ansible inventory file with SSH key reference from Jenkins credentials
                    writeFile file: 'inventory.ini', text: """[game_store_servers]
${publicIp} ansible_user=ec2-user ansible_ssh_common_args='-o StrictHostKeyChecking=no'
"""
                    
                    // Copy docker-compose.yml to workspace for Ansible
                    writeFile file: 'docker-compose.yml', text: readFile('docker-compose-template.yml')
                }
            }
        }
        
        stage('Wait for SSH') {
            steps {
                // Give EC2 instance time to initialize
                sleep(time: 60, unit: 'SECONDS')
            }
        }
        
        stage('Ansible Deploy') {
            steps {
                withCredentials([file(credentialsId: 'aws-ssh-key-pem', variable: 'SSH_KEY')]) {
                    // Run Ansible playbook with the SSH key from Jenkins credentials
                    bat "ansible-playbook -i inventory.ini --private-key=\"${SSH_KEY}\" deploy_game_store.yml"
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    def tfOutput = bat(script: 'terraform output -json application_urls', returnStdout: true).trim()
                    echo "Application deployed. URLs available in Terraform output."
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
            
        }
    }
}