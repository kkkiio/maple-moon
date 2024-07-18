struct LeftOver {
  w : Int
  h : Int
} derive(Debug, Eq)

fn compare_to(self : LeftOver, other : LeftOver) -> Direction {
  let wg = self.w >= other.w
  let hg = self.h >= other.h
  match (wg, hg) {
    (true, true) => Direction::TR
    (true, false) => Direction::BR
    (false, true) => Direction::TL
    (false, false) => Direction::BL
  }
}

test "empty" {
  let tree : Tree[Int, LeftOver] = Tree::new()
  @test.eq(tree.ceiling_key({ w: 0, h: 0 }), None)!
  @test.eq(tree.remove(0), None)!
}

test "best fit" {
  let tree : Tree[Int, LeftOver] = Tree::new()
  // given:
  @test.is_true(tree.add(1, { w: 1, h: 1 }))!
  @test.is_true(tree.add(2, { w: 2, h: 1 }))!
  @test.is_true(tree.add(3, { w: 1, h: 2 }))!
  @test.is_true(tree.add(4, { w: 2, h: 2 }))!
  // then:
  @test.eq(tree.ceiling_key({ w: 1, h: 1 }), Some(1))!
  @test.eq(tree.ceiling_key({ w: 2, h: 1 }), Some(2))!
  @test.eq(tree.ceiling_key({ w: 1, h: 2 }), Some(3))!
  @test.eq(tree.ceiling_key({ w: 2, h: 2 }), Some(4))!
  // when: 1,1 is removed
  @test.eq(tree.remove(1), Some({ w: 1, h: 1 }))!
  // then:
  let res = tree.ceiling_key({ w: 1, h: 1 })
  debug(res)
  @test.is_true(res == Some(2) || res == Some(3))!
}

test "remove" {
  let tree : Tree[Int, LeftOver] = Tree::new()
  let mut i = 0
  while i < 100 {
    let l = { w: i, h: i }
    @test.is_true(tree.add(i, l))!
    i = i + 1
  }
  i = 0
  while i < 100 {
    let l = { w: i, h: i }
    @test.eq(tree.remove(i), Some(l))!
    i = i + 1
  }
}

test "remove center" {
  let tree : Tree[Int, LeftOver] = Tree::new()
  // given: center 2,2 
  @test.is_true(tree.add(0, { w: 2, h: 2 }))!
  @test.is_true(tree.add(1, { w: 1, h: 1 }))!
  @test.is_true(tree.add(2, { w: 3, h: 3 }))!
  @test.is_true(tree.add(3, { w: 1, h: 3 }))!
  @test.is_true(tree.add(4, { w: 3, h: 1 }))!
  // when: remove 2,2
  @test.eq(tree.remove(0), Some({ w: 2, h: 2 }))!
  // then:
  @test.eq(tree.ceiling_key({ w: 1, h: 1 }), Some(1))!
  @test.eq(tree.ceiling_key({ w: 2, h: 1 }), Some(4))!
  @test.eq(tree.ceiling_key({ w: 1, h: 2 }), Some(3))!
  @test.eq(tree.ceiling_key({ w: 3, h: 3 }), Some(2))!
}
