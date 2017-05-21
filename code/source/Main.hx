package;

import flixel.FlxGame;
import openfl.Lib;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		new models.Game();
		addChild(new FlxGame(0, 0, MapState, 1, 60, 60, true));
	}
}
    