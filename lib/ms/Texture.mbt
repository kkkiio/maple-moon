// app/src/main/cpp/src/Graphics/Texture.h
// #pragma once

// #include <nlnx/bitmap.hpp>

// #include "DrawArgument.h"

// namespace ms {
// // Represents a single image loaded from a of game data
// class Texture {
// public:
//     Texture(nl::node source);

//     Texture();

//     ~Texture() = default;

//     void draw(const DrawArgument &args) const;

//     void shift(Point<int16_t> amount);

//     bool is_valid() const;

//     int16_t width() const;

//     int16_t height() const;

//     Point<int16_t> get_origin() const;

//     Point<int16_t> get_dimensions() const;

// private:
//     static nl::node find_child(const nl::node &source, const std::string &link);

//     nl::bitmap bitmap_;
//     Point<int16_t> origin_;
//     Point<int16_t> dimensions_;
// };
// }  // namespace ms
// #include "Texture.h"

// #include "GraphicsGL.h"

// namespace ms {
// Texture::Texture(nl::node src) {
//     if (src.data_type() == nl::node::type::bitmap) {
//         origin_ = src["origin"];

//         std::string source = src["source"];
//         std::string _outlink = src["_outlink"];
//         std::string _inlink = src["_inlink"];

//         auto foundSource = find_child(src, source);
//         auto foundOutlink = find_child(src, _outlink);

//         auto foundChild = foundSource || foundOutlink;

//         if (foundChild) {
//             src = foundSource ? foundSource : foundOutlink;
//         }

//         if (!foundChild && !_inlink.empty()) {
//             auto parent_node = src.root();

//             for (auto child_node = parent_node.begin();
//                  child_node != parent_node.end();
//                  ++child_node) {
//                 auto found_node = child_node.resolve(_inlink);

//                 if (found_node.data_type() == nl::node::type::bitmap) {
//                     src = found_node;
//                     break;
//                 }
//             }
//         }

//         bitmap_ = src;
//         dimensions_ = Point<int16_t>(bitmap_.width(), bitmap_.height());

//         GraphicsGL::get().add_bitmap(bitmap_);
//     }
// }

// Texture::Texture() = default;

// void Texture::draw(const DrawArgument &args) const {
// size_t id = bitmap_.id();

// if (id == 0) {
//     return;
// }

// GraphicsGL::get().draw(bitmap_,
//                        args.get_rectangle(origin_, dimensions_),
//                        args.get_color(),
//                        args.get_angle());
// }

// void Texture::shift(Point<int16_t> amount) {
//     origin_ -= amount;
// }

// bool Texture::is_valid() const {
//     return bitmap_.id() > 0;
// }

// int16_t Texture::width() const {
//     return dimensions_.x();
// }

// int16_t Texture::height() const {
//     return dimensions_.y();
// }

// Point<int16_t> Texture::get_origin() const {
//     return origin_;
// }

// Point<int16_t> Texture::get_dimensions() const {
//     return dimensions_;
// }

// nl::node Texture::find_child(const nl::node &source, const std::string &link) {
//     if (!link.empty()) {
//         nl::node parent_node = source.root();

//         return parent_node.resolve(link.substr(link.find('/') + 1));
//     }

//     return nl::node();
// }
// }  // namespace ms

struct Texture {
  bitmap : Bitmap?
  mut origin : Point[Int]
  dimensions : Point[Int]
} derive(Default)

fn Texture::from_resource(src : NxNode) -> Texture {
  println("loading texture from resource " + src.loader.name() + " " + src.path)
  match src["__b"].desc.as_number() {
    Some(bid) =>
      {
        bitmap: Some(src.loader.load_bitmap(bid.to_int())),
        origin: { x: 0, y: 0 },
        dimensions: { x: src["__w"].get_int(), y: src["__h"].get_int() },
      }
    None => { bitmap: None, origin: { x: 0, y: 0 }, dimensions: { x: 0, y: 0 } }
  }
}

fn draw(self : Texture, args : DrawArgument) -> Unit {
  match self.bitmap {
    None => ()
    Some(bitmap) => {
      // let rect = args.get_rectangle(self.origin, self.dimensions)
      let rect = Rectangle::from4(
        args.pos.x,
        args.pos.x + self.dimensions.x,
        args.pos.y,
        args.pos.y + self.dimensions.y,
      )
      let color = args.color
      GraphicsGL::get().draw_bitmap(bitmap, rect, color, args.angle)
    }
  }
}

pub fn shift(self : Texture, amount : Point[Int]) -> Unit {
  self.origin -= amount
}
