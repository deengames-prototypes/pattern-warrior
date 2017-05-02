package strategy;

import flixel.math.FlxRandom;
import flixel.util.FlxColor;

import turbo.Config;
import turbo.ecs.components.TextComponent;
import turbo.ecs.Entity;


import PlayState; // whoseturn

class NbackStreamStrategy
{
    private var onRoundEnd:Int->Void; // callback to PlayState, receives damage
    private var getCurrentTurn:Void->WhoseTurn; // Callback to PlayState. Receives who's turn it is.

    // From config.json. But Config.get(...) throws null if used here.
	// Probably because openfl didn't load assets yet or something.
    
	private var DAMAGE_PER_ATTACK:Int;
	private var DAMAGE_PER_MISSED_ATTACK:Int;
    private var DAMAGE_PER_BLOCK:Int;
	private var DAMAGE_PER_MISSED_BLOCK:Int;

    private var uniqueLettersPercent:Int;
	private var uniqueLettersPercentGrowth:Int;

	private var lettersThisRoundCount:Int;
	private var lettersThisRoundGrowth:Int;

    private var random:FlxRandom = new FlxRandom();
    private var lettersThisRound:Array<String>;

    private var ALL_LETTERS = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K",
        "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"];

    private var currentLetterIndex:Int = 0;

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
        
        uniqueLettersPercent = Config.get("streamUniqueLettersPercent");
		uniqueLettersPercentGrowth = Config.get("streamUniqueLettersPercentGrowth");
		lettersThisRoundCount = Config.get("streamTotalLettersCount");
		lettersThisRoundGrowth = Config.get("streamTotalLettersGrowth");

        this.onRoundEnd = onRoundEnd;
        this.getCurrentTurn = getCurrentTurn;

        this.currentLetterDisplay = new Entity().text("", 72).hide().move(225, 150);
        
        this.isUniqueButton = new Entity().text("Unique").hide().move(50, 200).onClick(function(x, y)
        {
            if (this.isUniqueButton.get(TextComponent).text.alpha > 0)
            {
                this.checkCurrentLetterUnique(true);  
            }
        }, false);
        
        this.isntUniqueButton = new Entity().text("Not Unique").hide().move(300, 200).onClick(function(x, y)
        {
            if (this.isUniqueButton.get(TextComponent).text.alpha > 0)
            {
                this.checkCurrentLetterUnique(false);  
            }
        }, false);

        this.status = new Entity().text("").hide().move(150, 250);

        entities.push(this.currentLetterDisplay);
        entities.push(this.isUniqueButton);
        entities.push(this.isntUniqueButton);
        entities.push(this.status);
    }

    public function onPlayButtonClicked()
    {
        this.generateLettersForThisRound();        
        this.currentLetterDisplay.show();
        this.isUniqueButton.show();
        this.isntUniqueButton.show();
        this.showCurrentLetter();
    }
    
    private function showCurrentLetter():Void
    {
        this.currentLetterDisplay.text(this.lettersThisRound[this.currentLetterIndex]);
    }

    private function generateLettersForThisRound():Void
    {
	    var uniqueLettersCount:Int = Std.int(Math.round(lettersThisRoundCount * uniqueLettersPercent / 100));

        // Get all the unique letters for this round
        this.lettersThisRound = new Array<String>();
        while (lettersThisRound.length < uniqueLettersCount)
        {
            var candidate = random.getObject(ALL_LETTERS);
            // new unique letter
            if (lettersThisRound.indexOf(candidate) == -1)
            {
                lettersThisRound.push(candidate);
            }
        }
        
        // Repeat existing letters, until full
        while (lettersThisRound.length < lettersThisRoundCount)
        {
            var dupe = random.getObject(lettersThisRound);    
            lettersThisRound.push(dupe); 
        }

        random.shuffle(lettersThisRound);
    }
    
    private function isUnique(letter:String, atIndex:Int):Bool
    {
        var currentRoundString = "";
        for (i in 0 ... atIndex + 1)
        {
            var letter = lettersThisRound[i];
            currentRoundString += letter;
        }
    
        // Consider the subset of letters 0..n for n = atIndex.
        // If indexOf(n) == lastIndexOf(n), the letter is unique.
        var toReturn = currentRoundString.indexOf(letter) == currentRoundString.lastIndexOf(letter);
        return toReturn;
    }
    
    private function checkCurrentLetterUnique(shouldBeUnique:Bool):Void
    {
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
            this.showCurrentLetter();
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
            uniqueLettersPercent += uniqueLettersPercentGrowth;
            lettersThisRoundCount += lettersThisRoundGrowth;            
        }
    }
}