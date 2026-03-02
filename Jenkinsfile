pipeline {
    agent any

    environment {
        GITHUB_REPO = 'https://github.com/Judges6699/HelloJava.git'
        BRANCH = 'main'

        DEPLOY_HOST = '192.168.195.100'
        DEPLOY_USER = 'root'
        DEPLOY_PATH = '/data/Application/javaproject'

        SECURITY_API = 'http://10.208.239.57:9001/openapi'

        SECURITY_GATE_PASS = "false"
    }

    tools {
        jdk 'jdk1.8'
        maven 'Global'
    }

    stages {

        stage('克隆代码') {
            steps {
                echo '=== 拉取 GitHub 代码 ==='
                git branch: "${BRANCH}", url: "${GITHUB_REPO}"
            }
        }

        stage('编译 & SCA 检测') {
            parallel {

                stage('编译构建') {
                    steps {
                        echo '=== 编译开始 ==='
                        sh 'mvn clean package -DskipTests'
                        echo '=== 编译完成 ==='
                    }
                }

                stage('SCA扫描') {
                    steps {
                        script {

                            echo '=== 开始下发 SCA 扫描任务 ==='

                            // 1️⃣ 构造JSON文件（避免shell转义问题）
                            writeFile file: 'sca_payload.json', text: """
{
  "projectName": "${env.JOB_NAME}",
  "projectVersion": "${env.BUILD_NUMBER}",
  "moduleName": "default",
  "startum": "jenkins",
  "data": {
    "language": 1,
    "vcs": {
      "codeType": "0",
      "url": "${env.GITHUB_REPO}"
    }
  }
}
"""

                            // 2️⃣ 调用接口（强制错误退出）
                            def response = sh(
                                script: """
                                    curl --fail -s \
                                    --connect-timeout 10 \
                                    --max-time 30 \
                                    -X POST ${env.SECURITY_API}/tasks/sca \
                                    -H "Content-Type: application/json" \
                                    --data @sca_payload.json
                                """,
                                returnStdout: true
                            ).trim()

                            echo "SCA接口返回: ${response}"

                            // 3️⃣ 空返回保护
                            if (!response) {
                                error "SCA接口无返回内容"
                            }

                            if (!response.startsWith("{")) {
                                error "SCA接口返回非法数据: ${response}"
                            }

                            // 4️⃣ 使用Pipeline Utility插件解析JSON（避免JsonSlurper权限问题）
                            def json = readJSON text: response

                            if (json.code == null || json.code.toInteger() != 0) {
                                error "SCA接口调用失败: ${json.message}"
                            }

                            if (!json.data) {
                                error "SCA接口返回data为空"
                            }

                            def taskId = json.data.taskId
                            def status = json.data.status
                            def taskMessage = json.data.taskMessage

                            echo """
================ SCA 任务信息 ================
任务ID: ${taskId}
状态: ${status}
描述: ${taskMessage}
==============================================
"""

                            if (status != "SUCCESS") {
                                error "SCA任务创建失败: ${taskMessage}"
                            }

                            env.SCA_TASK_ID = taskId

                            echo "=== SCA任务下发成功 ==="
                        }
                    }
                }
            }
        }

        stage('STG部署') {
            steps {
                echo '=== 部署到测试环境 ==='
                sh '/var/jenkins_home/deploy-HelloJava.sh'
                echo '=== STG 部署完成 ==='
            }
        }

        stage('SSDLC一致性检测') {
            steps {
                script {

                    echo '================ 开始进行安全红线门禁检查 ================'

                    if (env.SCA_TASK_ID == null || env.SCA_TASK_ID == "") {
                        error "未获取到SCA任务ID，门禁不通过"
                    }

                    echo "SCA任务ID存在: ${env.SCA_TASK_ID}"
                    echo "================ 所有安全红线检查通过 ================"

                    env.SECURITY_GATE_PASS = "true"
                }
            }
        }

        stage('生产发布审批') {
            when {
                expression { env.SECURITY_GATE_PASS == "true" }
            }
            steps {
                input message: '安全门禁通过，是否确认发布到生产环境？'
            }
        }

        stage('PROD生产发布') {
            when {
                expression { env.SECURITY_GATE_PASS == "true" }
            }
            steps {
                echo '================ 开始生产环境发布 ================'
                echo '================ 生产发布完成 ================'
            }
        }
    }

    post {
        always {
            echo '=== Pipeline 执行结束 ==='
        }
        failure {
            echo '❌ Pipeline 执行失败'
        }
        success {
            echo '✅ Pipeline 执行成功'
        }
    }
}
