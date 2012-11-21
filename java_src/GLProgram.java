package cities;

public interface GLProgram { 
  public int attrIndex(String name);
  
  public void bindTextures();

  public void setMouseCoordUnis();
  
  public void setWorldSizeUnis();
  
  public int uniIndex(String name);
  
  public void use();
}