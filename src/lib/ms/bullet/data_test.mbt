///|
async test "bullet data load supports official entries without incPAD" {
  @resource.set_item_loader(@local_loader.make_local_item_loader())
  @resource.set_character_loader(@local_loader.make_local_character_loader())
  @resource.set_string_loader(@local_loader.make_local_string_loader())
  let arrow = BulletData::load("02060000")
  inspect(arrow.watk, content="0")
  let crossbow_bolt = BulletData::load("02061000")
  inspect(crossbow_bolt.watk, content="0")
}
