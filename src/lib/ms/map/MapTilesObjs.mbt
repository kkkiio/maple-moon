///|
/// A tile and obj layer.
struct TilesObjs {
  tiles : Array[Tile] // sorted by z
  objs : Array[Obj] // sorted by z
}

///|
pub async fn load_tileset(ts : String) -> NxTileSet {
  let tile_loader : @resource.AsyncLoader = @resource.AsyncLoader::new(
    "tile",
    loader=@resource.DirResourceLoader::new(
      // "https://maple-res.kkkiiox.work/Map/Tile",
      "/assets/map/tile",
    ),
    base_url="/assets",
  )
  let node = tile_loader.load_res_async([ts + ".img"])
  @json.from_json(node.value())
}

///|
pub fn TilesObjs::load(
  tileset : NxTileSet?,
  object_sets : Map[String, Map[ObjectAnimationPath, @resource.NxAnimation]],
  tile_resource : Array[NxTileRef],
  obj_resource : Array[NxObj],
) -> TilesObjs {
  // Load tiles
  let tiles = []
  for tilenode in tile_resource {
    tiles.push(Tile::new(tilenode, tileset))
  }

  // Load objects
  let objs = []
  for nx_obj in obj_resource {
    let animation = object_sets[nx_obj.oS][ObjectAnimationPath::from_obj(nx_obj)]
    objs.push(Obj::new(nx_obj, animation))
  }
  TilesObjs::new(tiles, objs)
}

///|
fn TilesObjs::new(tiles : Array[Tile], objs : Array[Obj]) -> TilesObjs {
  // Sort tiles and objs by z
  let tileZMap = Map::new()
  for tile in tiles {
    let z = tile.z
    tileZMap.get_or_init(z, fn() { [] }).push(tile)
  }
  let objZMap = Map::new()
  for obj in objs {
    let z = obj.get_z()
    objZMap.get_or_init(z, fn() { [] }).push(obj)
  }
  let zTiles = tileZMap.to_array()
  zTiles.sort_by_key(fn(it) { it.0 })
  let zObjs = objZMap.to_array()
  zObjs.sort_by_key(fn(it) { it.0 })
  {
    tiles: zTiles.iter().flat_map(fn(it) { it.1.iter() }).collect(),
    objs: zObjs.iter().flat_map(fn(it) { it.1.iter() }).collect(),
  }
}

///|
pub fn TilesObjs::default() -> TilesObjs {
  { tiles: [], objs: [] }
}

///|
/// The collection of tile and obj layers on a map.
struct MapTilesObjs {
  layers : Array[TilesObjs]
}

///|
pub fn MapTilesObjs::load(
  tilesets : Map[String, NxTileSet],
  object_sets : Map[String, Map[ObjectAnimationPath, @resource.NxAnimation]],
  layer_resource : Array[NxLayer],
) -> MapTilesObjs {
  let layers = []
  for id in @map_layer.ids {
    let layer = layer_resource[id]
    let tileset = if layer.info is Some({ tS }) {
      Some(tilesets[tS])
    } else {
      None
    }
    layers.push(TilesObjs::load(tileset, object_sets, layer.tile, layer.obj))
  }
  { layers, }
}

///|
pub struct TileObjectsVisibility {
  tiles_visible : Bool
  objs_visible : Bool
} derive(Show)

///|
priv struct TileObjectsContext {
  tiles_objs : MapTilesObjs
  tile_entities : Array[@entity.Entity]
  obj_entities : Array[@entity.Entity]
  mut tiles_visible : Bool
  mut objs_visible : Bool
  mut tiles_dirty : Bool
  mut objs_dirty : Bool
}

///|
let tile_objects_context : Ref[TileObjectsContext?] = Ref::new(None)

///|
/// 将地图的 Tile 与 Obj 数据绑定到渲染系统，创建/重建对应实体。
/// - `tiles_objs`: 解析后的 Tile/Obj 数据。
pub fn set_tiles_objs(tiles_objs : MapTilesObjs) -> Unit {
  if tile_objects_context.val is Some(ctx) {
    destroy_entities(ctx.tile_entities)
    destroy_entities(ctx.obj_entities)
  }
  tile_objects_context.val = Some({
    tiles_objs,
    tile_entities: [],
    obj_entities: [],
    tiles_visible: true,
    objs_visible: true,
    tiles_dirty: true,
    objs_dirty: true,
  })
}

