pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        APP_NAME = "javasec"
        REMOTE_HOST = "192.168.195.100"      // 改成宿主机IP
        REMOTE_USER = "root"           // 改成宿主机用户名
        REMOTE_DIR  = "/data/Application/javasec"

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

        stage('Parallel Fake Build & SCA Trigger') {
            parallel {

                stage('Fake Compile') {
                    steps {
                        echo "=== Fake Compile Stage ==="
                        sh 'echo "Simulating build... no real compile executed."'
                    }
                }

                stage('Trigger SCA Task') {
                    steps {
                        echo "=== Trigger SCA Scan Task ==="

                        //catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                        //    script {
                        //        def status = sh(
                        //            script: """
                        //            curl -s -o sca_response.json -w "%{http_code}" \
                        //            -X POST ${SCA_API_URL} \
                        //            -H "Content-Type: application/json" \
                        //            -H "Authorization: Bearer ${SCA_TOKEN}" \
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
                        //            echo "SCA trigger failed but pipeline continues."
                        //            error("SCA trigger failed")
                        //        }
                        //    }
                        //}
                    }
                }
            }
        }

        stage('Deploy On Host') {
            steps {
                echo "=== Deploying on Host via SSH ==="

                sshagent(credentials: ['deploy-ssh']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} '
                        mkdir -p ${REMOTE_DIR}
                    '
                    """

                    sh """
                    scp -o StrictHostKeyChecking=no -r . ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}
                    """

                    sh """
                    ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} '
                        cd ${REMOTE_DIR} &&
                        docker stop javasec-container || true &&
                        docker rm javasec-container || true &&
                        docker build -t javasec:latest . &&
                        docker run -d -p 80:8888 -v logs:/logs --name javasec-container javasec:latest
                    '
                    """
                }
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
