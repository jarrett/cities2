require 'openstruct'

class GuiComponent
  MAX_RECTS = 100
  
  def self.attr_pool_allocator
    @attr_pool_allocator
  end
  
  def self.attr_vbo_id
    @attr_vbo_id
  end
  
  # Call this once and only once
  def buffer
    raise "Can't call #buffer twice for same GuiComponent. Did you mean to call rebuffer_positions?" if @buffered
    @buffered = true
    
    # 4 vertices, 4 vector components per vertex
    @attr_buffer_index = self.class.attr_pool_allocator.alloc(4 * 4)
    
    self.class.map_attr_buffer do |float_buffer|
      4.times do |i|
        # Position
        float_buffer.put @attr_buffer_index + i + 0, @corners[i].x
        float_buffer.put @attr_buffer_index + i + 1, @corners[i].y
        
        # Tex coords
        float_buffer.put @attr_buffer_index + i + 2, @corners[i].u
        float_buffer.put @attr_buffer_index + i + 3, @corners[i].v
      end
    end
    
    # Indices for 4 verts
    @element_buffer_index = self.class.element_pool_allocator.alloc(4)
    
    self.class.map_element_buffer do |int_buffer|
      4.times do |i|
        int_buffer.put @element_buffer_index + i, @attr_buffer_index + i
      end
    end
  end
  
  # All the setup that must be done exactly once before any GUI components are drawn
  def self.ensure_static_initialized
    unless @static_initialized
      # Program
      @program = GLProgram.new 'shaders/gui_vert.glsl', 'shaders/gui_frag.glsl'
      
      # VAO
      @vao_id = GL30.glGenVertexArrays
      GL30.glBindVertexArray(@vao_id)
      
      # Attribute buffer
      @attr_vbo_id = GL15.glGenBuffers
      GL15.glBindBuffer GL15::GL_ARRAY_BUFFER, @attr_vbo_id
      # 4 vertices, 4 vector components per vertex, 4 bytes per vector component (float)
      GL15.glBufferData GL15::GL_ARRAY_BUFFER, MAX_RECTS * 4 * 4 * 4, GL15::GL_STATIC_DRAW
      
      # Attribute buffer format
      # index, size, type, normalized, stride, offset
      # Stride: 2 vectors * 3 components per vector * 4 bytes per component
      # Offset for tex coords: 3 components per vector * 4 bytes per component
      position_index = @program.attr_index('position')
      tex_coord_index = @program.attr_index('texCoord')
      GL20.glEnableVertexAttribArray(position_index)
      GL20.glVertexAttribPointer(position_index, 3, GL11::GL_FLOAT, false, 2 * 3 * 4, 0)
      GL20.glEnableVertexAttribArray(tex_coord_index)
      GL20.glVertexAttribPointer(tex_coord_index, 3, GL11::GL_FLOAT, false, 2 * 3 * 4, 3 * 4)
      
      GL30.glBindVertexArray(0)
      
      # Index buffer
      @index_vbo_id = GL15.glGenBuffers
      GL15.glBindBuffer GL15::GL_ELEMENT_ARRAY_BUFFER, @index_vbo_id
      GL15.glBufferData GL15::GL_ELEMENT_ARRAY_BUFFER, MAX_RECTS * 4, GL15::GL_STATIC_DRAW
      
      # For each of these pool allocators, we're allowing each element of the allocator's map
      # to represent one GUI component, i.e. 4 vertices.
      @attr_pool_allocator = PoolAllocator.new(MAX_RECTS)
      @element_pool_allocator = PoolAllocator.new(MAX_RECTS)
      
      # Array of all components, not all of which are necessarily rendered every frame
      @components = []
      
      # Create sprite sheet and initialize each component, placing it into the @components array
      imgs = Dir.glob(File.join(ROOT, 'assets/gui/*.png')).collect do |path|
        javax.imageio.ImageIO.read(java.io.File.new(path))
      end
      bin_items = imgs.collect do |img|
        Binpack::Item.new(img, img.getWidth, img.getHeight)
      end
      packed = Binpack::Bin.pack(bin_items, [], Binpack::Bin.new(1024, 1024, 1)).first.items
      sprite_sheet = java.awt.image.BufferedImage.new(1024, 1024, java.awt.image.BufferedImage::TYPE_INT_RGB)
      graphics = sprite_sheet.getGraphics
      packed.items.each do |item, left, top|
        graphics.drawImage(item.obj, left, top)
        @components << new(left, top, item.width, item.height, item.rotated)
      end
      
      @static_initialized = true
    end
  end
  
  # Call in a GuiComponent.map_element_buffer block
  def hide(indices)
    @element_index.upto(@element_index + 3) do |i|
      indices[i] = -1
    end
  end
  
  def self.element_pool_allocator
    @element_pool_allocator
  end
  
  def self.index_vbo_id
    @index_vbo_id
  end
  
  # spr_left and spr_top are the offsets in the sprite sheet. When initializing a new GUI component,
  # you don't give it screen coordinates. Those are provided later, when the sprite is shown and
  # any time it moves.
  def initialize(spr_left, spr_top, width, height, rotated)
    @spr_left = spr_left
    @spr_top = spr_top
    @width = width
    @height = height
    @rotated = rotated
    
    # As we set up each corner, we take into account the rotation. If a sprite is rotated on the sheet,
    # it is rotated 90* CW.
    t = spr_top.to_f / 1024
    r = (spr_left + width).to_f / 1024
    b = (spr_top + height).to_f / 1024
    l = spr_left.to_f / 1024
    @corners = []
    # Top left. If rotated, top right corner on sprite sheet.
    @corners << OpenStruct.new(:x => nil, :y => nil, :u => rotated ? r : l, :v => t)
    # Bottom left. If rotated, top left corner on sprite sheet.
    @corners << OpenStruct.new(:x => nil, :y => nil, :u => l, :v => rotated ? t : b)
    # Bottom right. If rotated, bottom left corner on sprite sheet.
    @corners << OpenStruct.new(:x => nil, :y => nil, :u => rotated ? l : r, :v => b)
    # Top right. If rotated, bottom right corner on sprite sheet.
    @corners << OpenStruct.new(:x => nil, :y => nil, :u => r, :v => rotated ? b : t)
  end
  
  def self.map_attr_buffer
    GL15.glBindBuffer GL15::GL_ARRAY_BUFFER, @attr_vbo_id
    # 4 indices per rectangle, 4 bytes per index
    attrs = GL15.glMapBuffer(GL15::GL_ELEMENT_ARRAY_BUFFER, GL15::GL_READ_WRITE, MAX_RECTS * 4 * 4).asFloatBuffer
    yield attrs
    GL15.glUnmapBuffer GL15::GL_ARRAY_BUFFER
    GL15.glBindBuffer GL15::GL_ARRAY_BUFFER, 0
  end
  
  def self.map_element_buffer
    GL15.glBindBuffer GL15::GL_ELEMENT_ARRAY_BUFFER, @attr_vbo_id
    # 4 4 vertices per rectangle, 4 vector components per vertex, 4 bytes component
    indices = GL15.glMapBuffer(GL15::GL_ELEMENT_ARRAY_BUFFER, GL15::GL_READ_WRITE, MAX_RECTS * 4 * 4).asIntBuffer
    yield indices
    GL15.glUnmapBuffer GL15::GL_ELEMENT_ARRAY_BUFFER
    GL15.glBindBuffer GL15::GL_ELEMENT_ARRAY_BUFFER, 0
  end
  
  def rebuffer_positions
    self.class.map_attr_buffer do |float_buffer|
      4.times do |i|
        # Position
        float_buffer.put @attr_buffer_index + i + 0, @corners[i].x
        float_buffer.put @attr_buffer_index + i + 1, @corners[i].y
        
        # Skip tex coords
        2.times { float_buffer.get }
      end
    end
  end
  
  def self.render
    GL30.glBindVertexArray(@vao_id)
    program.use
    program.bindTextures
    # Count is the number of elements in the index buffer
    GL11.glDrawElements(GL11::GL_QUADS, @attr_pool_allocator.maxUsed, GL11::GL_UNSIGNED_INT, 0)
    GL30.glBindVertexArray(0)
  end
  
  # Call in a GuiComponent.map_element_buffer block
  def show(indices)
    @element_index.upto(@element_index + 3) do |i|
      indices[i] = @attr_index + (i - @element_index)
    end
  end
end