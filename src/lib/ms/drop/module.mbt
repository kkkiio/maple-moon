///|
struct Module {
  map_drops : MapDrops
}

///|
priv struct MapDropsContext {
  mut map_drops : MapDrops?
  mut loading : @utils.Future[Result[MapDrops, Error]]?
  pending_spawns : Array[DropSpawn]
  pending_removes : Array[(Int, Int)]
  mut physics : @physics.Physics?
}

///|
let map_drops_ctx : Ref[MapDropsContext?] = Ref::new(None)

///|
let scene_cleanup_registered : Ref[Bool] = Ref::new(false)

///|
fn new_loading_future() -> @utils.Future[Result[MapDrops, Error]] {
  @io_service.submit_background_task(async fn() {
    let loaded = Module::load()
    loaded.get_map_drops()
  })
}

///|
pub async fn Module::load() -> Module {
  let special_item_loader = @resource.get_item_special_loader()
  let src = special_item_loader.load_resource(["0900.img"])
  { map_drops: MapDrops::new(src) }
}

///|
pub fn Module::get_map_drops(self : Module) -> MapDrops {
  self.map_drops
}

///|

///|
pub fn setup_game_server_handlers() -> Unit {
  register_scene_cleanup_once()
  if map_drops_ctx.val is None {
    map_drops_ctx.val = Some({
      map_drops: None,
      loading: Some(new_loading_future()),
      pending_spawns: [],
      pending_removes: [],
      physics: None,
    })
  }
  @game_server.add_server_message_handler(
    "drop_loot",
    @server_proto.Opcode::DROP_LOOT.int_value(),
    json => {
      guard map_drops_ctx.val is Some(ctx) else { return }
      let drop : @server_proto.DropLootMessage = @json.from_json(json)
      let spawn : DropSpawn = {
        oid: drop.oid,
        item_id: drop.item_id,
        meso: drop.meso,
        owner: drop.owner,
        start: drop.dropfrom,
        dest: drop.dropto,
        drop_type: drop.pickuptype,
        mode: drop.mode,
        player_drop: drop.player_drop,
      }
      match ctx.map_drops {
        Some(map_drops) => map_drops.spawn(spawn)
        None => ctx.pending_spawns.push(spawn)
      }
    },
  )
  @game_server.add_server_message_handler(
    "remove_loot",
    @server_proto.Opcode::REMOVE_LOOT.int_value(),
    json => {
      guard map_drops_ctx.val is Some(ctx) else { return }
      let remove : @server_proto.RemoveLootMessage = @json.from_json(json)
      match ctx.map_drops {
        Some(map_drops) => map_drops.remove(remove.oid, remove.mode, None) // TODO: looter
        None => ctx.pending_removes.push((remove.oid, remove.mode))
      }
    },
  )
}

///|
fn register_scene_cleanup_once() -> Unit {
  if scene_cleanup_registered.val {
    return
  }
  scene_cleanup_registered.val = true
  @game_state.listen_scene_clear(fn(_reason) {
    clear_map_drops()
    true
  })
}

///|
pub fn set_map_physics(physics : @physics.Physics) -> Unit {
  if map_drops_ctx.val is Some(ctx) {
    ctx.physics = Some(physics)
  }
}

///|
pub fn clear_map_drops() -> Unit {
  if map_drops_ctx.val is Some(ctx) {
    match ctx.map_drops {
      Some(map_drops) => map_drops.clear()
      None => ()
    }
    ctx.pending_spawns.clear()
    ctx.pending_removes.clear()
    ctx.physics = None
  }
}

///|
pub fn map_drops_system(_delta : Double) -> Unit {
  guard map_drops_ctx.val is Some(ctx) else { return }
  if ctx.map_drops is None {
    match ctx.loading {
      Some(loading) =>
        match loading.poll() {
          Some(Ok(map_drops)) => {
            ctx.map_drops = Some(map_drops)
            ctx.loading = None
            for drop in ctx.pending_spawns {
              map_drops.spawn(drop)
            }
            for remove in ctx.pending_removes {
              map_drops.remove(remove.0, remove.1, None)
            }
            ctx.pending_spawns.clear()
            ctx.pending_removes.clear()
          }
          Some(Err(err)) => {
            @log.error("failed to load map drops", data={
              "err": err.to_string(),
            })
            ctx.loading = None
          }
          None => return
        }
      None => {
        ctx.loading = Some(new_loading_future())
        return
      }
    }
  }
  guard ctx.map_drops is Some(map_drops) else { return }
  guard ctx.physics is Some(physics) else { return }
  let times = @logic_fps.get_logic_times()
  for i = 0; i < times; i = i + 1 {
    map_drops.update(physics)
  }
}

///|
/// Try to pick up one drop intersecting the player's current position.
pub fn try_pickup_at(player_pos : @struct.Point[Int]) -> Bool {
  guard map_drops_ctx.val is Some(ctx) else { return false }
  guard ctx.map_drops is Some(map_drops) else { return false }
  for loot in map_drops.list_loot_at(player_pos) {
    let (oid, pos) = loot
    @game_server.send(@server_proto.PickupItemMessage::{ oid, position: pos })
    return true
  }
  false
}
