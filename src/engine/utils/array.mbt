///|
pub fn[T] remove_if(array : Array[T], f : (T) -> Bool) -> Unit {
  array.retain(fn(item) { !f(item) })
}
