///|
pub fn login_account_ffi(
  mod : Module,
  account : String,
  password : String,
  callback : (String) -> Unit
) -> Unit {
  mod.login(account, password, callback)
}

///|
pub fn login_last_used_ffi(mod : Module, callback : (String) -> Unit) -> Unit {
  mod.login_last_used(callback)
}
