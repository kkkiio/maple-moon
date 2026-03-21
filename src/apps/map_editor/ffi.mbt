///|
#external
priv type Value

///|
fn[T] Value::cast_from(value : T) -> Value = "%identity"

///|
fn[T] Value::cast(self : Value) -> T = "%identity"

///|
extern "js" fn Value::undefined() -> Value =
  #| () => undefined

///|
#external
type JsOptional[_]

///|
fn[T] JsOptional::from_option(value : T?) -> JsOptional[T] {
  match value {
    Some(v) => Value::cast_from(v).cast()
    None => Value::undefined().cast()
  }
}
