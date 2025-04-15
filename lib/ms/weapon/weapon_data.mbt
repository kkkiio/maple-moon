///|
struct WeaponData {
  equip_data : @data.EquipData
  t : Type
  two_handed : Bool
  attack_speed : Int
  attack : Int
  after_image : String
}

///|
pub fn WeaponData::from_item_data(item_data : @item.ItemData) -> WeaponData! {
  let equip_data = @data.EquipData::from_item_data!(item_data)
  let prefix = item_data.item_id / 10000
  let t = Type::by_value!(prefix)
  let two_handed = prefix == Type::STAFF.int_value() ||
    (
      prefix >= Type::SWORD_2H.int_value() &&
      prefix <= Type::POLEARM.int_value()
    ) ||
    prefix == Type::CROSSBOW.int_value()
  if equip_data.get_category() != "Weapon" {
    fail!("unsupported weapon type=\{equip_data.get_category()}")
  }
  let info = item_data.get_info()
  match info {
    {
      "attackSpeed": Json::Number(attack_speed),
      "attack": Json::Number(attack),
      "afterImage": Json::String(after_image),
      ..
    } => {
      let attack_speed = attack_speed.to_int()
      let attack = attack.to_int()
      let after_image = after_image
      // TODO: sound
      { equip_data, t, two_handed, attack_speed, attack, after_image }
    }
    _ => fail!("Invalid weapon data")
  }
}

///|
pub fn get_type(self : WeaponData) -> Type {
  self.t
}

///|
pub fn is_twohanded(self : WeaponData) -> Bool {
  self.two_handed
}

///|
pub fn get_speed(self : WeaponData) -> Int {
  self.attack_speed
}

///|
pub fn get_afterimage(self : WeaponData) -> String {
  self.after_image
}

///|
pub fn get_equipdata(self : WeaponData) -> @data.EquipData {
  self.equip_data
}

///|
pub fn get_attack(self : WeaponData) -> Int {
  self.attack
}
