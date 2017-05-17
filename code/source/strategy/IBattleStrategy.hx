package strategy;

import BattleState; // whoseturn
import turbo.ecs.Entity;

interface IBattleStrategy
{
    public function create(entities:Array<Entity>, onRoundEnd:Int->Void, getCurrentTurn:Void->WhoseTurn):Void;
    public function onFightButtonClicked():Void;
    public function onSpecialButtonClicked():Void;
}