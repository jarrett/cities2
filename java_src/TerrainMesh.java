package cities;

import javax.vecmath.Vector3d;
import cities.HeightField;
import cities.VBO;

class TerrainMesh {
  class Vertex {
    public Vector3d position;
    public Vector3d normal;
    
    public Vertex(Vector3d position, Vector3d normal) {
      this.position = position;
      this.normal = normal;
    }
  }
  
  HeightField heightField;
  int cols, rows;
  double squareSize;
  Vertex verts[][];
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
    int minColIndex = Math.min((int)Math.floor(minX / squareSize), 0);
    int minRowIndex = Math.min((int)Math.floor(minY / squareSize), 0);
    int maxColIndex = Math.max((int)Math.ceil( maxX / squareSize), cols());
    int maxRowIndex = Math.max((int)Math.ceil( maxY / squareSize), rows());
    
    /* For each of the vertices in the range, bilinearly interpolate between pixels
    to determine the z coord. Expand the range by one in each direction (without going
    out of bounds) so that we can later calculate normals. */
    for (int row = Math.min(minRowIndex - 1, 0); row <= Math.max(maxRowIndex + 1, rows()); row++) {
      for (int col = Math.min(minColIndex - 1, 0); col <= Math.max(maxColIndex + 1, cols()); col++) {
        verts[row][col].position.z = heightField.atXY(
          squareSize * col,
          squareSize * row
        );
      }
    }
    
    /* Calculate normals for each vertex in the range by averaging the normals of all neighboring triangles. */
    for (int row = minRowIndex; row <= maxRowIndex; row++) {
      for (int col = minRowIndex; row < maxRowIndex; row++) {
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
  
  public int rows() {
    return rows;
  }
  
  public TerrainMesh(HeightField heightField) {
    this.heightField = heightField;
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