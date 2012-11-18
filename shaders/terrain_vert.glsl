#version 150

/* Note that for a variable to exist in the compiled shader, it must be used in the shader! */
in vec3 position;
in vec3 normal;
out vec3 vNormal;
out vec3 vPosition;

void main() {
  gl_Position = vec4(position.x, position.y, position.z, 1.0);
  
  vPosition = position;
  vNormal = normal;
}