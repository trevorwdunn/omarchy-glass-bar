#version 440

// Liquid-glass lens over a known backdrop (the wallpaper). Port of the lens
// model from https://github.com/gentpan/liquidglass (references/optics.md):
// flat in the middle, bending in a curved band at the rim, a colour fringe,
// and a rim highlight that is brightest on the side facing the light.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
  mat4 qt_Matrix;
  float qt_Opacity;
  float refraction;     // maximum bend at the rim, px
  float bezel;          // curved-rim width as a share of the half short side
  float curvature;      // surface profile exponent
  float ior;            // index of refraction
  float chroma;         // blue bends (1 + chroma) times as far as red
  float specular;       // rim highlight strength
  float specularWidth;  // crisp rim line width, px
  float lightAngle;     // radians; 0 = from the right, -pi/2 = from the top
  float radius;         // lens corner radius, px
  float tint;           // how much of tintColor is mixed over the glass
  vec2 itemSize;        // size of this item, px
  vec4 lens;            // lens rectangle in item px: x, y, w, h
  vec4 uvMap;           // backdrop uv = uvMap.xy + p * uvMap.zw
  vec4 tintColor;
};

layout(binding = 1) uniform sampler2D source;

// Lateral offset of a vertical ray through the surface at depth s into the
// rim band (0 at the rim, 1 where the flat top starts), normalised to 0..1.
float bend(float s) {
  if (s >= 1.0) return 0.0;
  s = clamp(s, 0.002, 1.0);
  float k = curvature;
  float a = 1.0 - pow(1.0 - s, k);
  float slope = pow(a, 1.0 / k - 1.0) * pow(1.0 - s, k - 1.0);
  float theta = atan(slope);
  float refr = asin(clamp(sin(theta) / ior, -1.0, 1.0));
  return tan(theta - refr) / sqrt(ior * ior - 1.0);
}

void main() {
  vec2 p = qt_TexCoord0 * itemSize;
  vec2 half_ = lens.zw * 0.5;
  vec2 rel = p - (lens.xy + half_);
  float r = min(radius, min(half_.x, half_.y));
  vec2 q = abs(rel) - half_ + r;
  float d = min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;

  // Outward normal of the rounded rectangle.
  vec2 sgn = vec2(rel.x < 0.0 ? -1.0 : 1.0, rel.y < 0.0 ? -1.0 : 1.0);
  vec2 n;
  if (q.x > 0.0 && q.y > 0.0) n = normalize(q) * sgn;
  else if (q.x > q.y) n = vec2(sgn.x, 0.0);
  else n = vec2(0.0, sgn.y);

  float band = max(bezel * min(half_.x, half_.y), 0.001);
  float m = bend(-d / band);
  vec2 shift = -n * m * refraction;

  vec3 col;
  if (chroma > 0.001) {
    col.r = texture(source, uvMap.xy + (p + shift) * uvMap.zw).r;
    col.g = texture(source, uvMap.xy + (p + shift * (1.0 + chroma * 0.5)) * uvMap.zw).g;
    col.b = texture(source, uvMap.xy + (p + shift * (1.0 + chroma)) * uvMap.zw).b;
  } else {
    col = texture(source, uvMap.xy + (p + shift) * uvMap.zw).rgb;
  }

  col = mix(col, tintColor.rgb, tint);

  float e = -d;
  float crisp = clamp(1.0 - e / max(specularWidth, 0.001), 0.0, 1.0);
  float glow = clamp(1.0 - e / max(specularWidth * 5.0, 0.001), 0.0, 1.0);
  float f = dot(n, vec2(cos(lightAngle), sin(lightAngle)));
  float shade = 0.12 + 0.88 * (f > 0.0 ? f : 0.4 * -f);
  col += specular * (crisp * crisp + 0.3 * glow * glow) * shade;

  float coverage = clamp(0.5 - d, 0.0, 1.0);
  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0) * coverage * qt_Opacity;
}
