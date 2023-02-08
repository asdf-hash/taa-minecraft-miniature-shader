#version 120

#define gbuffers_water
#include "shader.h"

attribute vec4 mc_Entity;

uniform int isEyeInWater;
uniform int worldTime;
uniform vec3 cameraPosition;
uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelViewInverse;
uniform float frameTimeCounter;
uniform float fogStart;
uniform float fogEnd;
uniform float rainStrength;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 color;
varying vec4 normal;

varying vec3 torchColor;
varying float torchLight;

varying float diffuse;
varying float fogMix;
varying float reflectiveness;
varying float texstrength;

float noise(vec2 pos) {
	return fract(sin(dot(pos, vec2(18.9898, 28.633))) * 4378.5453);
}

vec3 getWorldPosition() {
   return mat3(gbufferModelViewInverse)
        * (gl_ModelViewMatrix * gl_Vertex).xyz
        + gbufferModelViewInverse[3].xyz;
}

float calculateFog(float fogDepth) {
   float x = worldTime * NORMALIZE_TIME;

   x = clamp(25.0*(x < MIDNIGHT ? SUNSET - x : x - SUNRISE) + 0.3,
             OVERWORLD_FOG_MIN,
             OVERWORLD_FOG_MAX);

   x = min(x, 1.0 - rainStrength);
   x = isEyeInWater == 0 ? x : 1.0;

   return clamp((fogDepth - x*fogStart) / (fogEnd - x*fogStart), 0.0, 1.0);
}

void main() {
   gl_Position = ftransform();

   color    = gl_Color;
   lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).st;
   texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;

   reflectiveness = mc_Entity.x == 10008.0 ? 1.0 : 0.5;
   torchLight = pow(lmcoord.s, CONTRAST + 1.5);
   torchColor = (0.5 + CONTRAST) * torchLight * TORCH_COLOR;
   normal.xyz = gl_Normal;

   vec3 worldPos  = getWorldPosition();
   vec2 waterPos  = floor(worldPos.xz) + floor(cameraPosition.xz);
   float posNoise = noise(waterPos);

   #if WATER_WAVE_SIZE > 0
      if (mc_Entity.x == 10008.0) {
         normal.xyz += vec3(
            0.01*WATER_WAVE_SIZE*sin(posNoise * frameTimeCounter),
            0.0,
            0.01*WATER_WAVE_SIZE*cos(posNoise * frameTimeCounter)
         );
      }
   #endif

   #ifdef WATER_SHOW_SOME_TEXTURE
      texstrength = 2.0*max(posNoise - 0.5, 0.2);
   #else
      texstrength = 0.0;
   #endif

   // scale normal to 0..1
   normal = vec4(0.5 + 0.5*normal.xyz, 1.0);

   // if the water is pointing directly up there's just some texture
   texstrength = gl_Normal.x == 0.0 && gl_Normal.z == 0.0 ? texstrength : 1.0;

   #if MC_VERSION >= 11300 && defined(ENABLE_FOG)
   fogMix = calculateFog(length(worldPos));
   #else
   fogMix = 0.0;
   texstrength = 0.0;
   #endif

   diffuse = 0.5 + 0.5
         //  reduce with reflectiveness
           * (1.0 - reflectiveness)
         //  reduce with fog
           * (1.0 - fogMix)
         //  reduce with rain strength
           * (1.0 - rainStrength)
         //  reduce with sky light
           * 2.0*max(min(1.6*lmcoord.t, 1.0) - 0.5, 0.0)
         //  thin objects have constant diffuse
           * clamp(2.5*dot(normalize(gl_NormalMatrix * gl_Normal),
                           normalize(shadowLightPosition)), MAX_SHADOW_SUBTRACT, 1.0);
}