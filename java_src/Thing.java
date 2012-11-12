package cities;

import java.util.zip.*;
import java.util.ArrayList;
import java.util.Map;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import org.yaml.snakeyaml.Yaml;

class Thing {
  String path;
  String name;
  static ArrayList<String> usedNames = new ArrayList<String>();
  
  private void loadFiles() throws IOException {
    Yaml yaml = new Yaml();
    Map spriteConfig;
    if (path.endsWith(".zip")) {
      ZipFile zip = new ZipFile(path);
      spriteConfig = (Map) yaml.load(
        zip.getEntry(name + "_spring_config.yml").toString()
      );
    } else {
      spriteConfig = (Map) yaml.load(
        new FileInputStream(new File(path + "/" + name + "_sprite_config.yml"))
      );
    }
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