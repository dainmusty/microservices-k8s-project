# To install argocd on a minikube
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl get pods -n argocd
kubectl port-forward svc/argocd-server -n argocd 8080:80
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode
qRouIH5ZYHyvgTwR

# To test the web-app
Port forward using its container port number (8081)
kubectl port-forward svc/argocd-server -n argocd 8081:80


# Minikube is not able to pull images from dockerhub thus you have to preload the image
Web App
1. docker pull dainmusty/phone-store:latest     # listens on port 80
2. minikube image load dainmusty/phone-store:latest

Token App
1. docker pull dainmusty/effulgencetech-nodejs-img:tag          # listens on port 8080
2. minikube image load dainmusty/effulgencetech-nodejs-img:tag
3. kubectl port-forward svc/argocd-server -n argocd 8081:80


Payment App
1. docker pull mongo:5.0          # listens on port 27017
2. Loads into the image to docker desktop
3. kubectl port-forward svc/argocd-server -n argocd 8081:80


# this installs nginx alb controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

kubectl apply -f ingress.yaml

http://web.apps.local
http://token.apps.local
http://payment.apps.local


kubectl exec -it -n token-app <pod> -- sh
wget -O- http://localhost:8080


# to add https
Perfect choice 👍
Let’s add HTTPS (TLS) locally with Minikube + nginx ingress, the production-correct way, without hacks.

We’ll do this in 4 clean steps.

🧩 Goal (what we’re building)

You’ll end up with:

https://web.apps.local
https://token.apps.local
https://payment.apps.local


✔ Valid local TLS
✔ Browser trusted cert
✔ Same pattern as EKS / ALB
✔ No port-forwards needed

1️⃣ Install & setup mkcert (local CA)

mkcert creates a trusted local Certificate Authority.

Windows (PowerShell – Admin)
choco install mkcert


OR download from:
https://github.com/FiloSottile/mkcert/releases

Initialize local CA
mkcert -install


This adds a trusted root cert to your OS & browser.

2️⃣ Generate certs for your apps

From any directory (repo root is fine):

mkcert \
  web.apps.local \
  token.apps.local \
  payment.apps.local


This creates two files:

web.apps.local+2.pem
web.apps.local+2-key.pem


(rename is fine, content matters)

3️⃣ Create a Kubernetes TLS Secret (once)

We’ll create one shared TLS secret.

kubectl create secret tls apps-local-tls \
  --cert=web.apps.local+2.pem \
  --key=web.apps.local+2-key.pem \
  -n ingress-nginx


✅ Stored where ingress controller runs
✅ Reusable by all ingresses

Verify:

kubectl get secret -n ingress-nginx

4️⃣ Update Ingress to use HTTPS
Example: token-app ingress (final)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: token-app
  namespace: token-app
spec:
  ingressClassName: nginx

  tls:
    - hosts:
        - token.apps.local
      secretName: apps-local-tls

  rules:
    - host: token.apps.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: token-app
                port:
                  number: 80


Do the same TLS block for:

web-app

payment-app

Only the host + service name change.

5️⃣ Restart ingress (important)
kubectl rollout restart deployment ingress-nginx-controller -n ingress-nginx

6️⃣ Test 🎉

Open browser:

https://token.apps.local
https://web.apps.local


✅ Green lock
✅ No browser warnings
✅ Real TLS

🧠 Key production lessons you just implemented
Topic	You did it right
Local CA	mkcert
TLS secrets	Kubernetes-native
Ingress TLS	spec.tls
No hacks	No port-forward
Cloud parity	Matches ALB

This exact pattern maps directly to:

AWS ALB + ACM

GKE Managed Certs

AKS App Gateway

Only the cert source changes.


Excellent choice. NetworkPolicies are where Kubernetes becomes “real security” 🔐
We’ll implement zero-trust networking step by step, without breaking your apps.

I’ll explain what, why, then give you exact manifests you can drop into Git and let ArgoCD apply.

🧠 Zero-Trust Model (what we’re enforcing)

Default Kubernetes behavior (bad):

Every pod can talk to every pod in every namespace

Zero-trust model (good):

Nothing talks to anything unless explicitly allowed

We’ll implement:

Default deny per namespace

Allow ingress traffic only from ingress-nginx

Allow DNS (required!)

(Optional) Allow app-to-app communication later

1️⃣ Prerequisite check (important)

NetworkPolicies only work if your CNI supports them.

Minikube drivers that support NetworkPolicy:

✅ docker

✅ containerd

❌ none (old VM drivers)

Verify your CNI:

kubectl get pods -n kube-system | grep -E "calico|cilium|weave"


Minikube usually uses calico, so you’re good.

2️⃣ Default-deny policy (per app namespace)

This is the foundation of zero-trust.

📄 networkpolicy-default-deny.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: token-app
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress

What this does

❌ Blocks ALL inbound traffic

❌ Blocks ALL outbound traffic

Applies to every pod in token-app

⚠️ If you stop here → app breaks (expected)

3️⃣ Allow ingress traffic from nginx ingress controller

Your apps must accept traffic only from ingress-nginx.

📄 networkpolicy-allow-ingress-nginx.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-from-nginx
  namespace: token-app
spec:
  podSelector:
    matchLabels:
      app: token-app

  policyTypes:
    - Ingress

  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: ingress-nginx
      ports:
        - protocol: TCP
          port: 8080

Why this is secure

✔ Only ingress controller can reach the app
✔ No other namespace can talk to it
✔ No pod-to-pod lateral movement

4️⃣ Allow DNS (mandatory or everything breaks)

Every pod needs DNS to function.

📄 networkpolicy-allow-dns.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: token-app
spec:
  podSelector: {}
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53


Without this:

❌ Images won’t pull

❌ Services won’t resolve

❌ HTTP clients fail

5️⃣ Apply same pattern to ALL apps

Repeat these 3 policies for:

web-app

payment-app

Only change:

namespace

app: label

target port (80 vs 8080)

Example port mapping
App	NetworkPolicy port
web-app	80
token-app	8080
payment-app	8080
6️⃣ Verify zero-trust is working
🔍 Test 1 — ingress still works
https://token.apps.local


✅ Should load

🔍 Test 2 — block lateral traffic
kubectl exec -it -n web-app <pod> -- wget -O- http://token-app.token-app.svc.cluster.local


❌ Should FAIL
✔ Zero-trust confirmed

🔍 Test 3 — ArgoCD health

ArgoCD should remain Healthy because:

It reads Kubernetes state

It does NOT need network access to pods

7️⃣ Folder structure (recommended)

Add this to each app:

apps/dev/token-app/
├── deployment.yaml
├── service.yaml
├── ingress.yaml
└── networkpolicies/
    ├── default-deny.yaml
    ├── allow-ingress-nginx.yaml
    └── allow-dns.yaml


ArgoCD will apply them automatically.

🔐 What security you just implemented (real-world)

You now have:

✔ Namespace isolation
✔ Ingress-only exposure
✔ No lateral movement
✔ DNS-only egress
✔ Cloud-grade zero-trust

This is exactly what security teams demand in production EKS clusters.