class GLProgram
  java_implements 'cities.GLProgramI'
  
  attr_reader :id
  
  java_signature 'public int attrIndex(String name)'
  def attr_index(name)
    @attr_indices[name] ||= GL20.glGetAttribLocation @id, name
    @attr_indices[name] == -1 ? raise("Index for attribute #{name} was -1") : @attr_indices[name]
  end
  
  java_signature 'public void bindTextures()'
  def bind_textures
    @textures.each_with_index do |(uni_name, texture), i|
      texture.bind uni_index(uni_name), i
    end
  end
  
  def initialize(vert_shader, frag_shader)
    if vert_shader.is_a?(String)
      vert_shader = GLShader.new(GL20::GL_VERTEX_SHADER, vert_shader)
    end
    if frag_shader.is_a?(String)
      frag_shader = GLShader.new(GL20::GL_FRAGMENT_SHADER, frag_shader)
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
    @frag_data_indices = {}
    @textures = {}
  end
  
  java_signature 'public void setMouseCoordUnis()'
  def set_mouse_coord_unis
    GL20.glUniform2f(uni_index('mouseCoords'), World.mouseX, World.mouseY)
  end
  
  java_signature 'public void setWorldSizeUnis()'
  def set_world_size_unis
    GL20.glUniform2f(uni_index('worldSize'), World.width, World.length)
  end
  
  attr_reader :textures
  
  java_signature 'public int uniIndex(String name)'
  def uni_index(name)
    @uni_indices[name] ||= GL20.glGetUniformLocation @id, name
    @uni_indices[name] == -1 ? raise("Index for uniform #{name} was -1") : @uni_indices[name]
  end
  
  java_signature 'public void use()'
  def use
    GL20.glUseProgram(id)
  end
end