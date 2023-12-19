pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'devmicky23/web-app'
  
    }

    stages {
        stage('Install Docker') {
            steps {
                script {
                    // Clone the GitHub repository
                    checkout([$class: 'GitSCM', branches: [[name: '*/master']], userRemoteConfigs: [[url: 'https://github.com/devrathoree/terraform.git']]])
                }
            }
       }

        stage('Install kubectl and AWS CLI') {
            steps {
                script {
                    // // Install kubectl
                    // sh '''
                    //     sudo apt-get update
                    //     sudo apt-get install -y -q apt-transport-https
                    //     sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
                    //     sudo echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
                    //     sudo apt-get update -q
                    //     sudo apt-get install -y -q kubectl
                    // '''

                    // Install AWS CLI
                    sh 'sudo apt-get install -y awscli'
                    sh " wget https://storage.googleapis.com/kubernetes-release/release/v1.23.6/bin/linux/amd64/kubectl -O kubectl"
                    sh "chmod +x kubectl"
                    sh "sudo mv kubectl /usr/local/bin/"
                }
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                script {
                    dir('oxer-html'){
                    // Build and push Docker image
                        sh "docker build -t ${DOCKER_IMAGE}  ."
                        
                        withCredentials([string(credentialsId: 'docker--cred', variable: 'DOCKER_PASS')]) {
                        sh "docker login -u devmicky23 -p ${DOCKER_PASS}"
                        sh "docker push ${DOCKER_IMAGE}"
                        }
                    }
                }
            }
        }

 
        
        stage('Integrate Jenkins with EKS Cluster and Deploy') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'aws-aws', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {                        
                        
                        sh "kubectl config set-credentials arn:aws:eks:us-east-1:550513526501:cluster/DEV_EKS --exec-api-version=client.authentication.k8s.io/v1beta1 --kubeconfig=${WORKSPACE}/kubeconfig"                        
                        echo "Debug: After kubectl set-credentials"
                        sh 'aws eks update-kubeconfig --name DEV_EKS --region us-east-1'
                        sh "mv ${JENKINS_HOME}/.kube/config ${WORKSPACE}/kubeconfig"
                    
                        sh "kubectl apply -f app.yaml  --kubeconfig=${WORKSPACE}/kubeconfig"
                    }
                }
            }
        }
    }
}
