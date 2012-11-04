package cities;

import org.lwjgl.opengl.*;
import java.nio.*;

class VBO {
  public enum VBODataType {INT, FLOAT, DOUBLE};
  
  VBODataType type;
  int target;
  int bufferId;
  
  protected void bind() {
    GL15.glBindBuffer(target, bufferId);
  }
  
  // Be sure to unmap immediately after reading/writing is finished, or the GPU may stall.
  // This needs to be changed. The last param should be the buffer you pass in.
  public java.nio.ByteBuffer map(int access) {
    return GL15.glMapBuffer(target, access, null);
  }
  
  protected void unbind() {
    GL15.glBindBuffer(target, 0);
  }
  
  public void unmap() {
    GL15.glUnmapBuffer(target);
  }
  
  public VBO(int target, VBODataType type) {
    this.type = type;
    this.target = target;
    bufferId = GL15.glGenBuffers();
  }
}