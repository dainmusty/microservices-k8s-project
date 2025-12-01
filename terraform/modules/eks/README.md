# 🧩 EKS Addons Troubleshooting & Setup Summary

_August 6, 2025_

This document summarizes key issues encountered and resolutions applied while configuring the following Terraform-managed Kubernetes addons on an EKS cluster:

- `argocd.tf`
- `ebs-csi-driver.tf`
- `alb-controller.tf`
- `prometheus-grafana.tf`

---

## 📦 1. ArgoCD Setup & Debugging

**Issues:**  
- Admin login password not obvious.  
- UI access required port-forwarding.

**Fixes:**  
- Accessed dashboard via:
  ```bash
  kubectl port-forward svc/argocd-server -n argocd 8080:80
  ```
- Retrieved password with:
  ```bash
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{{{{.data.password}}}}" | base64 -d
  ```
- Verified setup:
  - `helm list -n argocd`
  - `kubectl get svc -n argocd`
  - `kubectl get pods -n argocd`

---

## 📊 2. Prometheus & Grafana Observability Stack

**Issues:**  
- Manual port-forwarding needed.  
- Default insecure credentials and config.  
- Secrets were fetched at runtime using `aws-cli` in initContainers.

**Fixes:**  
- Used Helm `existingSecret` for Grafana admin:
  ```yaml
  grafana:
    admin:
      existingSecret: grafana-admin
  ```
- Disabled anonymous access:
  ```yaml
  grafana.ini:
    auth.anonymous:
      enabled: false
  ```
- Enabled persistence and resource limits:
  ```yaml
  persistence:
    enabled: true
    storageClassName: gp2
    size: 5Gi

  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 250m
      memory: 256Mi
  ```
- Enabled `serviceMonitor` for Prometheus to scrape Grafana.

**Outcome:**  
- 🔐 Secure access.  
- 💾 Persistent dashboards.  
- 📊 Prometheus can scrape Grafana metrics.

---

## ☁️ 3. ALB Controller

**Checks Performed:**  
- Verified LoadBalancer services:
  ```bash
  kubectl get svc -A | grep LoadBalancer
  ```
- Verified ALB controller logs and pods:
  ```bash
  kubectl get pods -n kube-system | grep alb
  kubectl logs -n kube-system <alb-pod>
  ```

---

## 🔩 4. EBS CSI Driver & EKS Connectivity

**Tasks:**  
- Connected to EKS cluster:
  ```bash
  aws eks --region us-east-1 update-kubeconfig --name <cluster>
  kubectl get nodes
  kubectl cluster-info
  kubectl get ns argocd
  ```

---

## 🔒 5. Secure Secrets & Alertmanager Slack Integration

**Original Issue:**  
- Runtime secret injection via `initContainer` and `aws-cli`.

**Fixes:**  
- Fetched secrets via Terraform:
  ```hcl
  data "aws_secretsmanager_secret_version" "slack_webhook" {
    secret_id = var.slack_webhook_secret_id
  }
  ```
- Created Kubernetes secret with `slack_api_url` key.

**Outcome:**  
- 🔐 Secure Slack alerting.  
- ✅ Deployment-time secret resolution.

---

## 📘 6. Terraform Modularization

**Improvements:**  
- Moved alert rules to `prometheus_rules.tf`.  
- Used modular `values = [ file(...) ]` pattern for Helm.

---

## 🧠 Summary Table

| Component              | Status & Outcome                                                     |
|------------------------|----------------------------------------------------------------------|
| ArgoCD                 | Admin access fixed, deployment vaalidated                            |
| Grafana/Prometheus     | Secrets secured, persistence added, alerting improved               |
| ALB Controller         | Logs and service verified                                            |
| EBS CSI Driver         | Cluster connectivity confirmed                                       |
| Alertmanager Slack     | Secrets pulled securely, runtime dependencies removed               |
| Terraform Structure    | Modular, maintainable setup aligned with best practices             |


The AWS Root CA is a Certificate Authority (CA) that Amazon Web Services uses to secure communication between services — like when your EKS cluster uses OIDC (OpenID Connect) to communicate securely with IAM and other services.

🛡️ What is a Root CA?
A Root Certificate Authority is a trusted entity that issues digital certificates. These certificates are used to establish secure (TLS/SSL) connections. In AWS, the OIDC provider your EKS cluster uses must be trusted, so its certificate needs to be verified — this is where the Root CA’s thumbprint comes in.



