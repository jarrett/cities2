# This class presents mostly the same interface as GuiSprite.

class Glyph
  @@loaded = false
  
  def self.get(code_point)
    raise 'Trying to call Sprite.get before Sprite.load_all' unless @loaded
    @all[code_point]
  end
  
  def initialize(code_point, x, y, w, h, x_offset, y_offset, x_advance)
    @code_point = code_point
    @x = x
    @y = y
    @w = w
    @h = h
    @x_offset = x_offset
    @y_offset = y_offset
    @x_advance = x_advance
    @@all[code_point] = self
  end
  
  def self.load_all
    unless @@loaded
      @@all = {}
      doc = Nokogiri.XML(File.read(File.join(ROOT, 'assets/font/junction.xml')))
      doc.css('chars char').each do |node|
        # Looks like this:
        # <char xadvance='8' x='132' chnl='0' yoffset='-3' y='144' xoffset='4' id='33' page='0' height='24' width='6'/>
        # id is the Unicode code point. x and y offset are the distance from the cursor. xadvance is how far to move
        # the cursor after drawing the glyph.
        new(
          node['id'],
          node['x'],
          node['y'],
          node['width'],
          node['height'],
          node['xoffset'],
          node['yoffset'],
          node['xadvance']
        )
        @@sprite_sheet = javax.imageio.ImageIO.read(java.io.File.new(File.join(ROOT, 'assets/font/junction.png')))
      end
      @@loaded = true
    end
  end
  
  def self.loaded?
    @@loaded
  end
  
  def self.sprite_sheet
    @@sprite_sheet
  end
end