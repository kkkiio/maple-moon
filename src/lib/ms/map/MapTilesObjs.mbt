///|
/// A tile and obj layer.
struct TilesObjs {
  tiles : Array[Tile] // sorted by z
  objs : Array[Obj] // sorted by z
}

///|
pub async fn TilesObjs::load(
  ts : String?,
  tile_resource : Array[NxTileRef],
  obj_resource : Array[NxObj],
) -> TilesObjs raise {
  let tileset = if ts is Some(ts) {
    let tile_loader : @resource.AsyncLoader = @resource.AsyncLoader::new(
      "tile",
      loader=@resource.DirResourceLoader::new(
        "https://maple-res.kkkiiox.work/Map/Tile",
      ),
    )
    let node = tile_loader.load_res_async([ts + ".img"])
    Some(@json.from_json(node.value()))
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
pub fn TilesObjs::update(self : TilesObjs) -> Unit {
  for obj in self.objs {
    obj.update()
  }
}

///|
pub fn TilesObjs::set_sprites(self : TilesObjs) -> Unit {
  for obj in self.objs {
    obj.set_sprites()
  }
  for tile in self.tiles {
    tile.set_sprites()
  }
}

///|
/// The collection of tile and obj layers on a map.
struct MapTilesObjs {
  layers : Array[TilesObjs]
}

///|
pub async fn MapTilesObjs::load(
  layer_resource : Array[NxLayer],
) -> MapTilesObjs raise {
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
pub fn MapTilesObjs::update(self : MapTilesObjs) -> Unit {
  for layer in self.layers {
    layer.update()
  }
}

///|
pub fn MapTilesObjs::set_sprites(self : MapTilesObjs) -> Unit {
  for layer in self.layers {
    layer.set_sprites()
  }
}
