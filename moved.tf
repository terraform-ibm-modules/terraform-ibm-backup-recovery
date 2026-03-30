moved {
  from = ibm_backup_recovery_connection_registration_token.registration_token
  to   = ibm_backup_recovery_connection_registration_token.registration_token[0]
}

moved {
  from = time_rotating.token_rotation
  to   = time_rotating.token_rotation[0]
}
