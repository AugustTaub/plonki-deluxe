shader_type canvas_item;

varying vec2 roll_pos;
varying float scale;

void vertex() {
    roll_pos = INSTANCE_CUSTOM.xy;
    scale = INSTANCE_CUSTOM.z;
}

void fragment() {
	vec2 p = (UV - 0.5) * scale;
	float r = length(p);
	
	if (r > 0.5) {
	    discard; 
	}
	
	float bulge_factor = 1.2; 
	float adjusted_r = pow(r * 2.0, bulge_factor) * 0.5;
	float z = sqrt(0.25 - adjusted_r * adjusted_r);
	
	vec2 sphere_uv = p / (z + 0.35); 
	
	
	vec2 spinning_uv = sphere_uv + roll_pos;
	
	vec4 tex_color = texture(TEXTURE, fract(spinning_uv));
	
	float edge_shading = clamp(z * 2.0, 0.0, 1.0);
	edge_shading = pow(edge_shading, 1.5);
	
	vec4 old_colold_col = COLOR;
	
	COLOR = vec4(tex_color.rgb * edge_shading, tex_color.a);
	//COLOR.rgb *= old_col.rgb;
	//COLOR.rgb *= COLOR.rgb * 1.2;
}