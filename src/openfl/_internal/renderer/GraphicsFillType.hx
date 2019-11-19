package openfl._internal.renderer;

/*@:fakeEnum(Int) enum GraphicsFillType
{
	SOLID_FILL;
	GRADIENT_FILL;
	BITMAP_FILL;
	END_FILL;
	SHADER_FILL;
}*/

@:enum abstract GraphicsFillType(Int)
{
	var SOLID_FILL = 0;
	var GRADIENT_FILL = 1;
	var BITMAP_FILL = 2;
	var END_FILL = 3;
	var SHADER_FILL = 4;
}
