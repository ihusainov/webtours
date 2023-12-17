Web Tours
=========

Тесовое приложение [микрофокус web tours](https://marketplace.microfocus.com/appdelivery/content/web-tours-sample-application)  
Используется для обучения LoadRunner и JMeter




Запуск jenkins в docker готового образа
------
```
docker run -d -n "jenkins" -v jenkins_home:/var/jenkins_home -p 8080:8080 -p 50000:50000 --restart=on-failure jenkins/jenkins:2.435-jdk17
http://your_ip:8080
```

Тестовый pipeline в jenkins для сборки webtours
------
```
pipeline {
    agent { label('webtours')}

    stages {
        stage('Hello') {
            steps {
                echo 'docker version'
            }
        }
        stage('Checkout'){
            steps{
                git branch: 'fix-deploy-jenkins',
                url: 'https://github.com/ihusainov/webtours.git'
                }
            }
        stage('Build'){
            steps{
                sh 'docker build -t webtours:v1 .'
                sh 'docker run --rm --name webtours -p 8085:80 -d webtours:v1'
            }
        }
    }
}
http://your_ip:8085/WebTours
```



