shader_type canvas_item;
render_mode blend_mix;

varying float alpha_adj;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void vertex() {
    alpha_adj = INSTANCE_CUSTOM.x;
}

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    vec3 screen_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgb;
    
    vec2 max_contrast_rg = step(0.5, 1.0 - screen_color.rg);
    
    COLOR.rg = max_contrast_rg;
    COLOR.b = tex_color.b;
    
    COLOR.a = tex_color.a * alpha_adj;
}