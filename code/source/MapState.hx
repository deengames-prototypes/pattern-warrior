package;

import flixel.FlxG;
import flixel.group.FlxGroup;

import models.Monster;
import models.Player;
import models.Game;

import strategy.MatchTilesStrategy;
import strategy.NbackStreamStrategy;
import strategy.MultipleChoiceNbackStreamStrategy;

import turbo.Config;
import turbo.ecs.TurboState;
import turbo.ecs.Entity;
import turbo.ecs.components.HealthComponent;
import turbo.ecs.components.ImageComponent;
import turbo.ecs.components.TextComponent;

class MapState extends TurboState
{
    private var WALL_THICKNESS:Int = 16;

	private var healthText:Entity;
	private var opponentHealthText:Entity;
	private var statusText:Entity;

	// Data objects!
	private var player:Player;

	private var playerEntity = new Entity(["player"]); 

	public function new()
	{
		super();
	}

	override public function create():Void
	{
		super.create();

        this.addBorderWalls();

		this.player = Game.instance.player;
        var playerEntity = new Entity(["player"]).size(64, 64).colour(255, 0, 0).moveWithKeyboard(250).move(50, 50);
        this.addEntity(playerEntity);
		playerEntity.collideWith("wall");
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

    private function addWall(x:Int, y:Int, width:Int, height:Int):Void
    {
        var wall = new Entity(["wall"]).size(width, height).colour(192, 192, 192).immovable().move(x, y);
        this.addEntity(wall);
    }
}