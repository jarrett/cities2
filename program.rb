module OpenGL
  class Program
    attr_reader :id
    
    def attr_index(name)
      @attr_indices[name] ||= GL20.glGetAttribLocation @id, name
    end
    
    def initialize(vert_shader, frag_shader)
      if vert_shader.is_a?(String)
        vert_shader = Shader.new(GL20::GL_VERTEX_SHADER, vert_shader)
      end
      if frag_shader.is_a?(String)
        frag_shader = Shader.new(GL20::GL_FRAGMENT_SHADER, frag_shader)
      end
      @id = GL20.glCreateProgram
      GL20.glAttachShader(@id, vert_shader.id)
      GL20.glAttachShader(@id, frag_shader.id)
      GL20.glLinkProgram(@id)
      if GL20.glGetProgram(@id, GL20::GL_LINK_STATUS) != 1
        raise("Error linking GLSL program: " + GL20.glGetProgramInfoLog(@id, 10000).inspect)
      end
      @attr_indices = {}
      @uni_indices = {}
    end
    
    def uni_index(name)
      @uni_indices[name] ||= GL20.glGetUniformLocation @id, name
    end
  end
end