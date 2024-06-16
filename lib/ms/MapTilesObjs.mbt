// A tile and obj layer.
struct TilesObjs {
  tiles : Map[Int, Tile]
  objs : Map[Int, Obj]
}

pub fn TilesObjs::from_resource(src : NxNode) -> TilesObjs {
  let tiles = Map::new()
  let objs = Map::new()
  let tileset = src["info"]["tS"].get_string() + ".img"
  src["tile"].get_object().iter(
    fn(_k, tilenode) {
      let tile = Tile::from_resource(tilenode, tileset)
      let z = tile.get_z()
      tiles.set(z, tile)
    },
  )
  src["obj"].get_object().iter(
    fn(_k, objnode) {
      let obj = Obj::from_resource(objnode)
      let z = obj.get_z()
      objs.set(z, obj)
    },
  )
  { tiles, objs }
}

pub fn TilesObjs::default() -> TilesObjs {
  { tiles: Map::new(), objs: Map::new() }
}

pub fn update(self : TilesObjs) -> Unit {
  self.objs.iter(fn(_k, obj) { obj.update() })
}

pub fn draw(self : TilesObjs, viewpos : Point[Int], alpha : Double) -> Unit {
  self.objs.iter(fn(_k, obj) { obj.draw(viewpos, alpha) })
  self.tiles.iter(fn(_k, tile) { tile.draw(viewpos) })
}

// The collection of tile and obj layers on a map.
struct MapTilesObjs {
  layers : FixedArray[TilesObjs]
}

pub fn MapTilesObjs::from_resource(src : NxNode) -> MapTilesObjs {
  let layers = FixedArray::new_with_index(
    @Layer.ids.length(),
    fn(layer_id) { TilesObjs::from_resource(src[layer_id.to_string()]) },
  )
  { layers, }
}

pub fn MapTilesObjs::default() -> MapTilesObjs {
  {
    layers: FixedArray::new(@Layer.ids.length(), fn() { TilesObjs::default() }),
  }
}

pub fn update(self : MapTilesObjs) -> Unit {
  self.layers.iter(fn(layer) { layer.update() })
}

pub fn draw(
  self : MapTilesObjs,
  layer : Int,
  viewpos : Point[Int],
  alpha : Double
) -> Unit {
  self.layers[layer].draw(viewpos, alpha)
}
