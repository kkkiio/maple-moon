///|
struct MapDrops {
  drops : Map[Int, &Drop]
  spawns : @queue.Queue[DropSpawn]
  meso_icons : Map[MesoIcon, MesoDropAnimation]
}

///|
fn MapDrops::MapDrops(src : Json) -> MapDrops raise {
  let meso_icons : Map[MesoIcon, MesoDropAnimation] = Map([])
  let icon_entries : Array[(MesoIcon, String)] = [
    (MesoIcon::BRONZE, "09000000"),
    (MesoIcon::GOLD, "09000001"),
    (MesoIcon::BUNDLE, "09000002"),
    (MesoIcon::BAG, "09000003"),
  ]
  for entry in icon_entries {
    let (icon_type, resource_id) = entry
    let source = nx_node_to_animation(get_icon_raw(src, resource_id))
    let clip = @res.compile_nx_animation(
      source,
      name="drop/meso/\{resource_id}",
    )
    let (graph, node) = @graphics.sprite_clip_graph(clip)
    meso_icons[icon_type] = { clip, graph, node }
  }
  { drops: Map([]), spawns: @queue.Queue([]), meso_icons }
}

///|
fn nx_node_to_animation(
  node : Json,
) -> @res.NxAnimation raise @json.JsonDecodeError {
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
  for elem = self.spawns.pop() {
    match elem {
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
  animation : MesoDropAnimation,
) -> &Drop {
  MesoDrop(
    self.oid,
    self.owner,
    self.start,
    self.dest,
    self.drop_type,
    self.mode,
    self.player_drop,
    animation,
  )
}

///|
fn DropSpawn::instantiate_item(
  self : DropSpawn,
  icon : @res.NxTexture,
) -> &Drop {
  ItemDrop(
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
