package cities;

import org.lwjgl.opengl.GL11;
import cities.GLError;

class Camera {
  // viewportHeight and viewportWidth are given in pixels. viewportZoom = pixels per OpenGL unit.
  // Currently, glTranslate is called before rotating about the z axis. This gives an intuitive feel,
  // to the controls, but it means the translate coords are not alinged with the world axes. This
  // could make it harder to cull, if we ever decide to do that.
  public static void setCamera(int viewportWidth, int viewportHeight, float viewportZoom, float transX, float transY, float rotZ, float rotX) throws RuntimeException {
    GL11.glMatrixMode(GL11.GL_MODELVIEW);
    GLError.check();
    GL11.glLoadIdentity();
    GLError.check();
    float twiceZoom = viewportZoom * 2;
    float xAbs = viewportWidth / twiceZoom;
    float yAbs = viewportHeight / twiceZoom;
    GL11.glOrtho(-1 * xAbs, xAbs, -1 * yAbs, yAbs, -500, 500);
    GLError.check();
    GL11.glRotatef(rotX, 1.0f, 0.0f, 0.0f);
    GLError.check();
    GL11.glTranslatef(transX, transY, 0);
    GLError.check();
    GL11.glRotatef(rotZ, 0.0f, 0.0f, 1.0f);
    GLError.check();
  }
}