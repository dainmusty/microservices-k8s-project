# To install argocd on a minikube
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl get pods -n argocd
kubectl port-forward svc/argocd-server -n argocd 8080:80
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode


Absolutely 👍
You’re on the right track already. We just need to cleanly convert the payment app into a MongoDB database service, fix a few mismatches, and make it internally accessible for testing.

We will keep this simple:

❌ No NetworkPolicies

❌ No HTTPS

✅ Internal MongoDB via ClusterIP

✅ Credentials via Secret

✅ Config via ConfigMap

⚠️ Ingress is NOT needed for MongoDB (important)

🔴 Important correction (very important)

MongoDB should NOT be exposed via Ingress

Ingress is HTTP/HTTPS only, while MongoDB is TCP (27017).
So we will remove the Ingress completely.

Your apps will connect using:

mongodb://<user>:<password>@payment-service.payment-app.svc.cluster.local:27017

✅ Final Clean Setup (MongoDB in payment-app namespace)
1️⃣ Secret (MongoDB credentials)

Put this in payment-app namespace (not web-app)

apiVersion: v1
kind: Secret
metadata:
  name: mongo-secret
  namespace: payment-app
type: Opaque
data:
  mongo-usr: YWRtaW4=        # admin
  mongo-pwd: cGFzc3dvcmQ=    # password

2️⃣ ConfigMap (optional but good practice)

Mongo itself doesn’t need much config, but this is fine for consistency.

apiVersion: v1
kind: ConfigMap
metadata:
  name: payment-app-config
  namespace: payment-app
data:
  MONGO_DB_NAME: payments
  APP_ENV: dev

3️⃣ Deployment (MongoDB)

✔ Fixed
✔ Uses secret correctly
✔ Correct labels
✔ Readiness probe works

apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb
  namespace: payment-app
  labels:
    app: mongo
    environment: dev
    managed-by: argocd
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongo
  template:
    metadata:
      labels:
        app: mongo
        environment: dev
        managed-by: argocd
    spec:
      containers:
        - name: mongo
          image: mongo:6.0
          ports:
            - containerPort: 27017
          env:
            - name: MONGO_INITDB_ROOT_USERNAME
              valueFrom:
                secretKeyRef:
                  name: mongo-secret
                  key: mongo-usr
            - name: MONGO_INITDB_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mongo-secret
                  key: mongo-pwd
            - name: MONGO_INITDB_DATABASE
              valueFrom:
                configMapKeyRef:
                  name: payment-app-config
                  key: MONGO_DB_NAME
          readinessProbe:
            exec:
              command:
                - mongosh
                - "--eval"
                - "db.adminCommand('ping')"
            initialDelaySeconds: 10
            periodSeconds: 10

4️⃣ Service (internal MongoDB access)

✔ ClusterIP
✔ Correct selector
✔ No external exposure

apiVersion: v1
kind: Service
metadata:
  name: payment-service
  namespace: payment-app
  labels:
    app: mongo
    environment: dev
    managed-by: argocd
spec:
  selector:
    app: mongo
  ports:
    - protocol: TCP
      port: 27017
      targetPort: 27017
  type: ClusterIP

5️⃣ ❌ REMOVE Ingress (not needed)

⚠️ Delete this completely:

kubectl delete ingress payment-app -n payment-app


MongoDB should never be exposed via HTTP ingress.

🧪 Testing (very important)
1️⃣ Check pod
kubectl get pods -n payment-app

2️⃣ Check service endpoints
kubectl get endpoints payment-service -n payment-app


You should see:

IP:27017

3️⃣ Test MongoDB from another pod
kubectl run mongo-client \
  --rm -it \
  --image=mongo:6.0 \
  -n payment-app -- bash


Inside the pod:

mongosh "mongodb://admin:password@payment-service:27017"


If you see:

test>


✅ MongoDB is running perfectly.

🔌 How your apps should connect

From web-app / token-app:

mongodb://admin:password@payment-service.payment-app.svc.cluster.local:27017/payments

✅ What you now have

✔ Payment app converted into MongoDB
✔ Secure credentials via Secrets
✔ Internal-only access
✔ ArgoCD-friendly manifests
✔ Clean, testable setup

🔜 Next logical steps (when ready)

1️⃣ Add PersistentVolume (Mongo data persistence)
2️⃣ Add NetworkPolicies (zero-trust)
3️⃣ Add MongoDB exporter → Prometheus
4️⃣ Move Mongo to StatefulSet

# kustomization.yaml
# apiVersion: kustomize.config.k8s.io/v1beta1
# kind: Kustomization

# namespace: payment-app

# resources:
#   - mongo-deployment.yaml
#   - mongo-service.yaml
#   - web-deployment.yaml
#   - web-service.yaml
#   - web-ingress.yaml
#   - configmap.yaml
#   - secret.yaml
