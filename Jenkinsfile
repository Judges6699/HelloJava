pipeline {
    agent any

    environment {
        GITHUB_REPO = 'https://github.com/Judges6699/HelloJava.git'
        BRANCH = 'main'

        // 宿主机信息
        DEPLOY_HOST = '192.168.195.100'
        DEPLOY_USER = 'root'
        DEPLOY_PATH = '/data/Application/javaproject'

        // SCA接口地址
        SCA_API = 'http://你的sca服务地址/openapi/tasks/sca'
    }

    stages {

        stage('Checkout') {
            steps {
                echo '=== 拉取 GitHub 代码 ==='
                git branch: "${BRANCH}", url: "${GITHUB_REPO}"
            }
        }

        stage('Build & SCA Parallel') {
            parallel {

                stage('Fake Build') {
                    steps {
                        echo '=== 伪编译开始 ==='
                        sh 'echo 编译中...'
                        sh 'sleep 3'
                        echo '=== 编译完成 ==='
                    }
                }

                stage('Trigger SCA') {
                    steps {
                        catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                            echo '=== 下发 SCA 扫描任务 ==='
                            //sh """
                            //    curl -X POST ${SCA_API} \
                            //    -H 'Content-Type: application/json' \
                            //    -d '{
                            //          "projectName": "javasec",
                            //          "projectVersion": "1.0",
                            //          "moduleName": "default",
                            //          "data": {
                            //              "company": "test"
                            //          }
                            //        }'
                            //"""
                            echo '=== SCA 任务下发完成 ==='
                        }
                    }
                }
            }
        }

        stage('Deploy on Host') {
            steps {
                echo '=== 部署到宿主机 ==='

                withCredentials([sshUserPrivateKey(
                        credentialsId: 'deploy-key',
                        keyFileVariable: 'SSH_KEY'
                )]) {

                    sh """
                        chmod 600 $SSH_KEY

                        ssh -o StrictHostKeyChecking=no -i $SSH_KEY ${DEPLOY_USER}@${DEPLOY_HOST} '
                            cd ${DEPLOY_PATH} &&
                            git pull &&
                            docker stop javasec || true &&
                            docker rm javasec || true &&
                            docker build -t javasec . &&
                            docker run -d --name javasec -p 80:8888 -v logs:/logs javasec
                        '
                    """
                }

                echo '=== 部署完成 ==='
            }
        }
    }

    post {
        always {
            echo '=== Pipeline 执行结束 ==='
        }
    }
}
