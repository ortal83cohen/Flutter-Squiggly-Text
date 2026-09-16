#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uSeed;
uniform float uScale;
uniform float uBaseFrequency;
uniform float uOctaves;
uniform vec2 uPointer;
uniform float uPointerRadius;
uniform float uPointerLift;
uniform sampler2D uText;
out vec4 fragColor;

float hashValue(vec2 point, float seed) {
  return fract(sin(dot(point + seed, vec2(127.1, 311.7))) * 43758.5453123);
}

float valueNoise(vec2 point, float seed) {
  vec2 cell = floor(point);
  vec2 local = fract(point);
  local = local * local * (3.0 - 2.0 * local);
  float lowerLeft = hashValue(cell, seed);
  float lowerRight = hashValue(cell + vec2(1.0, 0.0), seed);
  float upperLeft = hashValue(cell + vec2(0.0, 1.0), seed);
  float upperRight = hashValue(cell + vec2(1.0, 1.0), seed);
  return mix(
    mix(lowerLeft, lowerRight, local.x),
    mix(upperLeft, upperRight, local.x),
    local.y
  );
}

float turbulence(vec2 point, float seed) {
  float sum = 0.0;
  float amplitude = 0.5;
  float frequency = 1.0;
  for (int octave = 0; octave < 3; octave++) {
    sum += abs(valueNoise(point * frequency, seed + float(octave)) * 2.0 - 1.0) * amplitude;
    frequency *= 2.0;
    amplitude *= 0.5;
  }
  return clamp(sum, 0.0, 1.0);
}

void main() {
  vec2 fragment = FlutterFragCoord().xy;
  vec2 uv = fragment / uSize;
  if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
    fragColor = vec4(0.0);
    return;
  }

  if (uScale == 0.0) {
    fragColor = texture(uText, uv);
    return;
  }

  vec2 noisePoint = fragment * uBaseFrequency;
  vec2 noiseRG = vec2(
    turbulence(noisePoint, uSeed),
    turbulence(noisePoint + vec2(19.7, 47.3), uSeed + 13.0)
  );
  vec2 offset = uScale * (noiseRG - 0.5) * 2.0;

  if (uPointerLift != 0.0 && uPointerRadius > 0.0) {
    float distanceToPointer = distance(fragment, uPointer);
    float influence = 1.0 - smoothstep(0.0, uPointerRadius, distanceToPointer);
    if (uPointerLift > 0.0) {
      offset.y -= uPointerLift * influence * uScale;
    } else {
      vec2 towardPointer = normalize(uPointer - fragment);
      offset += towardPointer * (-uPointerLift) * influence * uScale;
    }
  }

  vec2 sampleUv = uv + offset / uSize;
  if (sampleUv.x < 0.0 || sampleUv.x > 1.0 || sampleUv.y < 0.0 || sampleUv.y > 1.0) {
    fragColor = vec4(0.0);
    return;
  }
  fragColor = texture(uText, sampleUv);
}
