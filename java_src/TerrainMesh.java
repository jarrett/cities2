package cities;

import javax.vecmath.Vector3f;
import javax.vecmath.Matrix4f;
import java.nio.*;
import org.lwjgl.opengl.*;
import org.lwjgl.BufferUtils;
import cities.HeightField;
import cities.GLError;
import cities.GLProgram;
import cities.MatrixUtils;

class TerrainMesh {
  static class Vertex {
    public Vector3f position;
    public Vector3f normal;
    
    public Vertex() {
      this.position = new Vector3f(0, 0, 0);
      this.normal = new Vector3f(0, 0, 0);
    }
    
    public Vertex(Vector3f position) {
      this.position = position;
      this.normal = new Vector3f(0, 0, 0);
    }
    
    public Vertex(Vector3f position, Vector3f normal) {
      this.position = position;
      this.normal = normal;
    }
  }
  
  HeightField heightField;
  // Rows and columns define the number of vertices. This is NOT the number of squares.
  // That would be rows or columns minus one.
  int cols, rows; 
  GLProgram program;
  float squareSize;
  boolean fullyGenerated = false;
  public Vertex verts[][];
  public int vaoId, attrVBOId, indexVBOId;
  Matrix4f camera;
  int cameraUniIndex, pickingUniIndex;
  FloatBuffer cameraFloats; // Saved as an instance variable so we don't have to create a new native buffer on each render call
  
  public int cols() {
    return cols;
  }
  
  // The first time you call this, you must generate the entire mesh! Attempting to render a partially
  // generated mesh will result in an error.
  public void generateMesh(float minX, float minY, float maxX, float maxY) {
    /* Determine the min and max rows and columns. Since the world coords passed in probably aren't
    coincident with vertices, err on the side of including more rows and columns. Clamp the mins and maxes
    within the bounds of the height field. */
    int minCol = Math.max((int)Math.floor(minX / squareSize), 0);
    int minRow = Math.max((int)Math.floor(minY / squareSize), 0);
    int maxCol = Math.min((int)Math.ceil( maxX / squareSize), cols() - 1);
    int maxRow = Math.min((int)Math.ceil( maxY / squareSize), rows() - 1);
    
    if (minCol == 0 && maxCol == cols() - 1 && minRow == 0 && maxRow == rows() - 1) {
      fullyGenerated = true;
    } else if (!fullyGenerated) {
      throw new RuntimeException("Can't call generateMesh on a subset of the mesh until it has been fully generated at least once.");
    }
    
    /* For each of the vertices in the range, bilinearly interpolate between pixels
    to determine the z coord. Expand the range by one in each direction (without going
    out of bounds) so that we can later calculate normals. */
    for (int row = Math.max(minRow - 1, 0); row <= Math.min(maxRow + 1, rows() - 1); row++) {
      for (int col = Math.max(minCol - 1, 0); col <= Math.min(maxCol + 1, cols() - 1); col++) {
        // If the vertex has not been initialized, initialize it. This always executes the first time
        // the mesh is generated.
        if (verts[row][col] == null) {
          verts[row][col] = new Vertex(new Vector3f(squareSize * col, squareSize * row, 0));
        }
        verts[row][col].position.z = heightField.atXY(
          // Either of these values could be slightly outside the height field's range.
          // The height field knows how to handle that.
          squareSize * col,
          squareSize * row
        );
      }
    }
    
    /* Calculate normals for each vertex in the range by averaging the normals of all neighboring triangles. */
    for (int row = minRow; row <= maxRow; row++) {
      for (int col = minCol; col <= maxCol; col++) {
        Vector3f averageNormal = new Vector3f(0, 0, 0);
        if (col > 0 && row > 0) { // Upper left
          averageNormal.add(
            triNormal(verts[col][row].position, verts[col - 1][row].position, verts[col][row - 1].position)
          );
        }
        if (col < cols() - 1 && row > 0) { // Upper right
          averageNormal.add(
            triNormal(verts[col][row].position, verts[col][row - 1].position, verts[col + 1][row].position)
          );
        }
        if (col < cols() - 1 && row < rows() - 1) { // Lower right
          averageNormal.add(
            triNormal(verts[col][row].position, verts[col + 1][row].position, verts[col][row + 1].position)
          );
        }
        if (col > 0 && row < rows() - 1) { // Lower left
          averageNormal.add(
            triNormal(verts[col][row].position, verts[col][row + 1].position, verts[col - 1][row].position)
          );
        }
        averageNormal.normalize();
        verts[col][row].normal = averageNormal;
      }
    }
  }
  