# Launch Template for EKS worker nodes if you are not using node groups
resource "aws_launch_template" "eks_worker" {
  name_prefix   = "${var.cluster_name}-worker-"
  image_id      = data.aws_ami.eks_worker.id
  instance_type = var.instance_type
  iam_instance_profile {
    name = var.worker_instance_profile_name
  }
  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    cluster_name = aws_eks_cluster.eks_cluster.name
    endpoint     = aws_eks_cluster.eks_cluster.endpoint
    ca_data      = aws_eks_cluster.eks_cluster.certificate_authority[0].data
    node_role    = var.eks_node_role_arn
  }))
  # ...add other settings as needed...
}

# Get latest EKS-optimized AMI
data "aws_ami" "eks_worker" {
  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI account
  filter {
    name   = "name"
    values = ["amazon-eks-node-*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Create 2 EC2 worker nodes
resource "aws_instance" "eks_worker" {
  count         = 2
  ami           = data.aws_ami.eks_worker.id
  instance_type = var.instance_type
  subnet_id     = element(var.subnet_ids, count.index)
  iam_instance_profile = var.worker_instance_profile_name
  user_data     = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    cluster_name = aws_eks_cluster.eks_cluster.name
    endpoint     = aws_eks_cluster.eks_cluster.endpoint
    ca_data      = aws_eks_cluster.eks_cluster.certificate_authority[0].data
    node_role    = var.eks_node_role_arn
  }))
  # ...add security groups, tags, etc. as needed...
}

# variables for node group
variable "cluster_name" {}
variable "eks_node_role_arn" {}
variable "eks_cluster_role_arn" {}
variable "cluster_AmazonEKSClusterPolicy" {}
variable "node_AmazonEKSWorkerNodePolicy" {}
variable "node_AmazonEKS_CNI_Policy" {}
variable "node_AmazonEC2ContainerRegistryReadOnly" {}
variable "node_group_name" {}
variable "instance_type" {}
variable "desired_nodes" {}
variable "min_nodes" {}
variable "max_nodes" {}
variable "subnet_ids" {
  type = list(string)
}

# terraform eks cluster code
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = var.eks_cluster_role_arn

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.cluster_security_group_id]
  }

  depends_on = [var.cluster_AmazonEKSClusterPolicy]
}

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.env}-nodegroup"
  node_role_arn   = var.eks_node_role_arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  instance_types = [var.instance_type]

  # Optionally, add labels, taints, or remote access config
  # remote_access {
  #   ec2_ssh_key = var.ssh_key_namelicy,
  # }

  depends_on = [
    aws_eks_cluster.eks_cluster,
    var.node_AmazonEC2ContainerRegistryReadOnly,
    var.node_AmazonEKS_CNI_Policy,
    var.node_AmazonEKSWorkerNodePolicy
  ]
} 



Updated saved memory
Thanks for the detailed comparison. Your eksctl command creates a fully working cluster because it:

Automatically creates public/private subnets with proper tags.

Associates required IAM roles and policies correctly.

Automatically installs EKS addons like vpc-cni, kube-proxy, and coredns.

Ensures OIDC provider is configured for IAM roles (critical for vpc-cni to work properly).

Your Terraform setup is missing key features, especially the EKS addons, OIDC, and possibly subnet tagging. Below is a corrected and eksctl-equivalent Terraform version, including EKS cluster, node group, addons, and OIDC setup.

✅ Terraform Code (Equivalent to eksctl)
1. EKS Cluster

resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = var.eks_cluster_role_arn

  version = "1.32"

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.cluster_security_group_id]
  }

  depends_on = [
    var.cluster_AmazonEKSClusterPolicy,
    aws_iam_openid_connect_provider.oidc
  ]
}
2. OIDC Provider

data "aws_eks_cluster" "eks" {
  name = aws_eks_cluster.eks_cluster.name
}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks_cluster.name
}

resource "aws_iam_openid_connect_provider" "oidc" {
  url = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [var.thumbprint]
}
Replace var.thumbprint with the correct thumbprint of the OIDC provider.

