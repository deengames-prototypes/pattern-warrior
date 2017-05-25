package;

import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.math.FlxRandom;
import flixel.math.FlxPoint;

import models.Monster;
import models.Player;
import models.Game;

import strategy.MatchTilesStrategy;
import strategy.NbackStreamStrategy;
import strategy.MultipleChoiceNbackStreamStrategy;

import turbo.Config;
import turbo.ecs.TurboState;
import turbo.ecs.Entity;
using turbo.ecs.EntityFluentApi;
import turbo.ecs.components.PositionComponent;
import turbo.ecs.components.SpriteComponent;

class MapState extends TurboState
{
    private var WALL_THICKNESS:Int = 8;
	private var minEnemies:Int;
	private var maxEnemies:Int;

	// Data objects!
	private var player:Player;

	private var random:FlxRandom = new FlxRandom();

	public function new()
	{
		super();
		minEnemies = Config.get("minEnemies");
		maxEnemies = Config.get("maxEnemies");
	}

	override public function create():Void
	{
		super.create();
		this.player = Game.instance.player;

		this.addEntity(new Entity("background").size(this.width, this.height).colour(0, 128, 0));
		
        this.addBorderWalls();
		this.addRandomWalls();

		this.createPlayerEntity();
		this.addEnemies();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);		
	}

    private function addBorderWalls():Void
    {
        this.addWall(0, 0, this.width, WALL_THICKNESS);
        this.addWall(0, this.height - WALL_THICKNESS, this.width, WALL_THICKNESS);
        this.addWall(0, 0, WALL_THICKNESS, this.height);
        this.addWall(this.width - WALL_THICKNESS, 0, WALL_THICKNESS, this.height);
    }

	private function addRandomWalls():Void
	{
		for (i in 0 ... Std.int(Config.get("numWalls")))
		{
			var obstacleWidth:Int = Config.get("obstacleWidth");
			var obstacleHeight:Int = Config.get("obstacleHeight");
			var biggerSize:Int = Std.int(Math.max(obstacleWidth, obstacleHeight));

			// Space out walls so they don't touch; they're one wall-size apart.
			var position = this.findEmptySpace(biggerSize * 2, biggerSize * 2);
			var x = Std.int(position.x + (biggerSize / 2));
			var y = Std.int(position.y + (biggerSize / 2));

			var isVertical:Bool = random.bool();
			
			if (isVertical)
			{
				this.addWall(x, y, biggerSize == obstacleHeight ? obstacleWidth : obstacleHeight, biggerSize);
			}
			else
			{
				this.addWall(x, y, biggerSize, biggerSize == obstacleWidth ? obstacleHeight : obstacleWidth);
			}
		}
	}

    private function addWall(x:Int, y:Int, width:Int, height:Int):Void
    {
        var wall = new Entity("wall").size(width, height).colour(128, 128, 128).immovable().move(x, y);
        this.addEntity(wall);
    }

	private function createPlayerEntity():Void
	{
        var playerEntity = new Entity("player").size(32, 32).colour(255, 0, 0).moveWithKeyboard(250).move(50, 50);
        this.addEntity(playerEntity);
		playerEntity.collideWith("wall");
	}

	private function addEnemies():Void
	{
		var numEnemies = random.int(minEnemies, maxEnemies);
		for (i in 0 ... numEnemies)
		{
			var pos = this.findEmptySpace(32, 32);
			var enemy = new Entity().size(32, 32).colour(0, 0, 255).move(pos.x, pos.y);
			this.addEntity(enemy);
		}
	}

	private function findEmptySpace(targetWidth:Int, targetHeight:Int):FlxPoint
	{
		var targetX:Int;
		var targetY:Int;

		var foundSpace:Bool = true;

		do
		{
			targetX = random.int(0, this.width - targetWidth);
			targetY = random.int(0, this.height - targetHeight);

			foundSpace = true;

			for (e in this.container.entities)
			{
				var pos = e.get(PositionComponent);
				var sprite = e.get(SpriteComponent);

				if (e.tags.indexOf("background") == -1 && sprite != null &&
					// AABB: https://developer.mozilla.org/en-US/docs/Games/Techniques/2D_collision_detection
					targetX < pos.x + sprite.sprite.width && targetX + targetWidth > pos.x &&
					targetY < pos.y + sprite.sprite.height && targetY + targetHeight > pos.y)
				{
					foundSpace = false;
					break;
				}
			}
		} while (!foundSpace);

		return new FlxPoint(targetX, targetY);
	}
}