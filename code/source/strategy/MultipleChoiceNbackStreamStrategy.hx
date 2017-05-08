package strategy;

import flixel.math.FlxRandom;
import flixel.util.FlxColor;

import turbo.Config;
import turbo.ecs.components.TextComponent;
import turbo.ecs.Entity;


import PlayState; // whoseturn

class MultipleChoiceNbackStreamStrategy
{
    private var onRoundEnd:Int->Void; // callback to PlayState, receives damage
    private var getCurrentTurn:Void->WhoseTurn; // Callback to PlayState. Receives who's turn it is.

    // From config.json. But Config.get(...) throws null if used here.
	// Probably because openfl didn't load assets yet or something.
    
	private var DAMAGE_PER_ATTACK:Int;
	private var DAMAGE_PER_MISSED_ATTACK:Int;
    private var DAMAGE_PER_BLOCK:Int;
	private var DAMAGE_PER_MISSED_BLOCK:Int;
    private var LETTERS_PER_TURN:Int;

    private var uniqueLettersPercent:Int;
	private var uniqueLettersPercentGrowth:Int;

    // Turn: every time you pick one letter out of four.
    // Round: a set of 5 turns that aggregate damage.
	private var turnsCount:Int;
	private var turnsGrowthPerRound:Int;

    private var random:FlxRandom = new FlxRandom();
    
    private var ALL_LETTERS = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K",
        "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"];

    // Letters picked by the PLAYER this round!
    private var lettersPickedThisRound = new Array<String>();
    // Letters for this turn, like right now
    private var currentTurnLetters = new Array<String>();

    // UI controls
    private var currentLetterDisplay:Array<Entity>;
    private var status:Entity;
    
    private var damageThisRound:Int = 0;

    public function new() { }

    public function create(entities:Array<Entity>, onRoundEnd:Int->Void, getCurrentTurn:Void->WhoseTurn)
    {
        DAMAGE_PER_ATTACK = Config.get("streamDamagePerHit");
		DAMAGE_PER_MISSED_ATTACK = Config.get("streamDamagePerMiss");
        DAMAGE_PER_BLOCK = Config.get("streamDamagePerBlock");
		DAMAGE_PER_MISSED_BLOCK = Config.get("streamDamagePerMissedBlock");
        
        uniqueLettersPercent = Config.get("multiNbackUniqueLettersPercent");		
		turnsCount = Config.get("streamTotalLettersCount");
		turnsGrowthPerRound = Config.get("streamTotalLettersGrowth");

        LETTERS_PER_TURN = Config.get("multiNbackLettersPerTurn");

        this.onRoundEnd = onRoundEnd;
        this.getCurrentTurn = getCurrentTurn;

        this.currentLetterDisplay = new Array<Entity>();
        this.currentLetterDisplay.push(new Entity().text("", 72).hide().move(200, 100));
        this.currentLetterDisplay.push(new Entity().text("", 72).hide().move(250, 100));
        this.currentLetterDisplay.push(new Entity().text("", 72).hide().move(200, 150));
        this.currentLetterDisplay.push(new Entity().text("", 72).hide().move(250, 150));
        
        this.status = new Entity().text("").hide().move(150, 275);

        for (ui in this.currentLetterDisplay)
        {
            entities.push(ui);
        }
        entities.push(this.status);
    }

    public function onPlayButtonClicked()
    {
        this.generateLettersForThisTurn();        
        for (ui in this.currentLetterDisplay)
        {
            ui.show();
        }
        this.showCurrentTurn();
    }

    private function showCurrentTurn():Void
    {
        for (i in 0 ... this.LETTERS_PER_TURN)
        {
            var ui = this.currentLetterDisplay[i];
            ui.text(this.currentTurnLetters[i]);
            trace('${i} => ${this.currentTurnLetters[i]}');
        }
    }
    
    private function generateLettersForThisTurn():Void
    {
        this.currentTurnLetters = new Array<String>();

        if (this.lettersPickedThisRound.length == 0)
        {
            // special case: everything is unique (nothing done yet)
            while (this.currentTurnLetters.length < LETTERS_PER_TURN)
            {
                this.currentTurnLetters.push(this.random.getObject(ALL_LETTERS));
            }
        }
        else
        {
            // Guarantee at least one unique letter
            var uniqueCount = Std.int(Math.round(uniqueLettersPercent * LETTERS_PER_TURN / 100));
            
            var nonUniqueCount = LETTERS_PER_TURN - uniqueCount;
            
            while (uniqueCount-- > 0)
            {                
                this.currentTurnLetters.push(this.getUniqueLetter());
            }            

            while (nonUniqueCount-- > 0)
            {
                this.currentTurnLetters.push(this.getNonUniqueLetter());
            }

            random.shuffle(this.currentTurnLetters);
        }
    }

    private function getUniqueLetter():String
    {
        var toReturn = random.getObject(ALL_LETTERS);
        while (this.lettersPickedThisRound.indexOf(toReturn) > -1)
        {
            toReturn = random.getObject(ALL_LETTERS);
        }
        trace('unique: ${toReturn}');
        return toReturn;
    }

    private function getNonUniqueLetter():String
    {
        if (this.lettersPickedThisRound.length == 0)
        {
            // There's no such thing as non-unique.
            trace('non-unique: anything');
            return random.getObject(ALL_LETTERS);
        }

        var toReturn = random.getObject(this.lettersPickedThisRound);
        trace('non-unique: ${toReturn}');
        return toReturn;
    }
        
    private function checkChoiceForDamage(shouldBeUnique:Bool):Void
    {
        /*
        var whoseTurn = this.getCurrentTurn();

        var currentLetter = this.lettersThisRound[this.currentLetterIndex];
        if (this.isUnique(currentLetter, this.currentLetterIndex) == shouldBeUnique)
        {
            if (whoseTurn == WhoseTurn.Player)
            {
                damageThisRound += DAMAGE_PER_ATTACK;
            }
            else
            {
                damageThisRound += DAMAGE_PER_BLOCK; // total block
            }
            this.status.text("Right").clearAfterEvents().after(0.75, function() { this.status.text(""); });
        } 
        else
        {
            if (whoseTurn == WhoseTurn.Player)
            {
                damageThisRound += DAMAGE_PER_MISSED_ATTACK;                
            }
            else
            {
                damageThisRound += DAMAGE_PER_MISSED_BLOCK;
            }
            this.status.text("WRONG!").clearAfterEvents().after(0.75, function() { this.status.text(""); });
        }
        
        this.currentLetterIndex++;
        if (this.currentLetterIndex < this.lettersThisRound.length)
        {
            this.generateLettersForThisTurn();
        }
        else
        {
            // Round is OVER!
            for (ui in this.currentLetterDisplay)
            {
                ui.hide();
            }
                        
            this.onRoundEnd(this.damageThisRound);

            this.damageThisRound = 0;
            this.currentLetterIndex = 0;

            // next round is harder
            turnsCount += turnsGrowthPerRound;            
        }
        */
    }
}