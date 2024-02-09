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