pipeline {
    agent any
    
    tools {
        jdk 'JDK11'
        maven 'Maven3'
    }
    
    environment {
        SCANNER_HOME = tool 'Vish-Sonar-Scanner'
    }

    stages {
        stage('Git Checkout') {
            steps {
                git 'https://github.com/devopsvish/BoardGameListingWebApp.git'
            }
        }
        
        stage('Maven Package') {
            steps {
                sh 'git checkout sonar-analysis'
                sh 'mvn clean package'
            }
        }
        
        stage('Sonar Analysis') {
            steps {
                withSonarQubeEnv('Vish-Sonar-Server') {
                    sh '''
                        $SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectName=BoardGameList \
                        -Dsonar.projectKey=BoardGameList \
                        -Dsonar.sources=src \
                        -Dsonar.branch.name=sonar-analysis \
                        -Dsonar.java.binaries=target/classes
                    '''
                }
            }
        }
    }
}
