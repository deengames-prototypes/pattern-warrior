package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.math.FlxMath;
import flixel.math.FlxRandom;

class PlayState extends FlxState
{
	/// TODO: ENUM
	public static inline var UP = "up";
	public static inline var RIGHT = "right";
	public static inline var DOWN = "down";
	public static inline var LEFT = "left";

	private static inline var NUM_GROUPS:Int = 3;
	private static inline var GROUP_SIZE:Int = 1;
	private static var ALL_TILES:Array<String> = [UP, RIGHT, DOWN, LEFT];
	private var random = new FlxRandom();

	override public function create():Void
	{
		super.create();

		var groups:Array<Array<String>> = [];
		for (i in 0 ... NUM_GROUPS) {
			
			var currentGroup = new Array<String>();
			for (j in 0 ... GROUP_SIZE) {
				currentGroup.push(random.getObject(ALL_TILES));
			}
			groups.push(currentGroup);
		}

		trace('Done: ${groups}');
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}
}