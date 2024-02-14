# KubeConfigPath: the kubeconfig file for the destination k8s cluster
NAMESPACE="arc-systems"
helm --kubeconfig ${KubeConfigPath} install arc \
    --namespace "${NAMESPACE}" \
    --create-namespace \
    ./gha-runner-scale-set-controller