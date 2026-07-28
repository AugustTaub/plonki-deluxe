shader_type canvas_item;

uniform float grid_resolution : hint_range(8.0, 256.0) = 64.0;
uniform float radius : hint_range(0.1, 0.5) = 0.35;
uniform float noise_amount : hint_range(0.0, 0.5) = 0.15;
uniform float noise_scale : hint_range(1.0, 20.0) = 5.0;
uniform float speed : hint_range(0.0, 5.0) = 1.0;

uniform float outline_thickness : hint_range(0.0, 0.1) = 0.05;

// Sprite sheet & Eye placement settings
uniform sampler2D eye_spritesheet : source_color, hint_default_transparent;
uniform vec2 spritesheet_grid = vec2(4.0, 1.0); // 8 sprites along the X-axis (1 row)
uniform vec2 eye_size = vec2(0.12, 0.12);
uniform vec2 eye_offset = vec2(0.08, 0.04);

// Inspector control to choose the eye config (Frame 0 to 7)
uniform float eye_frame : hint_range(0.0, 4.0) = 0.0;

uniform sampler2D center_texture : source_color, hint_default_white;
uniform float donut_inner_radius : hint_range(0.0, 0.4) = 0.2;

varying vec4 v_instance_color;
varying float instance_seed;
varying float v_eye_frame;
varying float donut_mode_float;

void vertex() {
	v_instance_color = COLOR;
	instance_seed = INSTANCE_CUSTOM.x;
	
	// Combines inspector uniform with INSTANCE_CUSTOM.y
	v_eye_frame = eye_frame + INSTANCE_CUSTOM.y;
	donut_mode_float = INSTANCE_CUSTOM.z;
}

float random(vec2 st) {
	return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 st) {
	vec2 i = floor(st);
	vec2 f = fract(st);
	
	float a = random(i);
	float b = random(i + vec2(1.0, 0.0));
	float c = random(i + vec2(0.0, 1.0));
	float d = random(i + vec2(1.0, 1.0));
	
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
	vec2 pixel_uv = floor(UV * grid_resolution) / grid_resolution;
	vec2 centered = pixel_uv - vec2(0.5);
	
	float dist = length(centered);
	float angle = atan(centered.y, centered.x);
	
	bool donut_mode = donut_mode_float > 0.5;
	
	float n = noise(vec2(angle * noise_scale + instance_seed, (TIME * speed) + instance_seed));
	float final_radius = radius + (n - 0.5) * noise_amount;
	float outline_inner = final_radius - outline_thickness;
	
	// Position centers for left and right eyes
	vec2 left_eye_center = vec2(-eye_offset.x, -eye_offset.y);
	vec2 right_eye_center = vec2(eye_offset.x, -eye_offset.y);
	
	// Normalized local UVs (0.0 to 1.0 range) for each eye
	vec2 uv_l = (centered - left_eye_center) / eye_size + vec2(0.5);
	vec2 uv_r = (centered - right_eye_center) / eye_size + vec2(0.5);
	
	// Check bounds for both eyes
	bool in_left = uv_l.x >= 0.0 && uv_l.x <= 1.0 && uv_l.y >= 0.0 && uv_l.y <= 1.0;
	bool in_right = uv_r.x >= 0.0 && uv_r.x <= 1.0 && uv_r.y >= 0.0 && uv_r.y <= 1.0;
	

	float current_frame = floor(mod(v_eye_frame, spritesheet_grid.x));
	
	// Sample single eye texture for left eye
	vec4 col_l = vec4(0.0);
	if (in_left) {
		vec2 sheet_uv_l = (uv_l + vec2(current_frame, 0.0)) / spritesheet_grid;
		col_l = texture(eye_spritesheet, sheet_uv_l);
	}
	
	// Sample single eye texture for right eye (horizontally mirrored)
	vec4 col_r = vec4(0.0);
	if (in_right) {
		vec2 uv_r_mirrored = vec2(1.0 - uv_r.x, uv_r.y);
		vec2 sheet_uv_r = (uv_r_mirrored + vec2(current_frame, 0.0)) / spritesheet_grid;
		col_r = texture(eye_spritesheet, sheet_uv_r);
	}
	
	// Combine eye color samples
	vec4 final_eye_color = vec4(0.0);
	if (in_left && col_l.a > 0.0) {
		final_eye_color = col_l;
	} else if (in_right && col_r.a > 0.0) {
		final_eye_color = col_r;
	}
	
	if (dist > final_radius) {
		COLOR = vec4(0.0);
	} else if (dist >= outline_inner) {
		COLOR = v_instance_color;
	} else {
		if (final_eye_color.a > 0.0) {
			COLOR = final_eye_color;
		} else if (donut_mode) {
			if (dist < donut_inner_radius) {
				vec2 tex_uv = centered / (donut_inner_radius * 2.0) + vec2(0.5);
				if (tex_uv.x >= 0.0 && tex_uv.x <= 1.0 && tex_uv.y >= 0.0 && tex_uv.y <= 1.0) {
					COLOR = texture(center_texture, tex_uv);
				} else {
					COLOR = vec4(0.0);
				}
			} else {
				COLOR = vec4(0.0, 0.0, 0.0, 1.0);
			}
		} else {
			COLOR = vec4(0.0, 0.0, 0.0, 1.0);
		}
	}
}