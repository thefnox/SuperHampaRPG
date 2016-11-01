WorldMap = View:extend{
	mapfile = "",
    FindObjectInRectangle = function(self, x, y, w, h, ignore)
        for _, sprite in pairs(self.objects.sprites) do
            if sprite:intersects(x, y, w, h) and sprite ~= ignore and sprite:instanceOf(NPC) then
                return sprite
            end
        end
        return false
    end,
    onNew = function (self)
        the.currentlevel = self
        self:loadLayers(self.mapfile)
        self.objects.map = self
        self.focus = the.player
        self:clampTo(self.map)
    end,
    onUpdate = function (self)
        self.map:displace(the.player)
        for _, npc in pairs(the.NPCs) do
            self.map:displace(npc)
        end
        self.objects:collide(self.objects)
    end
}