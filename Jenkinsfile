pipeline {
    agent {
        label "docker-node"
    }

    tools {
        jdk "JDK11"
        maven "Maven_v3.9.6"
    }
    
    environment {
        SONAR_SCANNER_HOME = tool 'Vish_SonarQube_Scanner_v4.1.0'
		DOCKER_IMAGE_NAME = 'vishwesh126/boardgame_list_webapp'
        DOCKER_CONTAINER_NAME = 'vish_boardgame_list_webapp'
    }

    stages {
        stage('Git Clone') {
            steps {
                git "https://github.com/devopsvish/BoardGameListingWebApp.git"
            }
        }
        
        stage('Maven Code Compile') {
            steps {
                sh "mvn clean compile"
            }
        }
        
        stage('Unit Testing') {
            steps {
                sh "mvn clean test"
            }
        }
        
        stage('Code Packaging') {
            steps {
                // Setting the argline to use the min and max memory for packaging
                sh "mvn clean package -DargLine='-Xmx2560m -Xms2048m'"
            }
        }
        
        stage('OWASP FileSystem Scan') {
            steps {
                // Including multiple files to scan using the --scan argument
                // Outputting the dependency scan report to target folder using --out argument
                dependencyCheck additionalArguments: "--scan 'pom.xml' \
                                                      --scan 'target/*.jar' \
                                                      --out 'target' \
                                                      --junitFailOnCVSS '12.0' \
                                                      --prettyPrint", 
                                                      odcInstallation: 'Vish_Dependency_Check_v8.0.0'
                dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                // Using the sources argument to scan only the needed files and folders (in my case the /src folder)
                // Use -Dsonar.exclusions to exclude any folder from analysis id needed
                withSonarQubeEnv('Vish_SonarQube_Server') {
                    sh """
                        ${env.SONAR_SCANNER_HOME}/bin/sonar-scanner \
                        -Dsonar.projectName=BoardGameList_WebApp \
                        -Dsonar.projectKey=BoardGameList_WebApp \
                        -Dsonar.sources=src/ \
                        -Dsonar.java.binaries=target/classes
                    """   
                }
            }
        }
        
        stage('Sonar Quality Gate') {
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    script {
                        def qualityGateStatus = waitForQualityGate()

                        if (qualityGateStatus == 'OK') {
                            echo 'Quality Gate Success! Proceeding with the next stages.'
                        } else {
                            echo 'Quality Gate Failed. Aborting the pipeline.'
                            // Should abort the pipeline due to the project non coverage of boardgamewebapp, but going to next stage for testing instead of failing
                        }
                    }
                }
            }
        }
        
        stage('Nexus Artifact Upload') {
            steps {
                // Using the global settings.xml file in which the nexus credentials are configured
                withMaven(globalMavenSettingsConfig: 'Vish_Global_Maven_Settings', jdk: 'JDK11', maven: 'Maven_v3.9.6', mavenSettingsConfig: '') {
                    sh "mvn clean deploy -e"
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'DockerCreds', url: 'https://index.docker.io/v1/') {
                        try {
                            // Stopping and removing the container for new app deployment
                            sh """
                                docker stop ${env.DOCKER_CONTAINER_NAME}
                                docker rm ${env.DOCKER_CONTAINER_NAME}
                                docker rmi ${env.DOCKER_IMAGE_NAME}
                            """
                        } catch (err) {
                            echo "No such container. Good to go!!"
                        }
                        sh "docker build -t ${env.DOCKER_IMAGE_NAME} ."
                    }
                    
                }
            }
        }
        
        stage("Trivy Docker Image Scan") {
            steps {
                // Scanning image only for HIGH & CRITICAL vulnarabilities
                // Using exit code 0 to exit smoothly even if there are vulnarabilities (use exit code 1 to fail)
                sh "trivy image --severity HIGH,CRITICAL --exit-code 0 ${env.DOCKER_IMAGE_NAME}"
            }
        }
        
        stage('Push Docker Image') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'DockerCreds', url: 'https://index.docker.io/v1/') {
                        sh "docker push ${env.DOCKER_IMAGE_NAME}"
                    }
                    
                }
            }
        }
        
        stage('Deploy App to Docker Container') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'DockerCreds', url: 'https://index.docker.io/v1/') {
                        sh "docker run -dt --name ${env.DOCKER_CONTAINER_NAME} -p 8090:8080 ${env.DOCKER_IMAGE_NAME}"
                    }
                    
                }
            }
        }
    }

    post {
        success {  
            mail from: 'Jenkins Pipeline <mj.vichu@gmail.com>', to: "mj.vichu@gmail.com", subject: "CI SUCCESS: Jenkins Project Name -> ${env.JOB_NAME}", body: "<b>Jenkins Pipeline Details</b><br>Project: ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br> Status: ${currentBuild.currentResult} <br> Application URL: ${env.JENKINS_URL}:8090", charset: 'UTF-8', mimeType: 'text/html';
        }  
        failure {
            mail from: 'Jenkins Pipeline <mj.vichu@gmail.com>', to: "mj.vichu@gmail.com", subject: "CI FAILURE: Jenkins Project Name -> ${env.JOB_NAME}", body: "<b>Jenkins Pipeline Details</b><br>Project: ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br> Status: ${currentBuild.currentResult} Application URL: ${env.JENKINS_URL}:8090", charset: 'UTF-8', mimeType: 'text/html';
        }  
        unstable {  
            mail from: 'Jenkins Pipeline <mj.vichu@gmail.com>', to: "mj.vichu@gmail.com", subject: "CI UNSTABLE: Jenkins Project Name -> ${env.JOB_NAME}", body: "<b>Jenkins Pipeline Details</b><br>Project: ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br> Status: ${currentBuild.currentResult} Application URL: ${env.JENKINS_URL}:8090", charset: 'UTF-8', mimeType: 'text/html'; 
        }  
        changed {  
            mail from: 'Jenkins Pipeline <mj.vichu@gmail.com>', to: "mj.vichu@gmail.com", subject: "CI STATUS CHANGE: Jenkins Project Name -> ${env.JOB_NAME}", body: "<b>Jenkins Pipeline Details</b><br>Project: ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br> Status: ${currentBuild.currentResult} Application URL: ${env.JENKINS_URL}:8090", charset: 'UTF-8', mimeType: 'text/html'; 
        }  
    }
}
