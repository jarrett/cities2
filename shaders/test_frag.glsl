#version 120

/* Note that for a variable to exist in the compiled shader, it must be used in the shader! */
varying vec3 vPosition;
varying vec3 vNormal;

void main() {
  vec3 litColor =
    vec3(1.0, 1.0, 1.0) *
    dot(
      normalize(vNormal),
      normalize(vec3(0.2, 0.2, 1.0))
    );
  gl_FragColor = vec4(
    litColor.x, litColor.y, litColor.z, 1.0
  );
  /*gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);*/
}