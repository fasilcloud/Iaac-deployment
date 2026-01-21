pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/fasilcloud/Iaac-deployment.git'
            }
        }

        stage('Terraform Security Scan') {
            steps {
                dir('Iaac/env/dev') {
                    sh '''
                       tfsec --exit-on-violation .
                    '''
                }
            }
        }

        stage('Terraform Init') {
            steps {
                dir('Iaac/env/dev') {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('Iaac/env/dev') {
                    sh 'terraform plan -out=tfplan'
                }
            }
        }

        stage('Manual Approval Before Apply') {
            steps {
                script {
                    def decision = input(
                        message: 'Apply Terraform changes to AWS?',
                        parameters: [
                            choice(
                                name: 'DEPLOY',
                                choices: ['Allow', 'Deny'],
                                description: 'Allow or Deny deployment'
                            )
                        ]
                    )
                    if (decision == 'Deny') {
                        error "Terraform deployment denied by user"
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('Iaac/env/dev') {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }

        stage('Post-Deployment') {
            steps {
                echo "Terraform AWS deployment complete"
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo 'AWS Terraform deployment succeeded'
        }
        failure {
            echo 'AWS Terraform deployment failed'
        }
    }
}
