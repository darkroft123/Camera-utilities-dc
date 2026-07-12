#pragma header

uniform float strength; // 0 = normal, 1 = invertido total

void main()
{
    vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv.xy);

    vec3 inverted = 1.0 - color.rgb;

    // Mezcla entre normal e invertido
    color.rgb = mix(color.rgb, inverted, strength);

    gl_FragColor = color;
}
