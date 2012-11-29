#version 150

/* Note that for a variable to exist in the compiled shader, it must be used in the shader! */
in vec2 vPosition;
in vec2 vTexCoord;
uniform sampler2D sprites;
out vec4 outColor;

void main() {
  outColor = texture(sprites, vTexCoord);
}