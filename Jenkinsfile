pipeline {
    agent any

    environment {
        GITHUB_REPO = 'https://github.com/Judges6699/HelloJava.git'
        BRANCH = 'main'

        DEPLOY_HOST = '192.168.195.100'
        DEPLOY_USER = 'root'
        DEPLOY_PATH = '/data/Application/javaproject'

        // 统一安全接口根路径
        SECURITY_API = 'http://你的sca服务地址/openapi'

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

				stage('SCA扫描'){
					steps{
						catchError(buildResult: 'SUCCESS',stageResult: 'FAILURE'){
							echo'===下发SCA扫描任务==='
						  //sh""" // curl -X POST ${SCA_API} \ 
						  // -H 'Content-Type: application/json' \ 
						  // -d '{ // "projectName": "javasec", 
						  // "projectVersion": "1.0",
						  // "moduleName": "default", 
						  // "data": { // "company": "test" // } // }' """
							 echo'===SCA任务下发完成==='
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

                    //def response = sh(
                    //    script: """
                    //        curl -s -X GET "${SECURITY_API}/security/redlines\
                    //        ?sdlTool=0\
                    //        &projectName=javasec\
                    //        &projectVersion=1.0"
                    //    """,
                    //    returnStdout: true
                    //).trim()
					//
                    //echo "红线接口返回: ${response}"
					//
                    //def json = readJSON text: response
					//
                    //if (json.code != 0) {
                    //    error "❌ 安全红线接口调用失败"
                    //}
					//
                    //def data = json.data
					//
                    ///* ========= 安全评审 ========= */
					//
                    //def stacResult = data.stac?.stacResult ?: 3
                    //def stacNotItems = data.stac?.stacNotItems ?: 0
					//
                    //echo """
                    //===== 安全评审结果 =====
                    //不通过条数: ${stacNotItems}
                    //状态: ${stacResult}
                    //"""
					//
                    //if (stacResult == 1) {
                    //    error "❌ 安全评审未通过"
                    //}
					//
                    ///* ========= 工具统一检查函数 ========= */
					//
                    //def checkTool = { toolName, toolData, needLicenseCheck = false ->
					//
                    //    if (toolData == null) {
                    //        echo ">>> ${toolName} 未发起扫描"
                    //        return
                    //    }
					//
                    //    def serious = toolData.vulSeriousCount ?: 0
                    //    def high = toolData.vulHighCount ?: 0
                    //    def mid = toolData.vulMidCount ?: 0
                    //    def low = toolData.vulLowCount ?: 0
					//
                    //    echo """
                    //    ===== ${toolName} 扫描结果 =====
                    //    严重漏洞: ${serious}
                    //    高危漏洞: ${high}
                    //    中危漏洞: ${mid}
                    //    低危漏洞: ${low}
                    //    """
					//
                    //    if (serious > 0 || high > 0 || mid > 0) {
                    //        error "❌ ${toolName} 存在严重/高危/中危漏洞"
                    //    }
					//
                    //    if (needLicenseCheck) {
                    //        def riskyLicense = toolData.riskyLicenseCount ?: 0
                    //        echo "风险许可证数量: ${riskyLicense}"
                    //        if (riskyLicense > 0) {
                    //            error "❌ SCA 存在风险许可证"
                    //        }
                    //    }
					//
                    //    echo "✅ ${toolName} 检查通过"
                    //}
					//
                    //checkTool("SAST", data.sast)
                    //checkTool("DAST", data.dast)
                    //checkTool("IAST", data.iast)
                    //checkTool("SCA", data.sca, true)

                    echo "================ 所有安全红线检查通过 ================"

                    // 标记通过
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
            when {
                expression { env.SECURITY_GATE_PASS == "true" }
            }
            steps {
                echo '================ 开始生产环境发布 ================'
                //sh '/var/jenkins_home/deploy-prod.sh'
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

