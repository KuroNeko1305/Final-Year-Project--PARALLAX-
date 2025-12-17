shader_type canvas_item; 
uniform sampler2D t: hint_screen_texture, filter_linear_mipmap;
void fragment() {
	COLOR.rgb *= textureLod(t, SCREEN_UV, 2.0).rgb;
}
