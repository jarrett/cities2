package cities;

import javax.vecmath.Vector3f;
import javax.vecmath.Matrix4f;
import org.lwjgl.opengl.GL11;
import cities.GLError;
import cities.MatrixUtils;

class Camera {  
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
  }
}