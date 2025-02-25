provider "aws" {
  region = "eu-central-1"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket = "mein-pipeline-artifacts-bucket-${random_string.suffix.result}"

}

resource "aws_s3_bucket_public_access_block" "pipeline_artifacts" {
  bucket                  = aws_s3_bucket.pipeline_artifacts.bucket
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
  depends_on              = [aws_s3_bucket.pipeline_artifacts, aws_s3_bucket_policy.pipeline_artifacts_policy]
}
resource "aws_s3_bucket_website_configuration" "pipeline_artifacts" {
  bucket = aws_s3_bucket.pipeline_artifacts.bucket
  index_document {
    suffix = "index.html"
  }
  depends_on = [aws_s3_bucket.pipeline_artifacts]
}

resource "aws_s3_bucket_policy" "pipeline_artifacts_policy" {
  bucket = aws_s3_bucket.pipeline_artifacts.bucket

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.pipeline_artifacts.arn}/*"
      }
    ]
  })
  depends_on = [aws_s3_bucket.pipeline_artifacts]
}

resource "aws_iam_role" "codepipeline_role" {
  name = "CodePipelineRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement : [{
      Effect = "Allow",
      Principal : {
        Service = "codepipeline.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role" "codebuild_role" {
  name = "CodeBuildRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement : [{
      Effect = "Allow",
      Principal : {
        Service = "codebuild.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "pipeline_policy" {
  name        = "PipelineCustomPolicy"
  description = "Kombinierte Berechtigungen für CodePipeline, CodeBuild und CloudWatch Logs"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["s3:*"],
        Resource = [
          "${aws_s3_bucket.pipeline_artifacts.arn}",
          "${aws_s3_bucket.pipeline_artifacts.arn}/*"
        ]
      },
      {
        Effect   = "Allow",
        Action   = ["codebuild:*"],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "codebuild:StartBuild"
        ],
        Resource = "arn:aws:codebuild:eu-central-1:861276110132:project/MeinBuildProjekt"
      },
      {
        Effect   = "Allow",
        Action   = ["codepipeline:*"],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:eu-central-1:861276110132:log-group:/aws/codebuild/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_policy_attachment" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.pipeline_policy.arn
}

resource "aws_iam_role_policy_attachment" "codepipeline_policy_attachment" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.pipeline_policy.arn
}

resource "aws_codebuild_project" "build" {
  name         = "MeinBuildProjekt"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:5.0"
    type         = "LINUX_CONTAINER"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "aws-pipeline/app/buildspec.yml"
  }
}

resource "aws_codepipeline" "pipeline" {
  name     = "MeinPipelineProjekt"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.pipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "GitHub_Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = "fchristian1"
        Repo       = "cicd"
        Branch     = "main"
        OAuthToken = var.github_token
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "S3_Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        BucketName = aws_s3_bucket.pipeline_artifacts.bucket
        Extract    = "true"
      }
    }
  }
}

variable "github_token" {
  description = "GitHub OAuth Token für Zugriff auf das Repository"
  type        = string
  sensitive   = true
}
