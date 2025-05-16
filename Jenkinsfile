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
        
        stage('Download & Setup Key') {
            steps {
                script {
                    sh """
                    aws s3 cp s3://gamestoretfstate/gamestore.pem ./gamestore.pem
                    chmod 400 gamestore.pem
                    mkdir -p ansible
                    cp gamestore.pem ansible/gamestore.pem
                    whoami
                    """
                }
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
                sh "terraform plan -var=\"ssh_private_key_path=./gamestore.pem\" -out=tfplan"
                sh "terraform apply -auto-approve tfplan"
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
                // Give EC2 instance more time to initialize
                sleep(time: 60, unit: 'SECONDS')
            }
        }
        
        stage('Ansible Configuration Deploy') {
            steps {
                dir("ansible") {
                    sh "ansible-playbook -i inventory.ini enviroment_setup.yml"
                }
            }
        }

        stage('Ansible Deploy App') {
            steps {
                dir("ansible") {
                    sh "ansible-playbook -i inventory.ini deploy_gamestore.yml"
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