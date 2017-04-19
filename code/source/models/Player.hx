package models;

import turbo.ecs.Entity;
import turbo.ecs.components.HealthComponent;
import turbo.Config;

class Player extends Entity
{
    public function new()
    {
        super();
        var totalHealth:Int = Config.get("playerHealth");
        this.health(totalHealth);
    }
}