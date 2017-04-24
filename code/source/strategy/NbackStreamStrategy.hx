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

	private static var totalLettersCount:Int;
	private static var totalLettersGrowth:Int;

    private var random:FlxRandom = new FlxRandom();
    private var lettersThisRound:Array<String>;

    private var ALL_LETTERS = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K",
        "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"];

    public function new() { }

    public function create(entities:Array<Entity>, onRoundEnd:Int->Void, getCurrentTurn:Void->WhoseTurn)
    {
        DAMAGE_PER_ATTACK = Config.get("streamDamagePerHit");
		DAMAGE_PER_MISSED_ATTACK = Config.get("streamDamagePerMiss");
		DAMAGE_PER_MISSED_BLOCK = Config.get("streamDamagePerMissedBlock");
        
        uniqueLettersPercent = Config.get("streamUniqueLettersPercent");
		uniqueLettersPercentGrowth = Config.get("streamUniqueLettersPercentGrowth");
		totalLettersCount = Config.get("streamTotalLettersCount");
		totalLettersGrowth = Config.get("streamTotalLettersGrowth");

        this.onRoundEnd = onRoundEnd;
        this.getCurrentTurn = getCurrentTurn;

        this.generateLettersForThisRound();
    }

    public function onPlayButtonClicked() {}

    private function generateLettersForThisRound():Void
    {
        this.lettersThisRound = new Array<String>();
	    var uniqueLettersCount:Int = Std.int(Math.round(totalLettersCount * uniqueLettersPercent / 100));

        // Get the total set of random letters this round
        var totalLetters = new Array<String>();
        while (totalLetters.length < uniqueLettersCount)
        {
            var candidate = random.getObject(ALL_LETTERS);
            // new unique letter
            if (totalLetters.indexOf(candidate) == -1)
            {
                totalLetters.push(candidate);
            }
        }
        
        // Repeat, until full
        while (totalLetters.length < totalLettersCount)
        {
            var dupe = random.getObject(totalLetters);    
            totalLetters.push(dupe); 
        }

        this.lettersThisRound = random.shuffleArray(totalLetters, totalLetters.length * 3);
        trace(this.lettersThisRound);

        // next round is harder
        uniqueLettersPercent += uniqueLettersPercentGrowth;
        totalLettersCount += totalLettersGrowth;        
    }
}