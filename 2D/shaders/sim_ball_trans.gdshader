shader_type canvas_item;
render_mode blend_mix;

varying float alpha_adj;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void vertex() {
    alpha_adj = INSTANCE_CUSTOM.x;
}

void fragment() {
	
	COLOR.rg = 2.0 - textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rg;
	COLOR.b = texture(TEXTURE , UV).b;
	COLOR.a = texture(TEXTURE , UV).a;
	
	

}
