shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D tex_frg_2;
varying vec2 svec;

void vertex() {
    // Capturing the trail vector from instance data
    svec = INSTANCE_CUSTOM.xy;
}

// Helper function to sample the texture with an offset and scale
vec4 get_trail_sample(sampler2D tex, vec2 uv, vec2 offset, float scale) {
	
	vec2 shifted_uv = (uv - 0.5 - offset) * scale + 0.5;
	
	// Check if we are outside the [0,1] range to prevent texture wrapping/bleeding
	if (shifted_uv.x < 0.0 || shifted_uv.x > 1.0 || shifted_uv.y < 0.0 || shifted_uv.y > 1.0) {
	    return vec4(0.0);
	}

	return texture(tex, shifted_uv);
	}

	void fragment() {
	
	vec4 t0 = get_trail_sample(tex_frg_2, UV, svec * 0.15, 4.0);
	
	vec4 t1 = get_trail_sample(tex_frg_2, UV, svec * 0.35, 5.0);
	
	vec4 t2 = get_trail_sample(tex_frg_2, UV, svec * 0.65, 6.0);
	
	
	vec4 final_color = t0+t1+t2;
	
	COLOR = final_color;
}