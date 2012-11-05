#version 120

/* Note that for a variable to exist in the compiled shader, it must be used in the shader! */
varying vec3 vPosition;
varying vec3 vNormal;

void main() {
  vec3 litColor = clamp(
    (
      vec3(1.0, 0.95, 0.9) * 0.8 * // sunlight color
      dot(
        vNormal,
        normalize(vec3(0.2, 0.2, 1.0)) // sunlight direction
      )
    ) + (vec3(0.7, 0.8, 1.0) * 0.2), // ambient light color
    vec3(0.0, 0.0, 0.0), // clamp min
    vec3(1.0, 1.0, 1.0)  // clamp max
  );
  gl_FragColor = vec4(
    litColor.x, litColor.y, litColor.z, 1.0
  );
}