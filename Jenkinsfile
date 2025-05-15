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
                sh 'terraform init'
            }
        }
        
        stage('Terraform Validate') {
            steps {
                sh 'terraform validate'
            }
        }
        
        stage('Terraform Plan and Apply') {
            steps {
                withCredentials([file(credentialsId: 'aws-ssh-key-pem', variable: 'SSH_KEY')]) {
                    // Use the same credentials context for both plan and apply
                    sh "terraform plan -var=\"ssh_private_key_path=${SSH_KEY}\" -out=tfplan"
                    sh "terraform apply -auto-approve tfplan"
                }
            }
        }
        
        stage('Update Inventory') {
            steps {
                sh 'bash update_inventory.sh'
            }
        }
        
        stage('Wait for SSH') {
            steps {
                echo "Waiting for EC2 instance to become available for SSH..."
                // Give EC2 instance more time to initialize - increased from 60 to 120 seconds
                sleep(time: 120, unit: 'SECONDS')
            }
        }
        
        stage('Ansible Deploy') {
            steps {
                withCredentials([file(credentialsId: 'aws-ssh-key-pem', variable: 'SSH_KEY')]) {
                    // Create a temporary copy of the SSH key in the workspace
                    sh '''
                        mkdir -p ansible
                        cp "${SSH_KEY}" ansible/gamestore.pem
                        chmod 600 ansible/gamestore.pem
                        
                        # Update inventory.ini to use correct SSH key path
                        sed -i 's|ansible_ssh_private_key_file=.*|ansible_ssh_private_key_file=ansible/gamestore.pem|' ansible/inventory.ini
                        
                        # Debug - List files and permissions in ansible directory
                        ls -l ansible
                        
                        # Create ansible.cfg file to disable host key checking
                        cat > ansible/ansible.cfg << EOF
[defaults]
host_key_checking = False
EOF
                    '''
                    
                    // Ensure Ansible is installed on the Jenkins server or agent
                    dir("ansible") {
                        sh '''
                            # Debug - Check inventory file content
                            cat inventory.ini
                            
                            # Debug - List files in current directory
                            ls -l
                            
                            # Run ansible with explicit private key path
                            ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.ini deploy_gamestore.yml --private-key=gamestore.pem -v
                        '''
                    }
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    try {
                        def tfOutput = sh(script: 'terraform output -raw application_urls', returnStdout: true).trim()
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
        }
    }
}