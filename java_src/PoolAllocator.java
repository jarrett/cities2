package cities;

class PoolAllocator {
  int length, cursor, maxUsed;
  boolean[] map;
  
  // Returns the index of the memory block that was allocated
  public int alloc(int neededCount) {
    int cursorStart = cursor;
    boolean hitCursorStart = false;
    int countFound = 0;
    while (true) {
      if (map[cursor]) {
        countFound ++;
      } else {
        countFound = 0;
      }
      
      if (countFound == neededCount) {
        int start = cursor - (neededCount - 1);
        for (int i = start; i <= cursor; i++) {
          map[i] = false;
        }
        incCursor();
        return start;
      }
      
      incCursor();
      
      // Check if we made it back to the start without finding a suitable block
      if (cursor == cursorStart) {
        if (hitCursorStart) {
          throw new RuntimeException("Could not find a block of " + neededCount + " free elements in VBO");
        }
        hitCursorStart = true;
      }
    }
  }
  
  public boolean at(int offset) {
    return map[offset];
  }
  
  public int cursor() {
    return this.cursor;
  }
  
  public void free(int offset, int freeCount) {
    for (int i = offset; i < offset + freeCount; i++) {
      map[i] = true;
    }
  }
  
  private void incCursor() {
    cursor ++;
    if (cursor == length) {
      // We've hit the end of the map. Start from the beginning.
      cursor = 0;
    }
    if (this.maxUsed < cursor) {
      this.maxUsed = cursor;
    }
  }
  
  public int maxUsed() {
    return this.maxUsed;
  }
  
  public PoolAllocator(int length) {
    this.length = length;
    this.cursor = 0;
    this.maxUsed = 0;
    this.map = new boolean[length];
    for (int i = 0; i < length; i++) {
      map[i] = true; // There's probably a more idiomatic way to write this
    }
  }
}