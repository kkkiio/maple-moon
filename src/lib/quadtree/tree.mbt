///|
pub(all) enum Direction {
  BL
  TR
  TL
  BR
} derive(Eq, Debug)

///|
pub(open) trait QuadCompare {
  compare_to(Self, Self) -> Direction
}

///|
pub struct Node[K, V] {
  key : K
  value : V
  priv mut parent : Node[K, V]?
  priv mut bl : Node[K, V]?
  priv mut tr : Node[K, V]?
  priv mut tl : Node[K, V]?
  priv mut br : Node[K, V]?
}

///|
struct Tree[K, V] {
  nodes : Map[K, Node[K, V]]
  mut root : Node[K, V]?
}

///|
pub fn[K, V] Tree::new() -> Tree[K, V] {
  { nodes: Map::new(), root: None }
}

///|
pub fn[K : Hash + Eq, V : QuadCompare] Tree::add(
  self : Tree[K, V],
  key : K,
  value : V,
) -> Bool {
  if self.nodes.contains(key) {
    return false
  }
  let node = {
    key,
    value,
    parent: None,
    bl: None,
    tr: None,
    tl: None,
    br: None,
  }
  self.set_link(self.root, node)
  self.nodes.set(key, node)
  true
}

///|
pub fn[K, V : QuadCompare] Tree::ceiling_key(
  self : Tree[K, V],
  value : V,
) -> K? {
  self.ceiling_entry(value).map(fn(n) { n.key })
}

///|
pub fn[K, V : QuadCompare] Tree::ceiling_entry(
  self : Tree[K, V],
  value : V,
) -> Node[K, V]? {
  self.find_ceiling_from(self.root, value)
}

///|
fn[K, V : QuadCompare] Tree::find_ceiling_from(
  self : Tree[K, V],
  start : Node[K, V]?,
  value : V,
) -> Node[K, V]? {
  let start_node = match start {
    Some(n) => n
    None => return None
  }
  match value.compare_to(start_node.value) {
    TR =>
      if is_enough(start_node.value, value) {
        start
      } else {
        self.find_ceiling_from(start_node.tr, value) // find bigger
      }
    BR =>
      match self.find_ceiling_from(start_node.br, value) { // try lower-height
        Some(_) as res => res
        None =>
          if is_enough(start_node.value, value) {
            start
          } else {
            self.find_ceiling_from(start_node.tr, value) // find bigger
          }
      }
    TL =>
      match self.find_ceiling_from(start_node.tl, value) { // try lower-width
        Some(_) as res => res
        None =>
          if is_enough(start_node.value, value) {
            start
          } else {
            self.find_ceiling_from(start_node.tr, value) // find bigger
          }
      }
    BL => // start_node is enough, try better-fit before return start_node
      match self.find_ceiling_from(start_node.bl, value) { // try smaller
        Some(_) as res => res
        None =>
          match self.find_ceiling_from(start_node.br, value) { // try lower-height
            Some(_) as res => res
            None =>
              match self.find_ceiling_from(start_node.tl, value) { // try lower-width
                Some(_) as res => res
                None => start
              }
          }
      }
  }
}

///|
pub fn[K : Hash + Eq, V : QuadCompare] Tree::remove(
  self : Tree[K, V],
  key : K,
) -> V? {
  let node = match self.nodes.get(key) {
    Some(n) => n
    None => return None
  }
  self.nodes.remove(key)
  let parent = node.parent
  match parent {
    Some(p) => p.remove_child(key)
    None => self.root = None
  }
  [node.bl, node.tr, node.tl, node.br].each(fn(it) {
    match it {
      Some(child) => {
        let start = match parent {
          Some(_) => parent
          None => self.root
        }
        self.set_link(start, child)
      }
      _ => ()
    }
  })
  Some(node.value)
}

///|
pub fn[K, V] Tree::clear(self : Tree[K, V]) -> Unit {
  self.nodes.clear()
  self.root = None
}

///|
fn[K, V : QuadCompare] Tree::set_link(
  self : Tree[K, V],
  start : Node[K, V]?,
  node : Node[K, V],
) -> Unit {
  if self.root is None {
    self.root = Some(node)
    node.parent = None
    return
  }
  for state = start {
    match state {
      Some(next) => continue next.add_or_next(node)
      None => break
    }
  }
}

///|
fn[K, V : QuadCompare] Node::add_or_next(
  self : Node[K, V],
  child : Node[K, V],
) -> Node[K, V]? {
  let cmp = child.value.compare_to(self.value)
  match cmp {
    BL => {
      let prev = self.bl
      if self.bl is None {
        self.bl = Some(child)
        child.parent = Some(self)
      }
      prev
    }
    TR => {
      let prev = self.tr
      if self.tr is None {
        self.tr = Some(child)
        child.parent = Some(self)
      }
      prev
    }
    TL => {
      let prev = self.tl
      if self.tl is None {
        self.tl = Some(child)
        child.parent = Some(self)
      }
      prev
    }
    BR => {
      let prev = self.br
      if self.br is None {
        self.br = Some(child)
        child.parent = Some(self)
      }
      prev
    }
  }
}

///|
fn[K : Eq, V] Node::remove_child(self : Node[K, V], key : K) -> Unit {
  match self.bl {
    Some(k) =>
      if k.key == key {
        self.bl = None
        return
      }
    _ => ()
  }
  match self.tr {
    Some(k) =>
      if k.key == key {
        self.tr = None
        return
      }
    _ => ()
  }
  match self.tl {
    Some(k) =>
      if k.key == key {
        self.tl = None
        return
      }
    _ => ()
  }
  match self.br {
    Some(k) =>
      if k.key == key {
        self.br = None
        return
      }
    _ => ()
  }
}

///|
fn[T : QuadCompare] is_enough(my : T, other : T) -> Bool {
  return my.compare_to(other) == Direction::TR
}
