# Once load_all has been called, there is exactly one instance of Sprite
# per sprite, and one instance glyph. Never make another.

class Sprite
  @@loaded = false
  
  def self.get(name)
    raise 'Trying to call Sprite.get before Sprite.load_all' unless @@loaded
    @@all[name]
  end
  
  attr_reader :h
  
  def h_frac
    @h_frac ||= h.to_f / 1024
  end
  
  # Coords are in pixels. Internally, u and v get converted to floats in [0,1].
  def initialize(name, u, v, w, h, rotated)
    raise "Trying to load sprite {name} twice" if @@all[name]
    @name = name
    @u = u
    @v = v
    @w = w
    @h = h
    @rotated = rotated
    @@all[name] = self
  end
  
  def self.load_all
    unless @@loaded
      # Load all the GUI sprite images and create an instance for each one. The instances will be
      # saved in Sprite.all.
      
      @@all = {}
      
      sprite_paths = Dir.glob(File.join(ROOT, 'assets/gui/*.png'))
      
      bin_items = sprite_paths.collect do |path|
        name = File.basename(path, File.extname(path))
        img = javax.imageio.ImageIO.read(java.io.File.new(path))
        Binpack::Item.new({:name => name, :img => img}, img.getWidth, img.getHeight)
      end
      
      packed = Binpack::Bin.pack(bin_items, [], Binpack::Bin.new(1024, 1024, 1)).first.items
      sprite_sheet = java.awt.image.BufferedImage.new(1024, 1024, java.awt.image.BufferedImage::TYPE_INT_RGB)
      graphics = sprite_sheet.getGraphics
      
      packed.each do |item, u_pix, v_pix|
        # item.obj is a BufferedImage containing the individual sprite. See the Javadoc for Graphics,
        # not Graphics2D, for this method signature. u_pix and v_pix are in pixels, not the range [0, 1].
        graphics.drawImage(item.obj[:img], u_pix, v_pix, nil)
        new(item.obj[:name], u_pix, v_pix, item.width, item.height, item.rotated) # This updates @all
      end
      
      @@loaded = true
    end
  end
  
  attr_reader :u
  
  def u_frac
    @u_frac ||= u.to_f / 1024
  end
  
  attr_reader :v
  
  def v_frac
    @v_frac = v.to_f / 1024
  end
  
  attr_reader :w
  
  def w_frac
    @w_frac ||= w.to_f / 1024
  end
end