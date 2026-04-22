shader_type canvas_item;
render_mode blend_mix;

varying vec2 svec;
varying float radius_px;

void vertex() {
    svec = INSTANCE_CUSTOM.xy;
    radius_px = INSTANCE_CUSTOM.z;
}

vec4 get_trail_sample(sampler2D tex, vec2 uv, vec2 offset, float scale_multiplier) {
    
    float actual_scale = (256.0 / radius_px * 0.5) * scale_multiplier;
    
    vec2 shifted_uv = (uv - 0.5 - offset) * actual_scale + 0.5;
    
    if (shifted_uv.x < 0.0 || shifted_uv.x > 1.0 || shifted_uv.y < 0.0 || shifted_uv.y > 1.0) {
        return vec4(0.0);
    }
    
    return texture(tex, shifted_uv);
}

void fragment() {
    // 1. Capture the initial color (Modulate/Self-Modulate)
    vec4 input_tint = COLOR;
    
    // 2. Run your existing sampling logic
    vec4 t0 = get_trail_sample(TEXTURE, UV, svec * 0.15, 1.0);
    vec4 t1 = get_trail_sample(TEXTURE, UV, svec * 0.35, 1.2);
    vec4 t2 = get_trail_sample(TEXTURE, UV, svec * 0.65, 1.4);
    
    vec4 final_sample = t0 + t1 + t2;
    
    // 3. Apply the captured color to the result
    // This tints the RGB and scales the Alpha based on the Node's settings
    COLOR = final_sample * input_tint;
}