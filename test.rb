require 'java'
require 'jar/lwjgl.jar'
require 'jar/cities.jar'

java_import 'org.lwjgl.opengl.Display'
java_import 'org.lwjgl.opengl.DisplayMode'
java_import 'org.lwjgl.opengl.GL11'
java_import 'org.lwjgl.opengl.GL15'
java_import 'org.lwjgl.opengl.GL20'
java_import 'org.lwjgl.input.Mouse'
java_import 'cities.HeightField'
java_import 'cities.TerrainMesh'
java_import 'cities.Camera'
java_import 'javax.vecmath.Vector3d'

def check_gl_error
  code = GL11.glGetError
  if code != GL11::GL_NO_ERROR
    raise "OpenGL error code: 0x#{code.to_s(16)}"
  end
end

height_field = HeightField.new(1, 1, 0.2)
height_field.loadFromImage('assets/height_test_100x100.jpg')
terrain_mesh = TerrainMesh.new(height_field, 1)
terrain_mesh.generateMesh(0, 0, 1, 1)

Display.setDisplayMode(DisplayMode.new(800,600))
Display.create
Display.setTitle('Cities')

# Attribute buffer setup
attr_buffer_id = GL15.glGenBuffers()
check_gl_error
GL15.glBindBuffer(GL15::GL_ARRAY_BUFFER, attr_buffer_id)
check_gl_error
# Must call glBufferData, or else the buffer will not be properly initialized for glMapBuffer
# 6 elements per vertex, 8 bytes per element
GL15.glBufferData(GL15::GL_ARRAY_BUFFER, (terrain_mesh.rows * terrain_mesh.cols) * 6 * 8 * 10, GL15::GL_STATIC_DRAW)
check_gl_error
byte_buffer = GL15.glMapBuffer(GL15::GL_ARRAY_BUFFER, GL15::GL_WRITE_ONLY, (terrain_mesh.rows * terrain_mesh.cols) * 6 * 8 * 10, nil).asDoubleBuffer
check_gl_error
byte_buffer.rewind
terrain_mesh.verts.each do |row|
  row.each do |vert|
    byte_buffer.put(
      [
        vert.position.x, vert.position.y, vert.position.z,
        vert.normal.x, vert.normal.y, vert.normal.z
        #vert.position.x, vert.position.y, vert.position.z
      ].to_java(:double)
    )
  end
end
GL15.glUnmapBuffer(GL15::GL_ARRAY_BUFFER)
check_gl_error
GL15.glBindBuffer(GL15::GL_ARRAY_BUFFER, 0)
check_gl_error

# Element buffer setup
elem_buffer_id = GL15.glGenBuffers()
check_gl_error
GL15.glBindBuffer(GL15::GL_ELEMENT_ARRAY_BUFFER, elem_buffer_id)
check_gl_error
# Must call glBufferData, or else the buffer will not be properly initialized for glMapBuffer
# 2 triangles per square, 3 indices per triangle, 4 bytes per index
GL15.glBufferData(GL15::GL_ELEMENT_ARRAY_BUFFER, terrain_mesh.squares * 2 * 3 * 4 * 10, GL15::GL_STATIC_DRAW)
check_gl_error
byte_buffer = GL15.glMapBuffer(GL15::GL_ELEMENT_ARRAY_BUFFER, GL15::GL_WRITE_ONLY, terrain_mesh.squares * 2 * 3 * 4 * 10, nil).asIntBuffer
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

# Shaders

def create_shader(type, path)
  shader_id = GL20.glCreateShader(type);
  check_gl_error
  GL20.glShaderSource(shader_id, File.read(path));
  check_gl_error
  GL20.glCompileShader(shader_id);
  if GL20.glGetShader(shader_id, GL20::GL_COMPILE_STATUS) != 1
    raise("Error in " + path + ": " + GL20.glGetShaderInfoLog(shader_id, 10000).inspect)
  end
  shader_id;
end

vert_shader_id = create_shader(GL20::GL_VERTEX_SHADER, 'shaders/test_vert.glsl')
check_gl_error
frag_shader_id = create_shader(GL20::GL_FRAGMENT_SHADER, 'shaders/test_frag.glsl')
check_gl_error
program_id = GL20.glCreateProgram
GL20.glAttachShader(program_id, vert_shader_id)
check_gl_error
GL20.glAttachShader(program_id, frag_shader_id)
check_gl_error
GL20.glLinkProgram(program_id)
if GL20.glGetProgram(program_id, GL20::GL_LINK_STATUS) != 1
  raise("Error linking GLSL program: " + GL20.glGetProgramInfoLog(program_id, 10000).inspect)
