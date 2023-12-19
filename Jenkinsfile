pipeline {
    agent {
        docker {
            image 'devmicky23/web-app'
            args '--user=root'
        }
    }

    stages {
        stage('Install kubectl and AWS CLI') {
            steps {
                script {
                    sh '''
                        sudo rm -f /usr/local/bin/kubectl
                        wget -qO- https://storage.googleapis.com/kubernetes-release/release/stable.txt
                        wget https://storage.googleapis.com/kubernetes-release/release/v1.29.0/bin/linux/amd64/kubectl
                        chmod +x kubectl
                        sudo mv kubectl /usr/local/bin/

                        # Install AWS CLI
                        sudo apt-get update
                        sudo apt-get install -y awscli
                    '''
                }
            }
        }
    
        stage('Checkout Code') {
            steps {
                script {
                    // Clone the GitHub repository
                    checkout([$class: 'GitSCM', branches: [[name: '*/main']], userRemoteConfigs: [[url: 'https://github.com/devrathoree/terraform.git']]])
                }
            }
        }

        stage('Integrate Jenkins with EKS Cluster and Deploy') {
            steps {
                script {
                    withAWS(credentials: 'aws-credentials-id', region: 'us-east-1') {
                        sh 'aws eks update-kubeconfig --name dev-eks-cluster --region us-east-1'
                    
                        sh 'kubectl apply -f deployment.yml --kubeconfig=/root/.kube/config'
                        sh 'kubectl apply -f service.yml --kubeconfig=/root/.kube/config'
                    }
                }
            }
        }
    }
}

