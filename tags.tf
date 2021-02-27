module "tags" {
  source = "git::git@github.com:Shkurupii/training-aws-modules.git//modules/tags"
  username = var.username
  environment = var.environment
  workspace = var.workspace
}
