///|
struct MapDrops {
  drops : @map_object.MapObjects[&Drop]
  loading_drops : Array[@utils.Future[Result[&Drop, Error]]]
  spawns : @queue.Queue[DropSpawn]
  meso_icons : Map[MesoIcon, @resource.NxAnimation]
}

///|
fn MapDrops::new(src : @resource.NxNode) -> MapDrops raise @json.JsonDecodeError {
  let meso_icons : Map[MesoIcon, @resource.NxAnimation] = Map::new()
  meso_icons[MesoIcon::BRONZE] = nx_node_to_animation(src["09000000"]["iconRaw"])
  meso_icons[MesoIcon::GOLD] = nx_node_to_animation(src["09000001"]["iconRaw"])
  meso_icons[MesoIcon::BUNDLE] = nx_node_to_animation(src["09000002"]["iconRaw"])
  meso_icons[MesoIcon::BAG] = nx_node_to_animation(src["09000003"]["iconRaw"])
  {
    drops: @map_object.MapObjects::new(),
    loading_drops: Array::new(),
    spawns: @queue.new(),
    meso_icons,
  }
}

///|
fn nx_node_to_animation(
  node : @resource.NxNode,
) -> @resource.NxAnimation raise @json.JsonDecodeError {
  @json.from_json(node.value())
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
      if not(self.drops.contains(oid)) {
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
          self.drops.add(spawn.instantiate_meso(icon))
        } else {
          self.loading_drops.push(
            @io_service.submit_background_task(fn() {
              let item_data = @item.ItemData::get_async(itemid)
              spawn.instantiate_item(item_data.get_icon(true))
            }),
          )
        }
      }
      continue self.spawns.pop()
    }
    None => break
  }
  self.loading_drops.retain(fn(it) {
    guard it.poll() is Some(res) else { return true }
    match res {
      Ok(drop) => self.drops.add(drop)
      Err(e) => {
        @log.error("failed to load drop", data={ "err": Show::to_string(e) })
        return true
      }
    }
    false
  })
  self.drops.update(physics)
}

///|
pub fn MapDrops::clear(self : MapDrops) -> Unit {
  self.drops.clear()
}

///|
pub fn MapDrops::list_loot_at(
  self : MapDrops,
  playerpos : @struct.Point[Int],
) -> Iter[(Int, @struct.Point[Int])] {
  self.drops
  .iter2()
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
) -> ItemDrop {
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
