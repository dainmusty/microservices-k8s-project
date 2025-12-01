# 🧾 EKS Infrastructure & GitOps Documentation

## 🗂️ Repository Structure

```
k8s/
├── bootstrap/  # ArgoCD root applications for each environment
│   ├── apps/
│   │   ├── shared-app.yml
│   │   └── app-dev.yml
│   ├── root-app-dev.yml    # ArgoCD App pointing to apps/dev (dev workloads)    
│   └── root-app-prod.yml   # ArgoCD App pointing to apps/prod (prod workloads)
├── shared/                 # Common resources shared by all apps/environments
│   ├── configmap.yml       # Shared config (e.g., mongo URL)
│   ├── secrets.yml         # Shared secrets (e.g., MongoDB credentials)
│   └── namespace.yml
└── apps/                   # Application workloads grouped by environment
    ├── dev/
    │   ├── web-app/        # Web frontend microservice
    │   ├── token-app/
    │   └── mongo/          # MongoDB deployment (not exposed via Ingress)
    └── prod/
```

---

## ✅ ArgoCD App of Apps Structure

* `bootstrap/root-app-dev.yml`: Defines ArgoCD root application pointing to `apps/`.
* `apps/shared-app.yml`: Deploys ConfigMaps, Secrets, and Namespace common to all applications.
* `apps/app-dev.yml`: Deploys individual dev apps (web, token, mongo) under the shared namespace.

---

## ⚙️ Key Kubernetes Manifests

### Shared Namespace

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: fonapp
  labels:
    name: fonapp
    app: fonapp
    environment: dev
    owner: dev-team
    tier: frontend
    version: v1.0.0
```

### Shared Ingress Sample (Web & Token microservice)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: fonapp
  labels:
    app: shared-ingress
    environment: dev
    managed-by: argocd
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
    alb.ingress.kubernetes.io/group.name: web-apps
    alb.ingress.kubernetes.io/healthcheck-path: /
spec:
  ingressClassName: alb
  rules:
    - http:
        paths:
          - path: /web
            pathType: Prefix
            backend:
              service:
                name: web-service
                port:
                  number: 8080
          - path: /token
            pathType: Prefix
            backend:
              service:
                name: frontend-service
                port:
                  number: 8080
```

---

## 🚀 ArgoCD Workflow & Best Practices

### 1. Manual `kubectl apply` for ArgoCD App

Apply the ArgoCD app manifest to register your app:

```bash
kubectl apply -f k8s/dev/fonapp-argocd-app.yaml -n argocd
```

This will let ArgoCD:

* Track the `k8s/fonapp` folder
* Auto-sync changes if `syncPolicy.automated` is enabled
* Self-heal and prune outdated resources

### 2. Improving Sync Triggers

Current: ArgoCD polls every 3 minutes.

Better:

* Enable GitHub → ArgoCD webhook
* Or trigger via CLI:

```yaml
- name: Sync ArgoCD App
  run: |
    argocd login argocd.example.com --username admin --password ${{ secrets.ARGOCD_PASSWORD }} --insecure
    argocd app sync fonapp
```

### 3. Bootstrap (App of Apps Pattern)

Rather than applying every app manually with `kubectl`, use a root app:

```bash
kubectl apply -f k8s/bootstrap/root-app-dev.yml -n argocd
```

This loads:

* `apps/shared-app.yml` (namespaces, secrets, configmaps)
* `apps/app-dev.yml` (individual services)

✅ You apply just ONCE and commit changes to manage everything.

---

## 🧠 Key Differences in GitOps Patterns

| Action                  | Your Current Setup   | Bootstrap Setup                     |
| ----------------------- | -------------------- | ----------------------------------- |
| `kubectl apply` needed  | ✅ Every app manually | ✅ Once (root app)                   |
| Add a new app           | Manual apply         | Just commit                         |
| Auto-management via Git | ✅ Per app            | ✅ For all apps                      |
| Scalable for many apps  | ❌ Not ideal          | ✅ Recommended for multi-team setups |

---

## 🛠️ Summary of Issues Encountered

| Issue                               | Description                                          | Resolution                                                                                                     |
| ----------------------------------- | ---------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| **Namespace conflicts**             | Some apps failed due to missing/misnamed namespace.  | Moved `namespace.yml` to shared folder, deployed via `shared-app.yaml`.                                        |
| **Out-of-order ArgoCD sync**        | Shared resources were missing during app deployment. | Introduced `shared-app.yaml` and used App of Apps to enforce order.                                            |
| **MongoDB exposed via Ingress**     | MongoDB was mistakenly exposed publicly.             | Removed Ingress; Mongo now uses internal-only ClusterIP.                                                       |
| **App structure confusion**         | Apps were loosely organized and inconsistent.        | Standardized layout: `apps/dev/web-app`, `token-app`, `payment-app`, each with own deployment/service/ingress. |
| **Duplicate Namespace Definitions** | Multiple versions caused config drift.               | Unified under one ArgoCD-managed version with labels.                                                          |
| **Manual Syncing of Dependencies**  | Secrets/configs needed to be manually applied.       | Moved to shared-app, managed declaratively via ArgoCD.                                                         |

---

## ✅ ArgoCD Best Practice Summary

| Feature                     | Status    | Comment                                           |
| --------------------------- | --------- | ------------------------------------------------- |
| ArgoCD auto-sync            | ✅         | Defined in app manifests                          |
| GitOps (manifests in Git)   | ✅         | All manifests are version-controlled              |
| Manual apply of Application | ⚠️        | Acceptable for bootstrap; consider using root app |
| ArgoCD webhook integration  | ❌         | Recommended for instant syncs                     |
| argocd CLI sync trigger     | ❌         | Optional alternative to webhook                   |
| Empty commit workaround     | ✅ Removed | Correctly removed as redundant                    |

---
