# minikube-project
microservices project
You’re very close — nothing is “broken”.
This is a classic App-of-Apps gotcha, and the Argo CD UI is actually telling us the truth.

Let’s walk through it methodically and fix it.

✅ What Argo CD Is Doing Right Now (Important)

From what you shared:

✅ apps-of-apps is Healthy

✅ apps-of-apps is Synced

✅ Repo, branch, and path are correct

❌ No child applications appear

This means Argo CD successfully synced the folder, but it did not find any Argo CD Application manifests inside it.

⚠️ App-of-Apps does NOT automatically create apps from folders.
It only creates apps from Application CRDs.

🔑 Critical Rule (This Is the Root Cause)

For App-of-Apps to work:

Each app folder MUST contain an Application manifest

Argo CD does not care about:

Deployments

Services

ConfigMaps

Secrets

Unless there is a file like this:

kind: Application
apiVersion: argoproj.io/v1alpha1


…it will not show anything in the UI.

🔍 What I Strongly Suspect Your Repo Looks Like

Something like this 👇 (very common):

apps/
└── dev/
    ├── web-app/
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   └── configmap.yaml
    ├── payment-app/
    │   ├── deployment.yaml
    │   └── service.yaml
    └── token/
        ├── deployment.yaml
        └── service.yaml


❌ Missing application.yaml in each app

So Argo CD syncs apps/dev, finds zero Application CRDs, and stops.

That’s why:

Root app = Healthy

UI = Only shows apps-of-apps

✅ What You MUST Have (Correct Structure)

Your repo must look like this:

apps/
└── dev/
    ├── web-app/
    │   ├── application.yaml   👈 REQUIRED
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   ├── configmap.yaml
    │   └── secret.yaml
    │
    ├── payment-app/
    │   ├── application.yaml   👈 REQUIRED
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   └── configmap.yaml
    │
    └── token/
        ├── application.yaml   👈 REQUIRED
        ├── deployment.yaml
        ├── service.yaml
        └── configmap.yaml

✅ Minimal application.yaml (Example: web-app)

📍 apps/dev/web-app/application.yaml

apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: web-app
  namespace: argocd
spec:
  project: default

  source:
    repoURL: https://github.com/dainmusty/minikube-project.git
    targetRevision: main
    path: apps/dev/web-app

  destination:
    server: https://kubernetes.default.svc
    namespace: web-app

  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true


👉 You need one of these per app (token, payment-app, etc.)

🧪 How to Verify Immediately (CLI)

Run this:

kubectl get applications -n argocd

Right now you’ll see:
NAME
apps-of-apps

After fixing:
NAME
apps-of-apps
web-app
payment-app
token

👀 How They Will Appear in the Argo CD UI

After you commit & push the application.yaml files:

Argo CD auto-syncs apps-of-apps

It creates child Applications

UI will show:

Applications
├── apps-of-apps
├── web-app
├── payment-app
└── token


Clicking each one shows:

Pods

Services

ConfigMaps

Health status

Sync history

🌐 How to Access the Apps (Minikube)

Since you’re on Minikube and Ingress is not added yet, use:

kubectl port-forward svc/web-app 8080:80 -n web-app


Then open:

http://localhost:8080


Repeat for payment-app and token.

✅ Final Checklist (Very Important)

✔ Root app points to apps/dev
✔ Each app folder contains application.yaml
✔ App path points to its own folder
✔ Namespace is created automatically
✔ Repo URL and branch match

🧠 Summary (One Sentence)

Your App-of-Apps is working perfectly, but Argo CD cannot show web-app, payment-app, and token because their folders do not yet contain Argo CD Application manifests.

If you want, next I can:

Review one of your actual application.yaml files

Validate your repo tree line-by-line

Add AppSets to avoid repeating YAML

Add Minikube Ingress (minikube tunnel)

Just tell me 👍
under summary
APPS-OF-APPS

