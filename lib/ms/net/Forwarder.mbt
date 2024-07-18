pub trait Forwarder {
  forward(Self, Bytes) -> Unit
}
