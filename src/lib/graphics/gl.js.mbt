///|
priv extern type GLenum

///|
extern "js" fn GL::ge(self : GL, name : String) -> GLenum =
  #| (gl, n) => gl[n]

///|
extern "js" fn GL::gi(self : GL, name : String) -> Int =
  #| (gl, n) => gl[n]

///| 
extern "js" fn GL::texParameteri(
  self : GL,
  target : GLenum,
  pname : GLenum,
  param : Int
) -> Unit =
  #| (gl, t, p, param) => gl.texParameteri(t, p, param)

///| 
extern "js" fn GL::enable(self : GL, cap : GLenum) -> Unit =
  #| (gl, c) => gl.enable(c)

///| 
extern "js" fn GL::pixelStorei(self : GL, pname : GLenum, param : Bool) -> Unit =
  #| (gl, p, param) => gl.pixelStorei(p, param)

///| 
extern "js" fn GL::blendFunc(
  self : GL,
  sfactor : GLenum,
  dfactor : GLenum
) -> Unit =
  #| (gl, s, d) => gl.blendFunc(s, d)
