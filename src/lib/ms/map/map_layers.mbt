///|
/// A tile and obj layer.
struct TilesObjsLayer {
  object_z_offset : Int
  objs : Array[Obj] // sorted by z
  tile_z_offset : Int
  tiles : Array[Tile] // sorted by z
  z_end : Int
}

///|
pub async fn load_tileset(ts : String) -> NxTileSet {
  let node = get_tile_loader().load_res_async([ts + ".img"])
  @json.from_json(node.value())
}

///|
pub fn TilesObjsLayer::from_resources(
  tileset : NxTileSet?,
  object_sets : Map[String, Map[ObjectAnimationPath, @resource.NxAnimation]],
  tile_resource : Array[NxTileRef],
  obj_resource : Array[NxObj],
  z_offset : Int,
) -> TilesObjsLayer {
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
  TilesObjsLayer::new(tiles, objs, z_offset)
}

///|
fn TilesObjsLayer::new(
  tiles : Array[Tile],
  objs : Array[Obj],
  z_offset : Int,
) -> TilesObjsLayer {
  let obj_z_map = Map::new()
  let object_z_offset = z_offset
  let mut max_z = 0
  for obj in objs {
    let z = obj.get_z()
    max_z = @cmp.maximum(max_z, z)
    obj_z_map.get_or_init(z, fn() { [] }).push(obj)
  }
  let tile_z_map = Map::new()
  let tile_z_offset = object_z_offset + max_z
  let mut max_z = 0
  for tile in tiles {
    let z = tile.z
    max_z = @cmp.maximum(max_z, z)
    tile_z_map.get_or_init(z, fn() { [] }).push(tile)
  }
  let z_end = tile_z_offset + max_z
  let zTiles = tile_z_map.to_array()
  zTiles.sort_by_key(fn(it) { it.0 })
  let zObjs = obj_z_map.to_array()
  zObjs.sort_by_key(fn(it) { it.0 })
  {
    tiles: zTiles.iter().flat_map(fn(it) { it.1.iter() }).collect(),
    objs: zObjs.iter().flat_map(fn(it) { it.1.iter() }).collect(),
    tile_z_offset,
    object_z_offset,
    z_end,
  }
}

///|
/// The collection of tile and obj layers on a map.
struct MapLayers {
  layers : Array[TilesObjsLayer]
}

///|
pub fn MapLayers::new(
  tilesets : Map[String, NxTileSet],
  object_sets : Map[String, Map[ObjectAnimationPath, @resource.NxAnimation]],
  layer_resource : Array[NxLayer],
) -> MapLayers {
  let layers = []
  let mut z_offset = @graphics.OBJECT_TILE_LAYER_ZINDEX
  for i in @graphics.map_layers {
    let nx_layer = layer_resource[i]
    let tileset = if nx_layer.info is Some({ tS }) {
      Some(tilesets[tS])
    } else {
      None
    }
    let layer = TilesObjsLayer::from_resources(
      tileset,
      object_sets,
      nx_layer.tile,
      nx_layer.obj,
      z_offset,
    )
    z_offset = layer.z_end
    layers.push(layer)
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
  tiles_objs : MapLayers
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
pub fn set_tiles_objs(tiles_objs : MapLayers) -> Unit {
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
    let z_offset = layer.tile_z_offset
    for tile in layer.tiles {
      let entity = ctx.tile_entities[idx]
      if ctx.tiles_visible {
        ensure_tile_sprite(tile, entity, z_offset)
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
    let z_offset = layer.object_z_offset
    for obj in layer.objs {
      let entity = ctx.obj_entities[idx]
      if ctx.objs_visible {
        ensure_obj_sprite(obj, entity, z_offset)
        set_entity_visibility(entity, true)
      } else {
        set_entity_visibility(entity, false)
      }
      idx += 1
    }
  }
}

///|
fn count_tiles(tiles_objs : MapLayers) -> Int {
  let mut total = 0
  for layer in tiles_objs.layers {
    total += layer.tiles.length()
  }
  total
}

///|
fn count_objs(tiles_objs : MapLayers) -> Int {
  let mut total = 0
  for layer in tiles_objs.layers {
    total += layer.objs.length()
  }
  total
}

///|
fn ensure_tile_sprite(
  tile : Tile,
  entity : @entity.Entity,
  z_offset : Int,
) -> Unit {
  if @sprite.sprites.get(entity) is Some(_) {
    return
  }
  tile.attach_entity(entity, z_offset)
}

///|
fn ensure_obj_sprite(
  obj : Obj,
  entity : @entity.Entity,
  z_offset : Int,
) -> Unit {
  if @sprite.sprites.get(entity) is Some(_) {
    return
  }
  obj.attach_entity(entity, z_offset)
}

///|
fn set_entity_visibility(entity : @entity.Entity, visible : Bool) -> Unit {
  if @sprite.sprites.get(entity) is Some(sprite) {
    sprite.visible = visible
  }
}

///|
using @resource {get_tile_loader}
