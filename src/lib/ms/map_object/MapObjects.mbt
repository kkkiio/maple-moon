///|
struct MapObjects[T] {
  objects : Map[Int, T]
  layers : FixedArray[Map[Int, Unit]]
  event_listeners : Array[(MapObjectEvent[T]) -> Bool]
}

///|
pub enum MapObjectEvent[T] {
  Add(T)
  Remove(Int)
  Clear
}

///|
pub fn[T] MapObjects::new() -> MapObjects[T] {
  {
    objects: {},
    layers: @map_layer.ids.map(fn(_id) { {} }),
    event_listeners: Array::new(),
  }
}

///|
pub fn[T] get(self : MapObjects[T], oid : Int) -> T? {
  self.objects.get(oid)
}

///|
pub fn[T : MapObject] draw(
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
pub fn[T : MapObject] update(
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
pub fn[T] clear(self : MapObjects[T]) -> Unit {
  self.objects.clear()
  self.layers.each(fn(layer) { layer.clear() })
  self.event_listeners.retain(fn(listener) { listener(MapObjectEvent::Clear) })
}

///|
pub fn[T] contains(self : MapObjects[T], oid : Int) -> Bool {
  self.objects.contains(oid)
}

///|
pub fn[T : MapObject] add(self : MapObjects[T], toadd : T) -> Unit {
  let oid = toadd.get_oid()
  let layer = toadd.get_layer()
  self.objects.set(oid, toadd)
  self.layers[layer].set(oid, ())
  self.event_listeners.retain(fn(listener) {
    listener(MapObjectEvent::Add(toadd))
  })
}

///|
pub fn[T : MapObject] remove(self : MapObjects[T], oid : Int) -> Unit {
  match self.objects.get(oid) {
    Some(mmo) => {
      let layer = mmo.get_layer()
      self.objects.remove(oid)
      self.layers[layer].remove(oid)
      self.event_listeners.retain(fn(listener) {
        listener(MapObjectEvent::Remove(oid))
      })
    }
    None => ()
  }
}

///|
pub fn[T] iter2(self : MapObjects[T]) -> Iter2[Int, T] {
  self.objects.iter2()
}

///|
pub fn[T] size(self : MapObjects[T]) -> Int {
  self.objects.size()
}

///|
pub fn[T] MapObjects::listen_object_changes(
  self : MapObjects[T],
  listener : (MapObjectEvent[T]) -> Bool
) -> Unit {
  self.event_listeners.push(listener)
}
