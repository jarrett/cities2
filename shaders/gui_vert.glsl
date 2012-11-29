#version 150

/* Note that for a variable to exist in the compiled shader, it must be used in the shader! */
in vec2 position;
in vec2 texCoord;
out vec2 vPosition;
out vec2 vTexCoord;

void main() {
  gl_Position = vec4(
    position.x,
    -1 * position.y,
    -1, // -1 is the near plane of the viewport.
    1
  );
  
  vPosition = position;
  vTexCoord = texCoord;
}