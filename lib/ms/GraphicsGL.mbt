// app/src/main/cpp/src/Graphics/GraphicsGL.h
// app/src/main/cpp/src/Graphics/GraphicsGL.cpp
// struct Quad {
//     struct Vertex {
//         // Local Space Position
//         GLshort localcoord_x;
//         GLshort localcoord_y;

//         // Texture Coordinates
//         GLshort texcoord_x;
//         GLshort texcoord_y;

//         Color color;
//     };

//     static const size_t LENGTH = 4;
//     Vertex vertices[LENGTH];

//     Quad(GLshort left,
//          GLshort right,
//          GLshort top,
//          GLshort bottom,
//          const Offset &offset,
//          const Color &color,
//          GLfloat rotation) {
//         vertices[0] = {left, top, offset.left, offset.top, color};
//         vertices[1] = {left, bottom, offset.left, offset.bottom, color};
//         vertices[2] = {right, bottom, offset.right, offset.bottom, color};
//         vertices[3] = {right, top, offset.right, offset.top, color};

//         if (rotation != 0.0f) {
//             GLfloat cos = std::cos(rotation);
//             GLfloat sin = std::sin(rotation);
//             GLshort center_x = (left + right) / 2;
//             GLshort center_y = (top + bottom) / 2;

//             for (size_t i = 0; i < LENGTH; i++) {
//                 GLshort vertice_x = vertices[i].localcoord_x - center_x;
//                 GLshort vertice_y = vertices[i].localcoord_y - center_y;
//                 GLfloat rounded_x =
//                         std::roundf(vertice_x * cos - vertice_y * sin);
//                 GLfloat rounded_y =
//                         std::roundf(vertice_x * sin + vertice_y * cos);
//                 vertices[i].localcoord_x =
//                         static_cast<GLshort>(rounded_x + center_x);
//                 vertices[i].localcoord_y =
//                         static_cast<GLshort>(rounded_y + center_y);
//             }
//         }
//     }
// };

struct GraphicsGL {
  quads : Array[Quad]
  offsets : @hashmap.HashMap[Int64, Offset]
}

pub fn draw(
  self : GraphicsGL,
  g : Gl_g,
  bmp : Bitmap,
  rect : Rectangle[Int],
  color : Color,
  angle : Double
) -> Unit {
  // if (locked_) {
  //     return;
  // }

  if color.invisible() {
    return
  }

  // if (rect.overlaps(SCREEN).not()) {
  //     return;
  // }

  self.quads.push(
    Quad::new(
      rect.left(),
      rect.right(),
      rect.top(),
      rect.bottom(),
      self.get_offset(g, bmp),
      color,
      angle,
    ),
  )
}

