shader_type canvas_item;

varying vec2 roll_pos;
varying float sphere_radius_px;
varying float rotation; 

void vertex() {
    roll_pos = INSTANCE_CUSTOM.xy;
    sphere_radius_px = INSTANCE_CUSTOM.z; 
    rotation = INSTANCE_CUSTOM.a;
}

void fragment() {
	float uv_radius = (sphere_radius_px * 2.0) / 256.0;
	
	vec2 center = UV - 0.5;
	float center_dist = length(center);
	
	// Discard pixels outside the radius
	if (center_dist > uv_radius) {
		discard; 
	}
	
	float center_dist_norm = center_dist * (0.5 / uv_radius);
	vec2 center_norm = center * (0.5 / uv_radius);
	
	float bulge_factor = 1.2; 
	float adjusted_center_dist = pow(center_dist_norm * 2.0, bulge_factor) * 0.5;
	float z = sqrt(0.25 - adjusted_center_dist * adjusted_center_dist);
	
	
	vec2 sphere_uv = center_norm / (z + 0.35); 
	
	float cos_r = cos(rotation);
	float sin_r = sin(rotation);
	mat2 rot = mat2(vec2(cos_r, -sin_r), vec2(sin_r, cos_r));
	
	vec2 rotated_uv = (rot * sphere_uv);
	vec2 spinning_uv = rotated_uv + roll_pos;
	
	vec4 tex_color = texture(TEXTURE, fract(spinning_uv));
	
	// shading
	float edge_shading = clamp(z * 2.0, 0.0, 1.0);
	edge_shading = pow(edge_shading, 1.5);
	
	COLOR = vec4(tex_color.rgb * edge_shading, tex_color.a);
}