///|
/// Tile 与 Obj 的刷新系统，在 App 的系统调度中注册，用于懒加载实体与切换可见性。
pub fn tile_objects_system(_delta : Double) -> Unit {
  guard tile_objects_context.val is Some(ctx) else { return }
  ensure_tile_entities(ctx)
  ensure_obj_entities(ctx)
  if ctx.tiles_dirty {
    apply_tile_visibility(ctx)
    ctx.tiles_dirty = false
  }
  if ctx.objs_dirty {
    apply_obj_visibility(ctx)
    ctx.objs_dirty = false
  }
}

///|
/// 控制 Tile 显示或隐藏。隐藏时会移除对应实体的 sprite。
/// - `visible`: `true` 显示全部 Tile，`false` 则全部隐藏。
pub fn set_tiles_visible(visible : Bool) -> Unit {
  guard tile_objects_context.val is Some(ctx) else { return }
  if ctx.tiles_visible == visible {
    return
  }
  ctx.tiles_visible = visible
  ctx.tiles_dirty = true
}

///|
/// 控制 Obj 显示或隐藏。隐藏时会移除对应实体的 sprite。
/// - `visible`: `true` 显示全部 Obj，`false` 则全部隐藏。
pub fn set_objs_visible(visible : Bool) -> Unit {
  guard tile_objects_context.val is Some(ctx) else { return }
  if ctx.objs_visible == visible {
    return
  }
  ctx.objs_visible = visible
  ctx.objs_dirty = true
}

///|
/// 获取当前 Tile/Obj 的可见性状态，用于调试显示。
pub fn get_tile_objects_visibility() -> TileObjectsVisibility {
  match tile_objects_context.val {
    Some({ tiles_visible, objs_visible, .. }) => { tiles_visible, objs_visible }
    None => { tiles_visible: true, objs_visible: true }
  }
}

///|
fn destroy_entities(entities : Array[@entity.Entity]) -> Unit {
  for entity in entities {
    entity.destroy()
  }
  entities.clear()
}

///|
fn ensure_tile_entities(ctx : TileObjectsContext) -> Unit {
  let expected = count_tiles(ctx.tiles_objs)
  if ctx.tile_entities.length() == expected {
    return
  }
  destroy_entities(ctx.tile_entities)
  for _ in 0..<expected {
    ctx.tile_entities.push(@entity.Entity::new())
  }
  ctx.tiles_dirty = true
}

///|
fn ensure_obj_entities(ctx : TileObjectsContext) -> Unit {
  let expected = count_objs(ctx.tiles_objs)
  if ctx.obj_entities.length() == expected {
    return
  }
  destroy_entities(ctx.obj_entities)
  for _ in 0..<expected {
    ctx.obj_entities.push(@entity.Entity::new())
  }
  ctx.objs_dirty = true
}

///|
fn apply_tile_visibility(ctx : TileObjectsContext) -> Unit {
  let mut idx = 0
  for layer in ctx.tiles_objs.layers {
    for tile in layer.tiles {
      let entity = ctx.tile_entities[idx]
      if ctx.tiles_visible {
        ensure_tile_sprite(tile, entity)
        set_entity_visibility(entity, true)
      } else {
        set_entity_visibility(entity, false)
      }
      idx += 1
    }
  }
}

///|
fn apply_obj_visibility(ctx : TileObjectsContext) -> Unit {
  let mut idx = 0
  for layer in ctx.tiles_objs.layers {
    for obj in layer.objs {
      let entity = ctx.obj_entities[idx]
      if ctx.objs_visible {
        ensure_obj_sprite(obj, entity)
        set_entity_visibility(entity, true)
      } else {
        set_entity_visibility(entity, false)
      }
      idx += 1
    }
  }
}

///|
fn count_tiles(tiles_objs : MapTilesObjs) -> Int {
  let mut total = 0
  for layer in tiles_objs.layers {
    total += layer.tiles.length()
  }
  total
}

///|
fn count_objs(tiles_objs : MapTilesObjs) -> Int {
  let mut total = 0
  for layer in tiles_objs.layers {
    total += layer.objs.length()
  }
  total
}

///|
fn ensure_tile_sprite(tile : Tile, entity : @entity.Entity) -> Unit {
  if @sprite.sprites.get(entity) is Some(_) {
    return
  }
  tile.attach_entity(entity)
}

///|
fn ensure_obj_sprite(obj : Obj, entity : @entity.Entity) -> Unit {
  if @sprite.sprites.get(entity) is Some(_) {
    return
  }
  obj.attach_entity(entity)
}

///|
fn set_entity_visibility(entity : @entity.Entity, visible : Bool) -> Unit {
  if @sprite.sprites.get(entity) is Some(sprite) {
    sprite.visible = visible
  }
}
