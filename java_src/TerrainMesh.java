package cities;

import javax.vecmath.Vector3d;
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
  public Vertex verts[][];
  VBO attrBuffer;
  VBO indexBuffer;
  
  public int cols() {
    return cols;
  }
  
  // This DOES NOT update the data in vram. pushToVBO must be called for that purpose.
  public void generateMesh(double minX, double minY, double maxX, double maxY) {
    /* Determine the min and max rows and columns. Since the world coords passed in probably aren't
    coincident with vertices, err on the side of including more rows and columns. Clamp the mins and maxes
    within the bounds of the height field. */
    int minCol = Math.min((int)Math.floor(minX / squareSize), 0);
    int minRow = Math.min((int)Math.floor(minY / squareSize), 0);
    int maxCol = Math.max((int)Math.ceil( maxX / squareSize), cols() - 1);
    int maxRow = Math.max((int)Math.ceil( maxY / squareSize), rows() - 1);
    
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
    attrBuffer = new VBO(GL11.GL_ARRAY_BUFFER, VBO.DOUBLE);
  }
  
  public void render() {
  }
  
  public int rows() {
    return rows;
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
    initBuffers();
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