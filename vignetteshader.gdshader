shader_type canvas_item;

uniform float inner_radius : hint_range(0.0, 5.0) = 0.3;   // size of the hole
uniform float outer_radius : hint_range(0.0, 5.0) = 0.75;  // where vignette starts
uniform float softness     : hint_range(0.0, 5.0) = 0.45;  // fade strength
uniform vec3 vignette_color : source_color = vec3(0.0, 0.0, 0.0);

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 centered = uv - vec2(0.5);
    float dist = length(centered) * 2.0;

    float hole     = smoothstep(inner_radius, inner_radius + softness, dist);
    float vignette = smoothstep(outer_radius, outer_radius - softness, dist);

    float alpha = vignette * hole;
    COLOR = vec4(vignette_color, alpha);
}