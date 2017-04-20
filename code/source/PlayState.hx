package;

import flixel.FlxG;
import flixel.math.FlxRandom;

import models.Monster;
import models.Player;

import turbo.Config;
import turbo.ecs.TurboState;
import turbo.ecs.Entity;
import turbo.ecs.components.HealthComponent;
import turbo.ecs.components.ImageComponent;
import turbo.ecs.components.PositionComponent;
import turbo.ecs.components.TextComponent;

class PlayState extends TurboState
{
	private static inline var MAX_TILES_PER_ROW:Int = 8; // 8 fit in a single row on-screen
	private static inline var MAX_GOUPS:Int = 5; // 5 groups max.
	private static inline var ROW_SPACING:Int = 24;
	private static var DAMAGE_PER_HIT:Int;
	private static var DAMAGE_PER_MISS:Int;

	private static var ALL_TILES:Array<Tile> = [Tile.Up, Tile.Right, Tile.Down, Tile.Left];
	private static inline var TILE_WIDTH:Int = 64;
	private static inline var TILE_HEIGHT:Int = 64;

	private var random = new FlxRandom();
	private var playButton = new Entity();

	private var numGroups:Int = 3;
	private var groupSize:Int = 1;

	// Corresponding sprites for "tiles". data["tile"] is the tile name
	private var tileSprites = new Array<Entity>();
	// UI buttons, including play, and user input
	private var inputControls = new Array<Entity>(); // match order of ALL_TILES
	private var userInput = new Array<Tile>();

	private var damageThisRound:Int = 0;

	private var healthText:Entity;
	private var opponentHealthText:Entity;

	// Data objects!
	private var player:Player;
	private var opponent:Monster;

	override public function create():Void
	{
		super.create();

		DAMAGE_PER_HIT = Config.get("damagePerHit");
		DAMAGE_PER_MISS = Config.get("damagePerMiss");

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
				
				this.entities.push(tile);
				this.tileSprites.push(tile);
			}
		}

		this.generateNewPattern();
		this.entities.push(playButton);

		playButton.image("assets/images/start.png").move(250, 800).onClick(function(x, y)
		{
			this.showInputControls();
			
			// Blank out inputs
			for (tile in tileSprites)
			{
				tile.get(ImageComponent).setImage("assets/images/blank.png");
			}

			this.showCurrentTile(0);			
		});

		for (tile in ALL_TILES)
		{
			this.addInputControl(tile);
		}

		this.hideInputControls();

		this.player = new Player();
		this.entities.push(this.player);

		// Text that shows health
		healthText = new Entity()
			.text('Health: ${this.player.get(HealthComponent).currentHealth}', 24)
			.move(400, 32);

		this.entities.push(healthText);
		
		this.opponent = new Monster();
		this.entities.push(this.opponent);
		opponent.move(32, 400 + 16 + 24);
		opponent.size(64, 64);

		opponentHealthText = new Entity()
			.text("Placeholder!", 24)
			.move(32, 400);
			
		this.entities.push(opponentHealthText);
		this.updateOpponentHealthText();		
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}

	private function addInputControl(tile:Tile):Void
	{
		var e = new Entity();
		var pos = playButton.get(PositionComponent);

		var tileName = '${tile}'.toLowerCase();
		e.setData("tile", tile);
		e.image('assets/images/${tileName}.png');
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

		e.onClick(function(x, y)
		{
			this.processInput(e.getData("tile"));
		});

		this.entities.push(e);
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

		// Play button is invisbile when controls are visible, and vice-versa
		if (visible == true)
		{
			playButton.hide();			
		} else {
			playButton.show();
		}
	}

	private function showCurrentTile(index:Int):Void
	{
		this.indexToSprite(index).get(ImageComponent).setImage("assets/images/current.png");
	}

	// Process something the user inputted, marking the state as correct
	// or incorrect; possibly switching back if this was the last input.
	private function processInput(input:Tile):Void
	{
		var index = userInput.length;
		var sprite = this.indexToSprite(index);
		var expected:Tile = sprite.getData("tile");
		var name = '${input}'.toLowerCase();

		if (expected != input)
		{
			name = '${expected}-wrong'.toLowerCase();
			damageThisRound -= DAMAGE_PER_MISS;
		}
		else
		{
			damageThisRound += DAMAGE_PER_HIT;
		}

		sprite.get(ImageComponent).setImage('assets/images/${name}.png');
		
		userInput.push(input);
		if (index == numGroups * groupSize - 1)
		{
			// no negative damage
			if (damageThisRound < 0) 
			{
				damageThisRound = 0;
			}
			this.opponent.get(HealthComponent).damage(damageThisRound);
			this.updateOpponentHealthText();

			// score
			damageThisRound = 0;
			userInput = new Array<Tile>(); // no .clear method?!

			// Scale difficulty. Fast.
			if (groupSize < MAX_TILES_PER_ROW)
			{
				groupSize++;
			}
			else
			{
				numGroups++;
			}

			// That was the last one. We're done.
			this.generateNewPattern();
			this.hideInputControls();			
		}
		else
		{
			this.showCurrentTile(index + 1);
		}
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

	private function updateOpponentHealthText():Void
	{
		var text = '${this.opponent.getData("name")}: ${this.opponent.get(HealthComponent).currentHealth}';
		this.opponentHealthText.get(TextComponent).setText(text);
	}
}

enum Tile
{
	Up;
	Right;
	Down;
	Left;
}