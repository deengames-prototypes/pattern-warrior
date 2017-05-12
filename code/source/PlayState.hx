package;

import flixel.FlxG;

import models.Monster;
import models.Player;
import strategy.MatchTilesStrategy;
import strategy.NbackStreamStrategy;
import strategy.MultipleChoiceNbackStreamStrategy;

import turbo.Config;
import turbo.ecs.TurboState;
import turbo.ecs.Entity;
import turbo.ecs.components.HealthComponent;
import turbo.ecs.components.ImageComponent;
import turbo.ecs.components.TextComponent;

class PlayState extends TurboState
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

	private var strategy = new MultipleChoiceNbackStreamStrategy();

	public function new()
	{
		super();
	}

	override public function create():Void
	{
		super.create();

		this.player = new Player();
		this.entities.push(this.player);

		this.strategy.create(this.entities, this.onRoundEnd, this.getCurrentTurn);

		// Text that shows health
		healthText = new Entity()
			.text('Health: ${this.player.get(HealthComponent).currentHealth}', 24)
			.move(200, 32);

		this.entities.push(healthText);
		
		this.opponent = new Monster();
		this.entities.push(this.opponent);
		opponent.move(32, 300 + 16 + 24);
		opponent.size(64, 64);

		opponentHealthText = new Entity()
			.text("Placeholder!", 24)
			.move(32, 300);
			
		this.entities.push(opponentHealthText);
		this.updateOpponentHealthText();		

		statusText = new Entity().text("Memorize and attack!", 16).move(25, 500);
		this.entities.push(statusText);
		
		fightButton.image("assets/images/fight.png").move(450, 350).onClick(function(x, y)
		{
			this.strategy.onFightButtonClicked();
			this.flipUiButtonsVisibility();
		});

		this.entities.push(fightButton);

		specialButton.image("assets/images/special.png").move(600, 350).onClick(function(x, y)
		{
			this.strategy.onSpecialButtonClicked();
			this.flipUiButtonsVisibility();
		});

		var numHealthPotions:Int = Config.get("healthPotions");
		for (i in 0 ... numHealthPotions)
		{
			var potionButton = new Entity().image("assets/images/heal.png");
			potionButton.move(960 - 25 - (64 * (i + 1)), 400).onClick(function(x, y)
			{
					var playerHealth = player.get(HealthComponent);
					var playerMaxHealth = playerHealth.totalHealth;
					var healthToHeal = Std.int(Std.int(Config.get("healthPercentRestoredPerPotion")) / 100 * playerMaxHealth);
					playerHealth.heal(healthToHeal);
					this.updateHealthDisplay();
					this.potionButtons.remove(potionButton);

					var img = potionButton.get(ImageComponent);
					img.alpha = 0; // "die"
					this.remove(img.sprite);
				});

			this.potionButtons.push(potionButton);
			this.entities.push(potionButton);
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
		img.setImage(currentTurn == WhoseTurn.Player ? "assets/images/fight.png" : "assets/images/defend.png");
		img.alpha = 1 - img.alpha;

		for (potionButton in this.potionButtons)
		{
			potionButton.get(ImageComponent).alpha = img.alpha;
		}

		specialButton.get(ImageComponent).sprite.alpha = 
			currentTurn == WhoseTurn.Player ? img.alpha : 0;		
	}

	private function updateOpponentHealthText():Void
	{
		var text = '${this.opponent.getData("name")}: ${this.opponent.get(HealthComponent).currentHealth}';
		this.opponentHealthText.get(TextComponent).setText(text);
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
			this.opponent.get(HealthComponent).damage(damageThisRound);

			var ifDeadMessage:String = this.opponent.get(HealthComponent).currentHealth <= 0 ? '${this.opponent.getData("name")} dies!' : "";
			this.statusText.get(TextComponent).setText('Hit for ${damageThisRound} damage! ${ifDeadMessage} Defend yourself!');

			// Spawn new monster if dead
			if (this.opponent.get(HealthComponent).currentHealth <= 0)
			{
				this.entities.remove(this.opponent);
				this.opponent = new Monster();
				this.entities.push(this.opponent);
			}

			this.updateOpponentHealthText();
		}
		else
		{
			this.player.get(HealthComponent).damage(damageThisRound);	
			this.statusText.get(TextComponent).setText('Got hit for ${damageThisRound} damage! ATTACK!');
			this.updateHealthDisplay();

			if (this.player.get(HealthComponent).currentHealth <= 0)
			{
				this.entities.push(new Entity().image("assets/images/overlay.png"));
				this.entities.push(new Entity().text("GAME OVER", 72).move(40, 250));
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
		this.healthText.get(TextComponent).setText('Health: ${this.player.get(HealthComponent).currentHealth}');
	}
}

enum WhoseTurn
{
	Player;
	Monster;
}