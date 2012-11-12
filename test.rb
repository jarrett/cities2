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
java_import 'cities.Thing'
java_import 'javax.vecmath.Vector3d'

def check_gl_error
  code = GL11.glGetError
  if code != GL11::GL_NO_ERROR
    raise "OpenGL error code: 0x#{code.to_s(16)}"
  end
end

def draw_line(position_attr_index, normal_attr_index, from, to)
  GL11.glLineWidth(4)
  GL11.glBegin(GL11::GL_LINES)
  GL20.glVertexAttrib3d(position_attr_index, from.x, from.y, from.z)
  GL20.glVertexAttrib3d(normal_attr_index, 0, 0, 1)
  GL20.glVertexAttrib3d(position_attr_index, to.x, to.y, to.z)
  GL20.glVertexAttrib3d(normal_attr_index, 0, 0, 1)
  GL11.glEnd
  check_gl_error
end

Display.setDisplayMode(DisplayMode.new(1500,900))
Display.create
Display.setTitle('Cities')

tall_grass_2_cfg = ThingConfig.new('tall_grass_2', 'assets/things/tall_grass_2.zip')

ground_height_field = HeightField.new(1, 1, 0.07)
ground_height_field.loadFromImage('assets/height_test_river_100x100.jpg')
ground_mesh = TerrainMesh.new(ground_height_field, 1)
ground_mesh.generateMesh(0, 0, 100, 100)
ground_mesh.initBuffers

water_height_field = HeightField.new(1, 1, 0.03)
water_height_field.loadFromImage('assets/water_height_100x100.jpg')
water_mesh = TerrainMesh.new(water_height_field, 1)
water_mesh.generateMesh(0, 0, 100, 100)
water_mesh.initBuffers

# Textures
grass_texture = Texture.new('assets/textures/grass_00.jpg')
cliff_texture = Texture.new('assets/textures/cliff.jpg')
rocky_grass_texture = Texture.new('assets/textures/rocky_grass.jpg')
sand_texture = Texture.new('assets/textures/sand.jpg')
ground_height_texture = Texture.new('assets/height_test_river_100x100.jpg')
water_height_texture = Texture.new('assets/water_height_100x100.jpg')
foam_texture = Texture.new('assets/textures/foam.jpg')

# Shaders
ground_program = OpenGL::Program.new('shaders/test_vert.glsl', 'shaders/ground_frag.glsl')
water_program = OpenGL::Program.new('shaders/test_vert.glsl', 'shaders/water_frag.glsl')

GL11.glClearColor(0.8, 0.85, 1, 0)
GL11.glEnable(GL11::GL_DEPTH_TEST)
GL11.glDepthMask(true)
GL11.glDepthFunc(GL11::GL_LEQUAL)
GL11.glEnable(GL11::GL_BLEND)
GL11.glBlendFunc(GL11::GL_SRC_ALPHA, GL11::GL_ONE_MINUS_SRC_ALPHA)

zoom = 10
rot_z = 45
rot_x = -45
trans_lr = 0
trans_ud = -50

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
  Camera.set(1500, 900, zoom, trans_lr, trans_ud, rot_z, rot_x)
  
  ground_program.use
  ground_mesh.attrBuffer.bind
  ground_mesh.indexBuffer.bind
  grass_texture.bind(ground_program.uni_index('grass'), 0)
  cliff_texture.bind(ground_program.uni_index('cliff'), 1)
  rocky_grass_texture.bind(ground_program.uni_index('rockyGrass'), 2)
  sand_texture.bind(ground_program.uni_index('sand'), 3)
  water_height_texture.bind(ground_program.uni_index('waterHeightMap'), 4)
  ground_mesh.setAttrPointers(
    ground_program.attr_index('position'),
    ground_program.attr_index('normal')
  )
  ground_mesh.drawElements
  
  water_program.use
  water_mesh.attrBuffer.bind
  water_mesh.indexBuffer.bind
  #water_normal_texture.bind(water_program.uni_index('normalMap'), 0)
  water_height_texture.bind(water_program.uni_index('waterHeightMap'), 1)
  ground_height_texture.bind(water_program.uni_index('groundHeightMap'), 2)
  foam_texture.bind(water_program.uni_index('foam'), 3)
  #cam_dir = Camera.direction
  #GL20.glUniform3f(
  #  water_program.uni_index('camDir'),
  #  cam_dir.x, cam_dir.y, cam_dir.z
  #)
  water_mesh.setAttrPointers(
    water_program.attr_index('position'),
    water_program.attr_index('normal')
  )
  water_mesh.drawElements
  
  Display.update
  check_gl_error
  Display.sync(30)
end
Display.destroy