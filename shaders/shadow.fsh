#version 120

uniform sampler2D texture;

varying vec2 texUV;
varying vec4 color;

void main() {
    vec4 albedo = texture2D(texture, texUV) * color;

    if (albedo.a <= 0.01) discard;

    gl_FragData[0] = albedo;
}