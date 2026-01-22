shader_type canvas_item;

uniform float radius : hint_range(-0.5, 1.5) = 0.3;
uniform vec2 center = vec2(0.5, 0.5);
uniform float softness : hint_range(0.001, 0.2) = 0.03;

void fragment() {
	// Convert UV to centered space
	vec2 uv = UV - center;

	// Aspect ratio correction (Godot 4)
	float aspect = (0.70 / SCREEN_PIXEL_SIZE.x) / (1.0 / SCREEN_PIXEL_SIZE.y);
	uv.x *= aspect;

	// Circular distance
	float dist = length(uv);

	// Smooth edge hole
	float mask = smoothstep(radius, radius + softness, dist);

	// Black overlay
	COLOR.rgb = vec3(0.0);

	// Transparent center, black outside
	COLOR.a = mask;
}
