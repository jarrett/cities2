package cities;

import org.lwjgl.opengl.GL11;
import org.lwjgl.opengl.GL12;
import org.lwjgl.opengl.GL13;
import org.lwjgl.opengl.GL20;
import org.lwjgl.BufferUtils;
import java.io.File;
import java.io.IOException;
import java.nio.ByteBuffer;
import javax.imageio.ImageIO;
import java.awt.geom.AffineTransform;
import java.awt.image.AffineTransformOp;
import java.awt.image.BufferedImage;
import cities.GLError;

class Texture {
  public String path;
  public int textureId;
  
  // attrIndex should be obtained by calling glGetUniformLocation
  // textureUnit is an offset from GL_TEXTURE0. I.e. it's the index of the texture unit.
  public void bind(int attrIndex, int textureUnit) {
    if (attrIndex == -1) {
      throw new RuntimeException("attribute index was -1");
    }
    GL13.glActiveTexture(textureUnit + GL13.GL_TEXTURE0);
    GL11.glBindTexture(GL11.GL_TEXTURE_2D, textureId);
    GL20.glUniform1i(attrIndex, textureUnit);
  }
  
  protected ByteBuffer bufferedImageToByteBuffer(BufferedImage img) {
    // Idea from:
    // http://www.java-gaming.org/topics/bufferedimage-to-lwjgl-texture/25516/msg/220280/view.html#msg220280
    int[] pixels = new int[img.getWidth() * img.getHeight()];
    img.getRGB(0, 0, img.getWidth(), img.getHeight(), pixels, 0, img.getWidth());
    ByteBuffer buf = BufferUtils.createByteBuffer(4 * img.getWidth() * img.getHeight());
    for(int y = 0; y < img.getHeight(); y++) {
      for(int x = 0; x < img.getWidth(); x++) {
        int pixel = pixels[(y * img.getWidth()) + x];
        buf.put((byte)((pixel >> 16) & 0xFF)); // red
        buf.put((byte)((pixel >> 8 ) & 0xFF)); // green
        buf.put((byte)( pixel        & 0xFF)); // blue
        buf.put((byte)((pixel >> 24) & 0xFF)); // alpha
        /*buf.put((byte)0xFF);
        buf.put((byte)0);
        buf.put((byte)0);
        buf.put((byte)0xFF);*/
      }
    }
    buf.rewind();
    //for (int i = 0; i < 8; i++) {
      //System.out.println(buf.get(i));
    //}
    return buf;
  }
  
  protected void createOpenGLTexture() throws java.io.IOException {
    textureId = GL11.glGenTextures();
    GL11.glBindTexture(GL11.GL_TEXTURE_2D, textureId);
    BufferedImage[] images = mipmaps();
    for (int i = 0; i < images.length; i++) {
      // i is the mipmap level
      ByteBuffer byteBuffer = bufferedImageToByteBuffer(images[i]);
      GL11.glTexImage2D(
        GL11.GL_TEXTURE_2D, i, GL11.GL_RGBA, images[i].getWidth(), images[i].getHeight(),
        0, GL11.GL_RGBA, GL11.GL_UNSIGNED_BYTE, byteBuffer
      );
      GLError.check();
    }
    GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL12.GL_TEXTURE_BASE_LEVEL, 0);
    GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL12.GL_TEXTURE_MAX_LEVEL,  images.length - 1);
    GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_MIN_FILTER, GL11.GL_LINEAR_MIPMAP_LINEAR);
    GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_MAG_FILTER, GL11.GL_LINEAR);
    GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_WRAP_S,     GL11.GL_REPEAT);
    GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_WRAP_T,     GL11.GL_REPEAT);
    GL11.glBindTexture(GL11.GL_TEXTURE_2D, 0);
    GLError.check();
  }
  
  protected int mipmapCount(BufferedImage img) {
    return (int)Math.ceil(
      Math.log(
        Math.max(img.getWidth(), img.getHeight())
      ) / Math.log(2)
    );
  }
  
  protected BufferedImage[] mipmaps() throws java.io.IOException {
    BufferedImage img0 = ImageIO.read(new File(path));
    if (img0 == null) {
      throw new RuntimeException("Could not load image: " + path);
    }
    int count = mipmapCount(img0);
    BufferedImage[] images = new BufferedImage[count];
    images[0] = img0;
    for (int i = 1; i < count; i++) {
      int newWidth =  Math.max((int)Math.floor(img0.getWidth()  / Math.pow(2, i)), 1);
      int newHeight = Math.max((int)Math.floor(img0.getHeight() / Math.pow(2, i)), 1);
      BufferedImage imgI = new BufferedImage(newWidth, newHeight, BufferedImage.TYPE_INT_ARGB);
      AffineTransform at = new AffineTransform();
      at.scale(Math.pow(0.5, i), Math.pow(0.5, i));
      AffineTransformOp op = new AffineTransformOp(at, AffineTransformOp.TYPE_BILINEAR);
      op.filter(img0, imgI);
      images[i] = imgI;
    }
    return images;
  }
  
  public Texture(String path) throws java.io.IOException {
    this.path = path;
    createOpenGLTexture();
  }
}