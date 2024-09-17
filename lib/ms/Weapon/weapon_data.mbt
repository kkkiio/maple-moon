struct WeaponData {
  equip_data : @equip.EquipData
  t : Type
  two_handed : Bool
  attack_speed : Int
  attack : Int
  after_image : String
}

let cache : Map[Int, WeaponData] = Map::new()

fn WeaponData::load(equipid : Int) -> WeaponData! {
  let equip_data = @equip.EquipData::get!(equipid)
  let prefix = equipid / 10000
  let t = by_value!(prefix)
  let two_handed = prefix == Type::STAFF.int_value() ||
    (
      prefix >= Type::SWORD_2H.int_value() &&
      prefix <= Type::POLEARM.int_value()
    ) ||
    prefix == Type::CROSSBOW.int_value()
  let src = @resource.character_loader().load_res(
    ["Weapon", "0" + equipid.to_string() + ".img", "info"],
  )
  let attack_speed = src["attackSpeed"].get_int!()
  let attack = src["attack"].get_int!()

  // TODO: sound

  let after_image = src["afterImage"].get_string()
  { equip_data, t, two_handed, attack_speed, attack, after_image }
}

pub fn WeaponData::get(equipid : Int) -> WeaponData! {
  match cache.get(equipid) {
    Some(data) => data
    None => {
      let data = WeaponData::load!(equipid)
      cache.set(equipid, data)
      data
    }
  }
}

pub fn get_type(self : WeaponData) -> Type {
  self.t
}

pub fn is_twohanded(self : WeaponData) -> Bool {
  self.two_handed
}

pub fn get_speed(self : WeaponData) -> Int {
  self.attack_speed
}

pub fn get_afterimage(self : WeaponData) -> String {
  self.after_image
}

pub fn get_equipdata(self : WeaponData) -> @equip.EquipData {
  self.equip_data
}

pub fn get_attack(self : WeaponData) -> Int {
  self.attack
}
