package strategy;

import flixel.math.FlxRandom;
import turbo.Config;
import turbo.ecs.Entity;
import PlayState; // whoseturn

class NbackStreamStrategy
{
    private var onRoundEnd:Int->Void; // callback to PlayState, receives damage
    private var getCurrentTurn:Void->WhoseTurn; // Callback to PlayState. Receives who's turn it is.

    // From config.json. But Config.get(...) throws null if used here.
	// Probably because openfl didn't load assets yet or something.
    
	private static var DAMAGE_PER_ATTACK:Int;
	private static var DAMAGE_PER_MISSED_ATTACK:Int;
	private static var DAMAGE_PER_MISSED_BLOCK:Int;

    private static var uniqueLettersPercent:Int;
	private static var uniqueLettersPercentGrowth:Int;

	private static var lettersThisRoundCount:Int;
	private static var lettersThisRoundGrowth:Int;

    private var random:FlxRandom = new FlxRandom();
    private var lettersThisRound:Array<String>;

    private var ALL_LETTERS = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K",
        "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"];

    // UI controls
    private var currentLetterDisplay:Entity;
    private var isUniqueButton:Entity;
    private var isntUniqueButton:Entity;

    public function new() { }

    public function create(entities:Array<Entity>, onRoundEnd:Int->Void, getCurrentTurn:Void->WhoseTurn)
    {
        DAMAGE_PER_ATTACK = Config.get("streamDamagePerHit");
		DAMAGE_PER_MISSED_ATTACK = Config.get("streamDamagePerMiss");
		DAMAGE_PER_MISSED_BLOCK = Config.get("streamDamagePerMissedBlock");
        
        uniqueLettersPercent = Config.get("streamUniqueLettersPercent");
		uniqueLettersPercentGrowth = Config.get("streamUniqueLettersPercentGrowth");
		lettersThisRoundCount = Config.get("streamlettersThisRoundCount");
		lettersThisRoundGrowth = Config.get("streamlettersThisRoundGrowth");

        this.onRoundEnd = onRoundEnd;
        this.getCurrentTurn = getCurrentTurn;

        this.generateLettersForThisRound();

        this.currentLetterDisplay = new Entity().text("A", 72).hide().move(250, 150);
        this.isUniqueButton = new Entity().text("Unique").hide().move(50, 300);
        this.isntUniqueButton = new Entity().text("Not Unique").hide().move(300, 300);

        entities.push(this.currentLetterDisplay);
        entities.push(this.isUniqueButton);
        entities.push(this.isntUniqueButton);
    }

    public function onPlayButtonClicked()
    {
        this.currentLetterDisplay.show();
        this.isUniqueButton.show();
        this.isntUniqueButton.show();
    }

    private function generateLettersForThisRound():Void
    {
	    var uniqueLettersCount:Int = Std.int(Math.round(lettersThisRoundCount * uniqueLettersPercent / 100));

        // Get all the unique letters for this round
        var lettersThisRound = new Array<String>();
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

        // next round is harder
        uniqueLettersPercent += uniqueLettersPercentGrowth;
        lettersThisRoundCount += lettersThisRoundGrowth;        
    }
}