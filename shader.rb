module OpenGL
  class Shader
    attr_reader :id
    
    def initialize(type, path)
      @id = GL20.glCreateShader(type)
      check_gl_error
      GL20.glShaderSource(@id, File.read(path))
      check_gl_error
      GL20.glCompileShader(@id)
      if GL20.glGetShader(@id, GL20::GL_COMPILE_STATUS) != 1
        raise("Error in #{path}: #{GL20.glGetShaderInfoLog(@id, 10000).inspect}")
      end
      @id
    end
  end
end