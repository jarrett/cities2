#version 120

/* Note that for a variable to exist in the compiled shader, it must be used in the shader! */
varying vec3 vPosition;
varying vec3 vNormal;

void main() {
  vPosition;
  vNormal;
  gl_FragColor = vec4(1.0, 0.2, 0.2, 1.0);
}