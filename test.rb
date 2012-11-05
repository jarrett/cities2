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

height_field = HeightField.new(1, 1, 1)
height_field.loadFromImage('assets/height_test_3x3.jpg')
terrain_mesh = TerrainMesh.new(height_field, 1)
puts "Cols: #{terrain_mesh.cols}"
puts "Rows: #{terrain_mesh.rows}"
terrain_mesh.generateMesh(0, 0, 1, 1)
terrain_mesh.verts.each_with_index do |row, y|
  row.each_with_index do |vert, x|
    puts "(#{x},#{y}): #{vert.position.x}, #{vert.position.y}, #{vert.position.z} - #{vert.normal.x}, #{vert.normal.y}, #{vert.normal.z}"
  end
end

Display.setDisplayMode(DisplayMode.new(800,600))
Display.create
Display.setTitle('Cities')


GL11.glClearColor(0.8, 0.85, 1, 0)
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
    rot_z += Mouse.getDX * 0.1
    rot_z = rot_z % 360
    rot_x += Mouse.getDY * 0.01
    rot_x = rot_x % 360
  elsif Mouse.isButtonDown(1)
    trans_lr += Mouse.getDX * 0.005
    trans_ud += Mouse.getDY * 0.005
  end
  Camera.set(800, 600, zoom, trans_lr, trans_ud, rot_z, rot_x)
  #GL11.glMatrixMode(GL11::GL_MODELVIEW)
  #GL11.glLoadIdentity()
  #GL11.glOrtho(-4, 4, -4, 4, -300, 300)
  #check_gl_error
  
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
  
  Display.update
  check_gl_error
  Display.sync(30)
end
Display.destroy