Notes:
/web → proxies to web-service (NodePort 8080 → targetPort 3000 inside the pod).

/token → proxies to frontend-service (NodePort 8080 → targetPort 80 inside the pod).

No ingress is defined for payment-service since MongoDB should only be accessed internally via ClusterIP (e.g., mongo://payment-service.fonapp.svc.cluster.local).

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
