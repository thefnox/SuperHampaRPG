STRICT = true
DEBUG = true
require 'loveframes'
require 'zoetrope'
require 'gamelib/polygon'
require 'gamelib/unit'
require 'gamelib/gamemap'
require 'gamelib/dialogue'
require 'gamelib/worldmap'
require 'gamelib/character'
require 'gamelib/item'
require 'levels/test'
require 'levels/cave'
require 'gameover'
require 'introview'
require 'introscene'
require 'mainmenu'

function math.round(num) 
    if num >= 0 then return math.floor(num+.5) 
    else return math.ceil(num-.5) end
end

function SwitchView(view)
    the.app.view = view
    --loveframes.Clear()
end

the.app = App:new
{
    onRun = function (self)
        the.app.view = TestBattle:new()
    end,
    onUpdate = function (self)
    end
}