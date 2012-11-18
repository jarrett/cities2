package cities;

import javax.vecmath.Vector3f;
import javax.vecmath.Matrix4f;
import java.nio.*;

// Because Sun was too lazy to implement these extremely basic methods on Matrix4f
class MatrixUtils {
  public static void copyToBuffer(Matrix4f mat, FloatBuffer buf) {
    if (mat == null) {
      throw new RuntimeException("First param of copyToBuffer was null");
    }
    if (buf == null) {
      throw new RuntimeException("Second param of copyToBuffer was null");
    }
    buf.rewind();
    buf.put(mat.m00);
    buf.put(mat.m01);
    buf.put(mat.m02);
    buf.put(mat.m03);
    buf.put(mat.m10);
    buf.put(mat.m11);
    buf.put(mat.m12);
    buf.put(mat.m13);
    buf.put(mat.m20);
    buf.put(mat.m21);
    buf.put(mat.m22);
    buf.put(mat.m23);
    buf.put(mat.m30);
    buf.put(mat.m31);
    buf.put(mat.m32);
    buf.put(mat.m33);
    buf.rewind();
  }
  
  public static Matrix4f translate(Vector3f to) {
    return new Matrix4f(
      1, 0, 0, to.x,
      0, 1, 0, to.y,
      0, 0, 1, to.z,
      0, 0, 0, 1
    );
  }
}