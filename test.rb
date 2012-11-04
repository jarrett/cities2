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

height_field = HeightField.new(1, 1, 1)
height_field.loadFromImage('assets/height_test.jpg')

Display.setDisplayMode(DisplayMode.new(800,600))
Display.create
Display.setTitle('Cities')


GL11.glClearColor(0.8, 0.85, 1, 0)
check_gl_error

until Display.isCloseRequested
  GL11.glClear(GL11::GL_COLOR_BUFFER_BIT | GL11::GL_DEPTH_BUFFER_BIT)

  
  
  Display.update
  check_gl_error
  Display.sync(30)
end
Display.destroy