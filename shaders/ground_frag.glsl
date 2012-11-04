#version 120

/* Note that for a variable to exist in the compiled shader, it must be used in the shader! */
varying vec3 worldCoords;
varying vec3 surfaceNormal;
uniform sampler2D ground;
uniform sampler2D cliff;
uniform vec2 mouseCoords;

void main() {
  vec4 textureColor;
  float verticality = dot(vec3(0.0, 0.0, 1.0), surfaceNormal);
  float groundTexScaleDiv = 20.0;
  float cliffTexScaleDiv = 5.0;
  vec2 normal2D = vec2(surfaceNormal.x, surfaceNormal.y);
  textureColor = mix(
    // smoothstep between two planar mappings for the cliff texture
    mix(
      texture2D(cliff, vec2(worldCoords.x / cliffTexScaleDiv, worldCoords.z / cliffTexScaleDiv)),
      texture2D(cliff, vec2(worldCoords.y / cliffTexScaleDiv, worldCoords.z / cliffTexScaleDiv)),
      smoothstep(
        -0.1,
        0.1,
        abs(dot(vec2(1.0, 0.0), normal2D)) - abs(dot(vec2(0.0, 1.0), normal2D))
      )
    ),
    texture2D(ground, vec2(worldCoords.x / groundTexScaleDiv, worldCoords.y / groundTexScaleDiv)),
    smoothstep(0.8, 0.95, verticality)
  );
  //textureColor = vec4(1.0, 1.0, 1.0, 1.0);
  float distanceFromMouse = distance(vec2(worldCoords.x, worldCoords.y), mouseCoords);
  gl_FragColor = mix(
    dot(surfaceNormal, normalize(vec3(0.3, 0.0, 1.0))) * textureColor,
    vec4(0.2, 0.25, 1.0, 1.0),
    (
      (1 - smoothstep(4.5, 4.7, distanceFromMouse)) *
      smoothstep(4, 4.2, distanceFromMouse)
    )
  );
  //gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
}