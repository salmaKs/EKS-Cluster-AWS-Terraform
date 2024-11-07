
# Import the Terraform AWS EKS module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "InternRFC-cluster"
  cluster_version = "1.30"

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
    
  }

  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  eks_managed_node_groups = {
    default = {
      ami_type = "AL2023_x86_64_STANDARD"

      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 2
      instance_type    = ["t3.medium"]
    }
  }

  # Update to map format for iam_role_additional_policies
  iam_role_additional_policies = {
    eks_access = aws_iam_policy.eks_access_policy.arn,
    ec2_access = aws_iam_policy.ec2_access_policy.arn
  }
}


# EKS Access Policy for EKS Control Plane
resource "aws_iam_policy" "eks_access_policy" {
  name        = "EKSClusterAccessPolicy"
  description = "Policy granting EKS access to manage Kubernetes API"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:AccessKubernetesApi"
        ],
        Resource = "*"
      }
    ]
  })
}

# EC2 Access Policy for Node Groups and Networking
resource "aws_iam_policy" "ec2_access_policy" {
  name        = "EC2ClusterAccessPolicy"
  description = "Policy granting EC2 permissions for EKS networking and instance management"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs"
        ],
        Resource = "*"
      }
    ]
  })
}

