///|
pub struct Module {
  inventory : Inventory
}

///|
pub fn Module::Module(inventory : Inventory) -> Module {
  { inventory, }
}
