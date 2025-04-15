///|
pub fn login_account(
  mod : Module,
  account : String,
  password : String,
  callback : (String) -> Unit
) -> Unit {
  mod.login(account, password, callback)
}
