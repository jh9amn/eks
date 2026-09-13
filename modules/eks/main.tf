# Master node group

## Create an IAM role for the EKS cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-eks-cluster-role"

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
}

## Attach the AmazonEKSClusterPolicy to the EKS cluster role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

## Create the EKS cluster
resource "aws_eks_cluster" "main" {
    name     = var.cluster_name
    role_arn = aws_iam_role.eks_cluster_role.arn
    version  = var.cluster_version
    
    vpc_config {
        subnet_ids = concat(
        aws_subnet.private.*.id,
        aws_subnet.public.*.id
        )
    }
    
    depends_on = [
        aws_iam_role_policy_attachment.eks_cluster_policy_attachment
    ]
}




/*-------------------------------------------------------------------*/

# Worker node group

## IAM role for the EKS worker nodes
resource "aws_iam_role" "eks_worker_role" {
  name = "${var.cluster_name}-eks-worker-role"

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
}

## Attach the AmazonEKSWorkerNodePolicy, AmazonEC2ContainerRegistryReadOnly, and AmazonEKS_CNI_Policy to the EKS worker role
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy_attachment" {
    for_each = toset([
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
        "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    ])

  role       = aws_iam_role.eks_worker_role.name
  policy_arn = each.value

}


## Create the EKS worker node group
resource "aws_eks_node_group" "main" {
    for_each = var.node_groups

    cluster_name    = aws_eks_cluster.main.name
    node_group_name = "${var.cluster_name}-${each.key}-node-group"
    node_role_arn   = aws_iam_role.eks_worker_role.arn
    subnet_ids      = aws_subnet.private.*.id
    instance_types  = each.value.instance_types
    capacity_type   = each.value.capacity_type

    scaling_config {
        desired_size = each.value.scaling_config.desired_size
        max_size     = each.value.scaling_config.max_size
        min_size     = each.value.scaling_config.min_size
    }

    depends_on = [
        aws_iam_role_policy_attachment.eks_worker_node_policy_attachment,
        aws_eks_cluster.main
    ]
}