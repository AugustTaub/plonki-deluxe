shader_type canvas_item;
render_mode blend_mix;

varying float alpha_adj;

void vertex() {
    alpha_adj = INSTANCE_CUSTOM.x;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float tex_alpha = tex.a;


	COLOR.rgb = vec3(tex.xyz);
	COLOR.a = tex_alpha * alpha_adj;


}
