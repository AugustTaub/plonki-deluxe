shader_type canvas_item;

uniform sampler2D atlas_texture : hint_default_white, filter_nearest;

varying float number;
varying float custom_alpha;

void vertex() {
	number = INSTANCE_CUSTOM.x;
	custom_alpha = INSTANCE_CUSTOM.y;
}

void fragment() {
	
	int val = int(clamp(number, 0.0, 99999.0));
	
	// find how many digits there are
	int num_digits = 1;
	
	if (val >= 10000) {
		num_digits = 5;
	}
	if (val >= 1000) {
		num_digits = 4;
	}
	else if (val >= 100) {
		num_digits = 3;
	} else if (val >= 10) {
		num_digits = 2;
	} else {
		num_digits = 1;
	}
	
	
	int total_active_cols = num_digits + 2;
	
	// cut off the part of the uv that exceeds the used columns
	float max_width_fraction = float(total_active_cols) / 5.0;
	if (UV.x > max_width_fraction) {
		discard;
	}
	

	float col_coord = UV.x * 5.0;
	int col_index = int(floor(col_coord));
	
	vec2 local_uv = vec2(fract(col_coord), UV.y);
	
	int hundreds = (val / 100) % 10;
	int tens = (val / 10) % 10;
	int ones = val % 10;
	
	int char_index = 0;
	
	// + symbol
	if (col_index == 0) {
		char_index = 11; 
	} 
	// coin symbol
	else if (col_index == total_active_cols - 1) {
		char_index = 10; 
	} 
	
	// logic tree for middle columns
	else {
		int digit_pos = col_index - 1;
		if (num_digits == 3) {
				if (digit_pos == 0) char_index = hundreds - 1;
				else if (digit_pos == 1) char_index = tens - 1;
				else if (digit_pos == 2) char_index = ones - 1;
		} else if (num_digits == 2) {
			if (digit_pos == 0) char_index = tens - 1;
			else if (digit_pos == 1) char_index = ones - 1;
		} else {
			if (digit_pos == 0) char_index = ones - 1;
		}
	}
	
	local_uv.x = (local_uv.x + float(char_index)) / 12.0;
	
	vec4 tex_color = texture(atlas_texture, local_uv);
	COLOR = tex_color;
	
	if (custom_alpha < 0.1) {
		discard;
	}
}