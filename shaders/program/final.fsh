#define final

#include "/shader.h"

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform sampler2D colortex0;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D depthtex0;
varying vec2 texUV;

#include "/common/math.glsl"
#include "/common/transformations.fsh"

bool isReflective(vec2 uv) {
   return texture2D(colortex7, uv).r > 0.99;
}

void main() {
   vec4 color = texture2D(colortex0, texUV);
   vec4 info  = texture2D(colortex7, texUV);

   if (info.x > 0.99) {
      // the normal doesn't come premultiplied by the normal matrix to
      // avoid the modelview transformations when view bobbing is on
      // which causes severe artifacts when moving
      vec3 prenormal = texture2D(colortex6, texUV).xyz*2.0 - 1.0;

      if (info.y > 0.99 && prenormal.y > 0.99) {
         prenormal.xz *= 0.01 * WATER_WAVE_SIZE;
      }

      float depth          = texture2D(depthtex0, texUV).x;
      vec3 normal          = world2screen(prenormal);
      vec3 fragPos         = uv2screen(texUV, depth);
      vec4 reflectionColor = vec4(0.0);
      #include "/common/getReflectionColor.fsh"

      float fresnel = 1.0 - dot(normal, -normalize(fragPos));

      color.rgb = mix(
         color.rgb,
         reflectionColor.rgb,
         reflectionColor.a * fresnel * 0.1*REFLECTIONS * (1.0 - color.rgb)
      );
   }

   gl_FragData[0] = color;
}