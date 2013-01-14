require 'ostruct'

# #update writes the component's vertex attributes into the appropriate places in the attribute buffer.
# It must be called manually. No other method within GuiComponent calls #update. (However, #update
# is recursive, so parents call #update on their children.)
#
# #show writes the component's vertex indices into the appropriate places in the element buffer, which
# will cause the component to be rendered on the next draw cycle. Likewise, #hide overwrites those
# spots in the element buffer with -1.

# #show is the appropriate way to display a component for the first time after it has been buffered.

class GuiComponent
  MAX_RECTS = 1
  
  attr_reader :children
  
  @@static_initialized = false
  
  # Relative to screen
  def abs_x
    @abs_x ||= (@parent ? @parent.abs_x + @x : @x)
  end
  
  def abs_y
    @abs_y ||= (@parent ? @parent.abs_y + @y : @y)
  end
  
  def attr_vbo_index
    raise('Calling attr_vbo_index for component with nil @sprite') unless @sprite
    # 4 vertices, 5 vector components per vertex
    @attr_vbo_index ||= @@attr_pool_allocator.alloc(1) * 4 * 5
  end
  
  def elem_vbo_index
    raise('Calling elem_vbo_index for component with nil @sprite') unless @sprite
    # 6 indices per quad
    @elem_vbo_index ||= @@element_pool_allocator.alloc(1) * 6
  end
  
  # All the setup that must be done exactly once before any GUI components are drawn.
  def self.ensure_static_initialized
    unless @@static_initialized
      Sprite.load_all unless Sprite.loaded?
      Glyph.load_all unless Glyph.loaded?
      
      # Program
      @@program = GLProgram.new 'shaders/gui_vert.glsl', 'shaders/gui_frag.glsl'
      check_gl_error
      @@program.textures['sprites'] = GLTexture.new(Sprite.sprite_sheet)
      @@program.textures['font'] = GLTexture.new(Glyph.sprite_sheet)
      @@screen_w_uni_index = @@program.uni_index('screenW')
      @@screen_h_uni_index = @@program.uni_index('screenH')
      check_gl_error
      
      # VAO
      @@vao_id = GL30.glGenVertexArrays
      GL30.glBindVertexArray(@@vao_id)
      check_gl_error
      
      # Attribute buffer
      @@attr_vbo_id = GL15.glGenBuffers
      GL15.glBindBuffer GL15::GL_ARRAY_BUFFER, @@attr_vbo_id
      # 4 vertices, 5 vector components per vertex (3 position, 2 tex), 4 bytes per vector component (float)
      GL15.glBufferData GL15::GL_ARRAY_BUFFER, MAX_RECTS * 4 * 5 * 4, GL15::GL_DYNAMIC_DRAW
      check_gl_error
      
      # Attribute buffer format:
      # There are 5 components to each vector: x, y, z, u, v.
      # Parameters of glVertexAttribPointer: index, size, type, normalized, stride, offset
      # Stride: 5 components per vertex * 4 bytes per component
      # Offset for tex coords: 5 components per vertex * 4 bytes per component
      position_index = @@program.attr_index('position')
      tex_coord_index = @@program.attr_index('texCoord')
      GL20.glEnableVertexAttribArray(position_index)
      GL20.glVertexAttribPointer(position_index, 3, GL11::GL_FLOAT, false, 5 * 4, 0)
      GL20.glEnableVertexAttribArray(tex_coord_index)
      GL20.glVertexAttribPointer(tex_coord_index, 2, GL11::GL_FLOAT, false, 5 * 4, 3 * 4)
      check_gl_error
      
      # Element buffer
      @@elem_vbo_id = GL15.glGenBuffers
      GL15.glBindBuffer GL15::GL_ELEMENT_ARRAY_BUFFER, @@elem_vbo_id
      # 6 indices per quad (because it's drawn as triangles) * 4 bytes per index
      GL15.glBufferData GL15::GL_ELEMENT_ARRAY_BUFFER, MAX_RECTS * 6 * 4, GL15::GL_DYNAMIC_DRAW
      check_gl_error
      
      # For each of these pool allocators, we're allowing each element of the allocator's map
      # to represent one GUI component. Thus, we can set the length of our pool allocators to
      # MAX_RECTS. So one unit in the attribute allocator is 4 * 5 * 4 = 80 bytes; one unit
      # in the elements allocator is 6 * 4 = 24 bytes.
      @@attr_pool_allocator = PoolAllocator.new(MAX_RECTS)
      @@element_pool_allocator = PoolAllocator.new(MAX_RECTS)
      check_gl_error
      
      GL30.glBindVertexArray(0)
      
      @@static_initialized = true
    end
  end
  
  def height=(new_h)
    @height = new_h
  end
  
  def hide
    raise 'not implemented'
  end
  
  # x and y are relative to screen if there is no parent. Otherwise, relative to parent.
  def initialize(x, y, width, height, options = {})
    @x = x
    @y = y
    @width = width
    @height = height
    @children = []
    if options[:sprite]
      self.sprite = options[:sprite]
    end
    if block_given?
      yield self
    end
  end
  
  attr_reader :parent
  
  # Uses glDrawElements.
  def self.render
    GL30.glBindVertexArray(@@vao_id)
    @@program.use
    @@program.bind_textures
    GL20.glUniform1i(@@screen_w_uni_index, Display.getWidth)
    GL20.glUniform1i(@@screen_h_uni_index, Display.getHeight)
    # Not sure why this is necessary, but without it, GL_ARRAY_BUFFER is bound to the terrain VBO.
    #GL15.glBindBuffer GL15::GL_ARRAY_BUFFER, @@attr_vbo_id
    #GL15.glBindBuffer GL15::GL_ELEMENT_ARRAY_BUFFER, @@elem_vbo_id
    #print_vbo GL15::GL_ELEMENT_ARRAY_BUFFER, :int
    #print_vbo GL15::GL_ARRAY_BUFFER, :float
    # Count is the number of elements in the index buffer
    # (@@attr_pool_allocator.maxUsed + 1) * 6: In the allocators, 1 element corresponds to a single
    # GuiComponent. The number of vertices to draw is thus the number of allocated slots times 6.
    # We add 1 because the number returned by maxUsed is an index, so the total is actually that
    # plus one.
    #puts "Count: #{(@@attr_pool_allocator.maxUsed + 1) * 6}"
    GL11.glDrawElements(GL11::GL_TRIANGLES, (@@attr_pool_allocator.maxUsed + 1) * 6, GL11::GL_UNSIGNED_INT, 0)
    GL30.glBindVertexArray(0)
    GL15.glBindBuffer GL15::GL_ARRAY_BUFFER, 0
    check_gl_error
  end
  
  def show
    # 6 indices per quad, 4 bytes per index
    byte_buffer = BufferUtils.createByteBuffer(6 * 4).asIntBuffer
    # Each of these is the index of the vertex within the attributes buffer. Thus, if elem_vbo_index
    # is 24, we're looking at the second thing in this array, and its value is 39, we will ultimately
    # write 39 to position 26 of the element buffer.
    byte_buffer.put([
      # Top left
      attr_vbo_index + 0,
      # Bottom left
      attr_vbo_index + 1,
      # Top right
      attr_vbo_index + 3,
      
      # Bottom left
      attr_vbo_index + 1,
      # Bottom right
      attr_vbo_index + 2,
      # Top right
      attr_vbo_index + 3,
    ].to_java(:int))
    
    byte_buffer.rewind
    GL15.glBindBuffer GL15::GL_ELEMENT_ARRAY_BUFFER, @@elem_vbo_id
    GL15.glBufferSubData(GL15::GL_ELEMENT_ARRAY_BUFFER, elem_vbo_index, byte_buffer)
    GL15.glBindBuffer GL15::GL_ELEMENT_ARRAY_BUFFER, 0
  end
  
  # Pass in a Sprite instance or the Sprite's ID as a String.
  def sprite=(sprite)
    unless sprite.is_a?(Sprite)
      sprite = Sprite.get(sprite.to_s)
    end
    @sprite = sprite
  end
  
  # Call this after changing the component's position. Its position and those of its descendants
  # will be rebuffered (for those that have a sprite).
  def update
    @abs_x = nil
    @abs_y = nil
    if @sprite
      pos_left = abs_x
      pos_right = abs_x + @width
      pos_top = abs_y
      pos_bottom = abs_y + @height
      tex_left = @sprite.u_frac
      tex_right = @sprite.u_frac + @sprite.w_frac
      tex_top = @sprite.v_frac
      tex_bottom = @sprite.v_frac + @sprite.h_frac
      
      # Write to the attribute buffer. We won't write to the element buffer until we call #show.
      
      # 4 vertices, 5 vector components per vertex (3 position, 2 tex), 4 bytes per vector component (float)
      byte_buffer = BufferUtils.createByteBuffer(4 * 5 * 4).asFloatBuffer
      byte_buffer.put([
        # Top left
        pos_top,
        pos_left,
        z,
        tex_left,
        tex_top,
        
        # Bottom left
        pos_left,
        pos_bottom,
        z,
        tex_left,
        tex_bottom,
        
        # Bottom right
        pos_right,
        pos_bottom,
        z,
        tex_right,
        tex_bottom,
        
        # Top right
        pos_right,
        pos_top,
        z,
        tex_right,
        tex_top
      ].to_java(:float))
      byte_buffer.rewind
      GL15.glBindBuffer GL15::GL_ARRAY_BUFFER, @@attr_vbo_id
      GL15.glBufferSubData(GL15::GL_ARRAY_BUFFER, attr_vbo_index, byte_buffer)
      GL15.glBindBuffer GL15::GL_ARRAY_BUFFER, 0
    end
    children.each { |c| c.update }
  end
  
  def width=(new_w)
    @width = new_w
  end
  
  # Relative to screen if there is no parent. Otherwise, relative to parent.
  def x=(new_x)
    @x = new_x
    @abs_x = nil
  end
  
  # Relative to screen if there is no parent. Otherwise, relative to parent.
  def y=(new_y)
    @y = new_y
    @abs_y = nil
  end
  
  def z
    if @z
      @z
    else
      if @parent
        @z = @parent.z + 0.0001
      else
        @z = 0.99
      end
    end
  end
  
  attr_writer :z
end