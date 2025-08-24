///|
extern "js" fn set_item(key : String, value : String) -> Unit =
  #| (key, value) => localStorage.setItem(key, value)

///|
extern "js" fn get_item(key : String) -> String? =
  #| (key) => {
  #|  let value = localStorage.getItem(key)
  #|  return value === null ? undefined : value
  #|}

///|
extern "js" fn remove_item(key : String) -> Unit =
  #| (key) => localStorage.removeItem(key)
