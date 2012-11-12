package cities;

import java.util.zip.*;
import java.util.ArrayList;
import java.io.IOException;

class Thing {
  String path;
  String name;
  static ArrayList<String> usedNames = new ArrayList<String>();
  
  // Path to its data files
  public Thing(String name, String path) throws IOException {
    this.path = path;
    this.name = name;
    if (path.endsWith(".zip")) {
      ZipFile zip = new ZipFile(path);
      zip.getEntry("");
    }
  }
}