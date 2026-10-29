pipeline {
  agent any
  environment {
    AWS_REGION = 'ap-south-1'
    ACCOUNT_ID = credentials('aws-account-id')
    ECR_REPO   = 'solo-ops-orders'
    REGISTRY   = "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    IMAGE_TAG  = "${env.GIT_COMMIT.take(7)}"
  }
  options { timestamps(); disableConcurrentBuilds(); timeout(time: 30, unit: 'MINUTES') }

  stages {
    stage('Test') {
      steps {
        dir('app') {
          sh '''
            python3 -m venv .venv && . .venv/bin/activate
            pip install -r requirements.txt
            pytest -q
          '''
        }
      }
    }
    stage('Build') {
      steps { sh "docker build -t ${REGISTRY}/${ECR_REPO}:${IMAGE_TAG} app/" }
    }
    stage('Scan') {
      steps {
        sh "trivy image --exit-code 1 --severity CRITICAL --ignore-unfixed ${REGISTRY}/${ECR_REPO}:${IMAGE_TAG}"
      }
    }
    stage('Push') {
      steps {
        sh """
          aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${REGISTRY}
          docker push ${REGISTRY}/${ECR_REPO}:${IMAGE_TAG}
        """
      }
    }
    stage('Deploy Dev') {
      when { branch 'main' }
      steps { sh "./scripts/deploy.sh dev ${IMAGE_TAG}" }
    }
    stage('Approve Prod') {
      when { branch 'main' }
      steps { input message: 'Deploy to PROD?', ok: 'Deploy' }
    }
    stage('Deploy Prod') {
      when { branch 'main' }
      steps { sh "./scripts/deploy.sh prod ${IMAGE_TAG}" }
    }
  }
  post {
    always  { sh "docker rmi ${REGISTRY}/${ECR_REPO}:${IMAGE_TAG} || true" }
    failure { echo 'Build failed - SNS/Slack notification hooks in Phase 5' }
  }
}