3. Managed Node Group

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.env}-nodegroup"
  node_role_arn   = var.eks_node_role_arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }

  instance_types = [var.instance_type]

  depends_on = [
    aws_eks_cluster.eks_cluster,
    var.node_AmazonEC2ContainerRegistryReadOnly,
    var.node_AmazonEKS_CNI_Policy,
    var.node_AmazonEKSWorkerNodePolicy
  ]
}
4. EKS Addons (CoreDNS, kube-proxy, VPC CNI, metrics-server)

resource "aws_eks_addon" "vpc_cni" {				# This is required for the creation of the node group.
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "vpc-cni"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "kube-proxy"
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "coredns"
}

resource "aws_eks_addon" "metrics_server" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "metrics-server"
}
🛠 Subnet Tagging Required by EKS
You must tag your private subnets like this:

resource "aws_subnet" "private" {
  # ... your subnet config ...
  tags = {
    "Name" = "private-subnet"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  }
}
Without these, EKS cannot schedule workloads or initialize CNI networking.

✅ Summary
Your Terraform code needs:

OIDC provider setup.

EKS Addons block to install vpc-cni, kube-proxy, coredns, etc.

Proper subnet tagging (kubernetes.io/cluster/CLUSTER_NAME = shared).

Ensure IAM policies and roles are associated correctly with the EKS node role.

Would you like a full Terraform module structure (including VPC, roles, subnets) to mirror eksctl entirely?




