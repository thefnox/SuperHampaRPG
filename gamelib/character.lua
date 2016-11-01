the.NPCs = {}
the.Party = {}

Player = PartyUnit:extend
{
    handler = "player",
    fullname = "Yonaiker",
    portrait = "images/player.png",
    facing = "up",
    width = 32,
    height = 64,
    image = 'images/spritetest.png',
    stats = {
        attack = 12,
        defense = 12,
        agility = 10,
        hp = 15,
        mp = 0,
        attackrange = 1,
        attacktype = "melee",
        moverange = 3,
    },
    progression = {
        [2] = {
            ["experience"] = 100,
            ["attack"] = 2,
        },
        [3] = {
            ["experience"] = 300,
            ["defense"] = 2,
            ["agility"] = 2,
        },
        [4] = {
            ["experience"] = 450,
            ["attack"] = 3,
        },
        [5] = {
            ["experience"] = 750,
            ["agility"] = 3,
            ["attack"] = 3
        }
    },
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
    DoTalk = function(self)
        self:CloseMenu()
        local obj
        if self.facing == "up" then
            obj = the.view:FindObjectInRectangle(self.x, self.y - 64, 32, 64, self)
        elseif self.facing == "left" then
            obj = the.view:FindObjectInRectangle(self.x-64, self.y + 16, 64, 32, self)
        elseif self.facing == "down" then
            obj = the.view:FindObjectInRectangle(self.x, self.y + 64, 32, 64, self)
        elseif self.facing == "right" then
            obj = the.view:FindObjectInRectangle(self.x+32, self.y + 16, 64, 32, self)
        end
        if not obj then
            DisplayDialogue("No hay nadie con quien hablar.", nil, "n")
        else
            if obj.onTalk then
                obj.onTalk()
            else
                DisplayDialogue("No hay nadie con quien hablar.", nil, "n")
            end
        end
        --the.view:FindObjectInRectangle(self.x, self.y)
    end,
    DoExamine = function(self)
        self:CloseMenu()
        local obj
        if self.facing == "up" then
            obj = the.view:FindObjectInRectangle(self.x, self.y - 64, 32, 64, self)
        elseif self.facing == "left" then
            obj = the.view:FindObjectInRectangle(self.x-64, self.y + 16, 64, 32, self)
        elseif self.facing == "down" then
            obj = the.view:FindObjectInRectangle(self.x, self.y + 64, 32, 64, self)
        elseif self.facing == "right" then
            obj = the.view:FindObjectInRectangle(self.x+32, self.y + 16, 64, 32, self)
        end
        if not obj then
            DisplayDialogue("No hay nada que examinar.", nil, "n")
        else
            if obj.onExamine then
                obj.onExamine()
            else
                DisplayDialogue("No hay nada que examinar.", nil, "n")
            end
        end
    end,
    ShowUse = function(self)
        self:CloseMenu(true)
        the.app.LockInput = true
        self.Menu = loveframes.Create("panel")
        self.Menu:SetSize(the.app.width/3, the.app.height/4)
        self.Menu:SetPos(the.app.width*1/3, the.app.width*2/4)
        self.Menu.Up = loveframes.Create("button", self.Menu)
        self.Menu.Draw = function( ) end
        self.Menu.Up:SetSize(self.Menu:GetWidth()/3, self.Menu:GetWidth()/3)
        self.Menu.Up:SetPos(self.Menu:GetWidth()*1/3, 0)
        if self.inventory[1] and self.inventory[1].name then
            self.Menu.Up:SetText(self.inventory[1].name)
        else
            self.Menu.Up:SetText("(Nada)")
        end
        self.Menu.Up.OnClick = function()
            self:DoUse(1)
        end
        self.Menu.Left = loveframes.Create("button", self.Menu)
        self.Menu.Left:SetSize(self.Menu:GetWidth()/3, self.Menu:GetWidth()/3)
        self.Menu.Left:SetPos(0, self.Menu:GetHeight()*1/3)
        if self.inventory[2] and self.inventory[2].name then
            self.Menu.Left:SetText(self.inventory[2].name)
        else
            self.Menu.Left:SetText("(Nada)")
        end
        self.Menu.Left.OnClick = function()
            self:DoUse(2)
        end
        self.Menu.Down = loveframes.Create("button", self.Menu)
        self.Menu.Down:SetSize(self.Menu:GetWidth()/3, self.Menu:GetWidth()/3)
        self.Menu.Down:SetPos(self.Menu:GetWidth()*1/3, self.Menu:GetHeight()*2/3)
        if self.inventory[3] and self.inventory[3].name then
            self.Menu.Down:SetText(self.inventory[3].name)
        else
            self.Menu.Down:SetText("(Nada)")
        end
        self.Menu.Down.OnClick = function()
            self:DoUse(3)
        end
        self.Menu.Right = loveframes.Create("button", self.Menu)
        self.Menu.Right:SetSize(self.Menu:GetWidth()/3, self.Menu:GetWidth()/3)
        self.Menu.Right:SetPos(self.Menu:GetWidth()*2/3, self.Menu:GetHeight()*1/3)
        if self.inventory[4] and self.inventory[4].name then
            self.Menu.Right:SetText(self.inventory[4].name)
        else
            self.Menu.Right:SetText("(Nada)")
        end
        self.Menu.Right.OnClick = function()
            self:DoUse(4)
        end
        self.Menu.SelectOption = function(object, option)
            if object[option] then
                self.Menu.SelectedOption = self.Menu[option]
                self.Menu[option].hover = true
            end
        end
    end,
    DoUse = function(self, item)
        self:CloseMenu()
        if not self.inventory[item] then
            DisplayDialogue("No tienes ningun item en esa posicion.", nil, "n")
        else
            local obj
            if self.facing == "up" then
                obj = the.view:FindObjectInRectangle(self.x, self.y - 64, 32, 64, self)
            elseif self.facing == "left" then
                obj = the.view:FindObjectInRectangle(self.x-64, self.y + 16, 64, 32, self)
            elseif self.facing == "down" then
                obj = the.view:FindObjectInRectangle(self.x, self.y + 64, 32, 64, self)
            elseif self.facing == "right" then
                obj = the.view:FindObjectInRectangle(self.x+32, self.y + 16, 64, 32, self)
            end
            if not obj then
                DisplayDialogue("No hay nada en que usar esto.", nil, "n")
            else
                if obj.onExamine then
                    obj.onUse(self.inventory[item])
                else
                    DisplayDialogue("Esta persona no necesita de tu item.", nil, "n")
                end
            end
        end
    end,
    ShowEquip = function(self)
        self:CloseMenu(true)
        the.app.LockInput = true
        self.Menu = loveframes.Create("panel")
        self.Menu:SetSize(the.app.width/3, the.app.height/4)
        self.Menu:SetPos(the.app.width*1/3, the.app.width*2/4)
        self.Menu.Up = loveframes.Create("button", self.Menu)
        self.Menu.Draw = function( ) end
        self.Menu.Up:SetSize(self.Menu:GetWidth()/3, self.Menu:GetWidth()/3)
        self.Menu.Up:SetPos(self.Menu:GetWidth()*1/3, 0)
        self.Menu.Up:SetText("Equip")
        self.Menu.Up.OnClick = function()
            self:ShowEquipMenu()
        end
        self.Menu.Left = loveframes.Create("button", self.Menu)
        self.Menu.Left:SetSize(self.Menu:GetWidth()/3, self.Menu:GetWidth()/3)
        self.Menu.Left:SetPos(0, self.Menu:GetHeight()*1/3)
        self.Menu.Left:SetText("Info")
        self.Menu.Left.OnClick = function()
            self:ShowInfoMenu()
        end
        self.Menu.Down = loveframes.Create("button", self.Menu)
        self.Menu.Down:SetSize(self.Menu:GetWidth()/3, self.Menu:GetWidth()/3)
        self.Menu.Down:SetPos(self.Menu:GetWidth()*1/3, self.Menu:GetHeight()*2/3)
        self.Menu.Down:SetText("Move")
        self.Menu.Down.OnClick = function()
            self:ShowMoveMenu()
        end
        self.Menu.Right = loveframes.Create("button", self.Menu)
        self.Menu.Right:SetSize(self.Menu:GetWidth()/3, self.Menu:GetWidth()/3)
        self.Menu.Right:SetPos(self.Menu:GetWidth()*2/3, self.Menu:GetHeight()*1/3)
        self.Menu.Right:SetText("Drop")
        self.Menu.Right.OnClick = function()
            self:ShowDropMenu()
        end
        self.Menu.SelectOption = function(object, option)
            if object[option] then
                self.Menu.SelectedOption = self.Menu[option]
                self.Menu[option].hover = true
            end
        end
    end,
    ShowEquipMenu = function(self)
        self:CloseMenu(true)
    end,
    ShowInfoMenu = function(self)
        self:CloseMenu(true)
    end,
    ShowDropMenu = function(self)
        self:CloseMenu(true)
    end,
    ShowMoveMenu = function(self)
        self:CloseMenu(true)
    end,
    ShowMenu = function (self, nosound)
        for _, npc in pairs(the.NPCs) do
            npc.lastvelocityx = npc.velocity.x
            npc.lastvelocityy = self.velocity.y
            npc.velocity.x=0
            npc.velocity.y=0
        end
        if not nosound then playSound("sounds/menuopen.wav") end
        the.app.LockInput = true
        self.Menu = loveframes.Create("panel")
        self.Menu.StartMenu = true
        self.Menu:SetSize(the.app.width/3, the.app.height/4)
        self.Menu:SetPos(the.app.width*1/3, the.app.width*2/4)
        self.Menu.Up = loveframes.Create("button", self.Menu)
        self.Menu.Draw = function( ) end
        self.Menu.Up:SetSize(self.Menu:GetWidth()/3, self.Menu:GetWidth()/3)
        self.Menu.Up:SetPos(self.Menu:GetWidth()*1/3, 0)
        self.Menu.Up:SetText("Talk")
        self.Menu.Up.OnClick = function()
            self:DoTalk()
        end
        self.Menu.Left = loveframes.Create("button", self.Menu)
        self.Menu.Left:SetSize(self.Menu:GetWidth()/3, self.Menu:GetWidth()/3)
        self.Menu.Left:SetPos(0, self.Menu:GetHeight()*1/3)
        self.Menu.Left:SetText("Examine")
        self.Menu.Left.OnClick = function()
            self:DoExamine()
        end
        self.Menu.Down = loveframes.Create("button", self.Menu)
        self.Menu.Down:SetSize(self.Menu:GetWidth()/3, self.Menu:GetWidth()/3)
        self.Menu.Down:SetPos(self.Menu:GetWidth()*1/3, self.Menu:GetHeight()*2/3)
        self.Menu.Down:SetText("Use")
        self.Menu.Down.OnClick = function()
            self:ShowUse()
        end
        self.Menu.Right = loveframes.Create("button", self.Menu)
        self.Menu.Right:SetSize(self.Menu:GetWidth()/3, self.Menu:GetWidth()/3)
        self.Menu.Right:SetPos(self.Menu:GetWidth()*2/3, self.Menu:GetHeight()*1/3)
        self.Menu.Right:SetText("Equip")
        self.Menu.Right.OnClick = function()
            self:ShowEquip()
        end
        self.Menu.SelectOption = function(object, option)
            if object[option] then
                self.Menu.SelectedOption = self.Menu[option]
                self.Menu[option].hover = true
            end
        end
    end,
    CloseMenu = function (self, nosound)
        if not self.Menu then return end
        if not nosound then playSound("sounds/menuclose.wav") end
        self.Menu:SetVisible(false)
        the.app.LockInput = false
        self.Menu = nil
        self.JustClosedMenu = true
    end,
    onUpdate = function (self)
        if self.Menu then
            self.velocity.x = 0
            self.velocity.y = 0
            if the.keys:justPressed("up") then
                self.Menu:SelectOption("Up")
                playSound("sounds/menuselect.wav")
            elseif the.keys:justPressed("down") then
                self.Menu:SelectOption("Down")
                playSound("sounds/menuselect.wav")
            elseif the.keys:justPressed("left") then
               self.Menu:SelectOption("Left")
               playSound("sounds/menuselect.wav")
            elseif the.keys:justPressed("right") then
                self.Menu:SelectOption("Right")
                playSound("sounds/menuselect.wav")
            end
            if self.Menu.SelectedOption and (the.keys:justPressed(" ") or the.keys:justPressed("enter")) then
                self.Menu.SelectedOption:OnClick()
            end
            if the.keys:justPressed("escape") then
                if self.Menu.StartMenu then
                    self:CloseMenu()
                else
                    playSound("sounds/menudecline.wav")
                    self:CloseMenu(true)
                    self:ShowMenu(true)
                end
            end
        end
        if not the.app.LockInput then
            self.velocity.x = 0
            self.velocity.y = 0
            if the.keys:pressed("up") then
                self.facing = "up"
                self.velocity.y = -200
                self:play("up")
            elseif the.keys:pressed("down") then
                self.facing = "down"
                self.velocity.y = 200
                self:play("down")
            elseif the.keys:pressed("left") then
                self.facing = "left"
                self.velocity.x = -200
                self:play("left")
            elseif the.keys:pressed("right") then
                self.facing = "right"
                self.velocity.x = 200
                self:play("right")
            end
            if the.keys:justReleased("up") then
                self.facing = "up"
                self:play("s_up")
            elseif the.keys:justReleased("down") then
                self.facing = "down"
                self:play("s_down")
            elseif the.keys:justReleased("left") then
                self.facing = "left"
                self:play("s_left")
            elseif the.keys:justReleased("right") then
                self.facing = "right"
                self:play("s_right")
            end
            if the.keys:justPressed(" ") and not self.JustClosedMenu then
                self:ShowMenu()
            end
            self.JustClosedMenu = false
        else
            self:freeze()
        end
    end,
    onCollide = function(self, other)
        if other:instanceOf(NPC) then
            other.velocity.x = 0
            other.velocity.y = 0
        end
    end,
    onNew = function(self)
        the.player = self
    end
}

