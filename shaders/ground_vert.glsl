#version 120

/* Note that for a variable to exist in the compiled shader, it must be used in the shader! */
attribute vec3 position;
attribute vec3 normal;
varying vec3 surfaceNormal;
varying vec3 worldCoords;


void main() {
  gl_Position = gl_ModelViewProjectionMatrix * vec4(position.x, position.y, position.z, 1.0);
  surfaceNormal = normal;
  worldCoords = position;
}