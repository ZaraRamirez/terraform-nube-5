data "aws_caller_identity" "current" {}

locals {
  state_bucket = coalesce(var.state_bucket_name, "${var.project}-tfstate-${data.aws_caller_identity.current.account_id}")
}

# ---------- Bucket de estado remoto ----------
resource "aws_s3_bucket" "state" {
  bucket = local.state_bucket
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------- Rol de GitHub Actions (OIDC), opcional ----------
# En AWS Academy Learner Lab no se pueden crear roles IAM: create_github_role = false
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_github_role && var.github_oidc_provider_arn == null ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

locals {
  oidc_provider_arn = var.create_github_role ? coalesce(var.github_oidc_provider_arn, try(aws_iam_openid_connect_provider.github[0].arn, null)) : null
}

data "aws_iam_policy_document" "github_assume" {
  count = var.create_github_role ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_owner}/${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "github" {
  count = var.create_github_role ? 1 : 0

  name               = "${var.project}-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_assume[0].json
}

# Terraform crea VPC, RDS, ECS, IAM, etc.: se necesita un permiso amplio.
resource "aws_iam_role_policy_attachment" "github" {
  count = var.create_github_role ? 1 : 0

  role       = aws_iam_role.github[0].name
  policy_arn = var.github_role_policy_arn
}
