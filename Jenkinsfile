pipeline{
    agent any

    tools{
        jdk  'jdk17'
        maven 'maven3'
    }

    stages {
        stage ("Clean workspace") {
            steps {
                cleanWs()
            }
        }

        stage ("Git Clone") {
            steps {
                git "https://github.com/Ravindra0849/Banking-Api.git"
            }
        }

        stage ("Code Compile") {
            steps {
                sh "mvn compile"
            }
        }
    }

}
