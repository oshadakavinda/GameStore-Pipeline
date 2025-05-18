# Game Store Application

A full-stack game store application with automated CI/CD pipelines for containerization and cloud deployment.

## Project Overview

This project consists of a Game Store application with:
- Frontend web application
- Backend API service
- CI/CD pipelines for Docker containerization
- Infrastructure as Code for AWS deployment
- Automated configuration management

## Architecture

The application is composed of:

1. **Frontend**: Blazor web application served in a Docker container
2. **Backend API**: RESTful API service (likely .NET Core) served in a Docker container
3. **CI/CD Pipeline**: Jenkins automation for building, testing, and deployment
4. **Infrastructure**: AWS resources managed through Terraform
5. **Configuration Management**: Ansible for server setup and application deployment

## Development Pipeline

The development pipeline consists of two main workflows:

### Docker Containerization Pipeline(CI pipeline)

This pipeline builds and pushes Docker images to Docker Hub:

1. Cleans the workspace
2. Clones the repository with sparse checkout for required directories
3. Logs in to Docker Hub
4. Builds the frontend Docker image
5. Builds the API Docker image
6. Pushes both images to Docker Hub

### AWS Deployment Pipeline(CD pipeline)

This pipeline provisions infrastructure and deploys the application to AWS:

1. Authenticates with AWS
2. Downloads SSH key for server access
3. Initializes and validates Terraform configuration
4. Plans and applies infrastructure changes through Terraform
5. Updates Ansible inventory with new infrastructure information
6. Configures server environment using Ansible
7. Deploys the Game Store application using Ansible
8. Verifies the deployment
9. Injects game data into the application

## Prerequisites
- wsl
- Docker and Docker Compose
- Jenkins with appropriate plugins
- AWS CLI configured
- Terraform
- Ansible
- Git

## Required Credentials

The following credentials need to be configured in Jenkins:

- `docker-hub`: Docker Hub username and password
- `aws-access-key-id`: AWS access key
- `aws-secret-access-key`: AWS secret key

## Infrastructure Resources

The application is deployed on AWS with the following resources (managed by Terraform):
- EC2 instances for hosting the application
- Security groups for network access control
- S3 bucket for Terraform state storage
- Other supporting AWS resources

## Deployment Process

1. **Docker Image Building**:
   - Images are built from `GameStore.Frontend/` and `GameStore.Api/` directories
   - Images are tagged and pushed to Docker Hub under `oshadakavinda2` account

2. **Infrastructure Provisioning**:
   - Terraform creates/updates AWS resources
   - SSH key is retrieved from S3 bucket for secure access

3. **Application Deployment**:
   - Ansible configures the server environment
   - Docker containers are pulled and started on the target servers
   - Game data is injected into the application database



## Local Development

For local development, use the Docker Compose file:

```bash
clone https://github.com/oshadakavinda/Game-Store
docker-compose up -d
```

## Access Points

After deployment, the application can be accessed via the URLs provided by Terraform output.

## Maintenance

- Jenkins pipeline is configured to keep the last 5 builds
- Workspace is cleaned after each pipeline run
- Failed builds are clearly marked

## Troubleshooting

If deployment fails:
1. Check Jenkins logs for specific error messages
2. Verify AWS credentials are valid
3. Ensure Docker Hub credentials are correct
4. Check network connectivity to AWS and Docker Hub

## Contributing

1. Fork the repository
2. Create your feature branch
3. Submit a pull request targeting the master branch
