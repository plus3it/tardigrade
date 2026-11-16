# Migration for global-only resource gating
# These moved blocks preserve existing global resources when count = 1 adds [0] to addresses

moved {
  from = module.cloudtrail
  to   = module.cloudtrail[0]
}

moved {
  from = module.iam_account
  to   = module.iam_account[0]
}