# cloudformation template for eks cluster
{
	"AWSTemplateFormatVersion": "2010-09-09",
	"Description": "EKS cluster (dedicated VPC: true, dedicated IAM: true) [created and managed by eksctl]",
	"Mappings": {
		"ServicePrincipalPartitionMap": {
			"aws": {
				"EC2": "ec2.amazonaws.com",
				"EKS": "eks.amazonaws.com",
				"EKSFargatePods": "eks-fargate-pods.amazonaws.com",
				"IRA": "rolesanywhere.amazonaws.com",
				"SSM": "ssm.amazonaws.com"
			},
			"aws-cn": {
				"EC2": "ec2.amazonaws.com.cn",
				"EKS": "eks.amazonaws.com",
				"EKSFargatePods": "eks-fargate-pods.amazonaws.com"
			},
			"aws-iso": {
				"EC2": "ec2.c2s.ic.gov",
				"EKS": "eks.amazonaws.com",
				"EKSFargatePods": "eks-fargate-pods.amazonaws.com"
			},
			"aws-iso-b": {
				"EC2": "ec2.sc2s.sgov.gov",
				"EKS": "eks.amazonaws.com",
				"EKSFargatePods": "eks-fargate-pods.amazonaws.com"
			},
			"aws-iso-e": {
				"EC2": "ec2.amazonaws.com",
				"EKS": "eks.amazonaws.com",
				"EKSFargatePods": "eks-fargate-pods.amazonaws.com"
			},
			"aws-iso-f": {
				"EC2": "ec2.amazonaws.com",
				"EKS": "eks.amazonaws.com",
				"EKSFargatePods": "eks-fargate-pods.amazonaws.com"
			},
			"aws-us-gov": {
				"EC2": "ec2.amazonaws.com",
				"EKS": "eks.amazonaws.com",
				"EKSFargatePods": "eks-fargate-pods.amazonaws.com",
				"IRA": "rolesanywhere.amazonaws.com",
				"SSM": "ssm.amazonaws.com"
			}
		}
	},
	"Resources": {
		"ClusterSharedNodeSecurityGroup": {
			"Type": "AWS::EC2::SecurityGroup",
			"Properties": {
				"GroupDescription": "Communication between all nodes in the cluster",
				"Tags": [
					{
						"Key": "Name",
						"Value": {
							"Fn::Sub": "${AWS::StackName}/ClusterSharedNodeSecurityGroup"
						}
					}
				],
				"VpcId": {
					"Ref": "VPC"
				}
			}
		},
		"ControlPlane": {
			"Type": "AWS::EKS::Cluster",
			"Properties": {
				"AccessConfig": {
					"AuthenticationMode": "API_AND_CONFIG_MAP",
					"BootstrapClusterCreatorAdminPermissions": true
				},
				"BootstrapSelfManagedAddons": false,
				"KubernetesNetworkConfig": {
					"IpFamily": "ipv4"
				},
				"Name": "effulgencetech-dev",
				"ResourcesVpcConfig": {
					"EndpointPrivateAccess": false,
					"EndpointPublicAccess": true,
					"SecurityGroupIds": [
						{
							"Ref": "ControlPlaneSecurityGroup"
						}
					],
					"SubnetIds": [
						{
							"Ref": "SubnetPublicUSEAST1A"
						},
						{
							"Ref": "SubnetPublicUSEAST1D"
						},
						{
							"Ref": "SubnetPrivateUSEAST1A"
						},
						{
							"Ref": "SubnetPrivateUSEAST1D"
						}
					]
				},
				"RoleArn": {
					"Fn::GetAtt": [
						"ServiceRole",
						"Arn"
					]
				},
				"Tags": [
					{
						"Key": "Name",
						"Value": {
							"Fn::Sub": "${AWS::StackName}/ControlPlane"
						}
					}
				],
				"Version": "1.32"
			}
		},
		"ControlPlaneSecurityGroup": {
			"Type": "AWS::EC2::SecurityGroup",
			"Properties": {
				"GroupDescription": "Communication between the control plane and worker nodegroups",
				"Tags": [
					{
						"Key": "Name",
						"Value": {
							"Fn::Sub": "${AWS::StackName}/ControlPlaneSecurityGroup"
						}
					}
				],
				"VpcId": {
					"Ref": "VPC"
				}
			}
		},
		"IngressDefaultClusterToNodeSG": {
			"Type": "AWS::EC2::SecurityGroupIngress",
			"Properties": {
				"Description": "Allow managed and unmanaged nodes to communicate with each other (all ports)",
				"FromPort": 0,
				"GroupId": {
					"Ref": "ClusterSharedNodeSecurityGroup"
				},
				"IpProtocol": "-1",
				"SourceSecurityGroupId": {
					"Fn::GetAtt": [
						"ControlPlane",
						"ClusterSecurityGroupId"
					]
				},
				"ToPort": 65535
			}
		},
		"IngressInterNodeGroupSG": {
			"Type": "AWS::EC2::SecurityGroupIngress",
			"Properties": {
				"Description": "Allow nodes to communicate with each other (all ports)",
				"FromPort": 0,
				"GroupId": {
					"Ref": "ClusterSharedNodeSecurityGroup"
				},
				"IpProtocol": "-1",
				"SourceSecurityGroupId": {
					"Ref": "ClusterSharedNodeSecurityGroup"
				},
				"ToPort": 65535
			}
		},
		"IngressNodeToDefaultClusterSG": {
			"Type": "AWS::EC2::SecurityGroupIngress",
			"Properties": {
				"Description": "Allow unmanaged nodes to communicate with control plane (all ports)",
				"FromPort": 0,
				"GroupId": {
					"Fn::GetAtt": [
						"ControlPlane",
						"ClusterSecurityGroupId"
					]
				},
				"IpProtocol": "-1",
				"SourceSecurityGroupId": {
					"Ref": "ClusterSharedNodeSecurityGroup"
				},
				"ToPort": 65535
			}
		},
		"InternetGateway": {
			"Type": "AWS::EC2::InternetGateway",
			"Properties": {
				"Tags": [
					{
						"Key": "Name",
						"Value": {
							"Fn::Sub": "${AWS::StackName}/InternetGateway"
						}
					}
				]
			}
		},
		"NATGateway": {
			"Type": "AWS::EC2::NatGateway",
			"Properties": {
				"AllocationId": {
					"Fn::GetAtt": [
						"NATIP",
						"AllocationId"
					]
				},
				"SubnetId": {
					"Ref": "SubnetPublicUSEAST1A"
				},
				"Tags": [
					{
						"Key": "Name",
						"Value": {
							"Fn::Sub": "${AWS::StackName}/NATGateway"
						}
					}
				]
			}
		},
		"NATIP": {
			"Type": "AWS::EC2::EIP",
			"Properties": {
				"Domain": "vpc",
				"Tags": [
					{
						"Key": "Name",
						"Value": {
							"Fn::Sub": "${AWS::StackName}/NATIP"
						}
					}
				]
			}
		},
		"NATPrivateSubnetRouteUSEAST1A": {
			"Type": "AWS::EC2::Route",
			"Properties": {
				"DestinationCidrBlock": "0.0.0.0/0",
				"NatGatewayId": {
					"Ref": "NATGateway"
				},
				"RouteTableId": {
					"Ref": "PrivateRouteTableUSEAST1A"
				}
			}
		},
		"NATPrivateSubnetRouteUSEAST1D": {
			"Type": "AWS::EC2::Route",
			"Properties": {
				"DestinationCidrBlock": "0.0.0.0/0",
				"NatGatewayId": {
					"Ref": "NATGateway"
				},
				"RouteTableId": {
					"Ref": "PrivateRouteTableUSEAST1D"
				}
			}
		},
		"PrivateRouteTableUSEAST1A": {
			"Type": "AWS::EC2::RouteTable",
			"Properties": {
				"Tags": [
					{
						"Key": "Name",
						"Value": {
							"Fn::Sub": "${AWS::StackName}/PrivateRouteTableUSEAST1A"
						}
					}
				],
				"VpcId": {
					"Ref": "VPC"
				}
			}
		},
		"PrivateRouteTableUSEAST1D": {
			"Type": "AWS::EC2::RouteTable",
			"Properties": {
				"Tags": [
					{
						"Key": "Name",
						"Value": {
							"Fn::Sub": "${AWS::StackName}/PrivateRouteTableUSEAST1D"
						}
					}
				],
				"VpcId": {
					"Ref": "VPC"
				}
			}
		},
		"PublicRouteTable": {
			"Type": "AWS::EC2::RouteTable",
			"Properties": {
				"Tags": [
					{
						"Key": "Name",
						"Value": {
							"Fn::Sub": "${AWS::StackName}/PublicRouteTable"
						}
					}
				],
				"VpcId": {
					"Ref": "VPC"
				}
			}
		},
		"PublicSubnetRoute": {
			"Type": "AWS::EC2::Route",
			"Properties": {
				"DestinationCidrBlock": "0.0.0.0/0",
				"GatewayId": {
					"Ref": "InternetGateway"
				},
				"RouteTableId": {
					"Ref": "PublicRouteTable"
				}
			},
			"DependsOn": [
				"VPCGatewayAttachment"
			]
		},
		"RouteTableAssociationPrivateUSEAST1A": {
			"Type": "AWS::EC2::SubnetRouteTableAssociation",
			"Properties": {
				"RouteTableId": {
					"Ref": "PrivateRouteTableUSEAST1A"
				},
				"SubnetId": {
					"Ref": "SubnetPrivateUSEAST1A"
				}
			}
		},
		"RouteTableAssociationPrivateUSEAST1D": {
			"Type": "AWS::EC2::SubnetRouteTableAssociation",
			"Properties": {
				"RouteTableId": {
					"Ref": "PrivateRouteTableUSEAST1D"
				},
				"SubnetId": {
					"Ref": "SubnetPrivateUSEAST1D"
				}
			}
		},
		"RouteTableAssociationPublicUSEAST1A": {
			"Type": "AWS::EC2::SubnetRouteTableAssociation",
			"Properties": {
				"RouteTableId": {
					"Ref": "PublicRouteTable"
				},
				"SubnetId": {
					"Ref": "SubnetPublicUSEAST1A"
				}
			}
		},
		"RouteTableAssociationPublicUSEAST1D": {
			"Type": "AWS::EC2::SubnetRouteTableAssociation",
			"Properties": {
				"RouteTableId": {
					"Ref": "PublicRouteTable"
				},
				"SubnetId": {
					"Ref": "SubnetPublicUSEAST1D"
				}
			}
		},
		"ServiceRole": {
			"Type": "AWS::IAM::Role",
			"Properties": {
				"AssumeRolePolicyDocument": {
					"Statement": [
						{
							"Action": [
								"sts:AssumeRole",
								"sts:TagSession"
							],
							"Effect": "Allow",
							"Principal": {
								"Service": [
									{
										"Fn::FindInMap": [
											"ServicePrincipalPartitionMap",
											{
												"Ref": "AWS::Partition"
											},
											"EKS"
										]
									}
								]
							}
						}
					],
					"Version": "2012-10-17"
				},
				"ManagedPolicyArns": [
					{
						"Fn::Sub": "arn:${AWS::Partition}:iam::aws:policy/AmazonEKSClusterPolicy"
					},
					{
						"Fn::Sub": "arn:${AWS::Partition}:iam::aws:policy/AmazonEKSVPCResourceController"
					}
				],
				"Tags": [
					{
						"Key": "Name",
						"Value": {
							"Fn::Sub": "${AWS::StackName}/ServiceRole"
						}
					}
				]
			}
		},
		"SubnetPrivateUSEAST1A": {
			"Type": "AWS::EC2::Subnet",
			"Properties": {
				"AvailabilityZone": "us-east-1a",
				"CidrBlock": "192.168.64.0/19",
				"Tags": [
					{
						"Key": "kubernetes.io/role/internal-elb",
						"Value": "1"
					},
					{
						"Key": "Name",
						"Value": {
							"Fn::Sub": "${AWS::StackName}/SubnetPrivateUSEAST1A"
						}
					}
				],
				"VpcId": {
					"Ref": "VPC"
				}
			}
		},
		"SubnetPrivateUSEAST1D": {
			"Type": "AWS::EC2::Subnet",
			"Properties": {
				"AvailabilityZone": "us-east-1d",
				"CidrBlock": "192.168.96.0/19",
				"Tags": [
					{
						"Key": "kubernetes.io/role/internal-elb",
						"Value": "1"
					},
					{
						"Key": "Name",
						"Value": {
							"Fn::Sub": "${AWS::StackName}/SubnetPrivateUSEAST1D"
						}
					}
				],
				"VpcId": {
					"Ref": "VPC"
				}
			}
		},
		"SubnetPublicUSEAST1A": {
			"Type": "AWS::EC2::Subnet",
			"Properties": {
				"AvailabilityZone": "us-east-1a",
				"CidrBlock": "192.168.0.0/19",
				"MapPublicIpOnLaunch": true,
				"Tags": [
					{
						"Key": "kubernetes.io/role/elb",
						"Value": "1"
					},
					{
						"Key": "Name",
						"Value": {
							"Fn::Sub": "${AWS::StackName}/SubnetPublicUSEAST1A"
						}
					}
				],
				"VpcId": {
					"Ref": "VPC"
				}
			}
		},
		"SubnetPublicUSEAST1D": {
			"Type": "AWS::EC2::Subnet",
			"Properties": {
				"AvailabilityZone": "us-east-1d",
				"CidrBlock": "192.168.32.0/19",
				"MapPublicIpOnLaunch": true,
				"Tags": [
					{
						"Key": "kubernetes.io/role/elb",
						"Value": "1"
					},
					{
						"Key": "Name",
						"Value": {
							"Fn::Sub": "${AWS::StackName}/SubnetPublicUSEAST1D"
						}
					}
				],
				"VpcId": {
					"Ref": "VPC"
				}
			}
		},
		"VPC": {
			"Type": "AWS::EC2::VPC",
			"Properties": {
				"CidrBlock": "192.168.0.0/16",
				"EnableDnsHostnames": true,
				"EnableDnsSupport": true,
				"Tags": [
					{
						"Key": "Name",
						"Value": {
							"Fn::Sub": "${AWS::StackName}/VPC"
						}
					}
				]
			}
		},
		"VPCGatewayAttachment": {
			"Type": "AWS::EC2::VPCGatewayAttachment",
			"Properties": {
				"InternetGatewayId": {
					"Ref": "InternetGateway"
				},
				"VpcId": {
					"Ref": "VPC"
				}
			}
		}
	},
	"Outputs": {
		"ARN": {
			"Value": {
				"Fn::GetAtt": [
					"ControlPlane",
					"Arn"
				]
			},
			"Export": {
				"Name": {
					"Fn::Sub": "${AWS::StackName}::ARN"
				}
			}
		},
		"CertificateAuthorityData": {
			"Value": {
				"Fn::GetAtt": [
					"ControlPlane",
					"CertificateAuthorityData"
				]
			}
		},
		"ClusterSecurityGroupId": {
			"Value": {
				"Fn::GetAtt": [
					"ControlPlane",
					"ClusterSecurityGroupId"
				]
			},
			"Export": {
				"Name": {
					"Fn::Sub": "${AWS::StackName}::ClusterSecurityGroupId"
				}
			}
		},
		"ClusterStackName": {
			"Value": {
				"Ref": "AWS::StackName"
			}
		},
		"Endpoint": {
			"Value": {
				"Fn::GetAtt": [
					"ControlPlane",
					"Endpoint"
				]
			},
			"Export": {
				"Name": {
					"Fn::Sub": "${AWS::StackName}::Endpoint"
				}
			}
		},
		"FeatureNATMode": {
			"Value": "Single"
		},
		"SecurityGroup": {
			"Value": {
				"Ref": "ControlPlaneSecurityGroup"
			},
			"Export": {
				"Name": {
					"Fn::Sub": "${AWS::StackName}::SecurityGroup"
				}
			}
		},
		"ServiceRoleARN": {
			"Value": {
				"Fn::GetAtt": [
					"ServiceRole",
					"Arn"
				]
			},
			"Export": {
				"Name": {
					"Fn::Sub": "${AWS::StackName}::ServiceRoleARN"
				}
			}
		},
		"SharedNodeSecurityGroup": {
			"Value": {
				"Ref": "ClusterSharedNodeSecurityGroup"
			},
			"Export": {
				"Name": {
					"Fn::Sub": "${AWS::StackName}::SharedNodeSecurityGroup"
				}
			}
		},
		"SubnetsPrivate": {
			"Value": {
				"Fn::Join": [
					",",
					[
						{
							"Ref": "SubnetPrivateUSEAST1A"
						},
						{
							"Ref": "SubnetPrivateUSEAST1D"
						}
					]
				]
			},
			"Export": {
				"Name": {
					"Fn::Sub": "${AWS::StackName}::SubnetsPrivate"
				}
			}
		},
		"SubnetsPublic": {
			"Value": {
				"Fn::Join": [
					",",
					[
						{
							"Ref": "SubnetPublicUSEAST1A"
						},
						{
							"Ref": "SubnetPublicUSEAST1D"
						}
					]
				]
			},
			"Export": {
				"Name": {
					"Fn::Sub": "${AWS::StackName}::SubnetsPublic"
				}
			}
		},
		"VPC": {
			"Value": {
				"Ref": "VPC"
			},
			"Export": {
				"Name": {
					"Fn::Sub": "${AWS::StackName}::VPC"
				}
			}
		}
	}
}

