pipeline {
    agent any
    options {
        skipDefaultCheckout(true)
    }
    environment {
        // App Settings
        app_name = 'parabank'
        app_version = 'v1'
        app_port = 8090
        project_name = 'Parabank_Master'
        buildId = "${project_name}-${BUILD_ID}"

        // Parasoft Licenses
        ls_url = "${LS_URL}"
        ls_user = "${LS_USER}"
        ls_pass = "${LS_PASS}"

        // Parasoft Jtest Settings
        saConfig = 'UTSA.properties'
        codeCovConfig = 'CalculateApplicationCoverage.properties'
        unitCovImage = "${project_name};${project_name}_UnitTest"

        // Parasoft SOAtest Settings
        fucntionalCovImage = "${project_name};${project_name}_FunctionalTest"

        // Parasoft DTP Settings
        dtp_url = "${DTP_URL}"
        dtp_user = 'demo'
        dtp_pass = 'demo-user'
        dtp_publish = false

    // Build Triggers
    }
    stages {
        stage('Configre Job') {
            steps {
                // Clean before build
                cleanWs()
                // Checkout project
                checkout scm
                // set GID
                script {
                    env.GID = sh(script: 'id -g jenkins', returnStdout: true).trim()
                }
                // build the project
                echo "Building ${env.JOB_NAME}..."
                // Debug
                sh 'ls -la'
            }
        }
        stage('Build') {
            when { equals expected: true, actual: true }
            steps {
                // Build with Jtest SA/UT/monitor

                // Set Up .propeties file
                sh '''
                # Create Folder for monitor
                mkdir monitor

                # Set Up and write .properties file
                echo $"
                parasoft.eula.accepted=true
                jtest.license.use_network=true
                jtest.license.network.edition=server_edition
                license.network.use.specified.server=true
                license.network.auth.enabled=true
                license.network.url=${LS_URL}
                license.network.user=${LS_USER}
                license.network.password=${LS_PASS}
                build.id="${buildId}"
                dtp.url="${DTP_URL}"
                dtp.user="${DTP_USER}"
                dtp.password="${DTP_PASS}"
                dtp.project=${project_name}" >> jtest/jtestcli.properties

                # Debug: Print jtestcli.properties file
                cat jtest/jtestcli.properties
                '''

                // Run Maven build with Jtest tasks via Docker
                sh '''
                docker run --rm -i \
                -u "$UID:$GID" \
                -v "$PWD:$PWD" \
                -w "$PWD" \
                $(docker build -q --no-cache ./jtest) /bin/bash -c " \
                mvn \
                -Dmaven.test.failure.ignore=true \
                test-compile jtest:agent \
                test jtest:jtest \
                -s jtest/.m2/settings.xml \
                -Djtest.settings='jtest/jtestcli.properties' \
                -Djtest.config='jtest/${saConfig}' \
                -Djtest.report.coverage.images="${unitCovImage}" \
                -Dproperty.report.dtp.publish=true; \
                mvn \
                -DskipTests=true \
                package jtest:monitor \
                -s jtest/.m2/settings.xml \
                -Djtest.settings='jtest/jtestcli.properties'; \
                "
                '''

                // Unzip Cov Monitor
                sh '''
                unzip target/*/*/monitor.zip -d .
                ls -la monitor
                '''
            }
        }
        stage('Deploy') {
            when { equals expected: true, actual: false }
            steps {
                // Deploy App Conatiner wth Cov Monitor
                sh '''
                # Stop app conatiner if running
                docker stop ${app_name}-${app_version} || true

                # Start Docker Container
                docker run -d \
                -p ${app_port}:8080 \
                -p 8050:8050 \
                -p 61616:61616 \
                -p 9001:9001 \
                --env-file "$PWD/jtest/monitor.env" \
                -v "$PWD/monitor:/home/docker/jtest/monitor" \
                --name ${app_name}-${app_version} \
                parasoft/parabank
                '''

                // Run Health Checks
                sh '''
                # Wait for Uptime
                sleep 15

                # Parabank Status Check
                curl -iv --raw http://localhost:8090/parabank

                # Cov Agent Status
                curl -iv --raw http://localhost:8050/status

                '''
            }
        }
        stage('Test') {
            when { equals expected: true, actual: false }
            steps {
                // Set Up SOAtest .properties file
                sh '''
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
                dtp.password=demo-user" >> soatest/soatestcli.properties

                # Debug: Print soatestcli.properties file
                cat soatest/soatestcli.properties
                '''

                // Run SOAtest tests
                sh '''
                docker run --rm -i \
                -u "$UID:$GID" \
                -e ACCEPT_EULA=true \
                -v "$PWD:$PWD" \
                parasoft/soavirt /bin/bash -c " \
                cat $PWD/soatest/soatestcli.properties; \
                soatestcli \
                -settings $PWD/soatest/soatestcli.properties \
                -machineId; \
                ls -la $PWD/jenkins/soatest; \
                cp "$PWD/jenkins/soatest"/* "/root/parasoft/soavirt_workspace/TestAssets/"; \
                soatestcli \
                -resource /TestAssets \
                -config '/root/parasoft/soavirt_workspace/TestAssets/AppCoverage.properties' \
                -settings $PWD/soatest/soatestcli.properties \
                -environment 127.17.0.1 \
                -report $PWD/soatest/report \
                -publish"
                '''

                // Publish Coverage
                sh '''
                docker run --rm -i \
                -u "UID:GID" \
                -v "$PWD:$PWD" \
                -w "$PWD" \
                parasoft/jtest \
                jtestcli \
                -settings jtest/jtestcli.properties \
                -staticcoverage "monitor/static_coverage.xml" \
                -runtimecoverage "target/jtest/runtime_coverage" \
                -config "${codeCovConfig}" \
                -property report.coverage.images="${fucntionalCovImage}" \
                -property session.tag="FunctionalTest" \
                -publish

                '''
            }
        }
        stage('Release') {
            when { equals expected: true, actual: false }
            steps {
                sh '''
                docker stop parabankv1
                docker rm parabankv1
                '''
            }
        }
        stage('Static Analysis Reports') {
            when { equals expected: true, actual: false }
            steps {
                echo '---> Parsing static analysis reports'
                step([$class: 'ParasoftPublisher', useReportPattern: true, reportPattern: 'target/jtest/*.xml', settings: ''])
            }

        }
        stage('Unit Test 10x') {
            when { equals expected: true, actual: false }
            steps {
                echo '---> Parsing 10.x unit test reports'
                step([$class: 'XUnitPublisher',
                    tools: [
                        [$class: 'ParasoftType',
                            pattern: 'target/jtest/*.xml',
                            failIfNotNew: false,
                            skipNoTestFiles: true,
                            stopProcessingIfError: false
                        ]
                    ]
                ])
            }
        }
        stage('Functional Tests 9x') {
            when { equals expected: true, actual: false }
            steps {
                echo '---> Parsing 9.x functional test reports'
                step([$class: 'XUnitPublisher',
                    tools: [
                        [$class: 'ParasoftSOAtest9xType',
                            pattern: 'soatest/report/*.xml',
                            failIfNotNew: false,
                            skipNoTestFiles: true,
                            stopProcessingIfError: false
                        ]
                    ]
                ])
            }
        }
    }
}
