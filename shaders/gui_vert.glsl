#version 150

/* Note that for a variable to exist in the compiled shader, it must be used in the shader! */
uniform int screenW;
uniform int screenH;
in vec3 position; // Given in pixels, not a fraction of the window size
in vec2 texCoord;
out vec2 vPosition;
out vec2 vTexCoord;

void main() {
  /*float x = position.x / screenW;
  float y = -1 * (position.y / screenH);*/
  screenW;
  screenH;
  float x = position.x * 0.02;
  float y = position.y * 0.02;
  gl_Position = vec4(
    x,
    y,
    0,//position.z, // -1 is the near plane of the viewport.
    1
  );
  
  vPosition = vec2(position);
  vTexCoord = texCoord;
}