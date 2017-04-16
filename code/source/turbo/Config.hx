package turbo;

import openfl.Assets;

class Config
{
    public static var values;

    ///
    // There's no easy way to access a field by field name in Haxe.
    // Using reflection gives us deplorable runtime. So, cache.
    ///
    public static function get(key:String):Any
    {
        if (values == null)
        {
            trace("Loading cache");
            loadAndCacheJson();
        }

        var toReturn = values.get(key);
        trace("Toreturn = " + toReturn);
        return toReturn;
    }

    private static function loadAndCacheJson():Void
    {
        values = new Map<String, Any>();
        var text = openfl.Assets.getText("assets/data/config.json");
        var json = haxe.Json.parse(text);
        // Inspired by JsonPrinter.objString
        var fields = Reflect.fields(json);
        for (i in 0 ... fields.length)
        {
            var name:String = fields[i];
			var value = Reflect.field(json, name);
            values.set(name, value);
        }
    }
}