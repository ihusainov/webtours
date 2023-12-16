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


Запуск в docker gitlab ci/cd для самостоятельной сборки образа
------
	
# использовать файл .gitlab-ci.yaml
# Установить на виртуалку gitlab-runner и постоянный диск для конфигурации gitlab-runner-volume
docker run --rm --name gitlab-runner -it -v gitlab-runner-volume:/etc/gitlab-runner -v /var/run/docker.sock:/var/run/docker.sock -d gitlab/gitlab-runner 

# Далее использовать файл config.toml для настройки gitlab ci/cd
# config.toml

```
concurrent = 1
check_interval = 0
shutdown_timeout = 0

[session_server]
  session_timeout = 1800

[[runners]]
  name = "docker-runner"
  url = "https://gitlab.pflb.ru/"
  id = 99
  token = "YOUR GITLAB TOKEN"
  token_obtained_at = 2023-12-07T19:55:23Z
  token_expires_at = 0001-01-01T00:00:00Z
  executor = "docker"
  [runners.docker]
    tls_verify = false
    image = "docker:stable"
    privileged = true
    disable_entrypoint_overwrite = false
    volumes = ["/cachei", "/var/run/docker.sock:/var/run/docker.sock"]
    shm_size = 0
    network_mtu = 0
    memory = "512m"
    memory_swap = "512m"
    memory_reservation = "265m"
    oom_kill_disable = false
    cpuset_cpus = "0,3"
    cpus = "2"
    userns_mode = "host"
    cap_add = ["NET_ADMIN"]
    cap_drop = ["DAC_OVERRIDE"]
    disable_cache = false
```

# Использовать в gitlab файл .gitlab-ci.yaml

```
stages:
  - build
  - test

image: docker:latest

variables:
  DOCKER_DRIVER: overlay2
  
services:
- docker:dind


build:
  stage: build
  script:
    - apk add --no-cache git docker-cli
    - git clone https://github.com/ihusainov/webtours.git
    - cd webtours
    - docker build -t webtours:v2 .
    - docker run --privileged --rm --name webtours -p 8085:80 -d webtours:v2


unit tests:
  stage: test
  script:
    - apk add --no-cache curl
    - curl http://localhost:8085
```
