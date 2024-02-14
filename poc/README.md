# Actions Runner Controller (ARC)

## Synopsis

Actions Runner Controller dedicates to build connections between github workflows and Kubernetes:  
- Build github runners as pods managed by `RunnerSet` in Kubernetes;
- Register the `RunnerSet` as the action runner in github runner groups;
- Listen to the github actions with specific `runs-on` label in github;
- Receive the github actions in `RunnerSet` and execute github actions in the relevant pod runners;
- Send the relevant info such as logs back to the source github actions;

> `RunnerSet`: A CRD defined in Kubernetes, could be transferred to series of pods, a single pod serves as a single runner to execte a single job from github actions.

The project is from the open-source project [actions/actions-runner-controller](https://github.com/actions/actions-runner-controller).

And the currently used release is [gha-runner-scale-set-0.8.2](https://github.com/actions/actions-runner-controller/releases/tag/gha-runner-scale-set-0.8.2). 

## Architecture

ARC is a system based on the [CRD && Operator](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/) in Kubernetes.

In which there are some components deployed in Kubernetes.

### Action Runner Controller

Action Runner Controller is a deployment that servers as the Operators which reconcile series of `CR` in the system. 

It is deployed from the runner [gha-runner-scale-set-controller](./gha-runner-scale-set-controller) helm chart as a global server and the brain of the whole system.

Generally, `Action Runner Controller` is deployed in the namespace `arc-systems` as the system component.


### Runner Set Listener

Runner Set Listener is a pod that serves as an agent which listens to Github to fetch the github actions and send info( logs, status, etc. ) back.

It is managed by the CR `RunnerSet` which is deployed from the [gha-runner-scale-set](./gha-runner-scale-set) helm chart.

From the view of Github, a single `Runner Set Listener` is registered as a single runner with a sinle label(the same as the name) in a single runner group( the `Default` by default ).

Generally, `Runner Set Listener` is deployed in the namespace `arc-systems` along with `Action Runner Controller` as the system component.

### Runner

Runner is a pod that executes the job from github actions, which is managed by the `Runner Set Listener`.

When the `Runner Set Listener` receives an action job from github, it will try to scale up a new pod as the runner to execute the action job.

And the count of the pod runners should be between a range which could be set in the helm chart by the variables `minRunners` and `maxRunners`.

Generally, `Runner` is deployed in the namespace defined in the deployment fron [gha-runner-scale-set](./gha-runner-scale-set) as the worker component.


## Installation

### Prerequisites

In order to use ARC, ensure you have the following:  
- A Kubernetes cluster；
- Kubectl: The installation could be found in [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl);
- Helm 3: The installation could be found in [Installing Helm](https://helm.sh/docs/intro/install/).
- KubeConfigPath: please make sure The kubeconfig path is exported in the terminal.
- TestToken: A valid github token(classic) with the admin access is required, and please export it as the Environment in the terminal.

> The github token could be validated referring to [Authenticating to the GitHub API](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/authenticating-to-the-github-api#deploying-using-personal-access-token-classic-authentication)

### Install Action Runner Controller (ARC) 

The ARC could be installed from the helm charts [gha-runner-scale-set-controller](./gha-runner-scale-set-controller).

For convenience, the shell is stored in the script [setup-arc](./setup-arc.sh) as:  
```bash
# KubeConfigPath: the kubeconfig file for the destination k8s cluster
NAMESPACE="arc-systems"
helm --kubeconfig ${KubeConfigPath} install arc \
    --namespace "${NAMESPACE}" \
    --create-namespace \
    ./gha-runner-scale-set-controller
```

Have a check in the Kubernetes:
```bash
# check the helm installation
$ helm --kubeconfig ${KubeConfigPath} list -A
##The console should be as:
NAME    NAMESPACE       REVISION	UPDATED                                	STATUS  	CHART                                     APP VERSION
arc     arc-systems       1       2024-02-09 10:19:11.79208 +0100 CET    	deployed	gha-runner-scale-set-controller-0.8.2       0.8.2

# check the pods in arc-system namespace
$ kubectl --kubeconfig ${KubeConfigPath} list -A -n arc-systems get po
##The console should be as:
NAME                                     READY   STATUS    RESTARTS   AGE
arc-gha-rs-controller-769795fb74-pwmvs   1/1     Running   0          12m
```


### Install Runner Set

The Runner Set could be installed from the helm charts [gha-runner-scale-set](./gha-runner-scale-set).

The Runner group could be configured with the variable `runnerGroup` in the [values.yaml](./gha-runner-scale-set/values.yaml),  
or set in the helm command with the flag `--set runnerGroup=${RunnerGroupName}`.


Here, the `Runner group` is set to `ARC-POC` in `values.yaml` for POC.


For convenience, the shell is stored in the script [setup-arc-runner-set](./setup-arc-runner-set.sh) as:
```bash
# KubeConfigPath: the kubeconfig file for the destination k8s cluster
# TestToken: the access token to the github org or repo with saml authenticated.
# INSTALLATION_NAME is the arc-runner-set name which is used as the only label for 'runs-on' in workflow.job
INSTALLATION_NAME="arc-runner-set"
NAMESPACE="arc-runners"
GITHUB_CONFIG_URL="https://github.com/BetssonGroup"
GITHUB_PAT=${TestToken}
helm --kubeconfig ${KubeConfigPath} install "${INSTALLATION_NAME}" \
    --namespace "${NAMESPACE}" \
    --create-namespace \
    --set githubConfigUrl="${GITHUB_CONFIG_URL}" \
    --set githubConfigSecret.github_token="${GITHUB_PAT}" \
    ./gha-runner-scale-set
```

Have a check in the Kubernetes:
```bash
# check the helm installation
$ helm --kubeconfig ${KubeConfigPath} list -A
##The console should be as:
NAME            NAMESPACE     REVISION	UPDATED                                 STATUS  	CHART                                    APP VERSION
arc             arc-systems   1       	2024-02-12 09:15:20.436603 +0100 CET   	deployed	gha-runner-scale-set-controller-0.8.2    0.8.2
arc-runner-set  arc-runners   1       	2024-02-12 09:18:11.434501 +0100 CET   	deployed	gha-runner-scale-set-0.8.2               0.8.2

# check the pods in arc-system namespace
$ kubectl --kubeconfig ${KubeConfigPath} -n arc-systems get po
##The console should be as:
NAME                                     READY   STATUS    RESTARTS   AGE
arc-gha-rs-controller-769795fb74-pwmvs   1/1     Running   0          12m
arc-runner-set-754b578d-listener         1/1     Running   0          10m
```

Have a check on Github:

Please open github on web, and found the `Runner groups` in:  
> Organizatin >> Settings >> Actions >> Runner groups

And look for the runner in the specific `Runner groups`, the default `Runner groups` is named as `Default`.

> Of cource more `Runner Set` could be installed,  
the script [setup-arc-runner-set1](./setup-arc-runner-set1.sh) will install a `Runner Set` named 'arc-runner-set1' in the namespace `arc-runners1`


## Using ARC in Github Actions

When finished the installation of ARC, we could use the ARC runner for github actions.

### Add Repository in Runner Group

If the runner is registered to the runner group requiring repository access, please ensure that the repository is added in the Runner group as:  
> Runner groups >> ${ RunnerGroupName} >> Repository access >> Selected repositories >> ${SecetedRepositoryName}

### Using Runner Set Name in Github Actions

Please prepare a workfolw in the selected repository, add use the name of runner set as the only lable as `runs-on` like:

```yaml
name: Agent Select

on:
  workflow_dispatch:
    inputs:
      INSTALLATION_NAME:
        type: choice
        description: "Installation name"
        required: true
        default: arc-runner-set
        options:
          - arc-runner-set
          - arc-runner-set1

jobs:
  build:
    runs-on: ${{ inputs.INSTALLATION_NAME }}
    steps:
      - name: Print GH Repo Name
        run: echo ${GITHUB_REPOSITORY#*/}
    
      - name: Test checkout v2
        uses: actions/checkout@v2

```

Run the workflow with the runner `arc-runner-set` and watch happened in Kubernetes:
```bash
# check the pods in arc-runners namespace
$ kubectl --kubeconfig ${KubeConfigPath} -n arc-runners get po --watch
##The console should be as:
NAME                                READY   STATUS    RESTARTS   AGE
arc-runner-set-v4wn8-runner-6dxfg   0/1     Pending   0          1s
arc-runner-set-v4wn8-runner-6dxfg   0/1     Pending   0          1s
arc-runner-set-v4wn8-runner-6dxfg   0/1     ContainerCreating   0          1s
arc-runner-set-v4wn8-runner-6dxfg   1/1     Running             0          4s
arc-runner-set-v4wn8-runner-6dxfg   0/1     Completed           0          19s
arc-runner-set-v4wn8-runner-6dxfg   0/1     Terminating         0          19s
arc-runner-set-v4wn8-runner-jvsvf   0/1     Pending             0          0s
arc-runner-set-v4wn8-runner-jvsvf   0/1     Pending             0          0s
arc-runner-set-v4wn8-runner-jvsvf   0/1     ContainerCreating   0          0s
arc-runner-set-v4wn8-runner-6dxfg   0/1     Terminating         0          21s
arc-runner-set-v4wn8-runner-6dxfg   0/1     Terminating         0          21s
arc-runner-set-v4wn8-runner-6dxfg   0/1     Terminating         0          21s
arc-runner-set-v4wn8-runner-jvsvf   1/1     Running             0          2s
arc-runner-set-v4wn8-runner-jvsvf   1/1     Terminating         0          4s
arc-runner-set-v4wn8-runner-jvsvf   0/1     Terminating         0          5s
arc-runner-set-v4wn8-runner-jvsvf   0/1     Terminating         0          5s
arc-runner-set-v4wn8-runner-jvsvf   0/1     Terminating         0          5s
```

From the lifecycle of the runner pod, we could see the pod runner is created when the test job is received and terminated when the job finished.

The pick-up time is around 30s.

## Customise the Runner Docker Image

### Build Customised Docker Image

The origin docker image used in runner-set is [ghcr.io/actions/actions-runner:latest](https://github.com/actions/runner/pkgs/container/actions-runner),
which is minimised, and many linux command couldn't be used inside.

Therefore, we deceded to build our customised docker images referring to the documents:
  - [Creating your own runner image](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/about-actions-runner-controller#creating-your-own-runner-image)

And the customised Dockerfile and Makefile could be found in [docker-images](./docker-images).

### Use Customised Docker image as the Runner Image

The docker image of the runner pod is defined in the [values.yaml](./gha-runner-scale-set/values.yaml) as:
```yaml
template:
  ……
  spec:
    containers:
      - name: runner
        image: container-registry.test.betsson.tech/betsson/arc-test:v0.0.1
        command: ["/home/runner/run.sh"]
```

Change the `image` to the customised docer image.

And then upgrade the `Runner Set` deployment of the helm chart as the script [upgrade-arc-runner-set.sh](./upgrade-arc-runner-set.sh):  
```bash
# KubeConfigPath: the kubeconfig file for the destination k8s cluster
# TestToken: the access token to the github org or repo with saml authenticated.
# INSTALLATION_NAME is the arc-runner-set name which is used as the only label for 'runs-on' in workflow.job
INSTALLATION_NAME="arc-runner-set"
NAMESPACE="arc-runners"
GITHUB_CONFIG_URL="https://github.com/BetssonGroup"
GITHUB_PAT=${TestToken}
helm --kubeconfig ${KubeConfigPath} upgrade "${INSTALLATION_NAME}" \
    --namespace "${NAMESPACE}" \
    --set githubConfigUrl="${GITHUB_CONFIG_URL}" \
    --set githubConfigSecret.github_token="${GITHUB_PAT}" \
    ./gha-runner-scale-set
```