PROJECT
default
ANNOTATIONS
kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"argoproj.io/v1alpha1","kind":"Application","metadata":{"annotations":{},"name":"apps-of-apps","namespace":"argocd"},"spec":{"destination":{"namespace":"argocd","server":"https://kubernetes.default.svc"},"project":"default","source":{"path":"apps/dev","repoURL":"https://github.com/dainmusty/minikube-project.git","targetRevision":"main"},"syncPolicy":{"automated":{"prune":true,"selfHeal":true},"syncOptions":["CreateNamespace=true"]}}}
CLUSTER
in-cluster (https://kubernetes.default.svc)
NAMESPACE
argocd   
CREATED AT
12/25/2025 01:59:03 (8 hours ago)
REPO URL
https://github.com/dainmusty/minikube-project.git
TARGET REVISION
main 
PATH
apps/dev 
SYNC OPTIONS
 CreateNamespace
RETRY OPTIONS
Retry disabled
STATUS
 Synced to main (69bc900) 
HEALTH
 Healthy
LINKS
SYNC POLICY

AUTOMATED

ENABLE AUTO-SYNC 

PRUNE RESOURCESunder parameters
DIRECTORY

DIRECTORY RECURSE
false
TOP-LEVEL ARGUMENTS
EXTERNAL VARIABLES
i saw this in argo, does the false mean anything?
below is my child app for the web-app. am still not seeing the child app. when i click on app of apps parent application, the above is what pops up.
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: web-app
  namespace: argocd
spec:
  project: default

  source:
    repoURL: https://github.com/dainmusty/minikube-project.git
    targetRevision: main
    path: apps/dev/web-app

  destination:
    server: https://kubernetes.default.svc
    namespace: web-app

  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true


Excellent catch — this screenshot detail is the key.
Yes, the DIRECTORY RECURSE = false does matter, and it explains exactly why you are not seeing the child apps.

You’ve done almost everything right. There is one missing switch.

✅ What DIRECTORY RECURSE = false Means (Plain English)

Your root App-of-Apps is configured like this:

source:
  path: apps/dev


But Argo CD is currently behaving as:

“Only look for manifests directly inside apps/dev/,
❌ do NOT look inside subfolders.”

Your child Applications live here:

apps/dev/web-app/application.yaml
apps/dev/payment-app/application.yaml
apps/dev/token/application.yaml


Because recurse is false, Argo CD:

Reads apps/dev/

Sees only folders

Does not descend into web-app/, payment-app/, token/

Finds zero Applications

Still reports Healthy & Synced (because nothing failed)

That is exactly the behavior you’re seeing.

🔑 Critical Rule for App-of-Apps

You must enable directory recursion on the root application.

Without it:

Nested child apps will never be discovered

UI will show only the root app

✅ The Fix (One-Line Change)

Update your root App-of-Apps manifest.

📍 apps-of-apps.yaml (ROOT APP)
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: apps-of-apps
  namespace: argocd
spec:
  project: default

  source:
    repoURL: https://github.com/dainmusty/minikube-project.git
    targetRevision: main
    path: apps/dev
    directory:
      recurse: true   # 👈 THIS IS THE MISSING PIECE

  destination:
    server: https://kubernetes.default.svc
    namespace: argocd

  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true

🔁 What to Do Now (Exact Steps)

1️⃣ Update the root app YAML
2️⃣ Commit and push

git add apps-of-apps.yaml
git commit -m "Enable directory recursion for App of Apps"
git push origin main


3️⃣ Argo CD will auto-sync (no kubectl needed)

✅ How to Verify (CLI)
kubectl get applications -n argocd


You should now see:

NAME
apps-of-apps
web-app
payment-app
token

👀 What You’ll See in the Argo CD UI

The UI will refresh automatically and show:

Applications
├── apps-of-apps
├── web-app
├── payment-app
└── token


Clicking web-app will now show:

Deployment

Service

ConfigMaps

Pods

Health status

🧠 Why This Is So Easy to Miss (Even for Seniors)

Default directory.recurse = false

UI shows it quietly under Parameters

Root app stays Healthy

No error messages

Looks like a path or sync issue

This exact thing trips up a lot of people.

✅ Final Confirmation

Your child app YAML is correct ✅
Your repo structure is correct ✅
Your paths are correct ✅

👉 The only missing piece was:

directory:
  recurse: true
❌ The problem (precise)

Your container listens on 8080, but your Service forwards to 80.

Deployment (correct)
containers:
  - name: token-app
    ports:
      - containerPort: 8080   # ✅ app listens here

Service (wrong)
ports:
  - port: 80
    targetPort: 80            # ❌ nothing listens on 80 in the pod


So traffic flow is currently:

Ingress → Service:80 → Pod:80 ❌ (connection refused)


That’s why:

wget http://localhost:8080 works inside the pod

http://token.apps.local returns 404 / 502

✅ The fix (only ONE line change)
✅ Correct Service manifest
apiVersion: v1
kind: Service
metadata:
  name: token-app
  namespace: token-app
spec:
  selector:
    app: token-app
  ports:
    - port: 80          # ingress talks to this
      targetPort: 8080  # forward to container port
  type: ClusterIP


✔ Ingress stays the same
✔ Deployment stays the same

🔁 What to do now

Update the Service manifest in Git

Commit & push

Let ArgoCD sync (or sync manually)

✅ Expected final traffic flow (correct)
Browser
 → http://token.apps.local
 → Ingress (80)
 → Service token-app (80)
 → Pod token-app (8080)
 → Node app responds ✅

🧠 Key rule to remember (this is important)

Ingress port = Service port
Service targetPort = Container port

They do not have to be the same — and usually aren’t.

🔍 Quick verification after sync
kubectl get endpoints token-app -n token-app


You should see:

IP:8080


Then open in browser:

http://token.apps.local


You are very close — this is the final wiring fix.
Once this works, all three apps (web, token, payment) will be cleanly normalized and production-aligned.

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    argocd.argoproj.io/tracking-id: token-app:networking.k8s.io/Ingress:token-app/token-app
    kubectl.kubernetes.io/last-applied-configuration: >
      {"apiVersion":"networking.k8s.io/v1","kind":"Ingress","metadata":{"annotations":{"argocd.argoproj.io/tracking-id":"token-app:networking.k8s.io/Ingress:token-app/token-app"},"name":"token-app","namespace":"token-app"},"spec":{"rules":[{"host":"token.apps.local","http":{"paths":[{"backend":{"service":{"name":"token-app","port":{"number":80}}},"path":"/","pathType":"Prefix"}]}}]}}
  creationTimestamp: '2025-12-25T22:47:08Z'
  generation: 1
  name: token-app
  namespace: token-app
  resourceVersion: '133531'
  uid: 597e7c0b-318b-4b44-960c-a4f063208e06
spec:
  rules:
    - host: token.apps.local
      http:
        paths:
          - backend:
              service:
                name: token-app
                port:
                  number: 80
            path: /
            pathType: Prefix
status:
  loadBalancer: {}

kubectl get endpoints token-app -n token-app
NAME        ENDPOINTS                             AGE
token-app   10.244.0.219:8080,10.244.0.220:8080   31h 

Excellent — this output is actually very good news.
It tells us exactly where we are and what the last missing piece is.

✅ What is now 100% correct
1️⃣ Service → Pod wiring ✅

Your endpoints prove it:

kubectl get endpoints token-app -n token-app

10.244.0.219:8080
10.244.0.220:8080


This confirms:

✔ Pods are running
✔ App listens on 8080
✔ Service correctly forwards 80 → 8080

So Service + Deployment are PERFECT now.

🔴 What is still missing (Ingress-specific)

Your Ingress does not specify which controller should handle it.

On Minikube, this is critical.

Right now, your Ingress has:

spec:
  rules:
    - host: token.apps.local


But no ingress class.

✅ REQUIRED FIX: Add ingressClassName

Your ingress controller is ingress-nginx, so you must explicitly bind to it.

✅ Correct Ingress (final)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: token-app
  namespace: token-app
spec:
  ingressClassName: nginx
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


⚠️ Do not use annotations anymore — ingressClassName is the modern, correct way.

🔁 What to do now

Update this ingress in Git

Commit & push

Let ArgoCD sync (or sync manually)

🧪 Verification steps (in order)
1️⃣ Confirm ingress picked up
kubectl get ingress token-app -n token-app


You should now see:

CLASS    nginx

2️⃣ Check ingress controller logs (optional)
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller | grep token

3️⃣ Open in browser
http://token.apps.local


✅ You should now see the same HTML you saw via wget localhost:8080.

🧠 Why web-app worked earlier without this

Most likely:

web-app ingress already had ingressClassName: nginx

or it was created when nginx was the default class

Kubernetes no longer assumes defaults reliably — explicit is required.

🏁 Final architecture (now complete)

You now have:

✔ App-of-Apps (ArgoCD)
✔ Per-app namespaces
✔ Normalized ingress (port 80 everywhere)
✔ Proper Service → Pod mapping
✔ Real production-grade routing

This setup will translate 1:1 to:

EKS + ALB

GKE

AKS
you can now

Add health/readiness probes

Add TLS (HTTPS locally)

Add NetworkPolicies

Move this exact layout to EKS