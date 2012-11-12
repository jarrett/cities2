package cities;

import javax.vecmath.Vector3d;
import java.nio.*;
import org.lwjgl.opengl.*;
import cities.HeightField;
import cities.VBO;

class TerrainMesh {
  static class Vertex {
    public Vector3d position;
    public Vector3d normal;
    
    public Vertex() {
      this.position = new Vector3d(0, 0, 0);
      this.normal = new Vector3d(0, 0, 0);
    }
    
    public Vertex(Vector3d position) {
      this.position = position;
      this.normal = new Vector3d(0, 0, 0);
    }
    
    public Vertex(Vector3d position, Vector3d normal) {
      this.position = position;
      this.normal = normal;
    }
  }
  
  HeightField heightField;
  // Rows and columns define the number of vertices. This is NOT the number of squares.
  // That would be rows or columns minus one.
  int cols, rows; 
  double squareSize;
  boolean fullyGenerated = false;
  public Vertex verts[][];
  public VBO attrBuffer;
  public VBO indexBuffer;
  
  public int cols() {
    return cols;
  }
  
  // The first time you call this, you must generate the entire mesh! Attempting to render a partially
  // generated mesh will result in an error.
  public void generateMesh(double minX, double minY, double maxX, double maxY) {
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
          verts[row][col] = new Vertex(new Vector3d(squareSize * col, squareSize * row, 0));
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
        Vector3d averageNormal = new Vector3d(0, 0, 0);
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
    // Attribute buffer
    
    // 6 elements per vertex
    attrBuffer = new VBO(GL15.GL_ARRAY_BUFFER, VBO.DataType.DOUBLE, GL15.GL_DYNAMIC_DRAW, rows() * cols() * 6);
    DoubleBuffer doubles = (DoubleBuffer) attrBuffer.map(GL15.GL_WRITE_ONLY);
    for (int row = 0; row < verts.length; row++) {
      for (int col = 0; col < verts[row].length; col++) {
        Vertex vert = verts[row][col];
        // position
        doubles.put(vert.position.x);
        doubles.put(vert.position.y);
        doubles.put(vert.position.z);
        // normal
        doubles.put(vert.normal.x);
        doubles.put(vert.normal.y);
        doubles.put(vert.normal.z);
      }
    }
    attrBuffer.unmap();
    
    // Index buffer
    
    // 2 triangles per square, three indices per triangle
    indexBuffer = new VBO(GL15.GL_ELEMENT_ARRAY_BUFFER, VBO.DataType.INT, GL15.GL_STATIC_DRAW, squares() * 2 * 3);
    IntBuffer ints = (IntBuffer) indexBuffer.map(GL15.GL_WRITE_ONLY);
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
  }
  
  public void drawElements() {    
    // Count is the number of elements in the index buffer
    // 2 triangles per square, 3 indices per triangle
    GL11.glDrawElements(GL11.GL_TRIANGLES, squares() * 2 * 3, GL11.GL_UNSIGNED_INT, 0);
  }
  
  public int rows() {
    return rows;
  }
  
  public void setAttrPointers(int positionIndex, int normalIndex) {
    // index, size, type, normalized, stride, offset
    // Stride: 2 vectors * 3 components per vector * 8 bytes per component
    // Offset for normals: 3 components per vector * 8 bytes per component
    GL20.glVertexAttribPointer(positionIndex, 3, GL11.GL_DOUBLE, false, 2 * 3 * 8, 0);
    GL20.glEnableVertexAttribArray(positionIndex);
    GL20.glVertexAttribPointer(normalIndex, 3, GL11.GL_DOUBLE, false, 2 * 3 * 8, 3 * 8);
    GL20.glEnableVertexAttribArray(normalIndex);
  }
  
  public int squares() {
    return (rows() - 1) * (cols() - 1);
  }
  
  public TerrainMesh(HeightField heightField, double squareSize) {
    this.heightField = heightField;
    this.squareSize = squareSize;
    cols = (int)Math.round(heightField.worldWidth() / squareSize);
    rows = (int)Math.round(heightField.worldLength() / squareSize);
    verts = new Vertex[cols][rows];
  }
  
  // Ensures that the Z component is positive.
  public static Vector3d triNormal(Vector3d v1, Vector3d v2, Vector3d v3) {
    Vector3d side1 = new Vector3d();
    Vector3d side2 = new Vector3d();
    Vector3d norm = new Vector3d();
    
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