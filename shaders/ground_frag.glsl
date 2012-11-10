#version 120

/* Note that for a variable to exist in the compiled shader, it must be used in the shader! */
varying vec3 vPosition;
varying vec3 vNormal;
uniform sampler2D dirt;

void main() {
  float texScale = (1.0 / 20.0);
  vec3 lightMult = clamp(
    (
      vec3(1.0, 0.95, 0.9) * 0.8 * // sunlight color
      dot(
        vNormal,
        normalize(vec3(0.2, 0.2, 1.0)) // sunlight direction
      )
    ) + (vec3(0.7, 0.8, 1.0) * 0.1), // ambient light color
    vec3(0.0, 0.0, 0.0), // clamp min
    vec3(1.0, 1.0, 1.0)  // clamp max
  );
  vec4 texCol = texture2D(dirt, vec2(vPosition.x * texScale, vPosition.y * texScale));
  gl_FragColor = vec4(
    lightMult.x * texCol.r,
    lightMult.y * texCol.g,
    lightMult.z * texCol.b,
    1.0
  );
  /* gl_FragColor = vec4(texCol.r, texCol.g, texCol.b, 1.0); */
}