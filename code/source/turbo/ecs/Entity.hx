package turbo.ecs;

import turbo.ecs.components.AbstractComponent;
import turbo.ecs.components.ColourComponent;
import turbo.ecs.components.HealthComponent;
import turbo.ecs.components.ImageComponent;
import turbo.ecs.components.PositionComponent;
import turbo.ecs.components.KeyboardInputComponent;
import turbo.ecs.components.CameraComponent;
import turbo.ecs.components.MouseClickComponent;

class Entity
{
    private var components:Map<String, AbstractComponent>;
    private var tags(default, null):Array<String>;
    
    public function new()
    {
        this.components = new Map<String, AbstractComponent>();
        this.tags = [];
    }
        
    ////////////////////// Start fluent API //////////////////////
    // Please sort alphabetically
    
    // Calling colour without calling size (or vice-versa) should give sensible results
    // The default is a 32x32 red square
    public function colour(red:Int, green:Int, blue:Int):Entity
    {
        if (!this.has(ColourComponent))
        {
            this.add(new ColourComponent(red, green, blue, 32, 32, this)); // default size
        }
        else
        {        
            var c = this.get(ColourComponent);
            this.add(new ColourComponent(red, green, blue, c.width, c.height, this));
        }

        if (!this.has(PositionComponent))
        {
            this.add(new PositionComponent(0, 0, this));
        }

        return this;
    }
    
    public function health(maximumHealth:Int):Entity
    {
        this.add(new HealthComponent(maximumHealth, this));
        return this;
    }
    
    public function image(image:String, repeat:Bool = false):Entity
    {
        this.add(new ImageComponent(image, repeat, this));
        if (!this.has(PositionComponent))
        {
            this.add(new PositionComponent(0, 0, this));
        }
        return this;
    }
    
    public function move(x:Int, y:Int):Entity
    {
        this.add(new PositionComponent(x, y, this));
        
        this.onEvent("Moved");

        return this;
    } 
    
    // MoveSpeed is in pixels per second
    public function moveWithKeyboard(moveSpeed:Int):Entity
    {
        this.add(new KeyboardInputComponent(moveSpeed, this));
        return this;
    }
    
    public function onClick(callback:Float->Float->Void):Entity
    {
        var mouseComponent:MouseClickComponent = new MouseClickComponent(callback, null, this);
        this.add(mouseComponent);
        return this;
    }
    
    public function size(width:Int, height:Int):Entity
    {
        if (!this.has(ColourComponent))
        {
            this.add(new ColourComponent(255, 0, 0, width, height, this)); // default colour
        }
        else
        {
            var c = this.get(ColourComponent);
            var clr = c.colour;
            
            this.remove(ColourComponent);
            ColourComponent.onRemove(c);
            
            this.add(new ColourComponent(clr.red, clr.green, clr.blue, width, height, this));   
        }        

        if (!this.has(PositionComponent))
        {
            this.add(new PositionComponent(0, 0, this));
        }

        return this;
    }

    public function trackWithCamera():Entity
    {
        this.add(new CameraComponent(this));
        return this;
    }
    
    /////////////////////// End fluent API ///////////////////////


    
    // You can only have one of each component by type
    public function add(component:AbstractComponent):Entity
    {
        var clazz = Type.getClass(component);
        var name = Type.getClassName(clazz);
        if (!this.has(clazz))
        {
            this.components.set(name, component);
        }
        return this;
    }
    
    /**
    Remove a component from this entity. (eg. e.remove(SpriteComponent))
    Does nothing if the component doesn't have that entity.
    */
    public function remove(clazz:Class<AbstractComponent>):Entity
    {
        var name = Type.getClassName(clazz);
        this.components.remove(name);
        return this;
    }
    
    // c is a Class<AbstractComponent> eg. SpriteComponent
    public function get<T>(clazz:Class<T>):T
    {
        var name:String = Type.getClassName(clazz);
        var toReturn:AbstractComponent = this.components.get(name);
        
        if (toReturn == null)
        {
            // Don't have the exact type. Maybe we have a subtype?
            // eg. asked for SpriteComponent when we have ImageComponent
            for (component in this.components)
            {
                if (Std.is(component, clazz))
                {
                    return cast(component);
                }                
            }
        }
        
        return cast(toReturn);
    }
    
    public function has(clazz:Class<AbstractComponent>):Bool
    {
        return this.get(clazz) != null;
    }

    public function onEvent(event:String):Void
    {
        for (component in this.components)
        {
            component.onEvent(event);
        }
    }

    public function update(elapsedSeconds:Float):Void
    {
        for (component in this.components)
        {
            component.update(elapsedSeconds);
        }
    }
}