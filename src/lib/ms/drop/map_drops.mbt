///|
struct MapDrops {
  drops : Map[Int, &Drop]
  spawns : @queue.Queue[DropSpawn]
  meso_icons : Map[MesoIcon, @resource.NxAnimation]
}

///|
fn MapDrops::new(src : Json) -> MapDrops raise @json.JsonDecodeError {
  let meso_icons : Map[MesoIcon, @resource.NxAnimation] = Map::new()
  meso_icons[MesoIcon::BRONZE] = nx_node_to_animation(
    get_icon_raw(src, "09000000"),
  )
  meso_icons[MesoIcon::GOLD] = nx_node_to_animation(
    get_icon_raw(src, "09000001"),
  )
  meso_icons[MesoIcon::BUNDLE] = nx_node_to_animation(
    get_icon_raw(src, "09000002"),
  )
  meso_icons[MesoIcon::BAG] = nx_node_to_animation(
    get_icon_raw(src, "09000003"),
  )
  { drops: Map::new(), spawns: @queue.new(), meso_icons }
}

///|
fn nx_node_to_animation(
  node : Json,
) -> @resource.NxAnimation raise @json.JsonDecodeError {
  @json.from_json(node)
}

///|
fn get_icon_raw(src : Json, id : String) -> Json {
  match src {
    Json::Object(root) =>
      match root.get(id) {
        Some(Json::Object(item)) => item.get("iconRaw").unwrap_or(Json::null())
        _ => Json::null()
      }
    _ => Json::null()
  }
}

///|
pub fn MapDrops::spawn(self : MapDrops, spawn : DropSpawn) -> Unit {
  self.spawns.push(spawn)
}

///|

///|
pub fn MapDrops::update(self : MapDrops, physics : @physics.Physics) -> Unit {
  loop self.spawns.pop() {
    Some(spawn) => {
      let oid = spawn.oid
      if !self.drops.contains(oid) {
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
          let icon = self.meso_icons.get(mesotype).unwrap() // TODO: handle error
          let drop = spawn.instantiate_meso(icon)
          self.drops.set(drop.get_oid(), drop)
        } else {
          let item_data = @item.request_item_data(itemid)
          let drop = spawn.instantiate_item(item_data.get_icon(true))
          self.drops.set(drop.get_oid(), drop)
        }
      }
      continue self.spawns.pop()
    }
    None => break
  }
  let to_remove = Array::new()
  for oid, drop in self.drops {
    let layer = drop.update(physics)
    if layer == -1 {
      to_remove.push(oid)
    }
  }
  for oid in to_remove {
    match self.drops.get(oid) {
      Some(drop) => {
        drop.destroy()
        self.drops.remove(oid) |> ignore
      }
      None => ()
    }
  }
}

///|
pub fn MapDrops::clear(self : MapDrops) -> Unit {
  while self.spawns.pop() is Some(_) {

  }
  for _, drop in self.drops {
    drop.destroy()
  }
  self.drops.clear()
}

///|
pub fn MapDrops::list_loot_at(
  self : MapDrops,
  playerpos : @struct.Point[Int],
) -> Iter[(Int, @struct.Point[Int])] {
  self.drops
  .iter()
  .filter(fn(it) { it.1.get_bounds().contains(playerpos) })
  .map(fn(it) { (it.0, it.1.get_position()) })
}

///|
pub fn MapDrops::remove(
  self : MapDrops,
  oid : Int,
  mode : Int,
  looter : @physics.PhysicsObject?,
) -> Unit {
  match self.drops.get(oid) {
    Some(drop) => drop.expire(mode, looter)
    None => ()
  }
}

///|
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

///|
fn DropSpawn::instantiate_meso(
  self : DropSpawn,
  icon : @resource.NxAnimation,
) -> &Drop {
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

///|
fn DropSpawn::instantiate_item(
  self : DropSpawn,
  icon : @resource.NxTexture,
) -> &Drop {
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

///|
priv enum MesoIcon {
  BRONZE
  GOLD
  BUNDLE
  BAG
} derive(Eq, Hash)
