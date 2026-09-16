#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uSeed;
uniform float uScale;
uniform float uBaseFrequency;
uniform float uOctaves;
uniform vec2 uPointer;
uniform float uPointerRadius;
uniform float uPointerLift;
uniform float uHoverMode;
uniform float uHoverScope;
uniform float uPointerActive;
uniform float uScopeLeft;
uniform float uScopeTop;
uniform float uScopeRight;
uniform float uScopeBottom;
uniform float uInteractionScale;
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

  if (uScale == 0.0 && uHoverMode == 0.0 && uPointerLift == 0.0) {
    fragColor = texture(uText, uv);
    return;
  }

  float distanceToPointer = distance(fragment, uPointer);
  float influence = 1.0 - smoothstep(0.0, uPointerRadius, distanceToPointer);
  float scopeInfluence = 1.0;
  if (uHoverScope == 0.0) {
    influence = 1.0;
  } else if (uHoverScope == 1.0) {
    float horizontal = smoothstep(uScopeLeft - 4.0, uScopeLeft, fragment.x) *
        (1.0 - smoothstep(uScopeRight, uScopeRight + 4.0, fragment.x));
    float vertical = smoothstep(uScopeTop - 4.0, uScopeTop, fragment.y) *
        (1.0 - smoothstep(uScopeBottom, uScopeBottom + 4.0, fragment.y));
    scopeInfluence = horizontal * vertical;
  } else if (uHoverScope == 2.0) {
    float horizontal = smoothstep(uScopeLeft - 3.0, uScopeLeft, fragment.x) *
        (1.0 - smoothstep(uScopeRight, uScopeRight + 3.0, fragment.x));
    float vertical = smoothstep(uScopeTop - 3.0, uScopeTop, fragment.y) *
        (1.0 - smoothstep(uScopeBottom, uScopeBottom + 3.0, fragment.y));
    scopeInfluence = horizontal * vertical;
  }
  if (uPointerActive == 0.0) {
    influence = 0.0;
    scopeInfluence = 0.0;
  }
  influence *= scopeInfluence;
  vec2 effectCenter = uPointer;
  if (uHoverScope == 0.0) {
    effectCenter = uSize * 0.5;
  } else {
    effectCenter = vec2(
      (uScopeLeft + uScopeRight) * 0.5,
      (uScopeTop + uScopeBottom) * 0.5
    );
  }
  if (uHoverMode == 1.0) {
    float scaleAmount = 0.12 * influence;
    vec2 fromPointer = fragment - effectCenter;
    vec2 scaled = effectCenter + fromPointer / (1.0 + scaleAmount);
    fragment = scaled;
    uv = fragment / uSize;
  } else if (uHoverMode == 2.0 || uHoverMode == 3.0) {
    float scaleAmount = (uHoverMode == 2.0 ? -0.32 : 0.5) * influence;
    vec2 fromPointer = fragment - effectCenter;
    vec2 scaled = effectCenter + fromPointer / (1.0 + scaleAmount);
    fragment = scaled;
    uv = fragment / uSize;
  } else if (uHoverMode == 4.0 || uHoverMode == 5.0) {
    float localInfluence = uHoverScope == 0.0
        ? 1.0
        : scopeInfluence;
    localInfluence *= uPointerActive;
    vec2 tremble = vec2(
      sin(uSeed * 19.0 + fragment.y * 0.12),
      cos(uSeed * 23.0 + fragment.x * 0.12)
    ) * 2.4 * localInfluence;
    fragment -= tremble;
    uv = fragment / uSize;
  }

  vec2 noisePoint = fragment * uBaseFrequency;
  vec2 noiseRG = vec2(
    turbulence(noisePoint, uSeed),
    turbulence(noisePoint + vec2(19.7, 47.3), uSeed + 13.0)
  );
  vec2 offset = uScale * (noiseRG - 0.5) * 2.0;
  if (uHoverScope != 0.0 && uPointerActive > 0.0) {
    offset *= scopeInfluence;
  }

  if (uPointerLift != 0.0 && uPointerRadius > 0.0) {
    if (uPointerLift > 0.0) {
      // Sampling below the output pixel moves the rendered glyph upward.
      offset.y += uPointerLift * influence * uInteractionScale;
    } else {
      vec2 towardPointer = (uPointer - fragment) / max(distance(uPointer, fragment), 0.001);
      offset -= towardPointer * (-uPointerLift) * influence * uInteractionScale;
    }
  }
  if (uHoverMode == 6.0 && uPointerRadius > 0.0) {
    vec2 awayFromPointer = fragment - uPointer;
    float lengthAway = max(length(awayFromPointer), 0.001);
    offset -= awayFromPointer / lengthAway * influence * 7.0;
  }

  vec2 sampleUv = clamp(uv + offset / uSize, vec2(0.001), vec2(0.999));
  fragColor = texture(uText, sampleUv);
}
