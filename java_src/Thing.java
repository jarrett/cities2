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
      spriteConfig = (Map) yaml.load(
        zipFile.getEntry(name + "_spring_config.yml").toString()
      );
    } else {
      zipped = false;
      spriteConfig = (Map) yaml.load(
        new FileInputStream(new File(path + "/" + name + "_sprite_config.yml"))
      );
    }
    zipFile = null; // Free the memory
  }
  
  @SuppressWarnings("unchecked")
  protected BufferedImage loadSprite(String spriteName) throws IOException {
    BufferedImage img;
    String imgPath = path + "/" + name + "_" + spriteName + ".png";
    if (zipped) {
      img = ImageIO.read(zipFile.getInputStream(zipFile.getEntry(imgPath)));
    } else {
      img = ImageIO.read(new FileInputStream(new File(imgPath)));
    }
    return img.getSubimage(
      (int) Math.ceil(((ArrayList<Double>) spriteConfig.get("top_left")).get(0)      * img.getWidth()),  // left crop
      (int) Math.ceil(((ArrayList<Double>) spriteConfig.get("top_middle")).get(1)    * img.getHeight()), // top crop
      (int) Math.ceil(((ArrayList<Double>) spriteConfig.get("bottom_right")).get(0)  * img.getWidth()),  // right crop
      (int) Math.ceil(((ArrayList<Double>) spriteConfig.get("bottom_middle")).get(1) * img.getHeight())  // bottom crop
    );
  }
  
  // Path to its data files
  public Thing(String name, String path) throws IOException {
    this.path = path;
    this.name = name;
    if (usedNames.indexOf(name) != 1) {
      throw new RuntimeException("Conflicting names: You have at least two Things named " + name);
    }
    usedNames.add(name);
    loadFiles();
  }
}