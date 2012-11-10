require 'java'
require 'jar/lwjgl.jar'
require 'jar/cities.jar'
require './shader'
require './program'

java_import 'org.lwjgl.opengl.Display'
java_import 'org.lwjgl.opengl.DisplayMode'
java_import 'org.lwjgl.opengl.GL11'
java_import 'org.lwjgl.opengl.GL15'
java_import 'org.lwjgl.opengl.GL20'
java_import 'org.lwjgl.input.Mouse'
java_import 'cities.HeightField'
java_import 'cities.TerrainMesh'
java_import 'cities.Camera'
java_import 'cities.Texture'
#java_import 'javax.vecmath.Vector3d'

def check_gl_error
  code = GL11.glGetError
  if code != GL11::GL_NO_ERROR
    raise "OpenGL error code: 0x#{code.to_s(16)}"
  end
end

height_field = HeightField.new(1, 1, 0.07)
height_field.loadFromImage('assets/height_test_100x100.jpg')
terrain_mesh = TerrainMesh.new(height_field, 1)
terrain_mesh.generateMesh(0, 0, 1, 1)

Display.setDisplayMode(DisplayMode.new(800,600))
Display.create
Display.setTitle('Cities')

# Attribute buffer setup
ground_attr_buffer_id = GL15.glGenBuffers()
check_gl_error
GL15.glBindBuffer(GL15::GL_ARRAY_BUFFER, ground_attr_buffer_id)
check_gl_error
# Must call glBufferData, or else the buffer will not be properly initialized for glMapBuffer
# 6 elements per vertex, 8 bytes per element
GL15.glBufferData(GL15::GL_ARRAY_BUFFER, (terrain_mesh.rows * terrain_mesh.cols) * 6 * 8, GL15::GL_STATIC_DRAW)
check_gl_error
byte_buffer = GL15.glMapBuffer(GL15::GL_ARRAY_BUFFER, GL15::GL_WRITE_ONLY, (terrain_mesh.rows * terrain_mesh.cols) * 6 * 8, nil).asDoubleBuffer
check_gl_error
byte_buffer.rewind
terrain_mesh.verts.each do |row|
  row.each do |vert|
    byte_buffer.put(
      [
        vert.position.x, vert.position.y, vert.position.z,
        vert.normal.x, vert.normal.y, vert.normal.z
      ].to_java(:double)
    )
  end
end
GL15.glUnmapBuffer(GL15::GL_ARRAY_BUFFER)
check_gl_error
GL15.glBindBuffer(GL15::GL_ARRAY_BUFFER, 0)
check_gl_error

# Element buffer setup
ground_elem_buffer_id = GL15.glGenBuffers()
check_gl_error
GL15.glBindBuffer(GL15::GL_ELEMENT_ARRAY_BUFFER, ground_elem_buffer_id)
check_gl_error
# Must call glBufferData, or else the buffer will not be properly initialized for glMapBuffer
# 2 triangles per square, 3 indices per triangle, 4 bytes per index
GL15.glBufferData(GL15::GL_ELEMENT_ARRAY_BUFFER, terrain_mesh.squares * 2 * 3 * 4, GL15::GL_STATIC_DRAW)
check_gl_error
byte_buffer = GL15.glMapBuffer(GL15::GL_ELEMENT_ARRAY_BUFFER, GL15::GL_WRITE_ONLY, terrain_mesh.squares * 2 * 3 * 4, nil).asIntBuffer
byte_buffer.rewind
(terrain_mesh.rows - 1).times do |row|
  (terrain_mesh.cols - 1).times do |col|
    tl = (row * terrain_mesh.cols) + col
    tr = (row * terrain_mesh.cols) + col + 1
    bl = ((row + 1) * terrain_mesh.cols) + col
    br = ((row + 1) * terrain_mesh.cols) + col + 1
    byte_buffer.put(
      [
        tl, bl, tr, # top-left triangle
        br, tr, bl # bottom-right triangle
      ].to_java(:int)
    )
  end
end
GL15.glUnmapBuffer(GL15::GL_ELEMENT_ARRAY_BUFFER)
check_gl_error
GL15.glBindBuffer(GL15::GL_ELEMENT_ARRAY_BUFFER, 0)
check_gl_error

# Textures
dirt_texture = Texture.new('assets/textures/dirt_00.jpg')

# Shaders
program = OpenGL::Program.new('shaders/test_vert.glsl', 'shaders/ground_frag.glsl')

