package cities;

import org.lwjgl.opengl.*;
import org.lwjgl.BufferUtils;
import java.nio.*;

class VBO {
  public enum VBODataType {BYTE, INT, FLOAT, DOUBLE};
  
  VBODataType type;
  int target;
  int bufferId;
  int count; // number of elements
  int size; // size in bytes
  
  // Be sure to unmap immediately after reading/writing is finished, or the GPU may stall.
  // This needs to be changed. The last param should be the buffer you pass in.
  public java.nio.ByteBuffer map(int access) {
    return GL15.glMapBuffer(target, access, null);
  }
  
  public void unmap() {
    GL15.glUnmapBuffer(target);
  }
  
  public VBO(int target, VBODataType type, int count) {
    this.type = type;
    this.target = target;
    bufferId = GL15.glGenBuffers();
    this.count = count;
    switch(type) {
    case VBO.BYTE:
      size = count;
      break;
    case VBO.INT:
      size = count * 4;
      break;
    case VBO.FLOAT:
      size = count * 8;
      break;
    case VBO.DOUBLE:
      break;
    }
  }
}