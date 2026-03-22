APP_NAME   := kvstore
IMAGE      := kuberedis-kvstore
TAG        := latest
NAMESPACE  := kuberedis
KIND_CLUSTER := kuberedis

# ── Go ───────────────────────────────────────────────
.PHONY: build test
build:
	go build -o bin/$(APP_NAME) ./cmd/kvstore

test:
	go test ./...

# ── Docker ───────────────────────────────────────────
.PHONY: docker-build kind-load
docker-build:
	docker build -t $(IMAGE):$(TAG) .

kind-load: docker-build
	kind load docker-image $(IMAGE):$(TAG) --name $(KIND_CLUSTER)

# ── Kind cluster ─────────────────────────────────────
.PHONY: kind-create kind-delete
kind-create:
	kind create cluster --name $(KIND_CLUSTER)

kind-delete:
	kind delete cluster --name $(KIND_CLUSTER)

# ── Kubernetes ───────────────────────────────────────
.PHONY: deploy teardown status
deploy:
	kubectl apply -f deploy/base/namespace.yaml
	kubectl apply -f deploy/base/configmap.yaml
	kubectl apply -f deploy/base/secret.yaml
	kubectl apply -f deploy/base/deployment.yaml
	kubectl apply -f deploy/base/service.yaml

teardown:
	kubectl delete namespace $(NAMESPACE) --ignore-not-found

status:
	kubectl get all -n $(NAMESPACE)

# ── Convenience ──────────────────────────────────────
.PHONY: port-forward logs
port-forward:
	kubectl port-forward -n $(NAMESPACE) svc/$(APP_NAME) 8080:80

logs:
	kubectl logs -n $(NAMESPACE) -l app=$(APP_NAME) --tail=50 -f

# ── Full workflow ────────────────────────────────────
.PHONY: up down
up: kind-create kind-load deploy
	@echo "Cluster ready. Run 'make port-forward' then curl http://localhost:8080/health"

down: teardown kind-delete
