///|
struct MapObjects[T] {
  objects : Map[Int, T]
  layers : FixedArray[Map[Int, Unit]]
}

///|
pub fn MapObjects::new[T]() -> MapObjects[T] {
  { objects: {}, layers: @map_layer.ids.map(fn(_id) { {} }) }
}

///|
pub fn get[T](self : MapObjects[T], oid : Int) -> T? {
  self.objects.get(oid)
}

///|
pub fn draw[T : MapObject](
  self : MapObjects[T],
  layer : @map_layer.Id,
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Unit {
  self.layers[layer].each(fn(oid, _v) {
    match self.get(oid) {
      Some(mmo) => if mmo.is_active() { mmo.draw(viewx, viewy, alpha) }
      None => ()
    }
  })
}

///|
pub fn update[T : MapObject](
  self : MapObjects[T],
  physics : @physics.Physics
) -> Unit {
  self.objects.each(fn(oid, mmo) {
    let oldlayer = mmo.get_layer()
    let newlayer = mmo.update(physics)
    if newlayer == -1 {
      self.remove(oid)
    } else if newlayer != oldlayer {
      self.layers[oldlayer].remove(oid)
      self.layers[newlayer].set(oid, ())
    }
  })
}

///|
pub fn clear[T](self : MapObjects[T]) -> Unit {
  self.objects.clear()
  self.layers.each(fn(layer) { layer.clear() })
}

///|
pub fn contains[T](self : MapObjects[T], oid : Int) -> Bool {
  self.objects.contains(oid)
}

///|
pub fn add[T : MapObject](self : MapObjects[T], toadd : T) -> Unit {
  let oid = toadd.get_oid()
  let layer = toadd.get_layer()
  self.objects.set(oid, toadd)
  self.layers[layer].set(oid, ())
}

///|
pub fn remove[T : MapObject](self : MapObjects[T], oid : Int) -> Unit {
  match self.objects.get(oid) {
    Some(mmo) => {
      let layer = mmo.get_layer()
      self.objects.remove(oid)
      self.layers[layer].remove(oid)
    }
    None => ()
  }
}

///|
pub fn iter2[T](self : MapObjects[T]) -> Iter2[Int, T] {
  self.objects.iter2()
}

///|
pub fn size[T](self : MapObjects[T]) -> Int {
  self.objects.size()
}
