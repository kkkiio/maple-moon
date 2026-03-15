///|
struct Module {
  change_job : (Int) -> Unit
}

///|
pub fn Module::new(change_job : (Int) -> Unit) -> Module {
  { change_job, }
}
