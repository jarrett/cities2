#version 150

/* Note that for a variable to exist in the compiled shader, it must be used in the shader! */
in vec3 vPosition;
in vec3 vNormal;
uniform bool picking;
uniform vec2 worldSize;
uniform vec2 mouseCoords;
uniform sampler2D grass;
uniform sampler2D rockyGrass;
uniform sampler2D cliff;
uniform sampler2D sand;
uniform sampler2D waterHeightMap;
out vec4 outColor;

vec3 planarMap(sampler2D tex, float scale, vec3 position, vec3 normal) {
  if (normal.z > 0.85) {
    return vec3(texture(tex, vec2(vPosition.x * scale, vPosition.y * scale)));
    //return vec3(0,0,0); // blue z
  } else if (normal.y > 0.75) {
    return vec3(texture(tex, vec2(vPosition.x * scale, vPosition.z * scale)));
    //return vec3(0,1,0); // green y
  } else if (normal.x > 0.75) {
    return vec3(texture(tex, vec2(vPosition.y * scale, vPosition.z * scale)));
    //return vec3(1,0,0); // red x
  } else {
    // Not exactly evenly weighted amongst the three samples, but at least it favors Z (which is special) and not X or Y.
    vec3 xCol = vec3(texture(tex, vec2(vPosition.y * scale, vPosition.z * scale)));
    vec3 yCol = vec3(texture(tex, vec2(vPosition.x * scale, vPosition.z * scale)));
    vec3 zCol = vec3(texture(tex, vec2(vPosition.x * scale, vPosition.y * scale)));
    
    //xCol = vec3(1,0,0);
    //yCol = vec3(0,1,0);
    //zCol = vec3(0,0,1);
    
    return mix(
      mix(
        xCol, yCol,
        smoothstep(-0.05, 0.05, abs(normal.y) - abs(normal.x))
      ),
      zCol,
      smoothstep(0.8, 0.85, normal.z)
    );
  }
}

void main() {
  if (picking) {
    outColor = vec4(vPosition.x / worldSize.x, vPosition.y / worldSize.y, 0, 1);
  } else {
    vec3 sunDir = normalize(vec3(-0.3, -0.3, 1.0));
    
    float heightAboveWater = vPosition.z - (texture(waterHeightMap, vec2(vPosition.x * 0.01, vPosition.y * 0.01)).r * 256 * 0.03);
    
    float levelness = vNormal.z;
    
    float texScale = 0.1; // Smaller numbers make the texture appear larger
    
    vec3 lightMult = clamp(
      (
        vec3(1.0, 0.95, 0.9) * 0.8 * // sunlight color
        dot(vNormal, sunDir)
      ) + (vec3(0.7, 0.8, 1.0) * 0.1), // ambient light color
      vec3(0.0, 0.0, 0.0), // clamp min
      vec3(1.0, 1.0, 1.0)  // clamp max
    );
      
    /*vec3 cliffCol =      vec3(texture(cliff,      vec2(vPosition.x * texScale, vPosition.y * texScale)));
    vec3 rockyGrassCol = vec3(texture(rockyGrass, vec2(vPosition.x * texScale, vPosition.y * texScale)));
    vec3 grassCol =      vec3(texture(grass,      vec2(vPosition.x * texScale, vPosition.y * texScale)));
    vec3 sandCol =       vec3(texture(sand,       vec2(vPosition.x * texScale, vPosition.y * texScale)));*/
    vec3 cliffCol =      planarMap(cliff,      texScale, vPosition, vNormal);
    vec3 grassCol =      planarMap(grass,      texScale, vPosition, vNormal);
    vec3 rockyGrassCol = planarMap(rockyGrass, texScale, vPosition, vNormal);
    vec3 sandCol =       planarMap(sand,       texScale, vPosition, vNormal);
    
    vec3 texCol = mix(
      cliffCol,
      mix(
        rockyGrassCol,
        mix(
          sandCol,
          grassCol,
          smoothstep(0.0, 0.75, heightAboveWater) // Increase these values to create more sand
        ),
        smoothstep(0.65, 0.88, levelness) // Decrease these values to create more rocky grass
      ),
      smoothstep(0.6, 0.75, levelness) // Decrease these values to create more cliffs
    );
    
    float distanceFromMouse = distance(vec2(vPosition), mouseCoords);
    
    int hasCursor = (heightAboveWater >= 0) ? 1 : 0;
    
    outColor = mix(
      vec4(lightMult * texCol, 1.0),
      vec4(0.2, 0.25, 1.0, 1.0),
      (
        (1 - smoothstep(4.5, 4.7, distanceFromMouse)) *
        smoothstep(4, 4.2, distanceFromMouse) *
        hasCursor
      )
    );
    
    // Turn this on to see how heightAboveWater maps onto the terrain
    //outColor = vec4((heightAboveWater * 0.125) * vec3(1, 1, 1), 1);
  }
}