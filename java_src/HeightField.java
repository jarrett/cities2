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
  // The height data is stored in a 2d array of doubles.
  //
  // To map from the array to world coordinates, the proper X, Y, and Z scale factors must be known. 
  // Scale is defined as world units per height field "pixel."
  // squareSize is the size in world coords of the mesh squares.
  int cols, rows;
  public double xScale, yScale, zScale; // cols => x, rows => y, height => z
  double heights[][];
  
  public double atXY(double worldX, double worldY) {
    // scale * height array offset = world coord
    // height array offset = world coord / scale
    int left   = (int)Math.floor(worldX / xScale);
    int right  = (int)Math.ceil( worldX / xScale);
    int top    = (int)Math.floor(worldY / yScale);
    int bottom = (int)Math.ceil( worldY / yScale);
    return (new InterpolationBilinear()).interpolate(
      heights[left][top],
      heights[right][top],
      heights[left][bottom],
      heights[right][bottom],
      (float)(worldX % xScale), // x fraction,
      (float)(worldY % yScale)  // y fraction*/
    ) * zScale;
  }
  
  public HeightField(double xScale, double yScale, double zScale) {
    this.xScale = xScale;
    this.yScale = yScale;
    this.zScale = zScale;
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
  
  public double worldLength() {
    return cols * yScale;
  }
  
  public double worldWidth() {
    return rows * xScale;
  }
}