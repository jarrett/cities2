#version 150

/* Note that for a variable to exist in the compiled shader, it must be used in the shader! */
in vec2 vPosition;
in vec2 vTexCoord;
uniform sampler2D sprites;
uniform sampler2D font;
out vec4 outColor;

void main() {
  /* Positive tex coords mean we should use the main sprite sheet. Negative coords mean
  we should use the font atlas. Just a silly little hack. Note that this only works if the
  font atlas has no sprite starting at (0,0). Luckily, our bitmap font generator applies some
  padding, so the upper-left glyph starts at (2,2) in pixel coords. */
  if (vTexCoord.x < 0 || vTexCoord.y < 0) {
    outColor = texture(font, -1 * vTexCoord);
  } else {
    outColor = texture(sprites, vTexCoord);
  }
}