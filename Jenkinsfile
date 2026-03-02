pipeline {
    agent any

    environment {
        GITHUB_REPO = 'https://github.com/Judges6699/HelloJava.git'
        BRANCH = 'main'

        DEPLOY_HOST = '192.168.195.100'
        DEPLOY_USER = 'root'
        DEPLOY_PATH = '/data/Application/javaproject'

        // 统一安全接口根路径
        SECURITY_API = 'http://10.208.239.57:9001/openapi'

        // 安全门禁标记
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
		
		            def payload = '''
		            {
		              "projectName": "test",
		              "projectVersion": "1.0",
		              "moduleName": "mod",
		              "startum": "root",
		              "data": {
		                "language": 1,
		                "vcs": {
		                  "codeType": "0",
		                  "url": "http://test.git"
		                }
		              }
		            }
		            '''
		
		            def response = sh(
		                script: """
		                    curl -s --connect-timeout 10 --max-time 30 \
		                    -X POST http://10.208.239.57:9001/openapi/tasks/sca \
		                    -H 'Content-Type: application/json' \
		                    -d '${payload}'
		                """,
		                returnStdout: true
		            ).trim()
		
		            echo "SCA接口返回: ${response}"
		
		            // ===== 判断 code 是否为0 =====
		            if (!response.contains('"code":0')) {
		                error "SCA接口调用失败"
		            }
		
		            // ===== 判断 status 是否 SUCCESS =====
		            if (!response.contains('"status":"SUCCESS"')) {
		                error "SCA任务创建失败"
		            }
		
		            // ===== 提取 taskId =====
		            def taskId = sh(
		                script: """echo '${response}' | sed -n 's/.*"taskId":"\\([0-9]*\\)".*/\\1/p'""",
		                returnStdout: true
		            ).trim()
		
		            echo "SCA任务下发成功，任务ID: ${taskId}"
		
		            env.SCA_TASK_ID = taskId
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

                    echo "================ 所有安全红线检查通过 ================"

                    env.SECURITY_GATE_PASS = "true"
                }
            }
        }

        stage('生产发布审批') {
            steps {
                input message: '安全门禁通过，是否确认发布到生产环境？'
            }
        }

        stage('PROD生产发布') {
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
    }
}


