# Node.js Service Deployment (WIP)
Deploy a Node.js Service to a remote server using GitHub Actions

## Project structure
```
├── .github
│   └── workflows
│       └── deploy_service.yml   # Github Actions CI/CD workflow   
├── ansible                      # Ansible playbooks and inventory
├── node_app                     # Node.js application code
└── terraform                    # Terraform configuration files    
```
## Deployment
### Prerequisites

- [GitHub account](https://github.com/)
- [AWS account](https://console.aws.amazon.com)
- SSH key pair generated.

### Setup
#### 1. Clone the project's GitHub repository.

Clone the repository:
   ```
   git clone https://github.com/MGhaith/nodejs-service-deployment.git
   cd nodejs-service-deployment
   ```

#### 2. Create a Github Repository 
You need this repository to store the project code, trigger the deployment workflow, and store secrets.

1. Create a new repository on [GitHub](https://github.com) for the project.
2. Generate an SSH key pair, if you don't one already.
   ```
   ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
   ```
3. Create a new secret in the repository settings (Settings > Secrets and variables > Actions > New repository secret).
   - Name: `SSH_PRIVATE_KEY`
   - Value: Your private SSH key (contents of `~/.ssh/id_rsa`)
   - Name: `SSH_PUBLIC_KEY`
   - Value: Your public SSH key (contents of `~/.ssh/id_rsa.pub`)

#### 3. Create IAM Role for OIDC
1. Log in to the [AWS Management Console](https://console.aws.amazon.com/).
2. Navigate to the IAM service.
3. Create a new `Web identity` role
    - Trusted entity type: `Web identity`
    - Identity provider: `token.actions.githubusercontent.com`
    - Audience: `sts.amazonaws.com`
    - GitHub organization: `Your Github Username` or `Your Github Organization`
    - GitHub repository: `Your repository name`
4. In the new role you created add the following inline policy:
    ```json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "EC2FullAccess",
                "Effect": "Allow",
                "Action": "ec2:*",
                "Resource": "*"
            },
            {
                "Sid": "STSGetCallerIdentity",
                "Effect": "Allow",
                "Action": "sts:GetCallerIdentity",
                "Resource": "*"
            }
        ]
    }
    ```
5. Copy the Role ARN, we will need it later.

#### 4. Create S3 bucket and DynamoDB table for Terraform state
1. Log in to the [AWS Management Console](https://console.aws.amazon.com/).
2. Navigate to the S3 service and create a new S3 bucket.
    - Bucket name: `node-app-terraform-state-<Your AWS Account ID>` (Replace `<Your AWS Account ID>` with your AWS Account ID)
    - Region: `us-east-1`
    - Enable versioning
    - Enable public access block
    - Create bucket
3. Navigate to the S3 service and create a new DynamoDB table for state locking
    - Table name: `node-app-terraform-locks`
    - Partition key: `LockID` (String)
    - Create table
4. update `terraform\backend.tf` with your bucket name and DynamoDB table name.
    ``` hcl
    terraform {
      required_version = ">= 1.13.0"
  
      backend "s3" {
        bucket         = "node-app-terraform-state-<Your AWS Account ID>"   # Change this
        key            = "global/terraform.tfstate"                     
        region         = "us-east-1"                                    
        dynamodb_table = "node-app-terraform-locks"                         # And this 
        encrypt        = true                                           
      }
    }
    ```

#### 4. Update project files.
1. In `.github\workflows\deploy_service.yml`, change the `role-to-assume` value to your role ARN.
    ``` yml
    - name: Configure AWS credentials via OIDC (Terraform)
      uses: aws-actions/configure-aws-credentials@v4
      with:
        role-to-assume: arn:aws:iam::<Account-ID>:role/<Role-Name> # Change this to your role ARN
        aws-region: us-east-1
    ```

2. In `ansible\roles\app\tasks\main.yml`, update the repo URL to point to your new repository.
    
    ``` yml
    - name: Clone repo into tmp
      git:
        # Change this to your repository URL
        repo: "https://github.com/yourusername/yourrepository.git"
        dest: /tmp/node-service-repo
        version: main
    ```
#### 5. Push changes to trigger deployment.
1. Commit and push your changes to the `main` branch of the repository you created.
    ```
    git add .
    git commit -m "Deploy Node.js service"
    git push origin main
    ```
2. Check the Actions tab in your repository to monitor the deployment progress.