GL11.glClearColor(0.8, 0.85, 1, 0)
check_gl_error
GL11.glEnable(GL11::GL_DEPTH_TEST)
GL11.glDepthMask(true)
GL11.glDepthFunc(GL11::GL_LEQUAL)
check_gl_error

zoom = 100
rot_z = 0
rot_x = 0
trans_lr = 0
trans_ud = 0

until Display.isCloseRequested
  GL11.glClear(GL11::GL_COLOR_BUFFER_BIT | GL11::GL_DEPTH_BUFFER_BIT)
  check_gl_error
  
  zoom = (1.1 ** (Mouse.getDWheel * 0.002)) * zoom
  if Mouse.isButtonDown(0)
    rot_z += Mouse.getDX * 0.17
    rot_z = rot_z % 360
    rot_x -= Mouse.getDY * 0.17
    if rot_x < -90
      rot_x = -90
    elsif rot_x > 0
      rot_x = 0
    end
  elsif Mouse.isButtonDown(1)
    trans_lr += Mouse.getDX * 1.5 / zoom
    trans_ud += Mouse.getDY * 1.5 / zoom
  end
  Camera.set(800, 600, zoom, trans_lr, trans_ud, rot_z, rot_x)
  
  # Use shader program
  GL20.glUseProgram(program.id)
  check_gl_error
  
  # Bind
  GL15.glBindBuffer(GL15::GL_ARRAY_BUFFER, ground_attr_buffer_id)
  check_gl_error
  GL15.glBindBuffer(GL15::GL_ELEMENT_ARRAY_BUFFER, ground_elem_buffer_id)
  check_gl_error
  dirt_texture.bind(program.uni_index('dirt'), 0)
  check_gl_error
  
  # Attribute pointers
  # index, size, type, normalized, stride, offset
  # Stride: 2 vectors * 3 components per vector * 8 bytes per component
  # Offset for normals: 3 components per vector * 8 bytes per component
  GL20.glVertexAttribPointer(program.attr_index('position'), 3, GL11::GL_DOUBLE, false, 2 * 3 * 8, 0)
  check_gl_error
  GL20.glEnableVertexAttribArray(program.attr_index('position'))
  check_gl_error
  GL20.glVertexAttribPointer(program.attr_index('normal'), 3, GL11::GL_DOUBLE, false, 2 * 3 * 8, 3 * 8)
  check_gl_error
  GL20.glEnableVertexAttribArray(program.attr_index('normal'))
  check_gl_error
  
  # Draw
  # Count is the number of elements in the index buffer
  # 2 triangles per square, 3 indices per triangle
  GL11.glDrawElements(GL11::GL_TRIANGLES, terrain_mesh.squares * 2 * 3, GL11::GL_UNSIGNED_INT, 0)
  check_gl_error
  
  # Unbind
  GL15.glBindBuffer(GL15::GL_ARRAY_BUFFER, 0)
  check_gl_error
  GL15.glBindBuffer(GL15::GL_ELEMENT_ARRAY_BUFFER, 0)
  check_gl_error
  
  if false
    # Draw the Z axis
    GL11.glBegin(GL11::GL_LINES)
    GL20.glVertexAttrib3d(program.attr_index('position'), 0, 0, 0)
    GL20.glVertexAttrib3d(program.attr_index('normal'), 0, 0, 1)
    GL20.glVertexAttrib3d(program.attr_index('position'), 0, 0, 200)
    GL20.glVertexAttrib3d(program.attr_index('normal'), 0, 0, 1)
    
    GL20.glVertexAttrib3d(program.attr_index('position'), 0, 0, 200)
    GL20.glVertexAttrib3d(program.attr_index('normal'), 0, 0, 1)
    GL20.glVertexAttrib3d(program.attr_index('position'), 3, 0, 190)
    GL20.glVertexAttrib3d(program.attr_index('normal'), 0, 0, 1)
    
    GL20.glVertexAttrib3d(program.attr_index('position'), 0, 0, 200)
    GL20.glVertexAttrib3d(program.attr_index('normal'), 0, 0, 1)
    GL20.glVertexAttrib3d(program.attr_index('position'), -3, 0, 190)
    GL20.glVertexAttrib3d(program.attr_index('normal'), 0, 0, 1)
    GL11.glEnd
    check_gl_error
  end
  
  Display.update
  check_gl_error
  Display.sync(30)
end
Display.destroy