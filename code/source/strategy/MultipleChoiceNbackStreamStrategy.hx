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
    private var LETTER_POSITIONS = [[250, 100], [200, 150], [300, 150], [250, 200]];

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
        for (i in 0 ... LETTERS_PER_TURN)
        {
            var x = LETTER_POSITIONS[i][0];
            var y = LETTER_POSITIONS[i][1];
            // needs text to handle clicks...
            var e = new Entity().text("??", 72).hide().move(x, y);
            e.onClick(function(a, b)
            {
                this.checkChoiceForDamage(i);
            }, false);
            this.currentLetterDisplay.push(e);
        }

        this.status = new Entity().text("").hide().move(25, 32);

        for (ui in this.currentLetterDisplay)
        {
            entities.push(ui);
        }
        entities.push(this.status);
    }

    public function onPlayButtonClicked()
    {
        this.generateLettersForThisTurn();        
        this.showCurrentTurn();
    }

    private function showCurrentTurn():Void
    {
        for (i in 0 ... this.LETTERS_PER_TURN)
        {
            var ui = this.currentLetterDisplay[i];
            ui.show();
            ui.text(this.currentTurnLetters[i]);
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
        return toReturn;
    }

    private function getNonUniqueLetter():String
    {
        if (this.lettersPickedThisRound.length == 0)
        {
            // There's no such thing as non-unique.
            return random.getObject(ALL_LETTERS);
        }

        var toReturn = random.getObject(this.lettersPickedThisRound);
        return toReturn;
    }

    private function isUnique(letter:String):Bool
    {
        return this.lettersPickedThisRound.indexOf(letter) == -1;
    }
        
    private function checkChoiceForDamage(index:Int):Void
    {
        var letter = this.currentTurnLetters[index];
        var whoseTurn = this.getCurrentTurn();

        if (this.isUnique(letter))
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

        this.lettersPickedThisRound.push(letter);
        
        if (this.lettersPickedThisRound.length < this.turnsCount)
        {
            this.generateLettersForThisTurn();
            this.showCurrentTurn();
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
            this.lettersPickedThisRound = new Array<String>();

            // next round is harder
            turnsCount += turnsGrowthPerRound;            
        }
    }
}