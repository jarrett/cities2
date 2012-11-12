package cities;

import javax.vecmath.Vector3d;
import javax.vecmath.Matrix4d;
import org.lwjgl.opengl.GL11;
import cities.GLError;

class Camera {
  public static Matrix4d inverseRotation;
  
  // viewportHeight and viewportWidth are given in pixels. viewportZoom = pixels per OpenGL unit.
  // Currently, glTranslate is called before rotating about the z axis. This gives an intuitive feel,
  // to the controls, but it means the translate coords are not alinged with the world axes. This
  // could make it harder to cull, if we ever decide to do that.
  public static void set(int viewportWidth, int viewportHeight, float viewportZoom, float transLR, float transUD, float rotZ, float rotX) throws RuntimeException {
    GL11.glMatrixMode(GL11.GL_PROJECTION);
    GL11.glLoadIdentity();
    float twiceZoom = viewportZoom * 2;
    float xAbs = viewportWidth / twiceZoom;
    float yAbs = viewportHeight / twiceZoom;
    GL11.glOrtho(-1 * xAbs, xAbs, -1 * yAbs, yAbs, -500, 500);
    GL11.glMatrixMode(GL11.GL_MODELVIEW);
    GL11.glLoadIdentity();
    // Translate
    GL11.glTranslatef(transLR, transUD, 0);
    // Rotate x
    GL11.glRotatef(rotX, 1.0f, 0.0f, 0.0f);
    // Rotate z
    GL11.glRotatef(rotZ, 0.0f, 0.0f, 1.0f);

    // Set up inverseRotation matrix
    Matrix4d rotZMat = new Matrix4d();
    rotZMat.rotZ(Math.toRadians(-1 * rotZ));
    Matrix4d rotXMat = new Matrix4d();
    rotXMat.rotX(Math.toRadians(-1 * rotX));
    inverseRotation = new Matrix4d(rotZMat);
    inverseRotation.mul(rotXMat);
  }
  
  public static Vector3d direction() {
    Vector3d vec = new Vector3d(0, 0, 1);
    inverseRotation.transform(vec);
    return vec;
  }
}