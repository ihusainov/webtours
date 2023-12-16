Web Tours
=========

Тесовое приложение [микрофокус web tours](https://marketplace.microfocus.com/appdelivery/content/web-tours-sample-application)  
Используется для обучения LoadRunner и JMeter




Запуск в docker готового образа
------
```
У вас должен быть установлен docker и ваш пользователь должен входить в группу docker
$ sudo docker pull ihusainov/webtours:v2
$ sudo docker run --rm --name webtours -p 8085:80 -d ihusainov/webtours:v2
$ http://127.0.0.1:8085/WebTours
```

Запуск в docker для самостоятельной сборки образа
------
```
$ git clone https://github.com/ihusainov/webtours.git
$ cd webtours

Отредактировать файл Dockerfile с необходимыми изменениями но можно ничего не менять.

$ sudo docker build -t webtours:v1 .
$ sudo docker run --rm --name webtours -p 8085:80 -d webtours:v1
$ http://127.0.0.1:8085/WebTours
```



