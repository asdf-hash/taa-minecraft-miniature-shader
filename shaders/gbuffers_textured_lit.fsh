#version 120

#define gbuffers_textured_lit

#include "/shader.h"

uniform int entityId;
uniform vec3 fogColor;
uniform vec3 cameraPosition;
uniform vec4 entityColor;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform mat4 gbufferProjectionInverse;
uniform sampler2D texture;
uniform sampler2D lightmap;
uniform sampler2D shadowtex1;

varying vec2 texUV;
varying vec2 lightUV;
varying vec3 worldPos;
varying vec3 lightColor;
varying vec4 color;
varying float fogMix;
varying float diffuse;
varying float torchLight;

#include "/common/math.glsl"
#include "/common/shadow.fsh"

void main() {
   vec4 albedo  = texture2D(texture, texUV) * color;
   vec4 ambient = texture2D(lightmap, vec2(AMBIENT_UV.s, lightUV.t));

   ambient.rgb *= INV_CONTRAST;

   ambient.rg *= (1.0 - SHADOW_BLUENESS);
   albedo.b   *= (1.0 - SHADOW_BLUENESS);

   ambient.rgb += TORCH_COLOR * max(0.0, torchLight - 0.5*length(ambient.rgb));
   ambient.rgb += CONTRAST * lightColor * getShadow();
   
   // render thunder
   albedo.a = entityId == 11000.0 ? 0.15 : albedo.a;

   // render entity color changes (e.g taking damage)
   albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);

   albedo *= ambient;
   
   albedo.rgb = mix(albedo.rgb, fogColor, fogMix);

   gl_FragData[0] = albedo;
}