pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        APP_NAME = "javasec"
        DOCKER_IMAGE = "javasec:latest"
        CONTAINER_NAME = "javasec-container"

        SCA_API_URL = "http://your-sdl-server/openapi/tasks/sca"
        SCA_TOKEN   = "your-api-token"
    }

    stages {

        stage('Checkout') {
            steps {
                echo "=== Checkout Source ==="
                checkout scm
            }
        }

        stage('Parallel Build & SCA Trigger') {
            parallel {

                stage('Build Jar') {
                    steps {
                        echo "=== Maven Package ==="
                        sh 'mvn clean package -DskipTests'
                    }
                }

                stage('Trigger SCA Task') {
                    steps {
                        echo "=== Trigger SCA Scan Task ==="

                        //catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                        //    script {
                        //        def status = sh(
                        //            script: """
                        //            curl -s -o sca_response.json -w "%{http_code}" \\
                        //            -X POST ${SCA_API_URL} \\
                        //            -H "Content-Type: application/json" \\
                        //            -H "Authorization: Bearer ${SCA_TOKEN}" \\
                        //            -d '{
                        //                    "projectName":"${env.JOB_NAME}",
                        //                    "branch":"${env.BRANCH_NAME ?: "main"}",
                        //                    "buildNumber":"${env.BUILD_NUMBER}"
                        //                }'
                        //            """,
                        //            returnStdout: true
                        //        ).trim()
						//
                        //        echo "SCA HTTP Status: ${status}"
						//
                        //        if (status != "200" && status != "201") {
                        //            echo "SCA trigger failed, but pipeline continues."
                        //            error("SCA trigger failed")
                        //        }
                        //    }
                        //}
                    }
                }
            }
        }

        stage('Unit Test') {
            steps {
                echo "=== Run Unit Tests ==="
                sh 'mvn test'
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Docker Build & Deploy') {
            steps {
                echo "=== Docker Build ==="
                sh """
                docker build -t ${DOCKER_IMAGE} .
                """

                echo "=== Stop Old Container ==="
                sh """
                docker stop ${CONTAINER_NAME} || true
                docker rm ${CONTAINER_NAME} || true
                """

                echo "=== Run New Container ==="
                sh """
                docker run -d \
                  --name ${CONTAINER_NAME} \
                  -p 80:8888 \
                  -v logs:/logs \
                  ${DOCKER_IMAGE}
                """
            }
        }
    }

    post {
        success {
            echo "Pipeline SUCCESS"
        }
        unstable {
            echo "Pipeline UNSTABLE (SCA trigger failed)"
        }
        failure {
            echo "Pipeline FAILED"
        }
        always {
            archiveArtifacts artifacts: 'sca_response.json', fingerprint: true
        }
    }
}