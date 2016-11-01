BattleUnit = Tile:extend{
    height = 64,
    width = 64,
    q = 0,
    r = 0,
    unit = nil,
    image = "images/battle_unit.png"
}

BattleMap = HexMap:extend{
	alpha = 100,
	units = {},
    battledata = {},
	partyspawnpositions = {},
	enemyspawnpositions = {},
	unitpositions = {},
	activeunit = nil,
	turnqueue = {},
    promise = Promise:new(),
    GameStart = function(self)
        self:NextInQueue()
    end,
    CheckWinningConditions = function(self)
        for _, char in pairs(self.units) do
            if char and char.unit and not char.unit.dead and char.unit.isenemy then
                return false
            end
        end
        return true
    end,
    CheckLosingConditions = function(self)
        for _, char in pairs(self.units) do
            if char and char.unit and not char.unit.dead and not char.unit.isenemy then
                return false
            end
        end
        return true
    end,
    FillQueue = function(self)
        self.turnqueue = {}
        for _, char in pairs(self.units) do
            if char.unit and not char.unit.dead then
                table.insert(self.turnqueue, char)
            end
        end
        table.sort(self.turnqueue, function(a, b)
            return a.unit.stats.agility > b.unit.stats.agility
        end)
    end,
	NextInQueue = function(self)
        if self.GameOver then return end
        if #self.turnqueue == 0 then
            self:FillQueue()
        end
        if self:CheckWinningConditions() then
            self.GameWon:fulfill()
            self.GameOver = true
            self:ClearColor()
            return
        end
        if self:CheckLosingConditions() then
            self.GameWon:fail()
            self.GameOver = true
            self:ClearColor()
            return            
        end
        local char = self.turnqueue[1]
        table.remove(self.turnqueue, 1)
        if char.unit.isenemy then
            self:ProcessEnemyTurn(char)
        else
            self:ProcessPlayerTurn(char)
        end
	end,
	ProcessPlayerTurn = function(self, char)
        if self.GameOver then return end
        print("DEBUG", char.unit.name, "TURN STARTED")
        the.view.focus = char
        self:ClearColor()
        self:CalculateMoves(char)
        self.ActiveCharacter = char
        local oldq = char.q
        local oldr = char.r
        print("DEBUG", "WAITING FOR MOVE")
        self.PickPromise = Promise:new()
        self.PickPromise:andThen(function(q, r)
            print("DEBUG", "MOVING CHARACTER")
            self.unitpositions[char.q][char.r] = nil
            self.unitpositions[q][r] = char
            char.q = q
            char.r = r
            char.x = self.hexes[q][r].x
            char.y = self.hexes[q][r].y
            self:ShowBattleMenu(self.ActiveCharacter, oldq, oldr)
        end)
        self.WaitingForHexSelection = true
        self.Selecting = true
	end,
    CalculateEnemyAttack = function(self, char)
        local visitedattack,attackhexes,strata
        if char.unit.stats.attacktype=="ranged" then
            visitedattack,attackhexes,strata = self:FindAllButAdyacents(char.q, char.r, char.unit.stats.attackrange)
        else
            visitedattack,attackhexes,strata = self:FindAllAdyacents(char.q, char.r, char.unit.stats.attackrange)
        end
        local results = {}
        local canattack = false
        for k, hex in pairs(attackhexes) do
            if not self.unitpositions[hex.coords.q][hex.coords.r] or self.unitpositions[hex.coords.q][hex.coords.r].unit.dead or self.unitpositions[hex.coords.q][hex.coords.r].unit.isenemy or self.unitpositions[hex.coords.q][hex.coords.r] == char then
                attackhexes[k] = nil
            else
                table.insert(results, hex)
                canattack = true
            end
        end
        return canattack, attackhexes
    end,
	ProcessEnemyTurn = function(self, char)
        if self.GameOver then return end
        self.PickPromise = nil
        print("DEBUG", char.unit.name, "TURN STARTED")
        self:ClearColor()
        local visitedmoves,movehexes,strata = self:FindAllInRange(char.q, char.r, char.unit.stats.moverange)
        print("DEBUG", "CALCULATING MOVES")
        local attackrange 
        local canattack, attackhexes = self:CalculateEnemyAttack(char)
        print("DEBUG", "CALCULATING ATTACKS")
        if canattack and char.unit.personality ~= "civilian" then
            print("DEBUG", "CAN ATTACK WITHOUT MOVING")
            table.sort(attackhexes, function(a, b)
                if not b then return true end
                if not a then return false end
                return self.unitpositions[a.coords.q][a.coords.r].health < self.unitpositions[b.coords.q][b.coords.r].health
            end)
            local target
            for _, hex in pairs(attackhexes) do
                target = hex
                break
            end
            local dmg, critical = CalculateDamage(char.unit, self.unitpositions[target.coords.q][target.coords.r].unit, math.max(0,target.weight-1)*10)
            print("DEBUG", "DAMAGE", dmg, "CRITICAL", critical)
            self.unitpositions[target.coords.q][target.coords.r].unit.health = math.max(0, self.unitpositions[target.coords.q][target.coords.r].unit.health - dmg)
            if self.unitpositions[target.coords.q][target.coords.r].unit.health == 0 then
                self.unitpositions[target.coords.q][target.coords.r].unit.dead = true
            end
            self:PostAttack(char.unit, self.unitpositions[target.coords.q][target.coords.r].unit, dmg, critical, self.unitpositions[target.coords.q][target.coords.r].unit.dead, target.coords.q, target.coords.r)
            --self:EndTurn(char.unit)
        else
            print("DEBUG", "CANNOT ATTACK WITHOUT MOVING")
            if char.unit.personality == "aggressive" then
                local closestenemy
                local mindistance = math.huge
                for _, char2 in pairs(self.units) do
                    if char2 and char2.unit and not char2.unit.dead and not char2.unit.isenemy then
                        print(char.q, char.r, char2.q, char2.r)
                        local distance = self:Distance(char.q, char.r, char2.q, char2.r)
                        if distance <= mindistance then
                            mindistance = distance
                            closestenemy = char2
                        end
                    end
                end
                print("DEBUG", "FOUND CLOSEST ENEMY")
                local hexinline, linevisited = self:FindInLine(char.q, char.r, closestenemy.q, closestenemy.r)
                local usefulmoves = false
                local maxdistance = -1
                local pickedhex
                for k, hex in pairs(movehexes) do
                    if not linevisited[hex.coords.q] or not linevisited[hex.coords.q][hex.coords.r] or self.unitpositions[hex.coords.q][hex.coords.r] then
                        movehexes[k] = nil
                    else
                        usefulmoves = true
                        local distance = self:Distance(char.q, char.r, hex.coords.q, hex.coords.r)
                        if distance > maxdistance then
                            maxdistance = distance
                            pickedhex = hex
                        end
                    end
                end
                if not usefulmoves then --pick random
                    local visitedmoves,movehexes,strata = self:FindAllInRange(char.q, char.r, char.unit.stats.moverange)
                    print("DEBUG", "MOVING CHARACTER TO RANDOM HEX")
                    shuffleTable(movehexes)
                    for k, hex in pairs(movehexes) do
                        if not self.unitpositions[hex.coords.q][hex.coords.r] then
                            pickedhex = hex
                            break
                        end
                    end
                    print(pickedhex, pickedhex.coords.q, pickedhex.coords.r)
                    if not self.unitpositions[char.q] then self.unitpositions[char.q] = {} end
                    self.unitpositions[char.q][char.r] = nil
                    if not self.unitpositions[pickedhex.coords.q] then self.unitpositions[pickedhex.coords.q] = {} end
                    self.unitpositions[pickedhex.coords.q][pickedhex.coords.r] = char
                    char.q = pickedhex.coords.q
                    char.r = pickedhex.coords.r
                    char.x = self.hexes[pickedhex.coords.q][pickedhex.coords.r].x
                    char.y = self.hexes[pickedhex.coords.q][pickedhex.coords.r].y
                    self:EndTurn(char.unit)
                else
                    --Check if can attack again
                    self.unitpositions[char.q][char.r] = nil
                    self.unitpositions[pickedhex.coords.q][pickedhex.coords.r] = char
                    char.q = pickedhex.coords.q
                    char.r =pickedhex.coords.r
                    char.x = self.hexes[pickedhex.coords.q][pickedhex.coords.r].x
                    char.y = self.hexes[pickedhex.coords.q][pickedhex.coords.r].y
                    canattack, attackhexes = self:CalculateEnemyAttack(char)
                    if canattack then
                        print("DEBUG", "CAN MOVE AND ATTACK")
                        table.sort(attackhexes, function(a, b)
                            if not b then return true end
                            if not a then return false end
                            return self.unitpositions[a.coords.q][a.coords.r].health < self.unitpositions[b.coords.q][b.coords.r].health
                        end)
                        local target
                        for _, hex in pairs(attackhexes) do
                            target = hex
                            break
                        end
                        local dmg, critical = CalculateDamage(char.unit, self.unitpositions[target.coords.q][target.coords.r].unit, math.max(0,target.weight-1)*10)
                        print("DEBUG", "DAMAGE", dmg, "CRITICAL", critical)
                        self.unitpositions[target.coords.q][target.coords.r].unit.health = math.max(0, self.unitpositions[target.coords.q][target.coords.r].unit.health - dmg)
                        if self.unitpositions[target.coords.q][target.coords.r].unit.health == 0 then
                            self.unitpositions[target.coords.q][target.coords.r].unit.dead = true
                        end
                        self:PostAttack(char.unit, self.unitpositions[target.coords.q][target.coords.r].unit, dmg, critical, self.unitpositions[target.coords.q][target.coords.r].unit.dead, target.coords.q, target.coords.r)
                        --self:EndTurn(char.unit)
                    else --just move to the most useful hex
                        print("DEBUG", "MOVING CHARACTER TO MOST USEFUL")
                        self.unitpositions[char.q][char.r] = nil
                        self.unitpositions[pickedhex.coords.q][pickedhex.coords.r] = char
                        char.q = pickedhex.coords.q
                        char.r =pickedhex.coords.r
                        char.x = self.hexes[pickedhex.coords.q][pickedhex.coords.r].x
                        char.y = self.hexes[pickedhex.coords.q][pickedhex.coords.r].y
                        self:EndTurn(char.unit)
                    end
                end
            elseif char.unit.personality == "guard" then

            elseif char.unit.personality == "coward" or char.unit.personality == "civilian" then

            end
        end
        --self:EndTurn(char.unit)
	end,
    EndTurn = function(self, unit)
        print("DEBUG", unit.name, "TURN ENDED")
        self:NextInQueue()
    end,
    PerformSelection = function(self, q, r)
        if self.Selecting then
            for _, hex in pairs(self.ValidHexes) do
                if hex.coords.q == q and hex.coords.r == r then
                    self.WaitingForHexSelection = false
                    self.Selecting = false
                    print("DEBUG", "PICKED",q,r, self.Selecting, self.PickPromise)
                    self.PickPromise:fulfill(q, r)
                    break
                end
            end
        end
    end,
	CalculateMoves = function(self, char)
	    --self.translate.x = this.x
	    --self.translate.y = this.y
	    local visited,hexes,strata = self:FindAllInRange(char.q, char.r, char.unit.stats.moverange)
	    self:ClearColor()
	    self.ValidHexes = hexes
	    for k, hex in pairs(hexes) do
            if self.unitpositions[hex.coords.q][hex.coords.r] and self.unitpositions[hex.coords.q][hex.coords.r] ~= char then
                self.ValidHexes[k] = nil
            else
	           hex:SetOrigColor(0,255,0,100)
	           hex:SetColor(0,255,0,100)
            end
	    end
	end,
	ShowBattleMenu = function(self, char, q, r)
        self:ClearColor()
        self.CancelPromise = Promise:new()
        self.CancelPromise:andThen(function()
            self:CloseMenu()
            char.q = q
            char.r = r
            char.x = self.hexes[q][r].x
            char.y = self.hexes[q][r].y
            self.CancelPromise = nil
            self:ProcessPlayerTurn(char)
        end)
        self.Menu = loveframes.Create("panel")
        self.Menu.StartMenu = true
        self.Menu:SetSize(the.app.width/3, the.app.height/4)
        self.Menu:SetPos(the.app.width*1/3, the.app.width*2/4)
        self.Menu.Up = loveframes.Create("button", self.Menu)
        self.Menu.Draw = function( ) end
        self.Menu.Up:SetSize(self.Menu:GetWidth()/3, self.Menu:GetWidth()/3)
        self.Menu.Up:SetPos(self.Menu:GetWidth()*1/3, 0)
        self.Menu.Up:SetText("Attack")
        self.Menu.Up.OnClick = function()
            self:DoAttack(char, q, r)
        end
        self.Menu.Left = loveframes.Create("button", self.Menu)
        self.Menu.Left:SetSize(self.Menu:GetWidth()/3, self.Menu:GetWidth()/3)
        self.Menu.Left:SetPos(0, self.Menu:GetHeight()*1/3)
        self.Menu.Left:SetText("Ability")
        self.Menu.Left.OnClick = function()
            self:DoAbility(char, q, r)
        end
        self.Menu.Down = loveframes.Create("button", self.Menu)
        self.Menu.Down:SetSize(self.Menu:GetWidth()/3, self.Menu:GetWidth()/3)
        self.Menu.Down:SetPos(self.Menu:GetWidth()*1/3, self.Menu:GetHeight()*2/3)
        self.Menu.Down:SetText("Stay")
        self.Menu.Down.OnClick = function()
            self:DoStay(char, q, r)
        end
        self.Menu.Right = loveframes.Create("button", self.Menu)
        self.Menu.Right:SetSize(self.Menu:GetWidth()/3, self.Menu:GetWidth()/3)
        self.Menu.Right:SetPos(self.Menu:GetWidth()*2/3, self.Menu:GetHeight()*1/3)
        self.Menu.Right:SetText("Use")
        self.Menu.Right.OnClick = function()
            self:DoUse(char, q, r)
        end
        self.Menu.SelectOption = function(object, option)
            if object[option] then
                self.Menu.SelectedOption = self.Menu[option]
                self.Menu[option].hover = true
            end
        end	
	end,
    CloseMenu = function (self)
        if not self.Menu then return end
        self.Menu:SetVisible(false)
        self.Menu = nil
    end,
	DoAttack = function(self, char, q, r)
        self:CloseMenu(true)
        self.CancelPromise = Promise:new()
        self.CancelPromise:andThen(function()
            self.Selecting = false
            self.WaitingForHexSelection = false
            self:CloseMenu()
            self:ShowBattleMenu(char, q, r)
        end)
        local hexes = self:CalculateAttackRange(char, char.unit.stats.attacktype, char.unit.stats.attackrange)
        if not hexes then
            self.LockInput = true
            DisplayDialogue("No hay objetivos validos alrededor", nil, "n"):andThen(function()
                self.LockInput = false
                self.CancelPromise:fulfill()
            end)
            return
        end
        print("DEBUG", "WAITING FOR TARGET")
        self.PickPromise = Promise:new()
        self.PickPromise:andThen(function(q, r)
            self.Selecting = false
            self.WaitingForHexSelection = false
            print("DEBUG", "ATTACKING", q, r)
            local dmg, critical = CalculateDamage(char.unit, self.unitpositions[q][r].unit, math.max(0,self.hexes[q][r].weight-1)*10)
            print("DEBUG", "DAMAGE", dmg, "CRITICAL", critical)
            self.unitpositions[q][r].unit.health = math.max(0, self.unitpositions[q][r].unit.health - dmg)
            if self.unitpositions[q][r].unit.health == 0 then
                self.unitpositions[q][r].unit.dead = true
            end
            self:PostAttack(char.unit, self.unitpositions[q][r].unit, dmg, critical, self.unitpositions[q][r].unit.dead, q, r)
        end)
        self.WaitingForHexSelection = true
        self.Selecting = true
    end,
    PostAttack = function(self, unit, target, dmg, critical, dead, q, r)
        self.LockInput = true
        local str = unit.name .. " ha atacado a "
        str = str .. target.name .. ", quitandole " .. dmg .. " puntos de vida"
        if critical then
            str = str .. " (CRITICAL HIT!)"
        end
        if dead then
            str = str .. " y " .. target.name .. " ha muerto!"
            print("mataste a", self.unitpositions[q][r])
            self.unitpositions[q][r] = nil
        end
        DisplayDialogue(str, nil, "n"):andThen(function()
            self.LockInput = false
            self:EndTurn(unit)
        end)
    end,
	DoAbility = function(self, char, q, r)
        self:CloseMenu(true)
        self.CancelPromise = Promise:new()
        self.CancelPromise:andThen(function()
            self:CloseMenu()
            self:ShowBattleMenu(char, q, r)
        end)
        self.Menu = loveframes.Create("panel")
        self.Menu.StartMenu = true
        self.Menu:SetSize(the.app.width/3, the.app.height/4)
        self.Menu:SetPos(the.app.width*1/3, the.app.width*2/4)
        self.Menu.Up = loveframes.Create("button", self.Menu)
        self.Menu.Draw = function( ) end
        self.Menu.Up:SetSize(self.Menu:GetWidth()/3, self.Menu:GetWidth()/3)
        self.Menu.Up:SetPos(self.Menu:GetWidth()*1/3, 0)
        self.Menu.Up:SetText("Attack")
        self.Menu.Up.OnClick = function()
            self:DoAttack(char)
        end
        self.Menu.Left = loveframes.Create("button", self.Menu)
        self.Menu.Left:SetSize(self.Menu:GetWidth()/3, self.Menu:GetWidth()/3)
        self.Menu.Left:SetPos(0, self.Menu:GetHeight()*1/3)
        self.Menu.Left:SetText("Ability")
        self.Menu.Left.OnClick = function()
            self:DoAbility(char)
        end
        self.Menu.Down = loveframes.Create("button", self.Menu)
        self.Menu.Down:SetSize(self.Menu:GetWidth()/3, self.Menu:GetWidth()/3)
        self.Menu.Down:SetPos(self.Menu:GetWidth()*1/3, self.Menu:GetHeight()*2/3)
        self.Menu.Down:SetText("Stay")
        self.Menu.Down.OnClick = function()
            self:DoStay(char)
        end
        self.Menu.Right = loveframes.Create("button", self.Menu)
        self.Menu.Right:SetSize(self.Menu:GetWidth()/3, self.Menu:GetWidth()/3)
        self.Menu.Right:SetPos(self.Menu:GetWidth()*2/3, self.Menu:GetHeight()*1/3)
        self.Menu.Right:SetText("Use")
        self.Menu.Right.OnClick = function()
            self:DoUse(char)
        end
        self.Menu.SelectOption = function(object, option)
            if object[option] then
                self.Menu.SelectedOption = self.Menu[option]
                self.Menu[option].hover = true
            end
        end	
	end,
    SelectUse = function(self, char, itemnumber, q, r)
        self:CloseMenu(true)
        self.CancelPromise = Promise:new()
        self.CancelPromise:andThen(function()
            self.Selecting = false
            self.WaitingForHexSelection = false
            self:CloseMenu()
            self:ShowBattleMenu(char, q, r)
        end)
        local hexes = self:CalculateUseRange(char)
        if not char.unit.inventory or not char.unit.inventory[itemnumber] then
            self.LockInput = true
            DisplayDialogue("No hay nada en esa posicion del inventario.", nil, "n"):andThen(function()
                self.LockInput = false
                self.CancelPromise:fulfill()
            end)
            return
        end
        print("DEBUG", "WAITING FOR TARGET")
        self.PickPromise = Promise:new()
        self.PickPromise:andThen(function(q, r)
            local useable, stat, increment = char.unit.inventory[itemnumber]:onUse(self.unitpositions[q][r].unit)
            local name = char.unit.inventory[itemnumber].name
            self.Selecting = false
            self.WaitingForHexSelection = false
            print("DEBUG", "USING ON", q, r)
            print("DEBUG", "DAMAGE", dmg, "CRITICAL", critical)
            char.unit.inventory[itemnumber] = nil
            self:PostUseItem(char.unit, self.unitpositions[q][r].unit, name, stat, increment)
        end)
        self.WaitingForHexSelection = true
        self.Selecting = true
    end,
    PostUseItem = function(self, unit, target, stat, increment)
        self:CloseMenu(true)
        DisplayDialogue("Haz usado " .. name .. " en " .. target.name .. " y aumentaste su " .. stat .. " en " .. tostring(increment), nil, "n"):andThen(function()
            self.LockInput = false
            self.CancelPromise:fulfill()
        end)
    end,
	DoUse = function(self, char, q, r)
        self:CloseMenu(true)
        self.CancelPromise = Promise:new()
        self.CancelPromise:andThen(function()
            self:CloseMenu()
            self:ShowBattleMenu(char, q, r)
        end)
        self.Menu = loveframes.Create("panel")
        self.Menu:SetSize(the.app.width/3, the.app.height/4)
        self.Menu:SetPos(the.app.width*1/3, the.app.width*2/4)
        self.Menu.Up = loveframes.Create("button", self.Menu)
        self.Menu.Draw = function( ) end
        self.Menu.Up:SetSize(self.Menu:GetWidth()/3, self.Menu:GetWidth()/3)
        self.Menu.Up:SetPos(self.Menu:GetWidth()*1/3, 0)
        if char.unit.inventory[1] and char.unit.inventory[1].name then
            self.Menu.Up:SetText(char.unit.inventory[1].name)
        else
            self.Menu.Up:SetText("(Nada)")
        end
        self.Menu.Up.OnClick = function()
            self:SelectUse(char, 1, q, r)
        end
        self.Menu.Left = loveframes.Create("button", self.Menu)
        self.Menu.Left:SetSize(self.Menu:GetWidth()/3, self.Menu:GetWidth()/3)
        self.Menu.Left:SetPos(0, self.Menu:GetHeight()*1/3)
        if char.unit.inventory[2] and char.unit.inventory[2].name then
            self.Menu.Left:SetText(char.unit.inventory[2].name)
        else
            self.Menu.Left:SetText("(Nada)")
        end
        self.Menu.Left.OnClick = function()
            self:SelectUse(char, 2, q, r)
        end
        self.Menu.Down = loveframes.Create("button", self.Menu)
        self.Menu.Down:SetSize(self.Menu:GetWidth()/3, self.Menu:GetWidth()/3)
        self.Menu.Down:SetPos(self.Menu:GetWidth()*1/3, self.Menu:GetHeight()*2/3)
        if char.unit.inventory[3] and char.unit.inventory[3].name then
            self.Menu.Down:SetText(char.unit.inventory[3].name)
        else
            self.Menu.Down:SetText("(Nada)")
        end
        self.Menu.Down.OnClick = function()
            self:SelectUse(char, 3, q, r)
        end
        self.Menu.Right = loveframes.Create("button", self.Menu)
        self.Menu.Right:SetSize(self.Menu:GetWidth()/3, self.Menu:GetWidth()/3)
        self.Menu.Right:SetPos(self.Menu:GetWidth()*2/3, self.Menu:GetHeight()*1/3)
        if char.unit.inventory[4] and char.unit.inventory[4].name then
            self.Menu.Right:SetText(char.unit.inventory[4].name)
        else
            self.Menu.Right:SetText("(Nada)")
        end
        self.Menu.Right.OnClick = function()
            self:SelectUse(char, 4, q, r)
        end
        self.Menu.SelectOption = function(object, option)
            if object[option] then
                self.Menu.SelectedOption = self.Menu[option]
                self.Menu[option].hover = true
            end
        end
	end,
	DoStay = function(self, char)
        self:CloseMenu(true)
        self:EndTurn( char.unit )
	end,
	CalculateAttackRange = function(self, char, attacktype, attackrange)
	    local visited,hexes,strata
        if attacktype=="ranged" then
	    	visited,hexes,strata = self:FindAllButAdyacents(char.q, char.r, attackrange)
        else
            visited,hexes,strata = self:FindAllAdyacents(char.q, char.r, attackrange)
	    end
	    self:ClearColor()
	    self.ValidHexes = hexes
        local validitytest = true
	    for k, hex in pairs(hexes) do
            if not self.unitpositions[hex.coords.q][hex.coords.r] or self.unitpositions[hex.coords.q][hex.coords.r].isenemy == char.unit.isenemy or self.unitpositions[hex.coords.q][hex.coords.r] == char then
                hexes[k] = nil
            else
               hex:SetOrigColor(255,0,0,100)
               hex:SetColor(255,0,0,100)
               validitytest = false
            end
	    end
        if validitytest then return false end
	    return hexes
	end,
    CalculateUseRange = function(self, char)
        local visited,hexes,strata = self:FindAllAdyacents(char.q, char.r, 1)
        self:ClearColor()
        self.ValidHexes = hexes
        for k, hex in pairs(hexes) do
            if not self.unitpositions[hex.coords.q] or not self.unitpositions[hex.coords.q][hex.coords.r] or self.unitpositions[hex.coords.q][hex.coords.r].isenemy == char.unit.isenemy then
                hexes[k] = nil
            else
               hex:SetOrigColor(0,255,0,100)
               hex:SetColor(0,255,0,100)
            end
        end
        return hexes
    end,
    ClearColor = function(self)
        for i=-self.scale, self.scale do
            for j=-self.scale, self.scale do
                if j+i<=self.scale and not (i*-1+j*-1>self.scale) then
                    if self.hexes[i][j].disabled then
                        self.hexes[i][j]:SetOrigColor(0,0,0,0)
                        self.hexes[i][j]:SetColor(0,0,0,0)
                    else
                        self.hexes[i][j]:SetOrigColor(255-(self.hexes[i][j].weight-1)*20,255-(self.hexes[i][j].weight-1)*20,255-(self.hexes[i][j].weight-1)*20,self.alpha)
                        self.hexes[i][j]:SetColor(255-(self.hexes[i][j].weight-1)*20,255-(self.hexes[i][j].weight-1)*20,255-(self.hexes[i][j].weight-1)*20,self.alpha)
                    end
                end
            end
        end
    end,
    onNew = function (self)
        self.GameWon = Promise:new()
        --self.minVisible.x, self.minVisible.y, self.maxVisible.x, self.maxVisible.y = self:BoundingBox()
        for i=-self.scale, self.scale do
            self.hexes[i] = {}
            self.unitpositions[i] = {}
            for j=-self.scale, self.scale do
                if j+i<=self.scale and not (i*-1+j*-1>self.scale) then
                    self.hexes[i][j] = HexTile:new{coords = {q=i, r=j}, x=self.x+(the.HexScale/2)*math.sqrt(3)*(i + j/2), y=self.y+(the.HexScale/2)*3/2*j}
                    self.hextiles:add(self.hexes[i][j])
                    self.hexes[i][j].weight = 1
                    self.hexes[i][j].disabled = false
                    if self.battledata.hexes[i] and self.battledata.hexes[i][j] then
                        self.hexes[i][j].weight = self.battledata.hexes[i][j].weight
                        self.hexes[i][j].disabled = self.battledata.hexes[i][j].disabled
                    end
                    self.hexes[i][j]:SetOrigColor(255-(self.hexes[i][j].weight-1)*20,255-(self.hexes[i][j].weight-1)*20,255-(self.hexes[i][j].weight-1)*20,self.alpha)
                    self.hexes[i][j]:SetColor(255-(self.hexes[i][j].weight-1)*20,255-(self.hexes[i][j].weight-1)*20,255-(self.hexes[i][j].weight-1)*20,self.alpha)
                    self.hexes[i][j].OnMouseEnter = function(this)
                        if this.disabled then return end
                        the.ActiveHex = this
                    end
                    self.hexes[i][j].OnMouseHover = function(this)
                        if this.disabled then return end
                        this:SetColor(math.abs(this.origcolor[1]-255), math.abs(this.origcolor[1]-255),math.abs(this.origcolor[1]-255), 255)
                        if the.mouse:justPressed() and self.WaitingForHexSelection then
                        	self:PerformSelection(this.coords.q, this.coords.r)
                        end
                    end
                    self.hexes[i][j].OnMouseExit = function(this)
                        if this.disabled then return end
                        this:SetColor(this.origcolor[1], this.origcolor[2],this.origcolor[3], this.origcolor[4])
                    end                
                end
            end
        end
        for _, char in pairs(self.battledata.units or {}) do
            local newunit = BattleUnit:new{
                q = char.q,
                r = char.r,
                unit = char.unit,
                image = char.image or char.unit.battleimage or "images/battle_unit.png"
            }
            char.unit.dead = false
            char.unit.health = char.unit.stats.hp
            char.unit.abilitypower = char.unit.stats.mp
            newunit.x = self.hexes[newunit.q][newunit.r].x
            newunit.y = self.hexes[newunit.q][newunit.r].y
            self.unitpositions[newunit.q][newunit.r] = newunit
            table.insert(self.units, newunit)
        end
    end,
    onUpdate = function(self)
        if self.Menu then
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
        end
        if not self.LockInput and the.keys:justPressed("escape") and self.CancelPromise then
            self.CancelPromise:fulfill()
        end
        local hex = self:PixelToHex(the.mouse.x, the.mouse.y)
        if hex then
            if not the.ActiveHex then
                hex:OnMouseEnter()
            elseif the.ActiveHex ~= hex then
                the.ActiveHex:OnMouseExit()
                hex:OnMouseEnter()
            else
                hex:OnMouseHover()
            end
        else
            if the.ActiveHex then
                the.ActiveHex:OnMouseExit()
                the.ActiveHex = nil
            end
        end
    end,
    draw = function (self, x, y)
        -- lock our x/y coordinates to integers
        -- to avoid gaps in the tiles
    
        x = math.floor(x or self.x)
        y = math.floor(y or self.y)
        -- draw each sprite in turn
        for i=-self.scale, self.scale do
            for j=-self.scale, self.scale do
                if j+i<=self.scale and not (i*-1+j*-1>self.scale) then
                  self.hexes[i][j]:draw()
                end
            end
        end

        for _, char in pairs(self.units) do
            if char.unit and not char.unit.dead then
                char:draw()
            end
        end
    end,
}

