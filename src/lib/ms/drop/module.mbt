///|
struct Module {
  map_drops : MapDrops
}

///|
priv struct MapDropsContext {
  mut map_drops : MapDrops?
  mut loading : @utils.Future[Result[MapDrops, Error]]?
  pending_spawns : Array[DropLoot]
  pending_removes : Array[RemoveLoot]
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
  let src = special_item_loader.load_res_async(["0900.img"])
  { map_drops: MapDrops::new(src.value()) }
}

///|
pub fn Module::get_map_drops(self : Module) -> MapDrops {
  self.map_drops
}

///|
pub fn Module::make_handlers(
  self : Module,
  get_character_by_id_fn : (Int) -> @physics.PhysicsObject?,
) -> Map[@net.Opcode, (@net.InPacket) -> Unit] {
  [
    @net.make_handler(@net.DROP_LOOT, parse_drop_loot, (drop : DropLoot) => {
      handle_drop_loot_parsed(self.map_drops, drop)
    }),
    @net.make_handler(@net.REMOVE_LOOT, parse_remove_loot, (remove : RemoveLoot) => {
      handle_remove_loot_parsed(self.map_drops, remove, get_character_by_id_fn)
    }),
  ]
  |> Map::from_array
}

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
    @net.Opcode::DROP_LOOT.int_value(),
    json => {
      guard map_drops_ctx.val is Some(ctx) else { return }
      let drop : @maple_protocol.DropLootMessage = @json.from_json(json)
      let parsed : DropLoot = {
        mode: drop.mode,
        oid: drop.oid,
        meso: drop.meso,
        item_id: drop.item_id,
        owner: drop.owner,
        pickuptype: drop.pickuptype,
        dropto: drop.dropto,
        dropfrom: drop.dropfrom,
        player_drop: drop.player_drop,
      }
      match ctx.map_drops {
        Some(map_drops) => handle_drop_loot_parsed(map_drops, parsed)
        None => ctx.pending_spawns.push(parsed)
      }
    },
  )
  @game_server.add_server_message_handler(
    "remove_loot",
    @net.Opcode::REMOVE_LOOT.int_value(),
    json => {
      guard map_drops_ctx.val is Some(ctx) else { return }
      let remove : @maple_protocol.RemoveLootMessage = @json.from_json(json)
      let parsed : RemoveLoot = {
        mode: remove.mode,
        oid: remove.oid,
        cid: remove.cid,
      }
      match ctx.map_drops {
        Some(map_drops) =>
          handle_remove_loot_parsed(map_drops, parsed, fn(_id) { None })
        None => ctx.pending_removes.push(parsed)
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
              handle_drop_loot_parsed(map_drops, drop)
            }
            for remove in ctx.pending_removes {
              handle_remove_loot_parsed(map_drops, remove, fn(_id) { None })
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
