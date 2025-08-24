///|
struct LocalStorage {} derive(Default)

///|
pub fn LocalStorage::new() -> LocalStorage {
  LocalStorage::default()
}

///| Sets the value of the pair identified by `key` to `value`.
pub fn LocalStorage::set_item(
  _ : LocalStorage,
  key : String,
  value : String
) -> Unit {
  set_item(key, value)
}

///| Retrieves the current value associated with the given `key`.
/// Returns `Some(value)` if the key exists, or `None` otherwise.
pub fn LocalStorage::get_item(_ : LocalStorage, key : String) -> String? {
  get_item(key)
}

///| Removes the key-value pair with the given `key` from localStorage.
pub fn LocalStorage::remove_item(_ : LocalStorage, key : String) -> Unit {
  remove_item(key)
}
