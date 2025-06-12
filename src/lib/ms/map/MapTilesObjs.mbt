///| A tile and obj layer.
struct TilesObjs {
  tiles : Array[Tile] // sorted by z
  objs : Array[Obj] // sorted by z
}

///|
pub async fn TilesObjs::load(
  ts : String?,
  tile_resource : Array[TileResource],
  obj_resource : Array[ObjResource]
) -> TilesObjs! {
  let tileset = if ts is Some(ts) {
    Some(tile_loader.load_res_async([ts + ".img"]))
  } else {
    None
  }
  // Load tiles
  let tiles = []
  for tilenode in tile_resource {
    tiles.push(Tile::new(tilenode, tileset))
  }

  // Load objects
  let objs = []
  for objnode in obj_resource {
    objs.push(Obj::load(objnode))
  }
  TilesObjs::new(tiles, objs)
}

///|
fn TilesObjs::new(tiles : Array[Tile], objs : Array[Obj]) -> TilesObjs {
  // Sort tiles and objs by z
  let tileZMap = Map::new()
  for tile in tiles {
    let z = tile.get_z()
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
pub fn TilesObjs::update(self : TilesObjs) -> Unit {
  for obj in self.objs {
    obj.update()
  }
}

///|
pub fn TilesObjs::draw(
  self : TilesObjs,
  viewpos : Point[Int],
  alpha : Double
) -> Unit {
  for obj in self.objs {
    obj.draw(viewpos, alpha)
  }
  for tile in self.tiles {
    tile.draw(viewpos)
  }
}

///| The collection of tile and obj layers on a map.
struct MapTilesObjs {
  layers : Array[TilesObjs]
}

///|
pub async fn MapTilesObjs::load(
  layer_resource : Array[LayerResource]
) -> MapTilesObjs! {
  let layers = []
  for id in @map_layer.ids {
    let layer = layer_resource[id]
    layers.push(
      TilesObjs::load(layer.info.map(fn(it) { it.tS }), layer.tile, layer.obj),
    )
  }
  { layers, }
}

///|
pub fn MapTilesObjs::default() -> MapTilesObjs {
  {
    layers: Array::makei(@map_layer.ids.length(), fn(_i) {
      TilesObjs::default()
    }),
  }
}

///|
pub fn MapTilesObjs::update(self : MapTilesObjs) -> Unit {
  for layer in self.layers {
    layer.update()
  }
}

///|
pub fn MapTilesObjs::draw(
  self : MapTilesObjs,
  layer : Int,
  viewpos : Point[Int],
  alpha : Double
) -> Unit {
  self.layers[layer].draw(viewpos, alpha)
}