BattleView = View:extend{
	imagefile = "",
	scale = 8,
	alpha = 100,
    battledata = {},
	PreBattle = function(self)
		local promise = Promise:new()
		promise:fulfill()
		return promise
	end,
	PostBattle = function(self)
        self.titletext = Text:new{ text="GANASTE LA BATALLA", x=the.app.width/2-150, y=the.app.height/2-25, width=350, height=50, align = 'center', font={"fonts/28days.ttf", 48},alpha=0, tint={0,0,0}}
        self:add(self.titletext)
        the.view.tween:start(self.titletext, 'alpha', 1, 2)
        :andThen(function()
            the.view.timer:after(3, function()
                self.ListenToInput = true
                the.app.view:fade({0,0,0},3):andThen(function()
                    the.app.view = MainMenuView:new()
                end)
            end)
        end)
	end,
	onNew = function(self)
		if self.imagefile ~= "" then
			self.background = Tile:new{image = self.imagefile}
			self.background.x = the.app.width/2 - self.background.width/2
			self.background.y = the.app.height/2 - self.background.height/2
		end
		self.hexmap = BattleMap:new{x=the.app.width/2-the.HexScale/2, y=the.app.height/2-the.HexScale/2, scale=self.scale, alpha=self.alpha, battledata=self.battledata}
		self:add(self.hexmap)
		self:PreBattle():andThen(function()
            self.hexmap:GameStart()
			self.hexmap.GameWon:andThen(function()
                self:onWin()
            end,
            function()
                self:onLose()
            end)
		end)
	end,
	onWin = function(self)
		self:PostBattle()
	end,
	onLose = function(self)
        GameOver()
	end
}

TestEnemy = EnemyUnit:extend{
    battleimage = "images/enemy_unit.png",
    name = "Test Enemy",
    stats = {
        attack = 8,
        defense = 8,
        agility = 8,
        hp = 4,
        mp = 0,
        attackrange = 1,
        attacktype = "melee",
        moverange = 3
    },    
}
TestAlly = PartyUnit:extend{
    name = "Test Ally",
    stats = {
        attack = 12,
        defense = 12,
        agility = 12,
        hp = 10,
        mp = 0,
        attackrange = 1,
        attacktype = "melee",
        moverange = 4
    },      
}
TestBattle = BattleView:extend{
	imagefile = "images/babby.png",
    battledata = {
        units = {
            {
                q = 1,
                r = 1,
                unit = TestEnemy:new()
            },
                        {
                q = 2,
                r = 2,
                unit = TestEnemy:new()
            },
            {
                q = -3,
                r = -3,
                unit = TestEnemy:new()
            },
            {
                q = -1,
                r = -2,
                unit = TestAlly:new()
            },
            {
                q = -2,
                r = -1,
                unit = TestAlly:new()
            },
            {
                q = -1,
                r = -1,
                unit = TestAlly:new()
            }
        },
        hexes = {}
    }
}