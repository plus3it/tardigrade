output "cloudtrail_bucket" {
  description = "CloudTrail S3 bucket object"
  value       = module.buckets["cloudtrail"].bucket
}

output "config_bucket" {
  description = "Config S3 bucket object"
  value       = module.buckets["config"].bucket
}
