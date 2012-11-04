package cities;

import org.lwjgl.opengl.GL11;

class GLError {
  public static void check() throws RuntimeException {
    int code = GL11.glGetError();
    if (code != GL11.GL_NO_ERROR) {
      throw(new RuntimeException("OpenGL error: 0x" + Integer.toHexString(code)));
    }
  }
}