NPC = Animation:extend
{
    onNew = function (self)
        if the.app.LockInput then
            self:freeze()
        end
        table.insert(the.NPCs, self)
        self.lastvelocityy = 0
        self.lastvelocityx = 0
        if not self.noroam then
            self.roamtimer = Timer:new()
            the.view:add(self.roamtimer)
            self.roamtimer:every(math.random(3, 5), function()
                if not self.forceanimation and not the.app.LockInput then    
                    local rand = math.random(1, 4)
                    if rand == 1 then self.velocity.x = 100
                    elseif rand == 2 then self.velocity.x = -100
                    elseif rand == 3 then self.velocity.y = 100
                    elseif rand == 4 then self.velocity.y = -100 end
                    local tmr = Timer:new()
                    the.view:add(tmr)

                    tmr:after(math.random(1,3), function()
                        self.lastvelocityx = self.velocity.x
                        self.lastvelocityy = self.velocity.y
                        self.velocity.x=0
                        self.velocity.y=0
                    end)
                end
            end)
        end
    end,
    onTalk = function (self)
        DisplayDialogue("Esta persona no tiene nada que decir.", nil, "n")
    end,
    onUse = function(self)
        DisplayDialogue("Esta persona no tiene ningun uso para esa item.", nil, "n")
    end,
    onExamine = function(self)
        DisplayDialogue("Solo es una persona normal.", nil, "n")
    end,
    onCollide = function(self, other)
        self:freeze()
        if other == the.player then
            self:displace(other)
        end
    end,
    onUpdate = function (self)
        if the.app.LockInput then
            self:freeze()
        end
        if not self.forceanimation then
            --walk
            if self.velocity.y > 0 then --down
                self:play("down")
            elseif self.velocity.y < 0 then --up
                self:play("up")
            elseif self.velocity.x > 0 then --right
                self:play("right")
            elseif self.velocity.x < 0 then --left
                self:play("left")
            else --stand
                if self.lastvelocityy > 0 then --down
                    self:play("s_down")
                elseif self.lastvelocityy < 0 then --up
                    self:play("s_up")
                elseif self.lastvelocityx > 0 then --right
                    self:play("s_right")
                elseif self.lastvelocityx < 0 then --left
                    self:play("s_left")
                end   
            end
        else
            self:play(self.forceanimation)
        end
    end
}