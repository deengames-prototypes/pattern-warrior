package models;

import turbo.ecs.Entity;
import turbo.ecs.components.HealthComponent;
import turbo.Config;

class Player
{
   public var healthComponent(default, null):HealthComponent;
   public var numHealthPotions:Int;
    // TODO: SP (and cost per skill use) goes in here

    public function new()
    {
        var health:Int = Config.get("playerHealth");
        this.healthComponent = new HealthComponent(health);
        this.numHealthPotions = Config.get("healthPotions");
    }
}