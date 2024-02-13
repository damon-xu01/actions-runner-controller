# Actions Runner Controller

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

For more information, please go to [poc/k8s/README.md](./poc/k8s//README.md)