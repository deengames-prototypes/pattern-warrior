package strategy;

import flixel.math.FlxRandom;
import PlayState; // whoseturn

import turbo.Config;
import turbo.ecs.Entity;
import turbo.ecs.components.ImageComponent;
import turbo.ecs.components.PositionComponent;

class MatchTilesStrategy
{
    private static inline var MAX_TILES_PER_ROW:Int = 8; // 8 fit in a single row on-screen
	private static inline var MAX_GOUPS:Int = 5; // 5 groups max.
	private static inline var ROW_SPACING:Int = 24;

	private static inline var TILE_WIDTH:Int = 64;
	private static inline var TILE_HEIGHT:Int = 64;

	private static var ALL_TILES:Array<Tile> = [Tile.Up, Tile.Right, Tile.Down, Tile.Left];
	
    private var numGroups:Int = 3;
	private var groupSize:Int = 1;

	// Corresponding sprites for "tiles". data["tile"] is the tile name
	private var tileSprites = new Array<Entity>();
	// UI buttons, including play, and user input
	private var inputControls = new Array<Entity>(); // match order of ALL_TILES
	private var userInput = new Array<Tile>();	

    private var damageThisRound:Int = 0;
    private var random = new FlxRandom();

    private var onRoundEnd:Int->Void; // callback to PlayState, receives damage
    private var getCurrentTurn:Void->WhoseTurn; // Callback to PlayState. Receives who's turn it is.

    // From config.json. But Config.get(...) throws null if used here.
	// Probably because openfl didn't load assets yet or something.
	private static var DAMAGE_PER_ATTACK:Int;
	private static var DAMAGE_PER_MISSED_ATTACK:Int;
	private static var DAMAGE_PER_MISSED_BLOCK:Int;

    public function new() { }

    public function create(entities:Array<Entity>, onRoundEnd:Int->Void, getCurrentTurn:Void->WhoseTurn)
    {
        DAMAGE_PER_ATTACK = Config.get("damagePerHit");
		DAMAGE_PER_MISSED_ATTACK = Config.get("damagePerMiss");
		DAMAGE_PER_MISSED_BLOCK = Config.get("damagePerMissedBlock");

        this.onRoundEnd = onRoundEnd;
        this.getCurrentTurn = getCurrentTurn;

        for (i in 0 ... MAX_GOUPS) {
			for (j in 0 ... MAX_TILES_PER_ROW) {
				var tileType:Tile = random.getObject(ALL_TILES);
				
				var x = j * TILE_WIDTH + 32;
				// Space out rows 32px high, plus padding between (i-1 * 16).
				// This makes things separate into rows so users don't get confused.
				var y = (i * TILE_HEIGHT + 32) + ((i + 1) * ROW_SPACING);
				
				var tile = new Entity()
					.image("assets/images/blank.png")
					.move(x, y)
					.hide();
				
				entities.push(tile);
				this.tileSprites.push(tile);
			}
		}

		this.generateNewPattern();

		for (tile in ALL_TILES)
		{
			this.addInputControl(tile, entities);
		}

		this.hideInputControls();
    }

	public function onPlayButtonClicked():Void
	{
 		// Blank out inputs
		for (tile in tileSprites)
		{
			tile.get(ImageComponent).setImage("assets/images/blank.png");
		}
		
		this.showInputControls();
		this.showCurrentTile(0);
	}

    private function addInputControl(tile:Tile, entities:Array<Entity>):Void
	{
		var e = new Entity();
		var posX = 250;
		var posY = 800;

		var tileName = '${tile}'.toLowerCase();
		e.setData("tile", tile);
		e.image('assets/images/${tileName}.png');
		if (tile == Tile.Up || tile == Tile.Down)
		{
			var x = posX;
			var y = posY - 200 + (tile == Tile.Up ?  -TILE_HEIGHT : TILE_HEIGHT);
			e.move(x, y);
		}
		else
		{
			var x = posX + (tile == Tile.Left ? -TILE_WIDTH : TILE_WIDTH);
			var y = posY - 200;
			e.move(x, y);
		}

		e.onClick(function(x, y)
		{
			this.processInput(e.getData("tile"));
		});

		entities.push(e);
		this.inputControls.push(e);
	}

	private function hideInputControls():Void
	{
		this.setInputControlsVisibility(false);
	}

	private function showInputControls():Void
	{
		this.setInputControlsVisibility(true);
	}

	private function setInputControlsVisibility(visible:Bool):Void
	{
		for (e in this.inputControls)
		{
			if (visible == true)
			{
				e.show();
			}
			else
			{
				e.hide();
			}
		}
	}

	private function showCurrentTile(index:Int):Void
	{
		this.indexToSprite(index).get(ImageComponent).setImage("assets/images/current.png");
	}

    // Assumes controls are already created
	private function generateNewPattern():Void
	{
		var index = 0;

		for (i in 0 ... numGroups) {
			for (j in 0 ... groupSize) {
				var tile:Tile = random.getObject(ALL_TILES);
				var sprite = this.indexToSprite(index); //this.tileSprites[i * groupSize + j];
				sprite.setData("tile", tile);
				var tileName = '${tile}'.toLowerCase();
				sprite.get(ImageComponent).setImage('assets/images/${tileName}.png');
				sprite.show();
				index++;
			}
		}
	}

	// Pick the right sprite. Since all rows/column sprites exist already,
	// we have to skip inactive/invisible ones...
	private function indexToSprite(index:Int):Entity
	{
		var x = index % groupSize;
		var y = Std.int(index / groupSize);
		var index = y * MAX_TILES_PER_ROW + x;
		var sprite = this.tileSprites[index];
		return sprite;
	}


	// Process something the user inputted, marking the state as correct
	// or incorrect; possibly switching back if this was the last input.
	private function processInput(input:Tile):Void
	{
		var index = userInput.length;
		var sprite = this.indexToSprite(index);
		var expected:Tile = sprite.getData("tile");
		var name = '${input}'.toLowerCase();
        var currentTurn = this.getCurrentTurn();

		if (expected == input)
		{
			// successful attack = DAMAGE_PER_ATTACK damage; successful block = 0 damage
			if (currentTurn == WhoseTurn.Player)
			{
				damageThisRound += DAMAGE_PER_ATTACK;
			}						
		}
		else
		{
			name = '${expected}-wrong'.toLowerCase();
			// unsucessful attack or block
			if (currentTurn == WhoseTurn.Player)
			{
				damageThisRound -=  DAMAGE_PER_MISSED_ATTACK;
			}
			else
			{
				damageThisRound += DAMAGE_PER_MISSED_BLOCK;
			}
		}

		sprite.get(ImageComponent).setImage('assets/images/${name}.png');
		
		userInput.push(input);
		if (index == numGroups * groupSize - 1)
		{
            this.onRoundEnd(damageThisRound);

			damageThisRound = 0;
			userInput = new Array<Tile>(); // no .clear method?!

			// That was the last one. We're done.
			this.generateNewPattern();
			this.hideInputControls();			
		}
		else
		{
			this.showCurrentTile(index + 1);
		}
	}

}

enum Tile
{
	Up;
	Right;
	Down;
	Left;
}