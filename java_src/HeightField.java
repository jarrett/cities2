package cities;

import java.awt.image.BufferedImage;
//import java.nio.*;
import java.io.File;
import java.io.IOException;
import javax.imageio.ImageIO;
import java.awt.Color;
import java.lang.Math;
import javax.media.jai.InterpolationBilinear;

class HeightField {
  // The height data is stored in a 2d array of floats.
  //
  // To map from the array to world coordinates, the proper X, Y, and Z scale factors must be known. 
  // Scale is defined as world units per height field "pixel."
  // squareSize is the size in world coords of the mesh squares.
  int cols, rows;
  public float xScale, yScale, zScale; // cols => x, rows => y, height => z
  float heights[][];
  
  // Can gracefully handle out-of-range coordinates
  public float atXY(float worldX, float worldY) {
    // scale * height array offset = world coord
    // height array offset = world coord / scale
    int left   = Math.max((int)Math.floor(worldX / xScale), 0   );
    int right  = Math.min((int)Math.ceil( worldX / xScale), cols);
    int top    = Math.max((int)Math.floor(worldY / yScale), 0   );
    int bottom = Math.min((int)Math.ceil( worldY / yScale), rows);
    return (new InterpolationBilinear()).interpolate(
      heights[left][top],
      heights[right][top],
      heights[left][bottom],
      heights[right][bottom],
      (float)(worldX % xScale), // x fraction,
      (float)(worldY % yScale)  // y fraction*/
    ) * zScale;
  }
  
  public HeightField(float xScale, float yScale, float zScale) {
    this.xScale = xScale;
    this.yScale = yScale;
    this.zScale = zScale;
  }
  
  // Overwrites any preexisting height data.
  // Typically, this should be called shortly after the constructor.
  public void loadFromImage(String imagePath) throws java.io.IOException {
    BufferedImage img = javax.imageio.ImageIO.read(new java.io.File(imagePath));
    cols = img.getWidth();
    rows = img.getHeight();
    heights = new float[cols][rows];
    for (int y = 0; y < img.getHeight(); y++) {
      for (int x = 0; x < img.getWidth(); x++) {
        heights[x][y] = (new Color(img.getRGB(x, y))).getRed();
      }
    }
  }
  
  public float worldLength() {
    return cols * yScale;
  }
  
  public float worldWidth() {
    return rows * xScale;
  }
}