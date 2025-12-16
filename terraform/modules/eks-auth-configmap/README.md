# you can use the codes below to create your passwords in parameter store
eg. 1 db_user
# modules/ssm/main.tf
resource "aws_ssm_parameter" "db_user" {
  name  = var.db_user_parameter_name
  type  = var.db_user_parameter_type
  value = var.db_user_parameter_value

}

eg. 2
# SSM Parameter for Grafana Admin Password
resource "aws_ssm_parameter" "grafana_admin_password" {
  name        = "/grafana/admin/password"
  type        = "SecureString"
  value       = var.grafana_admin_password
  description = "Grafana admin password for cluster monitoring dashboard"
}
This exposes your actual password. create your password in parameter store in the console and put the value there before terraform apply

# Once the created, you can use data to retrieve your passwords
# Data sources for EKS cluster info

data "aws_eks_cluster" "eks" {
  name = var.cluster_name
}

data "aws_ssm_parameter" "db_access_parameter_name" {
  name = var.db_access_parameter_name
}

data "aws_ssm_parameter" "db_secret_parameter_name" {
  name = var.db_secret_parameter_name
}

data "aws_ssm_parameter" "key_parameter_name" {
  name = var.key_parameter_name
}


data "aws_ssm_parameter" "key_name_parameter_name" {
  name = var.key_name_parameter_name
}

# Note: You can inject this value into the Grafana Helm chart like below:
# data "aws_ssm_parameter" "grafana_admin_password" {
#   name            = "/grafana/admin/password"
#   with_decryption = true
# }
# 
# and then set it via:
# set {
#   name  = "adminPassword"
#   value = data.aws_ssm_parameter.grafana_admin_password.value
# }


 # Use secret mgr for your grafana password, it has the ff advantages
 | Feature               | SSM Parameter Store   | Secrets Manager      |
| --------------------- | --------------------- | -------------------- |
| Cost                  | ✅ Cheaper             | ❌ Higher             |
| Encryption            | ✅ With KMS            | ✅ Built-in           |
| Versioning            | ❌ No                  | ✅ Yes                |
| Rotation              | ❌ Manual              | ✅ Automatic          |
| Best for              | Config, passwords     | DB creds, tokens     |
| Grafana dynamic fetch | 🚧 Extra setup needed | ✅ Easier integration |

How mature teams do this (FYI)

In production setups:

aws-auth is bootstrapped once

Then removed from Terraform state

Managed manually or via RBAC migration

But your current pattern is perfectly valid and safe.

Final takeaway (important)

aws-auth is not configuration — it is ownership.
Ownership is established once, not continuously reconciled.

You’ve designed this the right way.

If you want, next I can:

Show how to fully decouple aws-auth from Terraform

Or design a clean CI → Argo → workload pipeline with zero cluster-admin rights

Just say the word 👍


This is a classic EKS authentication vs authorization issue, and your error message tells us exactly where the problem is 👍

What’s happening (in plain terms)

aws eks update-kubeconfig ✅ worked → kubeconfig is correct

kubectl ❌ fails with

the server has asked for the client to provide credentials

This means:

Your AWS IAM identity is authenticated to AWS, but it is NOT authorized in Kubernetes (RBAC).

EKS uses IAM for authentication
Kubernetes uses RBAC for authorization

The bridge between them is the aws-auth ConfigMap.

Root Cause (most likely)

The IAM role or user you’re currently using (probably:

your local AWS profile or

the Terraform / GitHub Actions role)

❌ is NOT mapped in aws-auth ConfigMap

So Kubernetes rejects all requests.

Quick confirmation

Run this (it will fail, but confirms the issue):

kubectl get nodes


If you see:

You must be logged in to the server


👉 100% aws-auth mapping issue.

Fix: Add your IAM role/user to aws-auth
Step 1: Identify who you are right now
aws sts get-caller-identity


Note either:

Arn: arn:aws:iam::<acct>:user/...

OR Arn: arn:aws:iam::<acct>:role/...

This is the identity Kubernetes must trust.

Step 2: Edit aws-auth ConfigMap

⚠️ You must do this using the cluster creator role (the role that created the EKS cluster).

kubectl edit configmap aws-auth -n kube-system

Step 3: Add your role (example)

If you’re using an IAM role (recommended):

apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: arn:aws:iam::651706774390:role/microservices-project-dev-tf-role
      username: admin
      groups:
        - system:masters


