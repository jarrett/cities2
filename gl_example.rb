require 'java'
require 'jar/lwjgl.jar'
require 'jar/cities.jar'

java_import 'org.lwjgl.opengl.Display'
java_import 'org.lwjgl.opengl.DisplayMode'
java_import 'org.lwjgl.opengl.GL11'
java_import 'org.lwjgl.opengl.GL15'
java_import 'org.lwjgl.opengl.GL20'
java_import 'java.lang.System'
java_import 'cities.HeightField'
java_import 'cities.Camera'

def check_gl_error
  code = GL11.glGetError
  if code != GL11::GL_NO_ERROR
    raise "OpenGL error code: 0x#{code.to_s(16)}"
  end
end

Display.setDisplayMode(DisplayMode.new(800,600))
Display.create
Display.setTitle('Cities')

# Attribute buffer setup
attr_buffer_id = GL15.glGenBuffers()
check_gl_error
GL15.glBindBuffer(GL15::GL_ARRAY_BUFFER, attr_buffer_id)
check_gl_error
# Must call glBufferData, or else the buffer will not be properly initialized for glMapBuffer
GL15.glBufferData(GL15::GL_ARRAY_BUFFER, 3 * 6 * 8, GL15::GL_STATIC_DRAW)
check_gl_error
byte_buffer = GL15.glMapBuffer(GL15::GL_ARRAY_BUFFER, GL15::GL_WRITE_ONLY, 3 * 6 * 8, nil).asDoubleBuffer
check_gl_error
byte_buffer.rewind
byte_buffer.put(
  [
    # Positions   Normals
    -1, 0, -10,     0, 0, -1,
     1, 0, -10,     0, 0, -1,
     0, 1, -10,     0, 0, -1
  ].to_java(:double)
)
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
GL15.glBufferData(GL15::GL_ELEMENT_ARRAY_BUFFER, 3 * 4, GL15::GL_STATIC_DRAW)
check_gl_error
byte_buffer = GL15.glMapBuffer(GL15::GL_ELEMENT_ARRAY_BUFFER, GL15::GL_WRITE_ONLY, 3 * 4, nil).asIntBuffer
byte_buffer.rewind
byte_buffer.put(
  [0, 1, 2].to_java(:int)
)
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

until Display.isCloseRequested
  GL11.glClear(GL11::GL_COLOR_BUFFER_BIT | GL11::GL_DEPTH_BUFFER_BIT)
  
  Camera.setCamera(800, 600, 200, 0, 0, 0, 0)
  #GL11.glMatrixMode(GL11::GL_MODELVIEW)
  #GL11.glLoadIdentity()
  #GL11.glOrtho(-1, 1, -1, 1, -10, 10)
  #check_gl_error
  
  #GL11.glBegin(GL11::GL_TRIANGLES)
  #GL11.glVertex3d(0, 1, 0)
  #GL11.glVertex3d(1, 0, 0)
  #GL11.glVertex3d(-1, 0, 0)
  #GL11.glEnd
  
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
  GL20.glVertexAttribPointer(normal_attr_index, 3, GL11::GL_DOUBLE, false, 2 * 3 * 8, 3 * 8)
  check_gl_error
  GL20.glEnableVertexAttribArray(position_attr_index)
  check_gl_error
  GL20.glEnableVertexAttribArray(normal_attr_index)
  check_gl_error
  
  # Draw
  GL11.glDrawElements(GL11::GL_TRIANGLES, 3, GL11::GL_UNSIGNED_INT, 0) # Count is the number of elements in the index buffer
  check_gl_error
  
  # Unbind
  GL15.glBindBuffer(GL15::GL_ARRAY_BUFFER, 0)
  check_gl_error
  GL15.glBindBuffer(GL15::GL_ELEMENT_ARRAY_BUFFER, 0)
  check_gl_error
  
  Display.update
  check_gl_error
  Display.sync(30)
end
Display.destroy