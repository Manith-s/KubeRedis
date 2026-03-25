APP_NAME     := kvstore
IMAGE        := kuberedis-kvstore
TAG          := latest
NAMESPACE    := kuberedis
KIND_CLUSTER := kuberedis
CHART_DIR    := deploy/charts/kuberedis
RELEASE      := kuberedis

# ── Go ───────────────────────────────────────────────
.PHONY: build
build:
	go build -o bin/$(APP_NAME) ./cmd/kvstore

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

# ── Redis (StatefulSet) ─────────────────────────────
.PHONY: deploy-redis teardown-redis redis-status
deploy-redis:
	kubectl apply -f deploy/base/namespace.yaml
	kubectl apply -f deploy/base/redis-configmap.yaml
	kubectl apply -f deploy/base/redis-headless-service.yaml
	kubectl apply -f deploy/base/redis-statefulset.yaml
	@echo "Waiting for redis-0 to become ready..."
	kubectl rollout status statefulset/redis -n $(NAMESPACE) --timeout=120s

teardown-redis:
	kubectl delete statefulset redis -n $(NAMESPACE) --ignore-not-found
	kubectl delete service redis-headless -n $(NAMESPACE) --ignore-not-found
	kubectl delete configmap redis-config -n $(NAMESPACE) --ignore-not-found
	kubectl delete pvc -l app=redis -n $(NAMESPACE) --ignore-not-found

redis-status:
	@echo "=== StatefulSet ==="
	kubectl get statefulset redis -n $(NAMESPACE)
	@echo ""
	@echo "=== Pods ==="
	kubectl get pods -l app=redis -n $(NAMESPACE) -o wide
	@echo ""
	@echo "=== PVCs ==="
	kubectl get pvc -l app=redis -n $(NAMESPACE)

redis-cli:
	kubectl exec -it redis-0 -n $(NAMESPACE) -- redis-cli

# ── Kubernetes (full stack) ──────────────────────────
.PHONY: deploy teardown status
deploy: deploy-redis
	kubectl apply -f deploy/base/configmap.yaml
	kubectl apply -f deploy/base/secret.yaml
	kubectl apply -f deploy/base/deployment.yaml
	kubectl apply -f deploy/base/service.yaml

teardown:
	kubectl delete namespace $(NAMESPACE) --ignore-not-found

status:
	@echo "=== All Resources ==="
	kubectl get all -n $(NAMESPACE)
	@echo ""
	@echo "=== PVCs ==="
	kubectl get pvc -n $(NAMESPACE)

# ── Convenience ──────────────────────────────────────
.PHONY: port-forward logs
port-forward:
	kubectl port-forward -n $(NAMESPACE) svc/$(APP_NAME) 8080:80

logs:
	kubectl logs -n $(NAMESPACE) -l app=$(APP_NAME) --tail=50 -f

redis-logs:
	kubectl logs -n $(NAMESPACE) -l app=redis --tail=50 -f

# ── Helm ─────────────────────────────────────────────
.PHONY: helm-lint helm-template helm-install helm-upgrade helm-uninstall
.PHONY: helm-install-dev helm-install-staging

helm-lint:
	helm lint $(CHART_DIR)

helm-template:
	helm template $(RELEASE) $(CHART_DIR) --namespace $(NAMESPACE)

helm-install: kind-load
	helm install $(RELEASE) $(CHART_DIR) --namespace $(NAMESPACE) --create-namespace

helm-upgrade:
	helm upgrade $(RELEASE) $(CHART_DIR) --namespace $(NAMESPACE)

helm-uninstall:
	helm uninstall $(RELEASE) --namespace $(NAMESPACE)

helm-install-dev: kind-load
	helm install $(RELEASE) $(CHART_DIR) \
		--namespace $(NAMESPACE)-dev --create-namespace \
		-f $(CHART_DIR)/values-dev.yaml

helm-install-staging: kind-load
	helm install $(RELEASE) $(CHART_DIR) \
		--namespace $(NAMESPACE)-staging --create-namespace \
		-f $(CHART_DIR)/values-staging.yaml

# ── Full workflow ────────────────────────────────────
.PHONY: up down helm-up helm-down
up: kind-create kind-load deploy
	@echo "Cluster ready. Run 'make port-forward' then curl http://localhost:8080/health"

helm-up: kind-create kind-load helm-install
	@echo "Cluster ready (Helm). Run 'make port-forward' then curl http://localhost:8080/health"

down: teardown kind-delete

helm-down: helm-uninstall kind-delete
