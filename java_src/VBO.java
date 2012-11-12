package cities;

import org.lwjgl.opengl.*;
import org.lwjgl.BufferUtils;
import java.nio.*;

class VBO {
  public enum DataType {INT, DOUBLE};
  
  DataType type;
  int target;
  public int bufferId;
  int usage;
  int count; // number of elements
  int size; // size in bytes
  
  public void bind() {
    GL15.glBindBuffer(target, bufferId);
  }
  
  // Be sure to unmap immediately after reading/writing is finished, or the GPU may stall.
  // Implicitly binds.
  public java.nio.Buffer map(int access) {
    bind();
    ByteBuffer byteBuffer = GL15.glMapBuffer(target, access, size, null);
    byteBuffer.rewind();
    switch(type) {
    case INT:
      return byteBuffer.asIntBuffer();
    case DOUBLE:
      return byteBuffer.asDoubleBuffer();
    default:
      return null; // Unreachable. Required to make the compiler happy.
    }
  }
  
  public void unbind() {
    GL15.glBindBuffer(target, 0);
  }
  
  public void unmap() {
    GL15.glUnmapBuffer(target);
  }
  
  public VBO(int target, DataType type, int usage, int count) {
    this.target = target;
    this.type = type;
    this.usage = usage;
    this.bufferId = GL15.glGenBuffers();
    this.count = count;    
    switch(type) {
    case INT:
      this.size = count * 4;
      break;
    case DOUBLE:
      this.size = count * 8;
      break;
    }
    bind();
    GL15.glBufferData(target, size, usage);
  }
}