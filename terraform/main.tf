resource "aws_ecr_repository" "project4_app" {
  name                 = "project4-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = true

  tags = {
    Project     = "Project4"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_vpc" "project4" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "project4-vpc"
    Project     = "Project4"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_internet_gateway" "project4" {
  vpc_id = aws_vpc.project4.id

  tags = {
    Name        = "project4-igw"
    Project     = "Project4"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.project4.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "project4-public-${var.availability_zones[count.index]}"
    Project     = "Project4"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.project4.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name        = "project4-private-${var.availability_zones[count.index]}"
    Project     = "Project4"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.project4.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project4.id
  }

  tags = {
    Name        = "project4-public-rt"
    Project     = "Project4"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "project4-nat-eip"
    Project     = "Project4"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
resource "aws_nat_gateway" "project4" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name        = "project4-nat"
    Project     = "Project4"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }

  depends_on = [aws_internet_gateway.project4]
}
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.project4.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.project4.id
  }

  tags = {
    Name        = "project4-private-rt"
    Project     = "Project4"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
resource "aws_route_table_association" "private" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
resource "aws_iam_role" "eks_cluster" {
  name = "project4-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "project4-eks-cluster-role"
    Project     = "Project4"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
resource "aws_iam_role" "eks_node" {
  name = "project4-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "project4-eks-node-role"
    Project     = "Project4"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
resource "aws_iam_role_policy_attachment" "eks_node_worker_policy" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_ecr_policy" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

resource "aws_iam_role_policy_attachment" "eks_node_cni_policy" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
resource "aws_eks_cluster" "project4" {
  name     = "project4-eks"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.36"

  vpc_config {
    subnet_ids = concat(
      aws_subnet.public[*].id,
      aws_subnet.private[*].id
    )

    endpoint_private_access = true
    endpoint_public_access  = true
  }

  tags = {
    Name        = "project4-eks"
    Project     = "Project4"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}
resource "aws_iam_openid_connect_provider" "eks" {
  url = aws_eks_cluster.project4.identity[0].oidc[0].issuer

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = {
    Name        = "project4-eks-oidc"
    Project     = "Project4"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
resource "aws_iam_policy" "aws_load_balancer_controller" {
  name        = "AWSLoadBalancerControllerIAMPolicy-Project4"
  description = "IAM policy for the AWS Load Balancer Controller in Project 4"

  policy = file("${path.module}/aws-load-balancer-controller-policy.json")

  tags = {
    Name        = "project4-aws-load-balancer-controller-policy"
    Project     = "Project4"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
resource "aws_iam_role" "aws_load_balancer_controller" {
  name = "project4-aws-load-balancer-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"

            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "project4-aws-load-balancer-controller"
    Project     = "Project4"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}


resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}
resource "aws_eks_node_group" "project4" {
  cluster_name    = aws_eks_cluster.project4.name
  node_group_name = "project4-node-group"
  node_role_arn   = aws_iam_role.eks_node.arn

  subnet_ids = [
    aws_subnet.private[0].id,
    aws_subnet.private[1].id,
    aws_subnet.private[2].id
  ]

  instance_types = ["t3.small"]

  capacity_type = "ON_DEMAND"

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }

  update_config {
    max_unavailable = 1
  }

  tags = {
    Name        = "project4-node-group"
    Project     = "Project4"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_worker_policy,
    aws_iam_role_policy_attachment.eks_node_ecr_policy,
    aws_iam_role_policy_attachment.eks_node_cni_policy
  ]
}