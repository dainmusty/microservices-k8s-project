Best Practice — One Repo Per Image? or Multiple Images Per Repo?
AWS Best Practice → One image per repository

AWS recommends creating one ECR repo per microservice or application.

Why?
One repo per image is better because:

➤ Cleaner versioning (tags belong to one image only)

➤ Cleaner permissions (fine-grained repo permissions)

➤ Easier automation in CI/CD pipelines

➤ Prevents accidental overwriting of unrelated images

➤ Better isolation and simpler retention policies

Next steps:

GitHub Actions workflow to
pull from DockerHub → retag → push to ECR

Terraform to create lifecycle policies

ArgoCD image updater configuration for ECR

K8s Deployment auto-updating ECR image tags

Project diagram for LinkedIn