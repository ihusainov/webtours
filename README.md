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
	
Использовать файл .gitlab-ci.yaml

Установить на виртуалку gitlab-runner и постоянный диск для конфигурации gitlab-runner-volume
```
docker run --rm --name gitlab-runner -it -v gitlab-runner-volume:/etc/gitlab-runner -v /var/run/docker.sock:/var/run/docker.sock -d gitlab/gitlab-runner 
```

Далее использовать файл config.toml для настройки gitlab ci/cd
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

Использовать в gitlab файл .gitlab-ci.yaml

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

Запуск в kubernetes gitlab ci/cd для самостоятельной сборки образа
------
Создать файл в каталоге где установлен heml

values.yaml
```
## GitLab Runner Image
##
## By default it's using registry.gitlab.com/gitlab-org/gitlab-runner:alpine-v{VERSION}
## where {VERSION} is taken from Chart.yaml from appVersion field
##
## ref: https://gitlab.com/gitlab-org/gitlab-runner/container_registry/29383?orderBy=NAME&sort=asc&search[]=alpine-v&search[]=
##
## Note: If you change the image to the ubuntu release
##       don't forget to change the securityContext;
##       these images run on different user IDs.
##
image:
  registry: registry.gitlab.com
  image: gitlab-org/gitlab-runner
  # tag: alpine-v11.6.0

## When using GitLab Runner Helm Chart with gitlab-runner-ubi-images (https://gitlab.com/gitlab-org/ci-cd/gitlab-runner-ubi-images/container_registry)
## the installation fails because dumb-init is not packaged in the image. However, the tini is present.
## This configuration will allow gitlab-runner-ubi-images users to explicitly enabled the use of `tini` instead of `dumb-init`
useTini: false

## Specify a imagePullPolicy for the main runner deployment
## 'Always' if imageTag is 'latest', else set to 'IfNotPresent'
##
## Note: it does not apply to job containers launched by this executor.
## Use `pull_policy` in [runners.kubernetes] to change it.
##
## ref: https://kubernetes.io/docs/concepts/containers/images/#pre-pulled-images
##
imagePullPolicy: IfNotPresent

## Specifying ImagePullSecrets on a Pod
## Kubernetes supports specifying container image registry keys on a Pod.
## ref: https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod
##
# imagePullSecrets:
#   - name: "image-pull-secret"

## Timeout, in seconds, for liveness and readiness probes of a runner pod.
# probeTimeoutSeconds: 3

## How many runner pods to launch.
##
replicas: 1

## How many old ReplicaSets for this Deployment you want to retain
# revisionHistoryLimit: 10

## The GitLab Server URL (with protocol) that want to register the runner against
## ref: https://docs.gitlab.com/runner/commands/index.html#gitlab-runner-register
##
gitlabUrl: https://gitlab.pflb.ru/

## DEPRECATED: The Registration Token for adding new Runners to the GitLab Server.
##
## ref: https://docs.gitlab.com/ee/ci/runners/new_creation_workflow.html
##
# runnerRegistrationToken: ""

## The Runner Token for adding new Runners to the GitLab Server. This must
## be retrieved from your GitLab Instance. It is token of already registered runner.
## ref: (we don't yet have docs for that, but we want to use existing token)
##
runnerToken: "YOUR GITLAB TOKEN"
#

## Unregister all runners before termination
##
## Updating the runner's chart version or configuration will cause the runner container
## to be terminated and created again. This may cause your Gitlab instance to reference
## non-existant runners. Un-registering the runner before termination mitigates this issue.
## ref: https://docs.gitlab.com/runner/commands/index.html#gitlab-runner-unregister
##
# unregisterRunners: true

## When stopping the runner, give it time to wait for its jobs to terminate.
##
## Updating the runner's chart version or configuration will cause the runner container
## to be terminated with a graceful stop request. terminationGracePeriodSeconds
## instructs Kubernetes to wait long enough for the runner pod to terminate gracefully.
## ref: https://docs.gitlab.com/runner/commands/#signals
terminationGracePeriodSeconds: 3600

## Set the certsSecretName in order to pass custom certficates for GitLab Runner to use
## Provide resource name for a Kubernetes Secret Object in the same namespace,
## this is used to populate the /home/gitlab-runner/.gitlab-runner/certs/ directory
## ref: https://docs.gitlab.com/runner/configuration/tls-self-signed.html#supported-options-for-self-signed-certificates-targeting-the-gitlab-server
##
# certsSecretName:

## Configure the maximum number of concurrent jobs
## ref: https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-global-section
##
concurrent: 10

## Number of seconds until the forceful shutdown operation times out and exits the process.
## ref: https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-global-section
##
shutdown_timeout: 0

## Defines in seconds how often to check GitLab for a new builds
## ref: https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-global-section
##
checkInterval: 30

## Configure GitLab Runner's logging level. Available values are: debug, info, warn, error, fatal, panic
## ref: https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-global-section
##
logLevel: debug

## Configure GitLab Runner's logging format. Available values are: runner, text, json
## ref: https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-global-section
##
# logFormat:

## Configure GitLab Runner's Sentry DSN.
## ref https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-global-section
##
# sentryDsn:

## A custom bash script that will be executed prior to the invocation
## gitlab-runner process
#
#preEntrypointScript: |
#  echo "hello"

## Specify whether the runner should start the session server.
## Defaults to false
## ref:
##
## When sessionServer is enabled, the user can either provide a public publicIP
## or rely on the external IP auto discovery
## When a serviceAccountName is used with the automounting to the pod disable,
## we recommend the usage of the publicIP
sessionServer:
  enabled: false
  # annotations: {}
  # timeout: 1800
  # internalPort: 8093
  # externalPort: 9000
  # publicIP: ""
  # loadBalancerSourceRanges:
  #   - 1.2.3.4/32

## For RBAC support:
#rbac:
#  create: false
rbac:
  create: true
  rules:
   - resources: ["configmaps", "pods", "pods/attach", "secrets", "services"]
     verbs: ["get", "list", "watch", "create", "patch", "update", "delete"]
   - apiGroups: [""]
     resources: ["pods/exec"]
     verbs: ["create", "patch", "delete"]

  ## Define list of rules to be added to the rbac role permissions.
  ## Each rule supports the keys:
  ## - apiGroups: default "" (indicates the core API group) if missing or empty.
  ## - resources: default "*" if missing or empty.
  ## - verbs: default "*" if missing or empty.
  ##
  ## Read more about the recommended rules on the following link
  ##
  ## ref: https://docs.gitlab.com/runner/executors/kubernetes.html#configure-runner-api-permissions
  ##
  rules: []
  # - resources: ["configmaps", "events", "pods", "pods/attach", "pods/exec", "secrets", "services"]
  #   verbs: ["get", "list", "watch", "create", "patch", "update", "delete"]
  # - apiGroups: [""]
  #   resources: ["pods/exec"]
  #   verbs: ["create", "patch", "delete"]
  # - apiGroups: [""]
  #   resources: ["pods/log"]
  #   verbs: ["get"]

  ## Run the gitlab-bastion container with the ability to deploy/manage containers of jobs
  ## cluster-wide or only within namespace
  clusterWideAccess: false

  ## Use the following Kubernetes Service Account name if RBAC is disabled in this Helm chart (see rbac.create)
  ##
  # serviceAccountName: default

  ## Specify annotations for Service Accounts, useful for annotations such as eks.amazonaws.com/role-arn.
  ## Values may refer other values as the _tpl_ function is implicitly applied. Mind the quotes when using this, e.g.
  ## serviceAccountAnnotations:
  ##   eks.amazonaws.com/role-arn: "arn:aws:iam::{{ .Values.global.accountId }}:role/{{ .Values.global.iamRoleName }}"
  ##
  ## ref: https://docs.aws.amazon.com/eks/latest/userguide/associate-service-account-role.html
  ##
  # serviceAccountAnnotations: {}

  ## Use podSecurity Policy
  ## ref: https://kubernetes.io/docs/concepts/policy/pod-security-policy/
  podSecurityPolicy:
    enabled: false
    resourceNames:
    - gitlab-runner

  ## Specify one or more imagePullSecrets used for pulling the runner image
  ##
  ## ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#add-imagepullsecrets-to-a-service-account
  ##
  # imagePullSecrets: []

## Configure integrated Prometheus metrics exporter
##
## ref: https://docs.gitlab.com/runner/monitoring/#configuration-of-the-metrics-http-server
##
metrics:
  enabled: false

  ## Define a name for the metrics port
  ##
  portName: metrics

  ## Provide a port number for the integrated Prometheus metrics exporter
  ##
  port: 9252

  ## Configure a prometheus-operator serviceMonitor to allow autodetection of
  ## the scraping target. Requires enabling the service resource below.
  ##
  serviceMonitor:
    enabled: false

    ## Provide additional labels to the service monitor resource
    ##
    ## labels: {}

    ## Provide annotations to the service monitor ressource
    ##
    ## annotations: {}

    ## Define a scrape interval (otherwise prometheus default is used)
    ##
    ## ref: https://prometheus.io/docs/prometheus/latest/configuration/configuration/#scrape_config
    ##
    # interval: ""

    ## Specify the scrape protocol scheme e.g., https or http
    ##
    # scheme: "http"

    ## Supply a tls configuration for the service monitor
    ##
    ## ref: https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/charts/crds/crds/crd-servicemonitors.yaml
    ##
    # tlsConfig: {}

    ## The URI path where prometheus metrics can be scraped from
    ##
    # path: "/metrics"

    ## A list of MetricRelabelConfigs to apply to samples before ingestion
    ##
    ## ref: https://prometheus.io/docs/prometheus/latest/configuration/configuration/#metric_relabel_configs
    ##
    # metricRelabelings: []

    ## A list of RelabelConfigs to apply to samples before scraping
    ##
    ## ref: https://prometheus.io/docs/prometheus/latest/configuration/configuration/#relabel_config
    ##
    ## relabelings: []

## Configure a service resource e.g., to allow scraping metrics via
## prometheus-operator serviceMonitor
service:
  enabled: false

  ## Provide additonal labels for the service
  ##
  # labels: {}

  ## Provide additonal annotations for the service
  ##
  # annotations: {}

  ## Define a specific ClusterIP if you do not want a dynamic one
  ##
  ## ref: https://kubernetes.io/docs/concepts/services-networking/service/#choosing-your-own-ip-address
  ##
  # clusterIP: ""

  ## Define a list of one or more external IPs for this service
  ##
  ## ref: https://kubernetes.io/docs/concepts/services-networking/service/#external-ips
  ##
  # externalIPs: []

  ## Provide a specific loadbalancerIP e.g., of an external Loadbalancer
  ##
  ## ref: https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer
  ##
  # loadBalancerIP: ""

  ## Provide a list of source IP ranges to have access to this service
  ##
  ## ref: https://kubernetes.io/docs/concepts/services-networking/service/#aws-nlb-support
  ##
  # loadBalancerSourceRanges: []

  ## Specify the service type e.g., ClusterIP, NodePort, LoadBalancer or ExternalName
  ##
  ## ref: https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types
  ##
  type: ClusterIP

  ## Specify the services metrics nodeport if you use a service of type nodePort
  ##
  # metrics:

    ## Specify the node port under which the prometheus metrics of the runner are made
    ## available.
    ##
    ## ref: https://kubernetes.io/docs/concepts/services-networking/service/#nodeport
    ##
    # nodePort: ""

  ## Provide a list of additional ports to be exposed by this service
  ##
  ## ref: https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service
  ##
  # additionalPorts: []

## Configuration for the Pods that the runner launches for each new job
##
runners:
  # runner configuration, where the multi line strings is evaluated as
  # template so you can specify helm values inside of it.
  #
  # tpl: https://helm.sh/docs/howto/charts_tips_and_tricks/#using-the-tpl-function
  # runner configuration: https://docs.gitlab.com/runner/configuration/advanced-configuration.html
#  config: |
#    [[runners]]
#      [runners.kubernetes]
#        namespace = "{{.Release.Namespace}}"
#        image = "alpine"
  config: |
    [[runners]]
      [runners.kubernetes]
        namespace = "{{.Release.Namespace}}"
        image = "docker:latest"
        privileged = true
        [[runners.kubernetes.volumes.host_path]]
          name = "docker"
          mount_path = "/var/run/docker.sock"

  ## Absolute path for an existing runner configuration file
  ## Can be used alongside "volumes" and "volumeMounts" to use an external config file
  ## Active if runners.config is empty or null
  configPath: ""

  ## Which executor should be used
  ##
  # executor: kubernetes

  ## DEPRECATED: Specify whether the runner should be locked to a specific project: true, false.
  ##
  ## ref: https://docs.gitlab.com/ee/ci/runners/new_creation_workflow.html
  ##
  # locked: true

  ## DEPRECATED: Specify the tags associated with the runner. Comma-separated list of tags.
  ##
  ## ref: https://docs.gitlab.com/ee/ci/runners/new_creation_workflow.html
  ##
  # tags: ""

  ## Specify the name for the runner.
  ##
  # name: ""

  ## DEPRECATED:Specify the maximum timeout (in seconds) that will be set for job when using this Runner
  ##
  ## ref: https://docs.gitlab.com/ee/ci/runners/new_creation_workflow.html
  ##
  # maximumTimeout: ""

  ## DEPRECATED: Specify if jobs without tags should be run.
  ##
  ## ref: https://docs.gitlab.com/ee/ci/runners/new_creation_workflow.html
  ##
  # runUntagged: true

  ## DEPRECATED: Specify whether the runner should only run protected branches.
  ##
  ## ref: https://docs.gitlab.com/ee/ci/runners/new_creation_workflow.html
  ##
  # protected: true

  ## The name of the secret containing runner-token and runner-registration-token
  # secret: gitlab-runner

  ## Distributed runners caching
  ## ref: https://docs.gitlab.com/runner/configuration/autoscale.html#distributed-runners-caching
  ##
  ## If you want to use s3 based distributing caching:
  ## First of all you need to uncomment General settings and S3 settings sections.
  ##
  ## Create a secret 's3access' containing 'accesskey' & 'secretkey'
  ## ref: https://aws.amazon.com/blogs/security/wheres-my-secret-access-key/
  ##
  ## $ kubectl create secret generic s3access \
  ##   --from-literal=accesskey="YourAccessKey" \
  ##   --from-literal=secretkey="YourSecretKey"
  ## ref: https://kubernetes.io/docs/concepts/configuration/secret/
  ##
  ## If you want to use gcs based distributing caching:
  ## First of all you need to uncomment General settings and GCS settings sections.
  ##
  ## Access using credentials file:
  ## Create a secret 'google-application-credentials' containing your application credentials file.
  ## ref: https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnerscachegcs-section
  ## You could configure
  ## $ kubectl create secret generic google-application-credentials \
  ##   --from-file=gcs-application-credentials-file=./path-to-your-google-application-credentials-file.json
  ## ref: https://kubernetes.io/docs/concepts/configuration/secret/
  ##
  ## Access using access-id and private-key:
  ## Create a secret 'gcsaccess' containing 'gcs-access-id' & 'gcs-private-key'.
  ## ref: https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnerscachegcs-section
  ## You could configure
  ## $ kubectl create secret generic gcsaccess \
  ##   --from-literal=gcs-access-id="YourAccessID" \
  ##   --from-literal=gcs-private-key="YourPrivateKey"
  ## ref: https://kubernetes.io/docs/concepts/configuration/secret/
  ##
  ## If you want to use Azure-based distributed caching:
  ## First, uncomment General settings.
  ##
  ## Create a secret 'azureaccess' containing 'azure-account-name' & 'azure-account-key'
  ## ref: https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction
  ##
  ## $ kubectl create secret generic azureaccess \
  ##   --from-literal=azure-account-name="YourAccountName" \
  ##   --from-literal=azure-account-key="YourAccountKey"
  ## ref: https://kubernetes.io/docs/concepts/configuration/secret/

  cache: {}
    ## S3 the name of the secret.
    # secretName: s3access
    ## Use this line for access using gcs-access-id and gcs-private-key
    # secretName: gcsaccess
    ## Use this line for access using google-application-credentials file
    # secretName: google-application-credentials
    ## Use this line for access using Azure with azure-account-name and azure-account-key
    # secretName: azureaccess

## Specify the name of the scheduler which used to schedule runner pods.
## Kubernetes supports multiple scheduler configurations.
## ref: https://kubernetes.io/docs/reference/scheduling
# schedulerName: "my-custom-scheduler"

## Configure securitycontext for the main container
## ref: https://kubernetes.io/docs/concepts/security/pod-security-standards/
##
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: false
  runAsNonRoot: true
  privileged: false
  capabilities:
    drop: ["ALL"]

## Configure securitycontext valid for the whole pod
## ref: https://kubernetes.io/docs/concepts/security/pod-security-standards/
##
podSecurityContext:
  runAsUser: 100
  # runAsGroup: 65533
  fsGroup: 65533
  # supplementalGroups: [65533]

  ## Note: values for the ubuntu image:
  # runAsUser: 999
  # fsGroup: 999

## Configure resource requests and limits
## ref: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
##
resources: {}
  # limits:
  #   memory: 256Mi
  #   cpu: 200m
  #   ephemeral-storage: 512Mi
  # requests:
  #   memory: 128Mi
  #   cpu: 100m
  #   ephemeral-storage: 256Mi

## Affinity for pod assignment
## Ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity
##
affinity: {}

## TopologySpreadConstraints for pod assignment
## Ref: https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/
##
topologySpreadConstraints: {}
  # Example: The gitlab runner should be evenly spread across zones
  # - maxSkew: 1
  #   topologyKey: zone
  #   whenUnsatisfiable: DoNotSchedule
  #   labelSelector:
  #     matchLabels:
  #       foo: bar

## Node labels for pod assignment
## ref: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/
##
nodeSelector: {}
  # Example: The gitlab runner manager should not run on spot instances so you can assign
  # them to the regular worker nodes only.
  # node-role.kubernetes.io/worker: "true"

## List of node taints to tolerate (requires Kubernetes >= 1.6)
## Ref: https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/
##
tolerations: []
  # Example: Regular worker nodes may have a taint, thus you need to tolerate the taint
  # when you assign the gitlab runner manager with nodeSelector or affinity to the nodes.
  # - key: "node-role.kubernetes.io/worker"
  #   operator: "Exists"

## Configure environment variables that will be present when the registration command runs
## This provides further control over the registration process and the config.toml file
## ref: `gitlab-runner register --help`
## ref: https://docs.gitlab.com/runner/configuration/advanced-configuration.html
##
# envVars:
#   - name: RUNNER_EXECUTOR
#     value: kubernetes

## list of hosts and IPs that will be injected into the pod's hosts file
hostAliases: []
  # Example:
  # - ip: "127.0.0.1"
  #   hostnames:
  #   - "foo.local"
  #   - "bar.local"
  # - ip: "10.1.2.3"
  #   hostnames:
  #   - "foo.remote"
  #   - "bar.remote"

## Annotations to be added to deployment
##
deploymentAnnotations: {}
  # Example:
  # downscaler/uptime: <my_uptime_period>

## Labels to be added to deployment
##
deploymentLabels: {}
  # Example:
  # owner.team: <my_cool_team>

## Annotations to be added to manager pod
##
podAnnotations: {}
  # Example:
  # iam.amazonaws.com/role: <my_role_arn>

## Labels to be added to manager pod
##
podLabels: {}
  # Example:
  # owner.team: <my_cool_team>

## HPA support for custom metrics:
## This section enables runners to autoscale based on defined custom metrics.
## In order to use this functionality, Need to enable a custom metrics API server by
## implementing "custom.metrics.k8s.io" using supported third party adapter
## Example: https://github.com/directxman12/k8s-prometheus-adapter
##
#hpa: {}
  # minReplicas: 1
  # maxReplicas: 10
  # metrics:
  # - type: Pods
  #   pods:
  #     metricName: gitlab_runner_jobs
  #     targetAverageValue: 400m

## Configure priorityClassName for manager pod. See k8s docs for more info on how pod priority works:
##  https://kubernetes.io/docs/concepts/configuration/pod-priority-preemption/
priorityClassName: ""

## Secrets to be additionally mounted to the containers.
## All secrets are mounted through init-runner-secrets volume
## and placed as readonly at /init-secrets in the init container
## and finally copied to an in-memory volume runner-secrets that is
## mounted at /secrets.
secrets: []
  # Example:
  # - name: my-secret
  # - name: myOtherSecret
  #   items:
  #     - key: key_one
  #       path: path_one

## Boolean to turn off the automountServiceAccountToken in the deployment
## ref: https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/#bound-service-account-token-volume
##
# automountServiceAccountToken: false

## Additional config files to mount in the containers in `/configmaps`.
##
## Please note that a number of keys are reserved by the runner.
## See https://gitlab.com/gitlab-org/charts/gitlab-runner/-/blob/main/templates/configmap.yaml
## for a current list.
configMaps: {}

## Additional volumeMounts to add to the runner container
##
volumeMounts: []
  # Example:
  # - name: my-volume
  #   mountPath: /mount/path

## Additional volumes to add to the runner deployment
##
volumes: []
  # Example:
  # - name: my-volume
  #   persistentVolumeClaim:
  #     claimName: my-pvc
```

Далее выполнить команду

```
helm install --namespace default gitlab-runner -f values.yaml gitlab/gitlab-runner

# Если внести изменения в файл values.yaml то потом применить изменения
helm upgrade --namespace default gitlab-runner -f values.yaml gitlab/gitlab-runner
```

