module "temporary_directory" {
  path   = "${path.root}/.tmp"
  source = "../mkdir"
}

module "remove_archive_directory" {
  source  = "../powershell-command"
  command = <<COMMAND
  if (Test-Path -Path "${module.temporary_directory.path}/${var.long_prefix}") {
    Remove-Item -LiteralPath "${module.temporary_directory.path}/${var.long_prefix}" -Force -Recurse
  }
  COMMAND
}

module "archive_directory" {
  path       = "${module.temporary_directory.path}/${var.long_prefix}"
  source     = "../mkdir"
  depends_on = [module.remove_archive_directory]
}

module "install_modules" {
  source  = "../powershell-command"
  command = <<COMMAND
  ${join("\n", [for mod in var.modules : "npm install --prefix '${module.archive_directory.path}' ${mod}"])}
  COMMAND
}

resource "local_file" "lambda" {
  filename = "${module.archive_directory.path}/index.js"
  content  = var.content
}

resource "local_file" "contents" {
  for_each = var.contents
  filename = "${module.archive_directory.path}/${each.key}"
  content  = each.value
}

data "archive_file" "object" {
  type        = "zip"
  output_path = "${module.temporary_directory.path}/${var.long_prefix}-lambda.zip"
  source_dir  = module.archive_directory.path
  depends_on  = [local_file.lambda, module.install_modules, local_file.contents]
}

module "log_group" {
  source            = "../log-group"
  type              = "lambda"
  short_prefix      = var.short_prefix
  long_prefix       = var.long_prefix
  prefix            = var.short_prefix
  tags              = var.tags
  retention_in_days = var.retention_in_days
}

resource "aws_lambda_function" "object" {
  runtime          = "nodejs14.x"
  filename         = data.archive_file.object.output_path
  source_code_hash = data.archive_file.object.output_base64sha256
  function_name    = var.short_prefix
  role             = var.role
  timeout          = var.timeout
  memory_size      = var.memory_size
  handler          = var.handler
  layers           = var.layers
  dynamic "environment" {
    for_each = var.environment_variables != null ? [true] : []
    content {
      variables = var.environment_variables
    }
  }
  dynamic "vpc_config" {
    for_each = var.vpc_id != null ? [var.vpc_id] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }
  tags = merge(
    {
      Name = "${var.short_prefix}"
    },
  var.tags)
  depends_on = [module.log_group]
}
