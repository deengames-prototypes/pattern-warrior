package models;

import flixel.math.FlxRandom;
import turbo.Config;
import turbo.ecs.Entity;
import turbo.ecs.components.ColourComponent;
import turbo.ecs.components.HealthComponent;

class Monster extends Entity
{
    private static var colours:Array<Array<Int>> = [
        [255, 0, 0], // red
        [255, 128, 0], // orange
        [255, 225, 0], // yellow        
    ];

    private static var nouns:Array<String> = ["spider", "snail", "crab", "slime"];
    private static var adjectives:Array<String> = ["scary", "terrifying", "huge", "poisonous"];

    private static var random = new FlxRandom();
    private static var numSlain:Int = 0;

    public function new()
    {
        super();

        var initialMonsterHealth:Int = Config.get("initialMonsterHealth");
        var perMonsterHealthIncrease:Int = Config.get("perMonsterHealthIncrease");

        var c = random.getObject(colours);
        this.colour(c[0], c[1], c[2]);
        this.health(initialMonsterHealth + (perMonsterHealthIncrease * numSlain));
        numSlain++; // we're dead, sooner or later
        this.setData("name", '${random.getObject(adjectives)} ${random.getObject(nouns)}');
    }
}