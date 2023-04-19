pipeline {
    agent any
    options {
        skipDefaultCheckout(true)
    }
    environment {
        // App Settings
        parabank_port=8090
        project_name="Parabank_Master"
        buildId="${project_name}-${BUILD_ID}"

        
        // Parasoft Licenses
        ls_url="${PARASOFT_LS_URL}"
        ls_user="${PARASOFT_LS_USER}"
        ls_pass="${PARASOFT_LS_PASS}"
        
        // Parasoft Jtest Settings
        saConfig="UTSA.properties"
        codeCovConfig="CalculateApplicationCoverage.properties"    
        unitCovImage="${project_name};${project_name}_UnitTest"

        // Parasoft SOAtest Settings
        fucntionalCovImage="${project_name};${project_name}_FunctionalTest"
        
        // Parasoft DTP Settings
        dtp_url="${PARASOFT_DTP_URL}"
        dtp_user="demo"
        dtp_pass="demo-user"
        dtp_publish=false

        // Build Triggers

        }
    stages {
        stage('Configre Workspace') {
            steps {
                // Clean before build
                cleanWs()
                // Checkout project
                checkout scm
                // build the project                
                echo "Building ${env.JOB_NAME}..."
                // checkout jenkins deps
                sh "git clone 'https://github.com/gtrofimov/jenkins.git' "
                sh "ls -la"
            }
        }
        stage('Build') {
            when { equals expected: true, actual: true }
            steps {

                user = sh(returnStdout: true, script: 'id -u').trim()
                group = sh(returnStdout: true, script: 'id -g').trim()
                sh '''
                
                # Build with Jtest SA/UT/monitor

                # Create Folder for monitor
                mkdir monitor


                
                # Set Up and write .properties file
                echo $"
                parasoft.eula.accepted=true
                jtest.license.use_network=true
                jtest.license.network.edition=server_edition
                license.network.use.specified.server=true
                license.network.auth.enabled=true
                license.network.url=${ls_url}
                license.network.user=${ls_user}
                license.network.password=${ls_pass}
                build.id="${buildId}"
                dtp.url="${dtp_url}"
                dtp.user="${dtp_user}"
                dtp.password="${dtp_pass}"
                
                dtp.project=${project_name}" >> jenkins/jtest/jtestcli.properties
                
                # Debug: Print jtestcli.properties file
                cat jenkins/jtest/jtestcli.properties

                # Run Maven build with Jtest tasks via Docker
                docker run --rm -i \
                -u "$user:$group" \
                -v "$PWD:$PWD" \
                -w "$PWD" \
                $(docker build -q ./jenkins/jtest) /bin/bash -c " \
                mvn \
                -Dmaven.test.failure.ignore=true \
                test-compile jtest:agent \
                test jtest:jtest \
                -s /home/parasoft/.m2/settings.xml \
                -Djtest.settings='/home/parasoft/jtestcli.properties' \
                -Djtest.config='jenkins/jtest/${saConfig}' \
                -Djtest.report.coverage.images="${unitCovImage}" \
                -Dproperty.report.dtp.publish=true; \
                mvn \
                -DskipTests=true \
                package jtest:monitor \
                -s /home/parasoft/.m2/settings.xml \
                -Djtest.settings='/home/parasoft/jtestcli.properties'; \
                "

                # Unzip monitor.zip
                unzip **/target/*/*/monitor.zip -d .
                ls -la monitor
                '''
            }
        }
        stage('Deploy') {
            when { equals expected: true, actual: false }
            steps {
                sh '''
                
                # Deploy App with Coverage Agent
                
                # Start Docker Container
                docker run -d \
                -p ${parabank_port}:8080 \
                -p 8050:8050 \
                -p 61616:61616 \
                -p 9001:9001 \
                --env-file "$PWD/jenkins/jtest/monitor.env" \
                -v "$PWD/monitor:/home/docker/jtest/monitor" \
                --name parabankv1 \
                parasoft/parabank

                # Health Check
                sleep 15
                curl -iv --raw http://localhost:8090/parabank
                curl -iv --raw http://localhost:8050/status

                '''
            }
        }
        stage('Test') {
            when { equals expected: true, actual: false}
            steps {
                sh '''
                # Run SOAtest Tests with Cov
              
                # Set Up and write .properties file
                echo $"
                license.network.auth.enabled=true
                license.network.use.specified.server=true
                license.network.url=${ls_url}
                license.network.user=${ls_user}
                license.network.password=${ls_pass}
                soatest.license.network.edition=automation_edition
                soatest.license.use_network=true
                build.id=${buildId}
                dtp.enabled=true
                dtp.project=${project_name}
                dtp.url=${dtp_url}
                dtp.user=demo
                dtp.password=demo-user" >> jenkins/soatest/soatestcli.properties
                
                # Debug: Print soatestcli.properties file
                cat jenkins/soatest/soatestcli.properties
                
                # Run SOAtest Tests
                docker run --rm -i \
                -u 0:0 \
                -e ACCEPT_EULA=true \
                -v "$PWD:$PWD" \
                parasoft/soavirt /bin/bash -c " \
                cat $PWD/jenkins/soatest/soatestcli.properties; \
                soatestcli \
                -settings $PWD/jenkins/soatest/soatestcli.properties \
                -machineId; \
                ls -la $PWD/jenkins/soatest; \
                cp "$PWD/jenkins/soatest"/* "/root/parasoft/soavirt_workspace/TestAssets/"; \
                soatestcli \
                -resource /TestAssets \
                -config '/root/parasoft/soavirt_workspace/TestAssets/AppCoverage.properties' \
                -settings $PWD/jenkins/soatest/soatestcli.properties \
                -environment 127.17.0.1 \
                -report $PWD/jenkins/soatest/report \
                -publish"
                
                # Publish Coverage

                # Set up .properties (why am i doing this twice?)
                echo $"
                parasoft.eula.accepted=true
                jtest.license.use_network=true
                jtest.license.network.edition=server_edition
                license.network.use.specified.server=true
                license.network.auth.enabled=true
                license.network.url=${ls_url}
                license.network.user=${ls_user}
                license.network.password=${ls_pass}
                build.id="${buildId}"
                dtp.url=${dtp_url}
                dtp.user=demo
                dtp.password=demo-user
                dtp.project=${project_name}" >> jenkins/jtest/jtestcli.properties

                # Run Jtest command to publish test results
                docker run --rm -i \
                -u 0:0 \
                -v "$PWD:$PWD" \
                -w "$PWD" \
                $(docker build -q ./jenkins/jtest) \
                jtestcli \
                -settings /home/parasoft/jtestcli.properties \
                -staticcoverage "monitor/static_coverage.xml" \
                -runtimecoverage "parabank/target/jtest/runtime_coverage" \
                -config "${codeCovConfig}" \
                -property report.coverage.images="${fucntionalCovImage}" \
                -property session.tag="FunctionalTest" \
                -publish

                '''
            }
        }
        stage('Release') {
            when { equals expected: true, actual: false}
            steps {
                sh '''
                docker stop parabankv1
                docker rm parabankv1
                '''
            }
        }
        stage('Static Analysis Reports'){
            
            when { equals expected: true, actual: false}
            steps {
                echo '---> Parsing static analysis reports'
                step([$class: 'ParasoftPublisher', useReportPattern: true, reportPattern: '**/target/jtest/*.xml', settings: ''])      
            }
            
        
        }
        stage('Unit Test 10x'){
            steps {
                echo '---> Parsing 10.x unit test reports'
                step([$class: 'XUnitPublisher', 
                    tools: [
                        [$class: 'ParasoftType', 
                            pattern: '**/target/jtest/*.xml', 
                            failIfNotNew: false, 
                            skipNoTestFiles: true, 
                            stopProcessingIfError: false
                        ]
                    ]
                ])
            }
        }
        stage('Functional Tests 9x'){
            steps {
                echo '---> Parsing 9.x functional test reports'
                step([$class: 'XUnitPublisher', 
                    tools: [
                        [$class: 'ParasoftSOAtest9xType', 
                            pattern: '**/soatest/report/*.xml', 
                            failIfNotNew: false, 
                            skipNoTestFiles: true, 
                            stopProcessingIfError: false
                        ]
                    ]
                ])
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '**/target/*.war, **/target/jtest/**, **/soatest/report/**',
                fingerprint: true, 
                onlyIfSuccessful: true
        }
    }
}