shader_type spatial;
global uniform bool allow_animation = false;
render_mode unshaded, shadows_disabled, depth_prepass_alpha, blend_mix;
#include "vertexsnapping.gdshaderinc"

uniform bool billboard = false;
uniform bool y_billboard = false;
uniform sampler2D color_texture : source_color, filter_nearest, repeat_enable;

uniform vec4 transparent_color : source_color = vec4(1.0,0.0,1.0,1.0);
uniform vec4 tint_color : source_color = vec4(1.0,1.0,1.0,1.0);


uniform bool fog = false;
global uniform vec4 fog_color;
global uniform float sphere_size;
global uniform vec3 player_pos; 


group_uniforms spritesheet;

	uniform bool is_spritesheet = false;
	uniform ivec2 spritesheet_size = ivec2(1, 1);
	uniform ivec2 sprite = ivec2(0, 0);
	
group_uniforms animation;
	uniform bool enable_auto_animation_x = false;
	uniform bool enable_auto_animation_y = false;
	uniform int frame_count = 1;
	uniform int frame_offset = 0;
	uniform float animation_speed = 1.0;

group_uniforms uv_mofification;

	uniform vec2 uv_scale = vec2(1.0, 1.0);
	uniform vec2 uv_offset = vec2(0.0, 0.0);
	
group_uniforms advanced_vertex_colors;
	uniform bool vertex_color_as_mask = false;
	uniform bool invert = false;
	uniform bool add_blend_mode = false;
	uniform bool multiply_blend_mode = false;
	uniform vec4 masked_color : source_color = vec4(1.0,1.0,1.0,1.0);

const float alpha_scissor = 0.25;

void vertex()
{
	UV = UV * uv_scale + uv_offset;
	if(is_spritesheet)
	{
		vec2 anim_sprite = vec2(sprite);
		if(allow_animation)
		{
			if(enable_auto_animation_x && frame_count != 0)
			{
				anim_sprite.x = floor(TIME * animation_speed);
				anim_sprite.x = floor(anim_sprite.x / float(frame_count) * vec2(spritesheet_size).x);
				anim_sprite.x += float(frame_offset);
			}
			else if(enable_auto_animation_y && frame_count != 0)
			{
				anim_sprite.y = floor(TIME * animation_speed);
				anim_sprite.y = floor(anim_sprite.y / float(frame_count) * vec2(spritesheet_size).y);
				anim_sprite.y += float(frame_offset);
			}
		}
		UV = (UV + anim_sprite) / vec2(spritesheet_size);
	}

	if (y_billboard)
	{
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], MODEL_MATRIX[1], vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, MODEL_MATRIX[1].xyz)), 0.0), MODEL_MATRIX[3]);
		MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(1.0, 0.0, 0.0, 0.0), vec4(0.0, 1.0 / length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	}
	else if (billboard)
	{
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	}

	POSITION = get_snapped_pos(PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0));  // snap position to grid
	POSITION /= abs(POSITION.w);  // discard depth for affine mapping

	if (y_billboard)
	{
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
		MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	}
}

void fragment()
{
	vec4 texture_color = texture(color_texture, UV);
	
	if (vertex_color_as_mask)
	{
		ALBEDO = (texture_color * tint_color).rgb;
		float mask = length(COLOR.rgb);
		if (invert)
			mask = max(1.0 - mask, 0.0);

		if (add_blend_mode && !multiply_blend_mode)
			ALBEDO = mix(ALBEDO, ALBEDO + masked_color.rgb, mask);
		else if (!add_blend_mode && multiply_blend_mode)
			ALBEDO = mix(ALBEDO, ALBEDO * masked_color.rgb, mask);
		else if (add_blend_mode && multiply_blend_mode)
			ALBEDO = mix(ALBEDO, ALBEDO * masked_color.rgb + ALBEDO, mask);
		else
			ALBEDO = mix(ALBEDO, masked_color.rgb, mask);
	}
	else
		ALBEDO = (texture_color * tint_color * COLOR).rgb;
	
		
	if (length(texture_color - transparent_color) < 0.1)
		ALPHA = 0.0;
	else
		ALPHA = texture_color.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor;
}