package cities;

import javax.vecmath.Vector3f;
import javax.vecmath.Matrix4f;
import org.lwjgl.opengl.GL11;
import cities.GLError;
import cities.MatrixUtils;

class Camera {
  //public static Matrix4d inverseRotation;
  
  // viewportHeight and viewportWidth are given in pixels. viewportZoom = pixels per OpenGL unit.
  // Angles are given in radians.
  public static Matrix4f matrix(int viewportWidth, int viewportHeight, float viewportZoom, float transLR, float transUD, float zAngle, float xAngle) {
    // http://www.khronos.org/opengles/documentation/opengles1_0/html/glOrtho.html
    
    float twiceZoom = viewportZoom * 2;
    float right = viewportWidth / twiceZoom;
    float left = -1 * right;
    float top = viewportHeight / twiceZoom;
    float bottom = -1 * top;
    float near = -500;
    float far = 500;
    float tx = (right + left) / (right - left);
    float ty = (top + bottom) / (top - bottom);
    float tz = (far + near) / (far - near);
    
    Matrix4f proj = new Matrix4f(
      2 / (right - left), 0,                  0,                  tx,
      0,                  2 / (top - bottom), 0,                  ty,
      0,                  0,                  -2 / (far - near),  tz,
      0,                  0,                  0,                  1
    );
    
    // Translate the vertex
    Matrix4f trans = MatrixUtils.translate(new Vector3f(transLR, transUD, 0.0f));
    proj.mul(trans);
    
    // Rotate the vertex about X
    Matrix4f rotX = new Matrix4f();
    rotX.rotX(xAngle);
    proj.mul(rotX);
    
    // Rotate the vertex about Z
    Matrix4f rotZ = new Matrix4f();
    rotZ.rotZ(zAngle);
    proj.mul(rotZ);
    
    return proj;
    
    //cameraRotate(transLR, transUD);
    
    //GL11.glMatrixMode(GL11.GL_PROJECTION);
    //GL11.glLoadIdentity();
    //GL11.glOrtho(-1 * xAbs, xAbs, -1 * yAbs, yAbs, -500, 500);
    //GL11.glMatrixMode(GL11.GL_MODELVIEW);
    //GL11.glLoadIdentity();
    // Translate
    //GL11.glTranslatef(transLR, transUD, 0);
    // Rotate x
    //GL11.glRotatef(xAngle, 1.0f, 0.0f, 0.0f);
    // Rotate z
    //GL11.glRotatef(zAngle, 0.0f, 0.0f, 1.0f);

    // Set up inverseRotation matrix
    /*Matrix4d zAngleMat = new Matrix4d();
    zAngleMat.zAngle(Math.toRadians(-1 * zAngle));
    Matrix4d xAngleMat = new Matrix4d();
    xAngleMat.xAngle(Math.toRadians(-1 * xAngle));
    inverseRotation = new Matrix4d(zAngleMat);
    inverseRotation.mul(xAngleMat);*/
  }
  
  /*
  public static Vector3f direction() {
    Vector3d vec = new Vector3d(0, 0, 1);
    inverseRotation.transform(vec);
    return vec;
  }
  */
}