# cloudformation template for nodegroup creation
{
  "AWSTemplateFormatVersion": "2010-09-09",
  "Description": "EKS Managed Nodes (SSH access: false) [created by eksctl]",
  "Mappings": {
    "ServicePrincipalPartitionMap": {
      "aws": {
        "EC2": "ec2.amazonaws.com",
        "EKS": "eks.amazonaws.com",
        "EKSFargatePods": "eks-fargate-pods.amazonaws.com",
        "IRA": "rolesanywhere.amazonaws.com",
        "SSM": "ssm.amazonaws.com"
      },
      "aws-cn": {
        "EC2": "ec2.amazonaws.com.cn",
        "EKS": "eks.amazonaws.com",
        "EKSFargatePods": "eks-fargate-pods.amazonaws.com"
      },
      "aws-iso": {
        "EC2": "ec2.c2s.ic.gov",
        "EKS": "eks.amazonaws.com",
        "EKSFargatePods": "eks-fargate-pods.amazonaws.com"
      },
      "aws-iso-b": {
        "EC2": "ec2.sc2s.sgov.gov",
        "EKS": "eks.amazonaws.com",
        "EKSFargatePods": "eks-fargate-pods.amazonaws.com"
      },
      "aws-iso-e": {
        "EC2": "ec2.amazonaws.com",
        "EKS": "eks.amazonaws.com",
        "EKSFargatePods": "eks-fargate-pods.amazonaws.com"
      },
      "aws-iso-f": {
        "EC2": "ec2.amazonaws.com",
        "EKS": "eks.amazonaws.com",
        "EKSFargatePods": "eks-fargate-pods.amazonaws.com"
      },
      "aws-us-gov": {
        "EC2": "ec2.amazonaws.com",
        "EKS": "eks.amazonaws.com",
        "EKSFargatePods": "eks-fargate-pods.amazonaws.com",
        "IRA": "rolesanywhere.amazonaws.com",
        "SSM": "ssm.amazonaws.com"
      }
    }
  },
  "Resources": {
    "LaunchTemplate": {
      "Type": "AWS::EC2::LaunchTemplate",
      "Properties": {
        "LaunchTemplateData": {
          "BlockDeviceMappings": [
            {
              "DeviceName": "/dev/xvda",
              "Ebs": {
                "Iops": 3000,
                "Throughput": 125,
                "VolumeSize": 80,
                "VolumeType": "gp3"
              }
            }
          ],
          "MetadataOptions": {
            "HttpPutResponseHopLimit": 2,
            "HttpTokens": "required"
          },
          "SecurityGroupIds": [
            {
              "Fn::ImportValue": "eksctl-effulgencetech-dev-cluster::ClusterSecurityGroupId"
            }
          ],
          "TagSpecifications": [
            {
              "ResourceType": "instance",
              "Tags": [
                {
                  "Key": "Name",
                  "Value": "effulgencetech-dev-et-nodegroup-Node"
                },
                {
                  "Key": "alpha.eksctl.io/nodegroup-name",
                  "Value": "et-nodegroup"
                },
                {
                  "Key": "alpha.eksctl.io/nodegroup-type",
                  "Value": "managed"
                }
              ]
            },
            {
              "ResourceType": "volume",
              "Tags": [
                {
                  "Key": "Name",
                  "Value": "effulgencetech-dev-et-nodegroup-Node"
                },
                {
                  "Key": "alpha.eksctl.io/nodegroup-name",
                  "Value": "et-nodegroup"
                },
                {
                  "Key": "alpha.eksctl.io/nodegroup-type",
                  "Value": "managed"
                }
              ]
            },
            {
              "ResourceType": "network-interface",
              "Tags": [
                {
                  "Key": "Name",
                  "Value": "effulgencetech-dev-et-nodegroup-Node"
                },
                {
                  "Key": "alpha.eksctl.io/nodegroup-name",
                  "Value": "et-nodegroup"
                },
                {
                  "Key": "alpha.eksctl.io/nodegroup-type",
                  "Value": "managed"
                }
              ]
            }
          ]
        },
        "LaunchTemplateName": {
          "Fn::Sub": "${AWS::StackName}"
        }
      }
    },
    "ManagedNodeGroup": {
      "Type": "AWS::EKS::Nodegroup",
      "Properties": {
        "AmiType": "AL2_x86_64",
        "ClusterName": "effulgencetech-dev",
        "InstanceTypes": [
          "t2.medium"
        ],
        "Labels": {
          "alpha.eksctl.io/cluster-name": "effulgencetech-dev",
          "alpha.eksctl.io/nodegroup-name": "et-nodegroup"
        },
        "LaunchTemplate": {
          "Id": {
            "Ref": "LaunchTemplate"
          }
        },
        "NodeRole": {
          "Fn::GetAtt": [
            "NodeInstanceRole",
            "Arn"
          ]
        },
        "NodegroupName": "et-nodegroup",
        "ScalingConfig": {
          "DesiredSize": 2,
          "MaxSize": 3,
          "MinSize": 1
        },
        "Subnets": [
          "subnet-031313879e7b1038f",
          "subnet-0fe0364b288c2c996"
        ],
        "Tags": {
          "alpha.eksctl.io/nodegroup-name": "et-nodegroup",
          "alpha.eksctl.io/nodegroup-type": "managed"
        }
      }
    },
    "NodeInstanceRole": {
      "Type": "AWS::IAM::Role",
      "Properties": {
        "AssumeRolePolicyDocument": {
          "Statement": [
            {
              "Action": [
                "sts:AssumeRole"
              ],
              "Effect": "Allow",
              "Principal": {
                "Service": [
                  {
                    "Fn::FindInMap": [
                      "ServicePrincipalPartitionMap",
                      {
                        "Ref": "AWS::Partition"
                      },
                      "EC2"
                    ]
                  }
                ]
              }
            }
          ],
          "Version": "2012-10-17"
        },
        "ManagedPolicyArns": [
          {
            "Fn::Sub": "arn:${AWS::Partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
          },
          {
            "Fn::Sub": "arn:${AWS::Partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
          },
          {
            "Fn::Sub": "arn:${AWS::Partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
          },
          {
            "Fn::Sub": "arn:${AWS::Partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
          }
        ],
        "Path": "/",
        "Tags": [
          {
            "Key": "Name",
            "Value": {
              "Fn::Sub": "${AWS::StackName}/NodeInstanceRole"
            }
          }
        ]
      }
    }
  }
}


# "Fn::Sub": "arn:${AWS::Partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"

Key Points:
Create the EKS cluster first.

Wait for the cluster to be ready using a dummy null_resource.

Use data "aws_eks_cluster" to extract the OIDC URL after the cluster is created.

Feed this OIDC URL into the IAM module to create the IRSA role.

Pass the IRSA role ARN back into the EKS module to attach it to the vpc-cni addon.