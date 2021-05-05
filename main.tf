# Create IAM User for infrastructure management
# Also create a IAM Role so that other people can do things
# =======================
terraform {
  required_version = "~> 0.14.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  # This already exists from s3backend/
  backend "s3" {
    bucket         = "uwhackweek-tfstate"
    key            = "coiled-iam-user-config.tfstate"
    region         = "us-west-2"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-west-2"
}

data "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "uwhackweek-tfstate"
}

output "access_key" {
  value       = aws_iam_access_key.coiled-actor.id
  description = "coiled user access key"
}

output "secret_access_key" {
  value       = aws_iam_access_key.coiled-actor.secret
  description = "coiled user access key"
}

resource "aws_iam_user" "coiled-actor" {
  name = "coiled"
}

# Create ACCESS_KEY and SECRET_ACCESS_KEY
resource "aws_iam_access_key" "coiled-actor" {
  user = aws_iam_user.coiled-actor.name
}

resource "aws_iam_policy" "coiled-actor" {
  name        = "coiled-actions-user-policy"
  description = "Allow coiled user to assume role"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "sts:AssumeRole",
                "sts:TagSession"
            ],
            "Resource": "${aws_iam_role.coiled-role.arn}",
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_user_policy_attachment" "coiled-actor" {
  user       = aws_iam_user.coiled-actor.name
  policy_arn = aws_iam_policy.coiled-actor.arn
}

resource "aws_iam_role" "coiled-role" {
  name               = "coiled-actions-role"
  assume_role_policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [{
			"Sid": "AllowIamUserAssumeRole",
			"Effect": "Allow",
			"Action": "sts:AssumeRole",
			"Principal": {
				"AWS": "${aws_iam_user.coiled-actor.arn}"
			}
		},
		{
			"Sid": "AllowPassSessionTags",
			"Effect": "Allow",
			"Action": "sts:TagSession",
			"Principal": {
				"AWS": "${aws_iam_user.coiled-actor.arn}"
			}
		}
	]
}
EOF
}

# Permisions for what the role can do once assumed
# Simple test: access ti files in a specific S3 bucket
resource "aws_iam_policy" "coiled-tfs3" {
  name   = "coiled-role-tfs3"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${data.aws_s3_bucket.terraform_state_bucket.arn}",
        "${data.aws_s3_bucket.terraform_state_bucket.arn}/*"
      ]
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "coiled-tfs3" {
  role       = aws_iam_role.coiled-role.name
  policy_arn = aws_iam_policy.coiled-tfs3.arn
}

# Attach an AWS-managed policy for doing anything with S3
#resource "aws_iam_role_policy_attachment" "AmazonS3FullAccess" {
#  role       = aws_iam_role.coiled-role.name
#  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
#}

# More advanced: all required coiled permissions (read from sidecar file)
resource "aws_iam_policy" "coiled-permissions" {
  name   = "coiled-permissions"
  policy = file("coiled-permissions.json")
}

resource "aws_iam_role_policy_attachment" "coiled-permissions" {
  role       = aws_iam_role.coiled-role.name
  policy_arn = aws_iam_policy.coiled-permissions.arn
}
