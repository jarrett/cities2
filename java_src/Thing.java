package cities;

import java.util.ArrayList;
import cities.ThingConfig;

class Thing {
  ThingConfig cfg;
  public float x, y, z;
  static ArrayList<Thing> alive = new ArrayList<Thing>();
  // We may someday need more than one VBO to fit all Things. For now, our implementation just uses one.
  // But we're still storing that one in an ArrayList to make things easier in the future.
  static ArrayList<Integer> attrVBOIds = new ArrayList<Integer>();
  static ArrayList<Integer> indexVBOIds = new ArrayList<Integer>();
  
  public void makeLive() {
    alive.add(this);
    // For now, we're just going to put one VBO in the ArrayList.
    
  }
  
  // Returns the ID of the next usable attribute VBO
  protected int nextAttrVBOId() {
    if (attrVBOIds.get(0) == null) {
      // create the first VBO and return it
    }
    return 0;
  }
  
  // Returns the next usable index VBO
  protected int nextIndexVBOId() {
    return 0;
  }
  
  public Thing(ThingConfig cfg) {
    this.cfg = cfg;
  }
}