end

position_attr_index = GL20.glGetAttribLocation program_id, "position"
check_gl_error
normal_attr_index =   GL20.glGetAttribLocation program_id, "normal"
check_gl_error

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
    puts rot_x
  elsif Mouse.isButtonDown(1)
    trans_lr += Mouse.getDX * 1.5 / zoom
    trans_ud += Mouse.getDY * 1.5 / zoom
  end
  Camera.set(800, 600, zoom, trans_lr, trans_ud, rot_z, rot_x)
  
  # Use shader program
  GL20.glUseProgram(program_id)
  check_gl_error
  
  # Bind
  GL15.glBindBuffer(GL15::GL_ARRAY_BUFFER, attr_buffer_id)
  check_gl_error
  GL15.glBindBuffer(GL15::GL_ELEMENT_ARRAY_BUFFER, elem_buffer_id)
  check_gl_error
  
  # Attribute pointers
  # index, size, type, normalized, stride, offset
  # Stride: 2 vectors * 3 components per vector * 8 bytes per component
  # Offset for normals: 3 components per vector * 8 bytes per component
  GL20.glVertexAttribPointer(position_attr_index, 3, GL11::GL_DOUBLE, false, 2 * 3 * 8, 0)
  check_gl_error
  GL20.glEnableVertexAttribArray(position_attr_index)
  check_gl_error
  GL20.glVertexAttribPointer(normal_attr_index, 3, GL11::GL_DOUBLE, false, 2 * 3 * 8, 3 * 8)
  check_gl_error
  GL20.glEnableVertexAttribArray(normal_attr_index)
  check_gl_error
  
  # Draw
  # Count is the number of elements in the index buffer
  # 2 triangles per square, 3 indices per triangle, 4 bytes per index
  GL11.glDrawElements(GL11::GL_TRIANGLES, terrain_mesh.squares * 2 * 3 * 4, GL11::GL_UNSIGNED_INT, 0)
  check_gl_error
  
  # Unbind
  GL15.glBindBuffer(GL15::GL_ARRAY_BUFFER, 0)
  check_gl_error
  GL15.glBindBuffer(GL15::GL_ELEMENT_ARRAY_BUFFER, 0)
  check_gl_error
  
  GL11.glBegin(GL11::GL_LINES)
  GL20.glVertexAttrib3d(position_attr_index, 0, 0, 0)
  GL20.glVertexAttrib3d(normal_attr_index, 0, 0, 1)
  GL20.glVertexAttrib3d(position_attr_index, 0, 0, 200)
  GL20.glVertexAttrib3d(normal_attr_index, 0, 0, 1)
  
  GL20.glVertexAttrib3d(position_attr_index, 0, 0, 200)
  GL20.glVertexAttrib3d(normal_attr_index, 0, 0, 1)
  GL20.glVertexAttrib3d(position_attr_index, 3, 0, 190)
  GL20.glVertexAttrib3d(normal_attr_index, 0, 0, 1)
  
  GL20.glVertexAttrib3d(position_attr_index, 0, 0, 200)
  GL20.glVertexAttrib3d(normal_attr_index, 0, 0, 1)
  GL20.glVertexAttrib3d(position_attr_index, -3, 0, 190)
  GL20.glVertexAttrib3d(normal_attr_index, 0, 0, 1)
  GL11.glEnd
  check_gl_error
  
  if false
    GL11.glColor3d(1, 0, 0)
    GL11.glPointSize(5.0)
    check_gl_error
    
    GL11.glBegin(GL11::GL_POINTS)
    terrain_mesh.verts.each do |row|
      row.each do |vert|
        GL11.glVertex3d(vert.position.x, vert.position.y, vert.position.z)
      end
    end
    GL11.glEnd
    check_gl_error
    
    terrain_mesh.verts.each do |row|
      row.each do |vert|
        GL11.glBegin(GL11::GL_LINES)
        GL11.glVertex3d(vert.position.x, vert.position.y, vert.position.z)
        ray_end = Vector3d.new(vert.position)
        ray_end.add(vert.normal)
        GL11.glVertex3d(ray_end.x, ray_end.y, ray_end.z)
        GL11.glEnd
        check_gl_error
      end
    end
  end
  
  Display.update
  check_gl_error
  Display.sync(30)
end
Display.destroy