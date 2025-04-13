///|
struct MapDrops {
  drops : @map_object.MapObjects[&Drop]
  loading_drops : Array[@utils.Future[Result[&Drop, Error]]]
  spawns : @queue.T[DropSpawn]
  meso_icons : Map[MesoIcon, @graphics.Animation]
}

///|
fn MapDrops::new(src : @resource.NxNode) -> MapDrops {
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
    loading_drops: Array::new(),
    spawns: @queue.new(),
    meso_icons,
  }
}

///|
pub fn spawn(self : MapDrops, spawn : DropSpawn) -> Unit {
  self.spawns.push(spawn)
}

///|
pub fn draw(
  self : MapDrops,
  layer : @map_layer.Id,
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Unit {
  self.drops.draw(layer, viewx, viewy, alpha)
}

///|
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
            self.loading_drops.push(
              @item.ItemData::get_async(itemid).map_exn(fn(r) {
                let item_data = r.unwrap_or_error!()
                spawn.instantiate_item(item_data.get_icon(true))
              }),
            )
          }
        }
      }
      continue self.spawns.pop()
    }
    None => break
  }
  self.loading_drops.retain(fn(it) {
    guard let Some(res) = it.poll() else { None => return true }
    guard let Ok(drop) = res else {
      Err(e) => {
        @log.error({ "err": Show::to_string(e) }, "failed to load drop")
        true
      }
    }
    self.drops.add(drop)
    false
  })
  for _, mesoicon in self.meso_icons {
    mesoicon.update() |> ignore
  }
  self.drops.update(physics)
}

///|
pub fn clear(self : MapDrops) -> Unit {
  self.drops.clear()
}

///|
pub fn list_loot_at(
  self : MapDrops,
  playerpos : @struct.Point[Int]
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
  looter : @physics.PhysicsObject?
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
  icon : @graphics.Animation
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
  icon : @graphics.Texture
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
enum MesoIcon {
  BRONZE
  GOLD
  BUNDLE
  BAG
} derive(Eq, Hash)

///|
let special_item_loader : @resource.AsyncLoader = @resource.AsyncLoader::new(
  "special_item",
)
