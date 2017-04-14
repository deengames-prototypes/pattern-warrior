package;

import flixel.FlxG;
import flixel.math.FlxRandom;
import turbo.ecs.TurboState;
import turbo.ecs.Entity;
import turbo.ecs.components.ImageComponent;
import turbo.ecs.components.PositionComponent;

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

	private var tiles = new Array<Tile>();
	private var tileSprites = new Array<Entity>();
	private var inputControls = new Array<Entity>(); // match order of ALL_TILES

	override public function create():Void
	{
		super.create();

		var groups:Array<Array<Tile>> = [];
		for (i in 0 ... NUM_GROUPS) {
			for (j in 0 ... GROUP_SIZE) {
				var tileType:Tile = random.getObject(ALL_TILES);
				tiles.push(tileType);
				
				var x = j * TILE_WIDTH + 32;
				var y = i * TILE_HEIGHT + 32;
				
				var tile = new Entity()
					.image('assets/images/${tileType}.png')
					.move(x, y);

				this.entities.push(tile);
				this.tileSprites.push(tile);
			}
		}

		this.entities.push(playButton);
		playButton.image("assets/images/start.png").move(250, 800).onClick(function(x, y) {
			playButton.hide();
			for (tile in tileSprites)
			{
				tile.get(ImageComponent).setImage("assets/images/blank.png");
			}
		});

		for (tile in ALL_TILES)
		{
			this.addInputControl(tile);
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}

	private function addInputControl(tile:Tile):Void
	{
		var e = new Entity();
		var pos = playButton.get(PositionComponent);

		e.image('assets/images/${tile}.png');
		if (tile == Tile.Up || tile == Tile.Down)
		{
			var x = pos.x;
			var y = pos.y - 200 + (tile == Tile.Up ?  -TILE_HEIGHT : TILE_HEIGHT);
			e.move(x, y);
		} 
		else
		{
			var x = pos.x + (tile == Tile.Left ? -TILE_WIDTH : TILE_WIDTH);
			var y = pos.y - 200;
			e.move(x, y);
		}
		this.entities.push(e);
		this.inputControls.push(e);
	}
}

enum Tile {
	Up;
	Right;
	Down;
	Left;
}