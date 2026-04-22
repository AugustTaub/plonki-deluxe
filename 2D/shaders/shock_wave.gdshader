shader_type canvas_item;
render_mode blend_mix;

varying float radius_px;

void vertex() {
    radius_px = INSTANCE_CUSTOM.x;
}

vec4 get_trail_sample(sampler2D tex, vec2 uv, vec2 offset, float scale_multiplier) {
    
    float actual_scale = (1000.0 / radius_px * 0.5) * scale_multiplier;
    
    vec2 shifted_uv = (uv - 0.5 - offset) * actual_scale + 0.5;
    
    if (shifted_uv.x < 0.0 || shifted_uv.x > 1.0 || shifted_uv.y < 0.0 || shifted_uv.y > 1.0) {
        return vec4(0.0);
    }
    
    return texture(tex, shifted_uv);
}

void fragment() {
    vec4 input_tint = COLOR;
    
    vec4 t0 = get_trail_sample(TEXTURE, UV, vec2(0,0), 1.0);

    vec4 final_sample = t0;
    
    COLOR = final_sample * input_tint;
}