output "repository_urls" {
  description = "Map of repository name → URL"
  value = {
    for name, repo in aws_ecr_repository.services : name => repo.repository_url
  }
}

output "repository_arns" {
  description = "Map of repository name → ARN"
  value = {
    for name, repo in aws_ecr_repository.services : name => repo.arn
  }
}