  protected void initBuffers() {
    // Set up VAO
    vaoId = GL30.glGenVertexArrays();
    GL30.glBindVertexArray(vaoId);
    
    // Attribute buffer
    
    FloatBuffer floats = BufferUtils.createFloatBuffer(rows() * cols() * 6); // 6 elements per vertex
    for (int row = 0; row < verts.length; row++) {
      for (int col = 0; col < verts[row].length; col++) {
        Vertex vert = verts[row][col];
        // position
        floats.put(vert.position.x);
        floats.put(vert.position.y);
        floats.put(vert.position.z);
        // normal
        floats.put(vert.normal.x);
        floats.put(vert.normal.y);
        floats.put(vert.normal.z);
      }
    }
    floats.rewind();
    attrVBOId = GL15.glGenBuffers();
    GL15.glBindBuffer(GL15.GL_ARRAY_BUFFER, attrVBOId);
    GL15.glBufferData(GL15.GL_ARRAY_BUFFER, floats, GL15.GL_DYNAMIC_DRAW);
    if (GL15.glGetBufferParameter(GL15.GL_ARRAY_BUFFER, GL15.GL_BUFFER_SIZE) == 0) {
      throw new RuntimeException("glBufferData called, but GL_ARRAY_BUFFER size is still 0");
    }
    
    // index, size, type, normalized, stride, offset
    // Stride: 2 vectors * 3 components per vector * 4 bytes per component
    // Offset for normals: 3 components per vector * 4 bytes per component
    int positionIndex = program.attrIndex("position");
    int normalIndex = program.attrIndex("normal");
    GL20.glEnableVertexAttribArray(positionIndex);
    GL20.glVertexAttribPointer(positionIndex, 3, GL11.GL_FLOAT, false, 2 * 3 * 4, 0);
    GL20.glEnableVertexAttribArray(normalIndex);
    GL20.glVertexAttribPointer(normalIndex, 3, GL11.GL_FLOAT, false, 2 * 3 * 4, 3 * 4);
    
    // Index buffer
    
    IntBuffer ints = BufferUtils.createIntBuffer(squares() * 2 * 3); // 2 triangles per square, three indices per triangle
    for (int row = 0; row < rows() - 1; row++) {
      for (int col = 0; col < cols() - 1; col++) {
        int tl = (row * cols()) + col;
        int tr = (row * cols()) + col + 1;
        int bl = ((row + 1) * cols()) + col;
        int br = ((row + 1) * cols()) + col + 1;
        // top-left triangle
        ints.put(tl);
        ints.put(bl);
        ints.put(tr);
        // bottom-right triangle
        ints.put(br);
        ints.put(tr);
        ints.put(bl);
      }
    }
    ints.rewind();
    indexVBOId = GL15.glGenBuffers();
    GL15.glBindBuffer(GL15.GL_ELEMENT_ARRAY_BUFFER, indexVBOId);
    GL15.glBufferData(GL15.GL_ELEMENT_ARRAY_BUFFER, ints, GL15.GL_STATIC_DRAW);
    if (GL15.glGetBufferParameter(GL15.GL_ELEMENT_ARRAY_BUFFER, GL15.GL_BUFFER_SIZE) == 0) {
      throw new RuntimeException("glBufferData called, but GL_ELEMENT_ARRAY_BUFFER size is still 0");
    }
    
    GL30.glBindVertexArray(0);
  }
  
  public void render(boolean picking) {
    GL30.glBindVertexArray(vaoId);
    program.use();
    program.bindTextures();
    MatrixUtils.copyToBuffer(camera, cameraFloats);
    GL20.glUniform1i(pickingUniIndex, (picking) ? 1 : 0);
    program.setWorldSizeUnis();
    program.setMouseCoordUnis();
    GL20.glUniformMatrix4(cameraUniIndex, false, cameraFloats);
    // Count is the number of elements in the index buffer
    // 2 triangles per square, 3 indices per triangle
    GL11.glDrawElements(GL11.GL_TRIANGLES, squares() * 2 * 3, GL11.GL_UNSIGNED_INT, 0);
    GL30.glBindVertexArray(0);
  }
  
  public void render() {
    render(false);
  }
  
  public int rows() {
    return rows;
  } 
  
  public void setCamera(Matrix4f camera) {
    this.camera = camera;
  }
  
  public int squares() {
    return (rows() - 1) * (cols() - 1);
  }
  
  public TerrainMesh(HeightField heightField, float squareSize, GLProgram program) {
    this.heightField = heightField;
    this.squareSize = squareSize;
    this.program = program;
    cols = (int)Math.round(heightField.worldWidth() / squareSize);
    rows = (int)Math.round(heightField.worldLength() / squareSize);
    verts = new Vertex[cols][rows];
    cameraUniIndex = program.uniIndex("camera");
    cameraFloats = BufferUtils.createFloatBuffer(16);
    pickingUniIndex = program.uniIndex("picking");
  }
  
  // Ensures that the Z component is positive.
  public static Vector3f triNormal(Vector3f v1, Vector3f v2, Vector3f v3) {
    Vector3f side1 = new Vector3f();
    Vector3f side2 = new Vector3f();
    Vector3f norm = new Vector3f();
    
    side1.sub(v1, v2);
    side2.sub(v1, v3);
    
    norm.cross(side1, side2);
    norm.normalize();
    
    if (norm.z < 0) { // Ensure positive z
      norm.negate();
    }
    
    return norm;
  }
}