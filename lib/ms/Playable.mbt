// Interface for classes which can be controlled through key inputs.
trait Playable {
  // Sends a keystate to the object.
  send_action(Self, @KeyAction.Id, Bool) -> Unit
}