fn get_offset(self : GraphicsGL, g : Gl_g, bmp : Bitmap) -> Offset {
  let id = bmp.id()
  match self.offsets.get(id) {
    Some(c) => return c
    None => ()
  }
  let x = 0
  let y = 0
  let width = bmp.width()
  let height = bmp.height()
  if width <= 0 || height <= 0 {
    return Offset::default()
  }

  //     Leftover value = Leftover(x, y, width, height);

  //     size_t lid = leftovers_.findnode(
  //             value,
  //             [](const Leftover &val, const Leftover &leaf) {
  //                 return val.width() <= leaf.width() && val.height() <= leaf.height();
  //             });

  //     if (lid > 0) {
  //         const Leftover &leftover = leftovers_[lid];

  //         x = leftover.left;
  //         y = leftover.top;

  //         GLshort width_delta = leftover.width() - width;
  //         GLshort height_delta = leftover.height() - height;

  //         leftovers_.erase(lid);

  //         wasted_ -= width * height;

  //         if (width_delta >= MINLOSIZE && height_delta >= MINLOSIZE) {
  //             leftovers_.add(
  //                     rlid_,
  //                     Leftover(x + width, y + height, width_delta, height_delta));
  //             rlid_++;

  //             if (width >= MINLOSIZE) {
  //                 leftovers_.add(rlid_,
  //                                Leftover(x, y + height, width, height_delta));
  //                 rlid_++;
  //             }

  //             if (height >= MINLOSIZE) {
  //                 leftovers_.add(rlid_,
  //                                Leftover(x + width, y, width_delta, height));
  //                 rlid_++;
  //             }
  //         } else if (width_delta >= MINLOSIZE) {
  //             leftovers_.add(
  //                     rlid_,
  //                     Leftover(x + width, y, width_delta, height + height_delta));
  //             rlid_++;
  //         } else if (height_delta >= MINLOSIZE) {
  //             leftovers_.add(
  //                     rlid_,
  //                     Leftover(x, y + height, width + width_delta, height_delta));
  //             rlid_++;
  //         }
  //     } else {
  //         if (border_.x() + width > ATLASW) {
  //             border_.set_x(0);
  //             border_.shift_y(y_range_.second());

  //             if (border_.y() + height > ATLASH) {
  //                 clear_internal();
  //             } else {
  //                 y_range_ = Range<GLshort>();
  //             }
  //         }

  //         x = border_.x();
  //         y = border_.y();

  //         border_.shift_x(width);

  //         if (height > y_range_.second()) {
  //             if (x >= MINLOSIZE && height - y_range_.second() >= MINLOSIZE) {
  //                 leftovers_.add(rlid_,
  //                                Leftover(0,
  //                                         y_range_.first(),
  //                                         x,
  //                                         height - y_range_.second()));
  //                 rlid_++;
  //             }

  //             wasted_ += x * (height - y_range_.second());

  //             y_range_ = Range<int16_t>(y + height, height);
  //         } else if (height < y_range_.first() - y) {
  //             if (width >= MINLOSIZE
  //                 && y_range_.first() - y - height >= MINLOSIZE) {
  //                 leftovers_.add(rlid_,
  //                                Leftover(x,
  //                                         y + height,
  //                                         width,
  //                                         y_range_.first() - y - height));
  //                 rlid_++;
  //             }

  //             wasted_ += width * (y_range_.first() - y - height);
  //         }
  //     }

  //     // size_t used = ATLASW * border.y() + border.x() * yrange.second();
  //     //
  //     // double usedpercent = static_cast<double>(used) / (ATLASW * ATLASH);
  //     // double wastedpercent = static_cast<double>(wasted) / used;
  //     //
  //     // std::cout << "Used: [" << usedpercent << "] Wasted: [" << wastedpercent
  //     // << "]" << std::endl;

  //     glTexSubImage2D(GL_TEXTURE_2D,
  //                     0,
  //                     x,
  //                     y,
  //                     width,
  //                     height,
  //                     GL_RGBA,
  //                     GL_UNSIGNED_BYTE,
  //                     bmp.data());

  let offset = Offset::new(x, y, width, height)
  self.offsets.set(id, offset)
  offset
}

struct Quad {
  vertices : FixedArray[Vertex]
}

fn Quad::new(
  left : Int,
  right : Int,
  top : Int,
  bottom : Int,
  offset : Offset,
  color : Color,
  rotation : Double
) -> Quad {
  let vertices : FixedArray[Vertex] = [
    Vertex::new(left, top, offset.left, offset.top, color),
    Vertex::new(left, bottom, offset.left, offset.bottom, color),
    Vertex::new(right, bottom, offset.right, offset.bottom, color),
    Vertex::new(right, top, offset.right, offset.top, color),
  ]
  if rotation != 0.0 {
    let cos = @math.cos(rotation)
    let sin = @math.sin(rotation)
    let center_x = (left + right) / 2
    let center_y = (top + bottom) / 2
    vertices.iter(
      fn(v) -> Unit {
        let vertice_x = v.localcoord_x - center_x
        let vertice_y = v.localcoord_y - center_y
        let rounded_x = (vertice_x.to_double() * cos - vertice_y.to_double() * sin).round()
        let rounded_y = (vertice_x.to_double() * sin + vertice_y.to_double() * cos).round()
        v.localcoord_x = rounded_x.to_int() + center_x
        v.localcoord_y = rounded_y.to_int() + center_y
      },
    )
  }
  { vertices, }
}

struct Vertex {
  mut localcoord_x : Int
  mut localcoord_y : Int
  texcoord_x : Int
  texcoord_y : Int
  color : Color
}

fn Vertex::new(
  localcoord_x : Int,
  localcoord_y : Int,
  texcoord_x : Int,
  texcoord_y : Int,
  color : Color
) -> Vertex {
  { localcoord_x, localcoord_y, texcoord_x, texcoord_y, color }
}

struct Offset {
  left : Int
  right : Int
  top : Int
  bottom : Int
}

fn Offset::new(x : Int, y : Int, width : Int, height : Int) -> Offset {
  { left: x, right: x + width, top: y, bottom: y + height }
}

fn Offset::default() -> Offset {
  { left: 0, right: 0, top: 0, bottom: 0 }
}
