// app/src/main/cpp/src/Template/Interpolated.h
// template<typename T>
// template<typename T>
// class Linear {
//     static_assert(
//         std::is_floating_point<T>::value,
//         "Template parameter 'T' for Linear must be a floating point type.");

// public:
//     T get() const { return now_; }

//     T get(T alpha) const { return lerp(before_, now_, alpha); }

//     T last() const { return before_; }

//     void set(T value) {
//         now_ = value;
//         before_ = value;
//     }

//     void normalize() { before_ = now_; }

//     bool normalized() const { return before_ == now_; }

//     void operator=(T value) {
//         before_ = now_;
//         now_ = value;
//     }

//     void operator+=(T value) {
//         before_ = now_;
//         now_ += value;
//     }

//     void operator-=(T value) {
//         before_ = now_;
//         now_ -= value;
//     }

//     bool operator==(T value) const { return now_ == value; }

//     bool operator!=(T value) const { return now_ != value; }

//     bool operator<(T value) const { return now_ < value; }

//     bool operator<=(T value) const { return now_ <= value; }

//     bool operator>(T value) const { return now_ > value; }

//     bool operator>=(T value) const { return now_ >= value; }

//     T operator+(T value) const { return now_ + value; }

//     T operator-(T value) const { return now_ - value; }

//     T operator*(T value) const { return now_ * value; }

//     T operator/(T value) const { return now_ / value; }

//     T operator+(Linear<T> value) const { return now_ + value.get(); }

//     T operator-(Linear<T> value) const { return now_ - value.get(); }

//     T operator*(Linear<T> value) const { return now_ * value.get(); }

//     T operator/(Linear<T> value) const { return now_ / value.get(); }

// private:
//     T now_;
//     T before_;
// };

struct Nominal[T] {
  mut now : T
  mut before : T
  mut threshold : Double
}

fn Nominal::default[T : Default]() -> Nominal[T] {
  { now: T::default(), before: T::default(), threshold: 0.0 }
}

pub fn get[T](self : Nominal[T], alpha : Double) -> T {
  if alpha >= self.threshold {
    self.now
  } else {
    self.before
  }
}

pub fn last[T](self : Nominal[T]) -> T {
  self.before
}

pub fn set[T](self : Nominal[T], value : T) -> Unit {
  self.before = self.now
  self.now = value
}

pub fn normalize[T](self : Nominal[T]) -> Unit {
  self.before = self.now
}

pub fn normalized[T : Eq](self : Nominal[T]) -> Bool {
  self.before == self.now
}

pub fn next[T](self : Nominal[T], value : T, thrs : Double) -> Unit {
  self.before = self.now
  self.now = value
  self.threshold = thrs
}

struct Linear {
  mut now : Double
  mut before : Double
} derive(Default)

pub fn get(self : Linear, alpha : Double) -> Double {
  lerp(self.before, self.now, alpha)
}

pub fn set(self : Linear, value : Double) -> Unit {
  self.before = self.now
  self.now = value
}

pub fn last(self : Linear) -> Double {
  self.before
}

fn add(self : Linear, value : Double) -> Unit {
  self.before = self.now
  self.now += value
}

pub fn normalize(self : Linear) -> Unit {
  self.before = self.now
}

pub fn normalized(self : Linear) -> Bool {
  self.before == self.now
}

fn plus(self : Linear, value : Double) -> Double {
  self.now + value
}
