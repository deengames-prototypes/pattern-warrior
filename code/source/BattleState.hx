package;

import flixel.FlxG;
import flixel.FlxSprite;

import models.Monster;
import models.Player;
import models.Game;

import strategy.IBattleStrategy;
import strategy.MatchTilesStrategy;
import strategy.NbackStreamStrategy;
import strategy.MultipleChoiceNbackStreamStrategy;

import turbo.Config;
import turbo.ecs.TurboState;
import turbo.ecs.Entity;
import turbo.ecs.components.HealthComponent;
import turbo.ecs.components.ImageComponent;
import turbo.ecs.components.TextComponent;

class BattleState extends TurboState
{
	private var healthText:Entity;
	private var opponentHealthText:Entity;
	private var statusText:Entity;

	// Data objects!
	private var player:Player;
	private var opponent:Monster;
	private var currentTurn:WhoseTurn = WhoseTurn.Player;

	private var fightButton = new Entity();
	private var potionButtons = new Array<Entity>();
	private var specialButton = new Entity();

	private var strategy:IBattleStrategy;

	public function new()
	{
		super();
	}

	override public function create():Void
	{
		super.create();

		this.player = Game.instance.player;

        this.strategy = new MatchTilesStrategy();
		this.strategy.create(this.container.entities, this.onRoundEnd, this.getCurrentTurn);

		// Text that shows health
		healthText = new Entity()
			.text('Health: ${this.player.healthComponent.currentHealth}', 24)
			.move(200, 32);

		this.addEntity(healthText);
		
		this.opponent = new Monster();
		this.addEntity(this.opponent);
		opponent.move(32, 300 + 16 + 24);
		opponent.size(64, 64);

		opponentHealthText = new Entity()
			.text("Placeholder!", 24)
			.move(32, 300);
			
		this.addEntity(opponentHealthText);
		this.updateOpponentHealthText();		

		statusText = new Entity().text("Memorize and attack!", 16).move(25, 500);
		this.addEntity(statusText);
		
		fightButton.image("assets/images/fight.png").move(450, 350).onClick(function(s:FlxSprite)
		{
			this.strategy.onFightButtonClicked();
			this.flipUiButtonsVisibility();
		});

		this.addEntity(fightButton);

		specialButton.image("assets/images/special.png").move(600, 350).onClick(function(s:FlxSprite)
		{
			this.strategy.onSpecialButtonClicked();
			this.flipUiButtonsVisibility();
		});

		this.addEntity(specialButton);

		var numHealthPotions:Int = player.numHealthPotions;
		for (i in 0 ... numHealthPotions)
		{
			var potionButton = new Entity().image("assets/images/heal.png");
			potionButton.move(960 - 25 - (64 * (i + 1)), 400).onClick(function(s)
			{
					var health = this.player.healthComponent;
                    var toHeal = Std.int(Std.int(Config.get("healthPercentRestoredPerPotion")) / 100 * health.maximumHealth);
                    health.currentHealth = Std.int(Math.min(health.maximumHealth, health.currentHealth + toHeal));
					player.numHealthPotions -= 1;

					this.updateHealthDisplay();
					this.potionButtons.remove(potionButton);

					var img = potionButton.get(ImageComponent);
					img.show = false; // "die". TODO: remove the entity!!!
					this.remove(img.sprite);                    
				});

			this.potionButtons.push(potionButton);
			this.addEntity(potionButton);
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}

	// also flips heal button visibility
	private function flipUiButtonsVisibility():Void
	{
		var img = fightButton.get(ImageComponent);
		img.image = currentTurn == WhoseTurn.Player ? "assets/images/fight.png" : "assets/images/defend.png";
		img.show = !img.show;

		for (potionButton in this.potionButtons)
		{
			potionButton.get(ImageComponent).show = img.show;
		}

		specialButton.get(ImageComponent).show = 
			currentTurn == WhoseTurn.Player ? img.show : false;
	}

	private function updateOpponentHealthText():Void
	{
		var text = '${this.opponent.getData("name")}: ${this.opponent.get(HealthComponent).currentHealth}';
		this.opponentHealthText.get(TextComponent).text = text;
	}

	// States call this when the current round is over
	private function onRoundEnd(damageThisRound:Int):Void
	{
		// no negative damage
		if (damageThisRound < 0) 
		{
			damageThisRound = 0;
		}

		if (currentTurn == WhoseTurn.Player)
		{
			var health = this.opponent.get(HealthComponent);
            health.currentHealth = Std.int(Math.max(0, health.currentHealth - damageThisRound));

			var ifDeadMessage:String = this.opponent.get(HealthComponent).currentHealth <= 0 ? '${this.opponent.getData("name")} dies!' : "";
			this.statusText.get(TextComponent).text = 'Hit for ${damageThisRound} damage! ${ifDeadMessage} Defend yourself!';

			// Spawn new monster if dead
			if (health.currentHealth <= 0)
			{
				this.container.entities.remove(this.opponent);
				this.opponent = new Monster();
				this.addEntity(this.opponent);
			}

			this.updateOpponentHealthText();
		}
		else
		{
			var health = this.player.healthComponent;
            health.currentHealth = Std.int(Math.max(0, health.currentHealth - damageThisRound));	
			this.statusText.get(TextComponent).text = 'Got hit for ${damageThisRound} damage! ATTACK!';
			this.updateHealthDisplay();

			if (health.currentHealth <= 0)
			{
				this.addEntity(new Entity().image("assets/images/overlay.png"));
				this.addEntity(new Entity().text("GAME OVER", 72).move(40, 250));
				// TODO: disable all buttons, etc.
			}
		}

		currentTurn = currentTurn == WhoseTurn.Player ? WhoseTurn.Monster : WhoseTurn.Player;
		this.flipUiButtonsVisibility();
	}

	// States call this when they need to know whose turn it is
	private function getCurrentTurn():WhoseTurn
	{
		return this.currentTurn;
	}

	private function updateHealthDisplay():Void
	{
		this.healthText.get(TextComponent).text = 'Health: ${this.player.healthComponent.currentHealth}';
	}
}

enum WhoseTurn
{
	Player;
	Monster;
}