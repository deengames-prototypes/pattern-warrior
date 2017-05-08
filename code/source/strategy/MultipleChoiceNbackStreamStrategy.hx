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

    private var lettersPickedThisRound = ['S', 'A'];//new Array<String>();
    private var currentTurnLetters = new Array<String>();

    // UI controls
    private var currentLetterDisplay:Entity;
    private var isUniqueButton:Entity;
    private var isntUniqueButton:Entity;
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

        this.currentLetterDisplay = new Entity().text("", 72).hide().move(200, 150);
        
        this.isUniqueButton = new Entity().text("Unique").hide().move(8, 200).onClick(function(x, y)
        {
            if (this.isUniqueButton.get(TextComponent).text.alpha > 0)
            {
                this.checkChoiceForDamage(true);  
            }
        }, false);
        
        this.isntUniqueButton = new Entity().text("Not Unique").hide().move(216, 200).onClick(function(x, y)
        {
            if (this.isUniqueButton.get(TextComponent).text.alpha > 0)
            {
                this.checkChoiceForDamage(false);  
            }
        }, false);

        this.status = new Entity().text("").hide().move(150, 275);

        entities.push(this.currentLetterDisplay);
        entities.push(this.isUniqueButton);
        entities.push(this.isntUniqueButton);
        entities.push(this.status);
    }

    public function onPlayButtonClicked()
    {
        this.generateLettersForThisTurn();        
        this.currentLetterDisplay.show();
        this.isUniqueButton.show();
        this.isntUniqueButton.show();
    }
    
    private function generateLettersForThisTurn():Void
    {
        this.currentTurnLetters = new Array<String>();

        if (this.lettersPickedThisRound.length == 0)
        {
            // special case: everything is unique
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
            this.currentLetterDisplay.hide();
            this.isUniqueButton.hide();
            this.isntUniqueButton.hide();
                        
            this.onRoundEnd(this.damageThisRound);

            this.damageThisRound = 0;
            this.currentLetterIndex = 0;

            // next round is harder
            turnsCount += turnsGrowthPerRound;            
        }
        */
    }
}