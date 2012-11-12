package cities;

import java.util.zip.*;
import java.util.ArrayList;
import java.util.Map;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.ByteArrayInputStream;
import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import org.yaml.snakeyaml.Yaml;

class Thing {
  String path;
  String name;
  Map spriteConfig;
  boolean zipped;
  ZipFile zipFile;
  static ArrayList<String> usedNames = new ArrayList<String>();
  
  protected void loadFiles() throws IOException {
    Yaml yaml = new Yaml();
    BufferedImage sprN, sprNE, sprE, sprSE, sprS, sprSW, sprW, sprNW;
    if (path.endsWith(".zip")) {
      zipped = true;
      zipFile = new ZipFile(path);
      ZipEntry zipEntry = zipFile.getEntry(name + "_sprite_config.yml");
      if (zipEntry == null) { throw new IOException(path + " does not contain " + name + "_sprite_config.yml"); }
      spriteConfig = (Map) yaml.load(zipFile.getInputStream(zipEntry));
    } else {
      zipped = false;
      spriteConfig = (Map) yaml.load(
        new FileInputStream(new File(path + "/" + name + "_sprite_config.yml"))
      );
    }
    sprN = loadSprite("n");
    sprNE = loadSprite("ne");
    sprE = loadSprite("e");
    sprSE = loadSprite("se");
    sprS = loadSprite("s");
    sprSW = loadSprite("sw");
    sprW = loadSprite("w");
    sprNW = loadSprite("nw");
    zipFile = null; // Free the memory
  }
  
  @SuppressWarnings("unchecked")
  protected BufferedImage loadSprite(String direction) throws IOException {
    BufferedImage img;
    String imgName = name + "_" + direction + ".png";
    if (zipped) {
      ZipEntry zipEntry = zipFile.getEntry(imgName);
      if (zipEntry == null) { throw new IOException(path + " does not contain " + imgName); }
      img = ImageIO.read(zipFile.getInputStream(zipEntry));
    } else {
      img = ImageIO.read(new FileInputStream(new File(path + "/" + imgName)));
    }
    
    Map dirConfig = (Map) spriteConfig.get(direction);
    if (dirConfig == null) { throw new RuntimeException(name + "_sprite_config.yml does not include " + direction); }
    
    ArrayList<Double> tl = (ArrayList<Double>) dirConfig.get("top_left");
    if (tl == null) { throw new RuntimeException(name + "_sprite_config.yml does not include top_left"); }
    ArrayList<Double> tm = (ArrayList<Double>) dirConfig.get("top_middle");
    if (tm == null) { throw new RuntimeException(name + "_sprite_config.yml does not include top_middle"); }
    ArrayList<Double> br = (ArrayList<Double>) dirConfig.get("bottom_right");
    if (br == null) { throw new RuntimeException(name + "_sprite_config.yml does not include bottom_right"); }
    ArrayList<Double> bm = (ArrayList<Double>) dirConfig.get("bottom_middle");
    if (bm == null) { throw new RuntimeException(name + "_sprite_config.yml does not include bottom_middle"); }
    
    int leftCrop = (int) Math.max(Math.ceil(tl.get(0) * img.getWidth() ), 0);
    int topCrop =  (int) Math.max(Math.ceil(tm.get(1) * img.getHeight()), 0);
    
    return img.getSubimage(
      leftCrop,
      topCrop,
      (int) Math.min(Math.ceil(br.get(0) * img.getWidth() ), img.getWidth()  - (1 + leftCrop)),  // right crop
      (int) Math.min(Math.ceil(bm.get(1) * img.getHeight()), img.getHeight() - (1 + topCrop ))   // bottom crop
    );
  }
  
  // Path to its data files
  public Thing(String name, String path) throws IOException {
    this.path = path;
    this.name = name;
    if (usedNames.indexOf(name) != -1) {
      throw new RuntimeException("Conflicting names: You have at least two Things named " + name);
    }
    usedNames.add(name);
    loadFiles();
  }
}