package models;

import turbo.ecs.Entity;
import models.Player;

// Everything needed to represent a single isntance of our game,
// i.e. you can load/save this. Common data across multiple states.
class Game
{
    // There should only really be one at a time, and passing in values
    // to constructors doesn't work with "new FlxGame", so go singletonish.
    public static var instance(default, null):Game;
    public var player(default, null):Player;

    public function new()
    {
        Game.instance = this;
        this.player = new Player();
    }
}
