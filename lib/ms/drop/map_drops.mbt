struct MapDrops {
  drops : @map_object.MapObjects[Drop]
  spawns : @queue.T[DropSpawn]
  meso_icons : Map[MesoIcon, @graphics.Animation]
  mut loot_enabled : Bool
}

pub fn MapDrops::new() -> MapDrops {
  let src = @item.get_item_loader().load_res(["Special", "0900.img"])
  let meso_icons : Map[MesoIcon, @graphics.Animation] = Map::new()
  meso_icons[MesoIcon::BRONZE] = src["09000000"]["iconRaw"]
    |> @graphics.Animation::from_resource
  meso_icons[MesoIcon::GOLD] = src["09000001"]["iconRaw"]
    |> @graphics.Animation::from_resource
  meso_icons[MesoIcon::BUNDLE] = src["09000002"]["iconRaw"]
    |> @graphics.Animation::from_resource
  meso_icons[MesoIcon::BAG] = src["09000003"]["iconRaw"]
    |> @graphics.Animation::from_resource
  {
    drops: @map_object.MapObjects::new(),
    spawns: @queue.T::new(),
    meso_icons,
    loot_enabled: false,
  }
}

pub fn MapDrops::spawn(self : MapDrops, spawn : DropSpawn) -> Unit {
  self.spawns.push(spawn)
}

pub fn MapDrops::draw(
  self : MapDrops,
  layer : @layer.Id,
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Unit {
  self.drops.draw(layer, viewx, viewy, alpha)
}

pub fn MapDrops::update(self : MapDrops, physics : @physics.Physics) -> Unit {
  loop self.spawns.pop() {
    Some(spawn) => {
      let oid = spawn.oid
      match self.drops.get(oid) {
        Some(drop) => drop.makeactive()
        None => {
          let itemid = spawn.item_id
          let meso = spawn.meso
          if meso {
            let mesotype = if itemid > 999 {
              BAG
            } else if itemid > 99 {
              BUNDLE
            } else if itemid > 49 {
              GOLD
            } else {
              BRONZE
            }
            let icon = self.meso_icons[mesotype].unwrap()
            self.drops.add(spawn.instantiate_meso(icon))
          } else {
            let itemdata = @item.ItemData::get?(itemid).unwrap()
            self.drops.add(spawn.instantiate_item(itemdata.get_icon(true)))
          }
        }
      }
      continue self.spawns.pop()
    }
    None => break
  }
  for _, mesoicon in self.meso_icons {
    mesoicon.update() |> ignore
  }
  self.drops.update(physics)
  self.loot_enabled = true
}

pub fn MapDrops::clear(self : MapDrops) -> Unit {
  self.drops.clear()
}

pub fn MapDrops::find_loot_at(
  self : MapDrops,
  playerpos : @struct.Point[Int]
) -> (Int, @struct.Point[Int])? {
  guard self.loot_enabled else { return None }
  for oid, drop in self.drops {
    if drop.bounds().contains(playerpos) {
      self.loot_enabled = false
      let position = drop.get_position()
      return Some((oid, position))
    }
  }
  None
}

pub fn MapDrops::remove(
  self : MapDrops,
  oid : Int,
  mode : Int,
  looter : @physics.PhysicsObject?
) -> Unit {
  match self.drops.get(oid) {
    Some(drop) => drop.expire(mode, looter)
    None => ()
  }
}

struct DropSpawn {
  oid : Int
  item_id : Int
  meso : Bool
  owner : Int
  start : @struct.Point[Int]
  dest : @struct.Point[Int]
  drop_type : Int
  mode : Int
  player_drop : Bool
}

fn DropSpawn::instantiate_meso(
  self : DropSpawn,
  icon : @graphics.Animation
) -> Drop {
  MesoDrop::new(
    self.oid,
    self.owner,
    self.start,
    self.dest,
    self.drop_type,
    self.mode,
    self.player_drop,
    icon,
  )
}

fn DropSpawn::instantiate_item(
  self : DropSpawn,
  icon : @graphics.Texture
) -> Drop {
  ItemDrop::new(
    self.oid,
    self.owner,
    self.start,
    self.dest,
    self.drop_type,
    self.mode,
    self.item_id,
    self.player_drop,
    icon,
  )
}

enum MesoIcon {
  BRONZE
  GOLD
  BUNDLE
  BAG
} derive(Eq, Hash)
