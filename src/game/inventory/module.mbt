///|
pub struct Module {
  inventory : Inventory
}

///|
pub fn Module::new(inventory : Inventory) -> Module {
  { inventory, }
}
