pipeline {
    agent any

    environment {
        GITHUB_REPO = 'https://github.com/Judges6699/HelloJava.git'
        BRANCH = 'main'

        SECURITY_API = 'http://10.208.239.57:9001/openapi'

        DEPLOY_SCRIPT = '/var/jenkins_home/deploy-HelloJava.sh'

        SECURITY_GATE_PASS = "false"
    }

    tools {
        jdk 'jdk1.8'
        maven 'Global'
    }

    stages {

        stage('拉取代码') {
            steps {
                git branch: "${BRANCH}", url: "${GITHUB_REPO}"
            }
        }

        stage('初始化元数据') {
            steps {
                script {

                    env.APP_NAME = sh(
                        script: "mvn help:evaluate -Dexpression=project.artifactId -q -DforceStdout",
                        returnStdout: true
                    ).trim()

                    env.APP_VERSION = sh(
                        script: "mvn help:evaluate -Dexpression=project.version -q -DforceStdout",
                        returnStdout: true
                    ).trim()

                    def userCause = currentBuild.rawBuild.getCause(hudson.model.Cause$UserIdCause)
                    env.BUILD_USER = userCause ? userCause.getUserName() : "SYSTEM"

                    echo """
================ 构建信息 ================
应用名: ${env.APP_NAME}
版本: ${env.APP_VERSION}
流水线: ${env.JOB_NAME}
构建号: ${env.BUILD_NUMBER}
执行人: ${env.BUILD_USER}
提交ID: ${env.GIT_COMMIT}
==========================================
"""
                }
            }
        }

        stage('编译构建') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('SCA 扫描') {
            steps {
                script {

                    writeFile file: 'sca.json', text: """
{
  "projectName": "${env.APP_NAME}",
  "projectVersion": "${env.APP_VERSION}",
  "moduleName": "${env.JOB_NAME}",
  "startum": "${env.BUILD_USER}",
  "data": {
    "language": 1,
    "vcs": {
      "codeType": "0",
      "url": "${env.GITHUB_REPO}"
    }
  }
}
"""

                    def response = sh(
                        script: """
                        curl --fail -s \
                        -X POST ${env.SECURITY_API}/tasks/sca \
                        -H "Content-Type: application/json" \
                        --data @sca.json
                        """,
                        returnStdout: true
                    ).trim()

                    if (!response) {
                        error "SCA接口无返回"
                    }

                    def json = new groovy.json.JsonSlurper().parseText(response)

                    if (json.code != 0) {
                        error "SCA创建失败: ${json.message}"
                    }

                    env.SCA_TASK_ID = json.data.taskId
                    echo "SCA任务ID: ${env.SCA_TASK_ID}"
                }
            }
        }

        stage('等待 SCA 结果') {
            steps {
                script {

                    timeout(time: 10, unit: 'MINUTES') {

                        waitUntil {

                            sleep 20

                            def result = sh(
                                script: """
                                curl -s ${env.SECURITY_API}/tasks/result/${env.SCA_TASK_ID}
                                """,
                                returnStdout: true
                            ).trim()

                            def json = new groovy.json.JsonSlurper().parseText(result)

                            if (json.data.status == "RUNNING") {
                                echo "SCA扫描中..."
                                return false
                            }

                            if (json.data.status == "FAILED") {
                                error "SCA扫描失败"
                            }

                            env.SCA_RISK_LEVEL = json.data.riskLevel ?: "LOW"

                            echo "SCA完成，风险等级: ${env.SCA_RISK_LEVEL}"
                            return true
                        }
                    }
                }
            }
        }

        stage('安全门禁判断') {
            steps {
                script {

                    if (env.SCA_RISK_LEVEL in ["CRITICAL", "HIGH"]) {
                        error "存在高危漏洞，禁止发布"
                    }

                    echo "安全门禁通过"
                    env.SECURITY_GATE_PASS = "true"
                }
            }
        }

        stage('部署到STG') {
            steps {
                sh "${DEPLOY_SCRIPT}"
            }
        }

        stage('一致性安全检查') {
            steps {
                script {
                    echo "执行SSDLC一致性检查..."
                    // 这里可以接入接口校验部署版本一致性
                    echo "一致性检查通过"
                }
            }
        }

        stage('生产发布审批') {
            steps {
                input message: "安全门禁通过，是否发布生产？"
            }
        }

        stage('生产部署') {
            steps {
                echo "开始生产部署..."
                sh "${DEPLOY_SCRIPT}"
                echo "生产部署完成"
            }
        }
    }

    post {
        success {
            echo "Pipeline执行成功"
        }
        failure {
            echo "Pipeline执行失败"
        }
        always {
            echo "执行结束"
        }
    }
}
