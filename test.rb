require 'java'
require 'jar/lwjgl.jar'
require 'jar/cities.jar'
require './gl_shader'
require './gl_program'

java_import 'org.lwjgl.BufferUtils'
java_import 'org.lwjgl.opengl.Display'
java_import 'org.lwjgl.opengl.DisplayMode'
java_import 'org.lwjgl.opengl.PixelFormat'
java_import 'org.lwjgl.opengl.ContextAttribs'
java_import 'org.lwjgl.opengl.GL11'
java_import 'org.lwjgl.opengl.GL14'
java_import 'org.lwjgl.opengl.GL15'
java_import 'org.lwjgl.opengl.GL20'
java_import 'org.lwjgl.opengl.GL30'
java_import 'org.lwjgl.input.Mouse'
java_import 'cities.HeightField'
java_import 'cities.TerrainMesh'
java_import 'cities.Camera'
java_import 'cities.GLTexture'
java_import 'cities.Thing'
java_import 'cities.ThingConfig'
java_import 'cities.World'
java_import 'javax.vecmath.Vector3f'

WINDOW_W = 1100
WINDOW_H = 700

World.width = 100
World.length = 100

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

# When Java returns a signed byte that should have been unsigned, positive numbers greater
# than 127 get two's-complemented. This fixes it.
def cast_byte_to_unsigned(byte)
  (-1 * (byte^0xff)) - 1
end

Display.setDisplayMode(DisplayMode.new(WINDOW_W, WINDOW_H))
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

# Set up FBO
fbo_w = 1024
fbo_h = ((WINDOW_H.to_f / WINDOW_W) * 1024).floor
fbo_id = GL30.glGenFramebuffers
GL30.glBindFramebuffer(GL30::GL_FRAMEBUFFER, fbo_id)
fbo_rb_id = GL30.glGenRenderbuffers
GL30.glBindRenderbuffer(GL30::GL_RENDERBUFFER, fbo_rb_id)
GL30.glRenderbufferStorage(GL30::GL_RENDERBUFFER, GL11::GL_RGBA, fbo_w, fbo_h)
GL30.glFramebufferRenderbuffer(GL30::GL_FRAMEBUFFER, GL30::GL_COLOR_ATTACHMENT0, GL30::GL_RENDERBUFFER, fbo_rb_id)
fbo_rd_id = GL30.glGenRenderbuffers
GL30.glBindRenderbuffer(GL30::GL_RENDERBUFFER, fbo_rd_id)
GL30.glRenderbufferStorage(GL30::GL_RENDERBUFFER, GL14::GL_DEPTH_COMPONENT16, fbo_w, fbo_h)
GL30.glFramebufferRenderbuffer(GL30::GL_FRAMEBUFFER, GL30::GL_DEPTH_ATTACHMENT, GL30::GL_RENDERBUFFER, fbo_rd_id)
unless (code = GL30.glCheckFramebufferStatus(GL30::GL_FRAMEBUFFER)) == GL30::GL_FRAMEBUFFER_COMPLETE
  failure = case code
  when GL30::GL_FRAMEBUFFER_UNDEFINED
    'GL_FRAMEBUFFER_UNDEFINED'
  when GL30::GL_FRAMEBUFFER_UNSUPPORTED
    'GL_FRAMEBUFFER_UNSUPPORTED'
  when GL30::GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT
    'GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT'
  when GL30::GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT
    'GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT'
  when GL30::GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER
    'GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER'
  when GL30::GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER
    'GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER'
  when GL30::GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE
    'GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE'
  else
    "unrecognized failure code: #{code}"
  end
  raise "Framebuffer not complete: #{failure}"
end
GL30.glBindFramebuffer(GL30::GL_FRAMEBUFFER, 0)

# FBO test code
img_written = false
img = java.awt.image.BufferedImage.new(fbo_w, fbo_h, java.awt.image.BufferedImage::TYPE_INT_RGB)
#puts 'blitting color to BufferedImage'
#0.upto(899) do |y|
#  0.upto(1499) do |x|
#    img.setRGB(x, y, java.awt.Color.new(x.to_f / 1499, y.to_f / 899, 1.to_f).getRGB)
#  end
#end
#puts 'done blitting'
#javax.imageio.ImageIO.write(img, "jpg", java.io.File.new("framebuffer.jpg"))
# End FBO test code

mouse_pos_buf = BufferUtils.createFloatBuffer(4)

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
  cam_matrix = Camera.matrix(WINDOW_W, WINDOW_H, zoom, trans_lr, trans_ud, rot_z, rot_x)
  
  ground_mesh.setCamera(cam_matrix)
  ground_mesh.render
  
  water_mesh.setCamera(cam_matrix)
  water_mesh.render
  
  Display.update
  
  
  GL30.glBindFramebuffer(GL30::GL_FRAMEBUFFER, fbo_id)
  GL11.glClear(GL11::GL_COLOR_BUFFER_BIT | GL11::GL_DEPTH_BUFFER_BIT)
  ground_mesh.render true
  water_mesh.render true
  #Display.update
  #buf = BufferUtils.createFloatBuffer(fbo_w * fbo_h * 3)
  #buf.rewind
  
  GL11.glReadBuffer(GL30::GL_COLOR_ATTACHMENT0)
  #GL11.glReadPixels(0, 0, fbo_w, fbo_h, GL11::GL_RGB, GL11::GL_FLOAT, buf)
  
  #GL11.glReadPixels(0, 0, 1, 1, GL11::GL_RGB, GL11::GL_FLOAT, buf)
  mouse_pos_buf.rewind
  GL11.glReadPixels(
    Mouse.getX * (fbo_w.to_f / WINDOW_W).round,
    Mouse.getY * (fbo_h.to_f / WINDOW_H).round,
    1, 1,
    GL11::GL_RGBA, GL11::GL_FLOAT, mouse_pos_buf
  )
  #buf.rewind
  mouse_pos_buf.rewind
  if false
    fbo_h.times do |y|
      fbo_w.times do |x|
        r = buf.get
        g = buf.get
        b = buf.get
        #a = buf.get
        img.setRGB(x, (fbo_h - 1) - y, java.awt.Color.new(r, g, b).getRGB)
      end
    end
    javax.imageio.ImageIO.write(img, "jpg", java.io.File.new("framebuffer.jpg"))
  end
  World.mouseX = mouse_pos_buf.get * World.width
  World.mouseY = mouse_pos_buf.get * World.length
  mouse_pos_buf.get # blue
  a = mouse_pos_buf.get
  if a > 0
    #puts "world x: #{x}, world y: #{y}"
  else
    World.mouseX = -1
    World.mouseY = -1
  end
  GL30.glBindFramebuffer(GL30::GL_FRAMEBUFFER, 0)
  
  Display.sync(30)
end
Display.destroy