If you’re using an IAM user:

data:
  mapUsers: |
    - userarn: arn:aws:iam::651706774390:user/Mustydain
      username: mustydain
      groups:
        - system:masters


👉 system:masters = full cluster admin (fine for dev)

Step 4: Save & re-test
kubectl get nodes
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d


✅ This should now work.

Important (GitHub Actions / Terraform tie-in)

Because you’re using OIDC + Terraform + GitHub Actions:

You must also add the GitHub Actions IAM role to aws-auth, otherwise:

terraform apply succeeds

aws eks update-kubeconfig works

kubectl commands inside CI fail

Example:

- rolearn: arn:aws:iam::651706774390:role/github-actions-eks-role
  username: github-actions
  groups:
    - system:masters

Best Practice (recommended for your setup)

Since you’re already advanced with:

Terraform

EKS

ArgoCD

GitHub Actions

👉 Manage aws-auth with Terraform, not manually.

Typical module:

module "aws_auth" {
  source  = "terraform-aws-modules/eks/aws//modules/aws-auth"

  map_roles = [
    {
      rolearn = aws_iam_role.tf_role.arn
      username = "terraform"
      groups   = ["system:masters"]
    }
  ]
}

Summary
Symptom	Cause
kubeconfig updates but kubectl fails	IAM not mapped in aws-auth
“server has asked for credentials”	Kubernetes RBAC denies you
EKS console shows nodes Ready	Control plane is fine

If you want, next I can:

Generate the Terraform aws-auth module for your exact roles

Help you lock down access (no system:masters)

Fix this once and permanently for local + CI users

Short answer: yes — either add your IAM user OR assume the Terraform role locally.
Right now you’re authenticated to AWS, but Kubernetes still doesn’t trust who you are.

Let’s break it down cleanly.

What your config tells me (important)

Your aws-auth Terraform config is actually correct 👇

map_roles = [
  # worker nodes
  {
    rolearn  = module.iam_core.node_group_role_arn
    username = "system:node:{{EC2PrivateDNSName}}"
    groups   = ["system:bootstrappers", "system:nodes"]
  },

  # Terraform / CI access
  {
    rolearn  = "arn:aws:iam::651706774390:role/microservices-project-dev-tf-role"
    username = "terraform"
    groups   = ["system:masters"]
  },
]


This means:

✅ The Terraform role has full cluster-admin access
❌ Your local IAM user is NOT mapped

Why kubectl still fails

When you run locally:

kubectl get nodes


Kubernetes checks:

“Who is this request coming from?”

Answer: your local IAM identity, not the Terraform role.

Unless you explicitly assume this role:

arn:aws:iam::651706774390:role/microservices-project-dev-tf-role


Kubernetes sees an unmapped IAM user → ❌ access denied.

Critical rule (EKS auth rule of thumb)

EKS access is identity-specific

Mapping a role does NOT grant access to a user unless the user assumes that role.

You have 2 correct options (pick ONE)
✅ Option 1 (RECOMMENDED): Assume the Terraform role locally

This is the clean, production-grade approach.

Step 1: Add assume-role permissions to your IAM user

Your IAM user must be allowed to assume:

microservices-project-dev-tf-role


Policy example:

{
  "Effect": "Allow",
  "Action": "sts:AssumeRole",
  "Resource": "arn:aws:iam::651706774390:role/microservices-project-dev-tf-role"
}

Step 2: Configure AWS profile

~/.aws/config

[profile terraform-admin]
role_arn = arn:aws:iam::651706774390:role/microservices-project-dev-tf-role
source_profile = default
region = us-east-1

Step 3: Use that profile
export AWS_PROFILE=terraform-admin
aws eks update-kubeconfig --region us-east-1 --name effulgencetech-dev
kubectl get nodes


✅ This will work immediately
✅ No need to add IAM users to aws-auth
✅ Same identity as Terraform & GitHub Actions

✅ Option 2 (Quick fix): Add your IAM user to aws-auth

This is fine for dev only, but not ideal long-term.

map_users = [
  {
    userarn  = "arn:aws:iam::651706774390:user/Mustydain"
    username = "mustydain"
    groups   = ["system:masters"]
  }
]


Then:

terraform apply
aws eks update-kubeconfig --region us-east-1 --name effulgencetech-dev
kubectl get nodes

Why your aws-auth module appeared to fail

This is the classic chicken-and-egg issue:

