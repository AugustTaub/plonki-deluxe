shader_type canvas_item;

varying float v_progress;

void vertex() {
	v_progress = INSTANCE_CUSTOM.x;
}

void fragment() {
	
	vec4 tex_color = texture(TEXTURE, UV);
	
	vec2 centered_uv = UV - 0.5;
	float dist = length(centered_uv);
	float circle_mask = smoothstep(0.5, 0.48, dist);
	
	
	vec3 final_rgb = tex_color.rgb; 
	
	float v_fade = 1.0 - v_progress;
	
	COLOR = vec4(final_rgb, tex_color.a * circle_mask * v_fade);
}