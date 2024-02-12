IMG ?= container-registry.test.betsson.tech/betsson/arc-test
IMG_TAG ?= v0.0.1
RUNNER_VERSION ?= 2.313.0

docker-build:
	docker build \
	--build-arg RUNNER_VERSION=${RUNNER_VERSION} \
	-t ${IMG}:${IMG_TAG} .