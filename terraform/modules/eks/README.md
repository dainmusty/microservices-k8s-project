Yes — the way you’re getting the OIDC issuer is correct, but let’s verify the format and common pitfalls.

1️⃣ How Terraform outputs it:
output "oidc_provider_url" {
  value = aws_eks_cluster.dev_cluster.identity[0].oidc[0].issuer
}


This returns something like:

https://oidc.eks.us-east-1.amazonaws.com/id/7A2C6AB51D3637BC07FA403A62BA82F9


✅ This is expected. It includes https://.

2️⃣ What AWS IAM expects in the trust policy:

For IRSA, the Principal condition must not include https:// when referencing the issuer for :sub and :aud conditions.

So in Terraform, we must strip it when creating the role policy:

locals {
  oidc_provider_id = replace(aws_eks_cluster.dev_cluster.identity[0].oidc[0].issuer, "https://", "")
}


Then in the IAM policy:

variable = "${local.oidc_provider_id}:sub"
values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]

3️⃣ How to double-check from CLI:
aws eks describe-cluster --name effulgencetech-dev --query "cluster.identity.oidc.issuer" --output text


Should return something like:

https://oidc.eks.us-east-1.amazonaws.com/id/7A2C6AB51D3637BC07FA403A62BA82F9


✅ If it matches your Terraform output, the cluster is correct.

⚠️ Only thing to fix is removing https:// when building the IAM trust policy.


✅ The ONE missing piece (minimal & modern)

You need one Kubernetes ClusterRoleBinding that maps your role to cluster-admin.

🔐 Create this ONCE (recommended via Terraform or kubectl)
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: terraform-admin
subjects:
  - kind: User
    name: arn:aws:iam::651706774390:role/microservices-project-dev-tf-role
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io


Apply with:

kubectl apply -f clusterrolebinding.yaml

🎯 What happens immediately after

AWS Console:

Pods ✔

Nodes ✔

Services ✔

ConfigMaps ✔

kubectl works

No aws-auth ConfigMap

No legacy mappings

Fully modern EKS access model

🔥 Important best-practice note (you’re doing it right)

Your setup now follows AWS’s recommended 2024+ model for Amazon EKS:

✔ IAM Access Entries
✔ No aws-auth dependency
✔ Explicit RBAC bindings
✔ Clean separation of infra vs access

🧠 Final mental model (remember this)

IAM Access Entry = who may authenticate
Kubernetes RBAC = what they may see/do

Both are required.