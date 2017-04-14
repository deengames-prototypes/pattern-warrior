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
	private static inline var NUM_GROUPS:Int = 3;
	private static inline var GROUP_SIZE:Int = 1;
	private static var ALL_TILES:Array<Tile> = [Tile.Up, Tile.Right, Tile.Down, Tile.Left];
	private var random = new FlxRandom();

	override public function create():Void
	{
		super.create();

		var groups:Array<Array<Tile>> = [];
		for (i in 0 ... NUM_GROUPS) {
			
			var currentGroup = new Array<Tile>();
			for (j in 0 ... GROUP_SIZE) {
				currentGroup.push(random.getObject(ALL_TILES));
			}
			groups.push(currentGroup);
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}
}

enum Tile {
	Up;
	Right;
	Down;
	Left;
}