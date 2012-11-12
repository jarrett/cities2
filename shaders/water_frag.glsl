#version 120

/* Note that for a variable to exist in the compiled shader, it must be used in the shader! */
varying vec3 vPosition;
//uniform sampler2D normalMap;
uniform sampler2D waterHeightMap;
uniform sampler2D groundHeightMap;
uniform sampler2D foam;
//uniform vec3 camDir; // Must be normalized!

void main() {
  vec3 sunDir = normalize(vec3(-0.3, -0.3, 1.0));
  
  // Water depth. groundHeight and waterHeight are floats in the range [0, 1]. The funky scaling
  // is dependent on our (currently hardcoded) Z scale factors for the height fields. This will have
  // to change later.
  float groundHeight = texture2D(groundHeightMap, vec2((vPosition.x + 0.5) * 0.01, (vPosition.y + 0.5) * 0.01)).r * 0.07; // Why do we have to add 0.5 to each coordinate to make them match up?
  float waterHeight = texture2D(waterHeightMap, vec2(vPosition.x * 0.01, vPosition.y * 0.01)).r * 0.03;
  float depth = (waterHeight - groundHeight) / 0.03;
  
  // Water color
  float foamTexScale = 0.1; // Inverse. Smaller numbers make the map look bigger.
  vec3 waterCol = mix(
    vec3(texture2D(foam, vec2(vPosition.x * foamTexScale, vPosition.y * foamTexScale))), // Foam
    vec3(0.23, 0.27, 0.28) * (1 - clamp(0.0, 0.7, depth * 1.5)), // Base water color
    clamp(depth * 10, 0.2, 0.9) // Mix factor for foam. Higher mix factor means less foam.
  );
  
  // Turn this on to see how different depth functions map onto the surface
  //waterCol = mix(vec3(1, 1, 1), vec3(0, 0, 0), depth);
  //waterCol = mix(vec3(1, 1, 1), vec3(0, 0, 0), depth * 2);
  //waterCol = mix(vec3(1, 1, 1), vec3(0, 0, 0), depth * 20);
  
  
  // Normal map
  /*float normalMapScale = 0.05; // Inverse. Smaller numbers make the map look bigger.
  vec3 normal = normalize(vec3(texture2D(normalMap, vec2(vPosition.x * normalMapScale, vPosition.y * normalMapScale))));*/
  vec3 normal = vec3(0, 0, 1);
  
  // Ambient
  vec3 amb = waterCol * 0.2;
  
  // Diffuse
  float diffMult = dot(normal, sunDir);
  vec3 diff = waterCol * diffMult;
  
  // Specular
  /*vec3 halfway = normalize(sunDir + camDir); // Halfway vector between light and viewing directions
  
  float specPhong = pow(
    clamp(
      dot(halfway, normal),
      0, 1
    ),
    8 // Higher exponents make the surface less reflective.
  );
   
  vec3 spec = vec3(1, 1, 1) * specPhong;*/
  
  float opacity = clamp(depth * 20, 0, 0.9); // Opacity for most of the water's surface
  gl_FragColor = vec4(
    clamp(
      amb + diff,
      vec3(0, 0, 0), vec3(1, 1, 1)
    ),
    opacity
  );
}