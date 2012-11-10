#version 120

/* Note that for a variable to exist in the compiled shader, it must be used in the shader! */
varying vec3 vPosition;
uniform sampler2D normalMap;

void main() {
  gl_FragColor = vec4(0.5, 0.6, 1.0, 0.6);
}