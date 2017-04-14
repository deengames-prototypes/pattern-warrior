package turbo.ecs.components;

import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import turbo.ecs.components.SpriteComponent;

class ImageComponent extends SpriteComponent
{
    // Used to auto-add to the current state
    public static var onAdd:ImageComponent->Void;

    public var image:String = "";
    
    // internal
    public var isRepeating:Bool;

    public function new(fileName:String,isRepeating:Bool = false, parent:Entity)
    {
        super(parent);
        this.image = fileName;
        this.isRepeating = isRepeating;

        if (this.isRepeating)
        {
            this.sprite = new FlxBackdrop(this.image) ;
        }
        else
        {
            this.sprite = new FlxSprite(0, 0, this.image);
        }

        if (ImageComponent.onAdd != null)
        {
            ImageComponent.onAdd(this);
        }
    }

    override public function onEvent(event:String)
    {
        super.onEvent(event);

        var position = this.parent.get(PositionComponent);
        this.sprite.x = position.x;
        this.sprite.y = position.y;        
    }
}