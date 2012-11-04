package cities;

/*import org.lwjgl.*;
import org.lwjgl.opengl.*;
import org.lwjgl.util.glu.GLU;
import org.lwjgl.BufferUtils;
import javax.vecmath.Vector3f;
import java.util.Arrays;*/

import java.awt.image.BufferedImage;
import java.nio.*;
import java.io.File;
import java.io.IOException;
import javax.imageio.ImageIO;
import java.awt.Color;
import java.lang.Math;
import javax.vecmath.Vector3d;
import javax.media.jai.InterpolationBilinear;
import org.lwjgl.opengl.*;
import cities.VBO;

class HeightField {
  class Vertex {
    public Vector3d position;
    public Vector3d normal;
    
    public Vertex(Vector3d position, Vector3d normal) {
      this.position = position;
      this.normal = normal;
    }
  }
  
  // The height data is stored in an array of doubles. The array is one-dimensional, so the length
  // and width must be known in order to meaningfully read the array. Further, to map from the array
  // to world coordinates, the proper X, Y, and Z scale factors must be known. Scale is defined as
  // world units per height field "pixel."
  //
  // squareSize is the size in world coords of the mesh squares.
  int length, width, meshCols, meshRows;
  public double wScale, lScale, hScale, squareSize; // w => x, l => y, h => z
  double heights[][];
  Vertex verts[][];
  VBO attrBuffer;
  VBO indexBuffer;
  
  public double atXY(double worldX, double worldY) {
    // scale * height array offset = world coord
    // height array offset = world coord / scale
    int left   = (int)Math.floor(worldX / wScale);
    int right  = (int)Math.ceil( worldX / wScale);
    int top    = (int)Math.floor(worldY / lScale);
    int bottom = (int)Math.ceil( worldY / lScale);
    return (new InterpolationBilinear()).interpolate(
      heights[left][top],
      heights[right][top],
      heights[left][bottom],
      heights[right][bottom],
      (float)(worldX % wScale), // x fraction,
      (float)(worldY % lScale)  // y fraction*/
    ) * hScale;
  }
  
  // This DOES NOT update the data in vram. pushToVBO must be called for that purpose.
  public void generateMesh(double minX, double minY, double maxX, double maxY) {
    /* Determine the min and max rows and columns. Since the world coords passed in probably aren't
    coincident with vertices, err on the side of including more rows and columns. Clamp the mins and maxes
    within the bounds of the height field. */
    int minColIndex = Math.min((int)Math.floor(minX / squareSize), 0);
    int minRowIndex = Math.min((int)Math.floor(minY / squareSize), 0);
    int maxColIndex = Math.max((int)Math.ceil( maxX / squareSize), meshCols());
    int maxRowIndex = Math.max((int)Math.ceil( maxY / squareSize), meshRows());
    
    /* For each of the vertices in the range, bilinearly interpolate between pixels
    to determine the z coord. Expand the range by one in each direction (without going
    out of bounds) so that we can later calculate normals. */
    for (int row = Math.min(minRowIndex - 1, 0); row <= Math.max(maxRowIndex + 1, meshRows()); row++) {
      for (int col = Math.min(minColIndex - 1, 0); col <= Math.max(maxColIndex + 1, meshCols()); col++) {
        verts[row][col].position.z = atXY(
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
        if (col < meshCols() - 1 && row > 0) { // Upper right
          averageNormal.add(
            triNormal(verts[col][row].position, verts[col][row - 1].position, verts[col + 1][row].position)
          );
        }
        if (col < meshCols() - 1 && row < meshRows() - 1) { // Lower right
          averageNormal.add(
            triNormal(verts[col][row].position, verts[col + 1][row].position, verts[col][row + 1].position)
          );
        }
        if (col > 0 && row < meshRows() - 1) { // Lower left
          averageNormal.add(
            triNormal(verts[col][row].position, verts[col][row + 1].position, verts[col - 1][row].position)
          );
        }
        averageNormal.normalize();
        verts[col][row].normal = averageNormal;
      }
    }
  }
  
  public HeightField(double wScale, double lScale, double hScale) {
    this.wScale = wScale;
    this.lScale = lScale;
    this.hScale = hScale;
  }
  
  // Overwrites any preexisting height data.
  // Typically, this should be called shortly after the constructor.
  public void loadFromImage(String imagePath) throws java.io.IOException {
    BufferedImage img = javax.imageio.ImageIO.read(new java.io.File(imagePath));
    heights = new double[img.getWidth()][img.getHeight()];
    for (int y = 0; y < img.getHeight(); y++) {
      for (int x = 0; x < img.getWidth(); x++) {
        heights[x][y] = (new Color(img.getRGB(x, y))).getRed();
      }
    }
  }
  
  public int meshCols() {
    return meshCols;
  }
  
  public int meshRows() {
    return meshRows();
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
  
  public double worldLength() {
    return length * lScale;
  }
  
  public double worldWidth() {
    return width * wScale;
  }
}