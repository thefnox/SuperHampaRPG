TestNPC1 = NPC:extend{
    width = 32,
    height = 64,
    image = 'images/spritetest.png',
    sequences = 
    {
        s_down = { frames = {1}, fps = 1 },
        s_left = { frames = {7}, fps = 1 },
        s_up = { frames = {13}, fps = 1 },
        s_right = { frames = {19}, fps = 1 },
        down = { frames = {2, 3, 4, 5, 6}, fps = 10 },
        left = { frames = {8, 9, 10, 11, 12}, fps = 10 },
        up = { frames = {14, 15, 16, 17, 18}, fps = 10},
        right = { frames = {20, 21, 22, 23, 24}, fps = 10}
    },
    onTalk = function (self)
        DisplayDialogue("kelokeee pedazo de mamaguevo quien cono de madre de crees tu para hablarme asi becerro", "images/tuky.png", "r")
    end,
    onUse = function(self)
        DisplayDialogue("Esta persona no tiene ningun uso para esa item.", nil, "n")
    end,
    onExamine = function(self)
        DisplayDialogue("Tiene pinta de estupido el tipo este", nil, "n")
    end,
}


TestLevel = WorldMap:extend{
	mapfile = "maps/map1.lua"
}