require 'java'
require 'jar/lwjgl.jar'
require 'jar/cities.jar'
require './gl_shader'
require './gl_program'

java_import 'org.lwjgl.opengl.Display'
java_import 'org.lwjgl.opengl.DisplayMode'
java_import 'org.lwjgl.opengl.PixelFormat'
java_import 'org.lwjgl.opengl.ContextAttribs'
java_import 'org.lwjgl.opengl.GL11'
java_import 'org.lwjgl.opengl.GL15'
java_import 'org.lwjgl.opengl.GL20'
java_import 'org.lwjgl.input.Mouse'
java_import 'cities.HeightField'
java_import 'cities.TerrainMesh'
java_import 'cities.Camera'
java_import 'cities.GLTexture'
java_import 'cities.Thing'
java_import 'cities.ThingConfig'
java_import 'javax.vecmath.Vector3f'

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
Display.create(
  PixelFormat.new,
  ContextAttribs.new(3, 2).withProfileCore(true)
)
Display.setTitle('Cities')

# Shaders
ground_program = GLProgram.new('shaders/terrain_vert.glsl', 'shaders/ground_frag.glsl')
water_program = GLProgram.new('shaders/terrain_vert.glsl', 'shaders/water_frag.glsl')
check_gl_error

# Textures
grass_texture = GLTexture.new('assets/textures/grass_00.jpg')
cliff_texture = GLTexture.new('assets/textures/cliff.jpg')
rocky_grass_texture = GLTexture.new('assets/textures/rocky_grass.jpg')
sand_texture = GLTexture.new('assets/textures/sand.jpg')
ground_height_texture = GLTexture.new('assets/height_test_river_100x100.jpg')
water_height_texture = GLTexture.new('assets/water_height_100x100.jpg')
foam_texture = GLTexture.new('assets/textures/foam.jpg')
check_gl_error

ground_program.textures['grass'] = grass_texture
ground_program.textures['cliff'] = cliff_texture
ground_program.textures['rockyGrass'] = rocky_grass_texture
ground_program.textures['sand'] = sand_texture
ground_program.textures['waterHeightMap'] = water_height_texture

water_program.textures['waterHeightMap'] = water_height_texture
water_program.textures['groundHeightMap'] = ground_height_texture
water_program.textures['foam'] = foam_texture

ground_height_field = HeightField.new(1, 1, 0.07)
ground_height_field.loadFromImage('assets/height_test_river_100x100.jpg')
ground_mesh = TerrainMesh.new(ground_height_field, 1, ground_program)
ground_mesh.generateMesh(0, 0, 100, 100)
ground_mesh.initBuffers
check_gl_error

tall_grass_2_cfg = ThingConfig.new('tall_grass_2', 'assets/things/tall_grass_2.zip')
tall_grasses = []
100.times do |i|
  tall_grass = Thing.new(tall_grass_2_cfg)
  tall_grass.x = rand(99)
  tall_grass.y = rand(99)
  # Don't put it in the river
  if (tall_grass.z = ground_height_field.atXY(tall_grass.x, tall_grass.y)) > 4
    tall_grass.makeLive
    tall_grasses << tall_grass
  end
end

water_height_field = HeightField.new(1, 1, 0.03)
water_height_field.loadFromImage('assets/water_height_100x100.jpg')
water_mesh = TerrainMesh.new(water_height_field, 1, water_program)
water_mesh.generateMesh(0, 0, 100, 100)
water_mesh.initBuffers
check_gl_error

GL11.glClearColor(0.8, 0.85, 1, 0)
GL11.glEnable(GL11::GL_DEPTH_TEST)
GL11.glDepthMask(true)
GL11.glDepthFunc(GL11::GL_LEQUAL)
GL11.glEnable(GL11::GL_BLEND)
GL11.glBlendFunc(GL11::GL_SRC_ALPHA, GL11::GL_ONE_MINUS_SRC_ALPHA)
check_gl_error

zoom = 10
rot_z = Math::PI / 4
rot_x = Math::PI / -4
trans_lr = 0
trans_ud = -50

# FBO test code
img_written = false
img = java.awt.image.BufferedImage.new(1500, 900, java.awt.image.BufferedImage::TYPE_INT_RGB)
puts 'blitting color to BufferedImage'
#0.upto(899) do |y|
#  0.upto(1499) do |x|
#    img.setRGB(x, y, java.awt.Color.new(x.to_f / 1499, y.to_f / 899, 1.to_f).getRGB)
#  end
#end
puts 'done blitting'
javax.imageio.ImageIO.write(img, "jpg", java.io.File.new("framebuffer.jpg"))
# End FBO test code

until Display.isCloseRequested
  GL11.glClear(GL11::GL_COLOR_BUFFER_BIT | GL11::GL_DEPTH_BUFFER_BIT)
  check_gl_error
  
  zoom = (1.1 ** (Mouse.getDWheel * 0.002)) * zoom
  if Mouse.isButtonDown(0)
    rot_z += Mouse.getDX * 0.003
    rot_z = rot_z % (Math::PI * 2)
    rot_x -= Mouse.getDY * 0.003
    if rot_x < Math::PI / (-2)
      rot_x = Math::PI / (-2)
    elsif rot_x > 0
      rot_x = 0
    end
  elsif Mouse.isButtonDown(1)
    trans_lr += Mouse.getDX * 1.5 / zoom
    trans_ud += Mouse.getDY * 1.5 / zoom
  end
  cam_matrix = Camera.matrix(1500, 900, zoom, trans_lr, trans_ud, rot_z, rot_x)
  
  ground_mesh.setCamera(cam_matrix)
  ground_mesh.render
  
  water_mesh.setCamera(cam_matrix)
  water_mesh.render
  
  Display.update
  Display.sync(30)
end
Display.destroy