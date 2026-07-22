shader_type canvas_item;

varying vec2 roll_pos;
varying float rotation; 

void vertex() {
	// INSTANCE_CUSTOM.z contains the radius in pixels.
	float sphere_radius_px = INSTANCE_CUSTOM.z;
	
	// Scales the 1x1 QuadMesh to diameter in pixels (radius * 2)
	VERTEX *= sphere_radius_px * 2.0;
}

void fragment() {
	// Sample the texture bound to the MultiMeshInstance2D
	vec4 tex_color = texture(TEXTURE, UV);
	
	// Center is (0, 0) relative to UV space [-0.5, 0.5]
	vec2 center = UV - vec2(0.5);
	float center_dist = length(center);
	
	// Discard pixels outside the unit circle (radius of 0.5 in UV space)
	if (center_dist > 0.5) {
		discard;
	}
	
	COLOR = vec4(tex_color.rgb , tex_color.a);
}