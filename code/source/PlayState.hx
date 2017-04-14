package;

import flixel.FlxG;
import flixel.math.FlxRandom;
import turbo.ecs.TurboState;
import turbo.ecs.Entity;
import turbo.ecs.components.ImageComponent;

class PlayState extends TurboState
{
	private static inline var NUM_GROUPS:Int = 3;
	private static inline var GROUP_SIZE:Int = 1;
	private static inline var MAX_TILES_PER_ROW:Int = 8; // 8 fit in a single row on-screen

	private static var ALL_TILES:Array<Tile> = [Tile.Up, Tile.Right, Tile.Down, Tile.Left];
	private static inline var TILE_WIDTH:Int = 64;
	private static inline var TILE_HEIGHT:Int = 64;

	private var random = new FlxRandom();
	private var playButton = new Entity();
	private var tiles = new Array<Entity>();

	override public function create():Void
	{
		super.create();

		var groups:Array<Array<Tile>> = [];
		for (i in 0 ... NUM_GROUPS) {
			var currentGroup = new Array<Tile>();
			for (j in 0 ... GROUP_SIZE) {
				var tileType:Tile = random.getObject(ALL_TILES);
				currentGroup.push(tileType);
				var x = j * TILE_WIDTH + 32;
				var y = i * TILE_HEIGHT + 32;
				trace('${tileType} at (${x}, ${y})');
				
				var tile = new Entity()
					.image('assets/images/${tileType}.png')
					.move(x, y);
				this.entities.push(tile);
				this.tiles.push(tile);
			}
			groups.push(currentGroup);
		}

		this.entities.push(playButton);
		playButton.image("assets/images/start.png").move(250, 800).onClick(function(x, y) {
			playButton.hide();
			for (tile in tiles)
			{
				tile.get(ImageComponent).setImage("assets/images/blank.png");
			}
		});
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