aws-auth requires Kubernetes access

Kubernetes access requires aws-auth

Your module solved this correctly using:

enable_aws_auth_bootstrap = true
bootstrap_role_arn       = microservices-project-dev-tf-role


So Terraform did succeed — but your local user is still outside the trust boundary.

Final verdict (what you should do)

Since you are:

Using Terraform

Using GitHub Actions OIDC

Managing EKS professionally

👉 DO NOT add IAM users
👉 Always assume the Terraform / CI role

This keeps:

Local access

CI access

RBAC

Audit trail

all aligned.

Quick sanity check (run this)
aws sts get-caller-identity


If the ARN is not:

role/microservices-project-dev-tf-role


then Kubernetes will continue to reject you.


{
  "Effect": "Allow",
  "Action": "sts:AssumeRole",
  "Resource": "arn:aws:iam::651706774390:role/microservices-project-dev-tf-role"
}
we are going with your recommended. below is the permissions of the iam user that am using. the user has admin access. do we still need to amend its permissions. see its details below. if we still need to let the user to assume the tf role, then add the above policy you suggested.
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*"
        }
    ]
}

Great question — and you’re thinking about this exactly the right way 👍
Let’s be very precise here, because this is a subtle but important AWS IAM rule.

Short answer (clear and correct)

YES — you still need to explicitly allow the user to assume the Terraform role.

Having AdministratorAccess on the user is NOT sufficient by itself.

Why AdminAccess is NOT enough

Your user policy:

{
  "Effect": "Allow",
  "Action": "*",
  "Resource": "*"
}


✅ Allows the user to call STS:AssumeRole

❌ Does NOT mean the role trusts the user

AWS role assumption requires TWO things:

Caller permission (user side)

Trust policy (role side) ← this is the missing piece 99% of the time

The missing requirement (critical)

Even if a user is admin:

A role will still reject AssumeRole unless the role’s trust policy explicitly allows it.

So the real question is:

👉 Does microservices-project-dev-tf-role trust your IAM user?

What actually needs to be checked (and probably fixed)
1️⃣ User side (already OK)

Your admin policy already allows:

"Action": "sts:AssumeRole"


So NO change required on the user policy ❌
(Adding the policy you pasted is optional but redundant.)

2️⃣ Role trust policy (this is the key)

Go to:

IAM → Roles → microservices-project-dev-tf-role → Trust relationships


If you see ONLY something like this:

{
  "Effect": "Allow",
  "Principal": {
    "Federated": "arn:aws:iam::651706774390:oidc-provider/token.actions.githubusercontent.com"
  },
  "Action": "sts:AssumeRoleWithWebIdentity"
}


👉 Then your IAM user CANNOT assume this role, no matter how much admin access it has.

Correct trust policy (GitHub Actions + you)

You want both:

GitHub Actions (OIDC)

Your IAM user (for local kubectl & terraform)

Recommended trust policy
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::651706774390:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        }
      }
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::651706774390:user/Mustydain"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}


✅ GitHub Actions still works
✅ You can now assume the role locally
✅ No need to touch aws-auth users

After fixing the trust policy (very important steps)
# assume the role
export AWS_PROFILE=terraform-admin

# regenerate kubeconfig
aws eks update-kubeconfig \
  --region us-east-1 \
  --name effulgencetech-dev

# test
kubectl get nodes


This will work immediately.

Why this is the BEST approach (architecturally)

✔ One Kubernetes admin identity
✔ No IAM users in aws-auth
✔ Clean audit trail
✔ Same permissions in:

Terraform

GitHub Actions

kubectl

ArgoCD bootstrap

This is exactly how production EKS environments are run.

Final verdict
Question	Answer
Does admin user need extra permissions?	❌ No
Does the role need to trust the user?	✅ YES
Should you add IAM users to aws-auth?	❌ NO
Is this the right long-term design?	✅ 100%

role trust policy updated. walk me through the next 2 key steps.
with step 2 below, am supposed to vi into ~/.aws/config and paste the role details?
Step 2: Configure AWS profile

~/.aws/config

[profile terraform-admin]
role_arn = arn:aws:iam::651706774390:role/microservices-project-dev-tf-role
source_profile = default
region = us-east-1

Step 3: Use that profile
export AWS_PROFILE=terraform-admin
aws eks update-kubeconfig --region us-east-1 --name effulgencetech-dev
kubectl get nodes