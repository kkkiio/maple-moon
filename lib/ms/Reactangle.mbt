// app/src/main/cpp/src/Template/Rectangle.h
// template<class T>
// class Rectangle {
// public:
//     Rectangle(const nl::node &sourceLeftTop,
//               const nl::node &sourceRightBottom) :
//         left_top_(sourceLeftTop),
//         right_bottom_(sourceRightBottom) {}
//     Rectangle(const nl::node &source) :
//         left_top_(source["lt"]),
//         right_bottom_(source["rb"]) {}

//     constexpr Rectangle(Point<T> leftTop, Point<T> rightBottom) :
//         left_top_(leftTop),
//         right_bottom_(rightBottom) {}
//     constexpr Rectangle(T left, T right, T top, T bottom) :
//         left_top_(left, top),
//         right_bottom_(right, bottom) {}
//     constexpr Rectangle() = default;

//     constexpr T width() const { return std::abs(left() - right()); }

//     constexpr T height() const { return std::abs(top() - bottom()); }

//     constexpr T left() const { return left_top_.x(); }

//     constexpr T top() const { return left_top_.y(); }

//     constexpr T right() const { return right_bottom_.x(); }

//     constexpr T bottom() const { return right_bottom_.y(); }

//     constexpr bool contains(const Point<T> &v) const {
//         return !straight() && v.x() >= left() && v.x() <= right()
//                && v.y() >= top() && v.y() <= bottom();
//     }

//     constexpr bool overlaps(const Rectangle<T> &ar) const {
//         return get_horizontal().overlaps(Range<T>(ar.left(), ar.right()))
//                && get_vertical().overlaps(Range<T>(ar.top(), ar.bottom()));
//     }

//     constexpr bool straight() const { return left_top_ == right_bottom_; }

//     constexpr bool empty() const {
//         return left_top_.straight() && right_bottom_.straight() && straight();
//     }

//     constexpr const Point<T> &get_left_top() const { return left_top_; }

//     constexpr const Point<T> &get_right_bottom() const { return right_bottom_; }

//     constexpr Range<T> get_horizontal() const { return { left(), right() }; }

//     constexpr Range<T> get_vertical() const { return { top(), bottom() }; }

//     void shift(const Point<T> &v) {
//         left_top_ = left_top_ + v;
//         right_bottom_ = right_bottom_ + v;
//     }

// private:
//     Point<T> left_top_;
//     Point<T> right_bottom_;
// };

struct Rectangle[T] {
  left_top : Point[T]
  right_bottom : Point[T]
}

pub fn Rectangle::from4[T](
  left : T,
  right : T,
  top : T,
  bottom : T
) -> Rectangle[T] {
  { left_top: { x: left, y: top }, right_bottom: { x: right, y: bottom } }
}

pub fn left[T](self : Rectangle[T]) -> T {
  self.left_top.x
}

pub fn top[T](self : Rectangle[T]) -> T {
  self.left_top.y
}

pub fn right[T](self : Rectangle[T]) -> T {
  self.right_bottom.x
}

pub fn bottom[T](self : Rectangle[T]) -> T {
  self.right_bottom.y
}
