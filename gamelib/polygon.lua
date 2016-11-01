the.HexScale = 64
the.ActiveHex = nil
the.ActiveHexColor = {255, 0, 0, 100}

local function RoundHex(q, r)
    local x = q
    local z=r-.75--numeros magicos ftw
    local y=-x-z
    local rx=math.round(x)
    local rz=math.round(z)
    local ry=math.round(y)
    local x_diff = math.abs(rx - x)
    local y_diff = math.abs(ry - y)
    local z_diff = math.abs(rz - z)

    if rx + ry + rz == 0 then return rx, rz end 

    if x_diff > y_diff and x_diff > z_diff then
        rx = -ry-rz
    elseif y_diff > z_diff then
        ry = -rx-rz
    else
        rz = -rx-ry
    end

    return rx, rz
end

local function RoundHexCube(x, y, z)
    local rx=math.round(x)
    local rz=math.round(z)
    local ry=math.round(y)
    local x_diff = math.abs(rx - x)
    local y_diff = math.abs(ry - y)
    local z_diff = math.abs(rz - z)

    if rx + ry + rz == 0 then return rx, rz end 

    if x_diff > y_diff and x_diff > z_diff then
        rx = -ry-rz
    elseif y_diff > z_diff then
        ry = -rx-rz
    else
        rz = -rx-ry
    end

    return rx, rz
end

HexTile = Tile:extend
{
    colored = true,
    weight = 0,
    width = the.HexScale,
    height = the.HexScale,
    image = 'images/hex.png',
    origcolor = {},
    coords = {},
    vertices = {},
    SetAlpha = function(self, a)
      if not a then self.alpha = 1 return end
      self.alpha = a / 100
    end,
    SetOrigColor = function(self, r, g, b, a)
      self.origcolor[1] = r
      self.origcolor[2] = g
      self.origcolor[3] = b
      self.origcolor[4] = a
    end,      
    SetColor = function(self, r, g, b, a)
      if not r and not g and not b then self.colored = false self:SetAlpha() return end
      if a then self:SetAlpha(a) end
      self.colored = true
      self.tint[1] = r/255
      self.tint[2] = g/255
      self.tint[3] = b/255
    end,
    GenerateVertices = function( self )
        local angle
        for i=1, 6 do
            self.vertices[i] = {}
            angle = 2 * math.pi / 6 * (i + 0.5)
            self.vertices[i].x = self.x + the.HexScale/2 * math.cos(angle)
            self.vertices[i].y = self.y + the.HexScale/2 * math.sin(angle)
        end
    end,
    onNew = function( self )
        self.coords.q = self.coords.q or 0
        self.coords.r = self.coords.r or 0
        self:GenerateVertices()
        self:SetColor(self.origcolor[1], self.origcolor[2],self.origcolor[3], self.origcolor[4])
    end,
    OnMouseEnter = function(self)
    end,
    OnMouseHover = function(self)
    end,
    OnMouseExit = function(self)
    end,
    onUpdate = function(self)
    end
}

HexMap = Sprite:extend
{
    alpha=100,
    visible=true,
    hexes = {},
    hextiles = Group:new(),
    scale = 1,
    origcolor = {255,255,255,100},
    BoundingBox = function(self)
        local minx = self.x+(the.HexScale/2)*math.sqrt(3)*(-self.scale)-the.HexScale
        local miny = self.y+(the.HexScale/2)*3/2*-self.scale-the.HexScale
        local maxx = self.x+(the.HexScale/2)*math.sqrt(3)*(self.scale)+the.HexScale
        local maxy = self.y+(the.HexScale/2)*3/2*self.scale+the.HexScale
        return minx, miny, maxx, maxy
    end,
    PixelToHex = function(self,x,y)
        x = x - self.x
        y = y - self.y
        local q = (1/3*math.sqrt(3) * x - 1/3 * y) / (the.HexScale/2)
        local r = 2/3 * y / (the.HexScale/2)
        q, r = RoundHex(q,r)
        if self.hexes[q] and self.hexes[q][r] then
          return self.hexes[q][r]
        else return false end
    end,
    FindNeighbors = function(self,q,r)
        local neighbors = {}
        if self.hexes[q] and self.hexes[q][r-1] and not self.hexes[q][r-1].disabled then table.insert(neighbors, self.hexes[q][r-1]) end
        if self.hexes[q] and self.hexes[q][r+1] and not self.hexes[q][r+1].disabled then table.insert(neighbors, self.hexes[q][r+1]) end
        if self.hexes[q-1] and self.hexes[q-1][r+1] and not self.hexes[q-1][r+1].disabled then table.insert(neighbors, self.hexes[q-1][r+1]) end
        if self.hexes[q+1] and self.hexes[q+1][r-1] and not self.hexes[q+1][r-1].disabled then table.insert(neighbors, self.hexes[q+1][r-1]) end
        if self.hexes[q+1] and self.hexes[q+1][r] and not self.hexes[q+1][r].disabled then table.insert(neighbors, self.hexes[q+1][r]) end
        if  self.hexes[q-1] and self.hexes[q-1][r] and not self.hexes[q-1][r].disabled then table.insert(neighbors, self.hexes[q-1][r]) end
        return neighbors
    end,
    FindAllAdyacents = function(self, startq, startr, range)
        if not self.hexes[startq] or not self.hexes[startq][startr] then return {}, {}, {} end
        local results = {}
        local visited = {}
        local final = {}
        local origin = self.hexes[startq][startr]
        visited[tostring(startq) .. tostring(startr)] = true
        results[0] = {origin}
        table.insert(final, origin)
        local q, r
        for i=1, range do
            for _, hex in pairs(results[i-1] or {}) do
                for __, neighbor in pairs(self:FindNeighbors(hex.coords.q, hex.coords.r)) do
                    if not visited[tostring(neighbor.coords.q) .. tostring(neighbor.coords.r)] and not neighbor.disabled then
                        if not results[i] then results[i] = {} end
                        table.insert(results[i], neighbor)
                        visited[tostring(neighbor.coords.q) .. tostring(neighbor.coords.r)] = true
                        table.insert(final, neighbor)
                    end
                end
            end
        end
        return visited, final, results
    end,
    Distance = function( self, q1, r1, q2, r2 )
        return (math.abs(q1 - q2) + math.abs(r1 - r2) + math.abs(q1 + r1 - q2 - r2)) / 2
    end,
    FindInLine = function( self, q1, r1, q2, r2)
        local ax = q1 + 1e-6
        local ay = -q1-r1 + 1e-6
        local az = r1 + 1e-6
        local bx = q2
        local by = -q2-r2
        local bz = r2
        local difx = ax - bx
        local dify = ay - by
        local difz = az - bz
        local n = math.max(math.abs(difx-dify), math.abs(dify-difz), math.abs(difz-difx))
        local prevq, prevr
        local p
        local hexes = {}
        local visited = {}
        for i=0, n do
            local pq, pr = RoundHexCube(ax*(1-i/n)+bx*i/n, ay*(1-i/n)+by*i/n, az*(1-i/n)+bz*i/n)
            if not (visited[pq] and visited[pq][pr]) and not (pq == prevq and pr == prevr) then
                if not visited[pq] then visited[pq] = {} end
                visited[pq][pr] = true
                table.insert(hexes, self.hexes[pq][pr])
                prevq = pq
                prevr = pr
            end
        end
        return hexes, visited
    end,
    FindAllButAdyacents = function(self, startq, startr, range)
        if not self.hexes[startq] or not self.hexes[startq][startr] then return {}, {}, {} end
        local results = {}
        local visited = {}
        local final = {}
        local origin = self.hexes[startq][startr]
        visited[tostring(startq) .. tostring(startr)] = true
        results[0] = {origin}
        table.insert(final, origin)
        local q, r
        for i=2, range do
            for _, hex in pairs(results[i-1] or {}) do
                for __, neighbor in pairs(self:FindNeighbors(hex.coords.q, hex.coords.r)) do
                    if not visited[tostring(neighbor.coords.q) .. tostring(neighbor.coords.r)] and not neighbor.disabled then
                        if not results[i] then results[i] = {} end
                        table.insert(results[i], neighbor)
                        visited[tostring(neighbor.coords.q) .. tostring(neighbor.coords.r)] = true
                        table.insert(final, neighbor)
                    end
                end
            end
        end
        return visited, final, results
    end,
    FindAllInRange = function(self, startq, startr, range)
        if not self.hexes[startq] or not self.hexes[startq][startr] then return {}, {}, {} end
        local results = {}
        local visited = {}
        local final = {}
        local origin = self.hexes[startq][startr]
        visited[tostring(startq) .. tostring(startr)] = true
        results[0] = {origin}
        table.insert(final, origin)
        local q, r
        for i=1, range do
            for _, hex in pairs(results[i-1] or {}) do
                for __, neighbor in pairs(self:FindNeighbors(hex.coords.q, hex.coords.r)) do
                    if i==1 or (not visited[tostring(neighbor.coords.q) .. tostring(neighbor.coords.r)] and not neighbor.disabled and i-1+neighbor.weight<=range) then
                        if not results[i-1+neighbor.weight] then results[i-1+neighbor.weight] = {} end
                        table.insert(results[i-1+neighbor.weight], neighbor)
                        visited[tostring(neighbor.coords.q) .. tostring(neighbor.coords.r)] = true
                        table.insert(final, self.hexes[neighbor.coords.q][neighbor.coords.r])
                    end
                end
            end
        end
        return visited, final, results
    end,

    onNew = function( self )
        for i=-self.scale, self.scale do
            self.hexes[i] = {}
            for j=-self.scale, self.scale do
                if j+i<=self.scale and not (i*-1+j*-1>self.scale) then
                    self.hexes[i][j] = HexTile:new{coords = {q=i, r=j}, x=self.x+(the.HexScale/2)*math.sqrt(3)*(i + j/2), y=self.y+(the.HexScale/2)*3/2*j}
                    self.hextiles:add(self.hexes[i][j])
                end
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
    end,
}

DebugTestLine = View:extend
{
    onNew = function (self)
        self.hexmap = HexMap:new{x=the.app.width/2-the.HexScale/2, y=the.app.height/2-the.HexScale/2, scale=8, alpha = 100}
        --self.minVisible.x, self.minVisible.y, self.maxVisible.x, self.maxVisible.y = self.hexmap:BoundingBox()
        self.hexmap.ClearColor = function(this)
            for i=-self.hexmap.scale, self.hexmap.scale do
                for j=-self.hexmap.scale, self.hexmap.scale do
                    if j+i<=self.hexmap.scale and not (i*-1+j*-1>self.hexmap.scale) then
                        if self.hexmap.hexes[i][j].disabled then
                            self.hexmap.hexes[i][j]:SetOrigColor(0,0,0,0)
                            self.hexmap.hexes[i][j]:SetColor(0,0,0,0)
                        else
                            self.hexmap.hexes[i][j]:SetOrigColor(255-(self.hexmap.hexes[i][j].weight-1)*20,255-(self.hexmap.hexes[i][j].weight-1)*20,255-(self.hexmap.hexes[i][j].weight-1)*20,100)
                            self.hexmap.hexes[i][j]:SetColor(255-(self.hexmap.hexes[i][j].weight-1)*20,255-(self.hexmap.hexes[i][j].weight-1)*20,255-(self.hexmap.hexes[i][j].weight-1)*20,100)
                        end
                    end
                end
            end
        end
        for i=-self.hexmap.scale, self.hexmap.scale do
            for j=-self.hexmap.scale, self.hexmap.scale do
                if j+i<=self.hexmap.scale and not (i*-1+j*-1>self.hexmap.scale) then
                    if self.hexmap.hexes[i][j].disabled then
                        self.hexmap.hexes[i][j]:SetOrigColor(0,0,0,0)
                        self.hexmap.hexes[i][j]:SetColor(0,0,0,0)
                    else
                        self.hexmap.hexes[i][j]:SetOrigColor(255-(self.hexmap.hexes[i][j].weight-1)*20,255-(self.hexmap.hexes[i][j].weight-1)*20,255-(self.hexmap.hexes[i][j].weight-1)*20,100)
                        self.hexmap.hexes[i][j]:SetColor(255-(self.hexmap.hexes[i][j].weight-1)*20,255-(self.hexmap.hexes[i][j].weight-1)*20,255-(self.hexmap.hexes[i][j].weight-1)*20,100)
                    end
                    self.hexmap.hexes[i][j].OnMouseEnter = function(this)
                        if this.disabled then return end
                        the.ActiveHex = this
                    end
                    self.hexmap.hexes[i][j].OnMouseHover = function(this)
                        if this.disabled then return end
                        this:SetColor(math.abs(this.origcolor[1]-255), math.abs(this.origcolor[1]-255),math.abs(this.origcolor[1]-255), 255)
                        if the.mouse:justPressed() then
                            --self.translate.x = this.x
                            --self.translate.y = this.y
                            local hexes, visited = self.hexmap:FindInLine(0, 0, this.coords.q, this.coords.r, 2)
                            self.hexmap:ClearColor()
                            for _, hex in pairs(hexes) do
                                hex:SetOrigColor(0,255,0,100)
                                hex:SetColor(0,255,0,100)
                            end
                        end
                    end
                    self.hexmap.hexes[i][j].OnMouseExit = function(this)
                        if this.disabled then return end
                        this:SetColor(this.origcolor[1], this.origcolor[2],this.origcolor[3], this.origcolor[4])
                    end
                end
            end
        end
         self:add(self.hexmap)
    end,
    onUpdate = function(self)
        local hex = self.hexmap:PixelToHex(the.mouse.x, the.mouse.y)
        if hex then
            if not the.ActiveHex then
                hex:OnMouseEnter()
                the.app.view:panTo({100, 100},2)
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
    end
}

DebugPolygonView = View:extend
{
    onNew = function (self)
        self.hexmap = HexMap:new{x=the.app.width/2-the.HexScale/2, y=the.app.height/2-the.HexScale/2, scale=8}
        --self.minVisible.x, self.minVisible.y, self.maxVisible.x, self.maxVisible.y = self.hexmap:BoundingBox()
        self.hexmap.ClearColor = function(this)
            for i=-self.hexmap.scale, self.hexmap.scale do
                for j=-self.hexmap.scale, self.hexmap.scale do
                    if j+i<=self.hexmap.scale and not (i*-1+j*-1>self.hexmap.scale) then
                        if self.hexmap.hexes[i][j].disabled then
                            self.hexmap.hexes[i][j]:SetOrigColor(0,0,0,0)
                            self.hexmap.hexes[i][j]:SetColor(0,0,0,0)
                        else
                            self.hexmap.hexes[i][j]:SetOrigColor(255-(self.hexmap.hexes[i][j].weight-1)*20,255-(self.hexmap.hexes[i][j].weight-1)*20,255-(self.hexmap.hexes[i][j].weight-1)*20,100)
                            self.hexmap.hexes[i][j]:SetColor(255-(self.hexmap.hexes[i][j].weight-1)*20,255-(self.hexmap.hexes[i][j].weight-1)*20,255-(self.hexmap.hexes[i][j].weight-1)*20,100)
                        end
                    end
                end
            end
        end
        for i=-self.hexmap.scale, self.hexmap.scale do
            for j=-self.hexmap.scale, self.hexmap.scale do
                if j+i<=self.hexmap.scale and not (i*-1+j*-1>self.hexmap.scale) then
                    self.hexmap.hexes[i][j].weight = math.random(1,3)
                    if math.random(1, 16) == 16 then
                        self.hexmap.hexes[i][j].disabled = true
                        self.hexmap.hexes[i][j]:SetOrigColor(0,0,0,0)
                        self.hexmap.hexes[i][j]:SetColor(0,0,0,0)
                    else
                        self.hexmap.hexes[i][j]:SetOrigColor(255-(self.hexmap.hexes[i][j].weight-1)*20,255-(self.hexmap.hexes[i][j].weight-1)*20,255-(self.hexmap.hexes[i][j].weight-1)*20,100)
                        self.hexmap.hexes[i][j]:SetColor(255-(self.hexmap.hexes[i][j].weight-1)*20,255-(self.hexmap.hexes[i][j].weight-1)*20,255-(self.hexmap.hexes[i][j].weight-1)*20,100)
                    end
                end
            end
        end
        self:add(self.hexmap)
    end,
    onUpdate = function(self)
        local hex = self.hexmap:PixelToHex(the.mouse.x, the.mouse.y)
        if hex then
            if not the.ActiveHex then
                hex:OnMouseEnter()
                the.app.view:panTo({100, 100},2)
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
        local curvisited = {}
        for i=-self.hexmap.scale, self.hexmap.scale do
            for j=-self.hexmap.scale, self.hexmap.scale do
                if j+i<=self.hexmap.scale and not (i*-1+j*-1>self.hexmap.scale) then
                    self.hexmap.hexes[i][j].OnMouseEnter = function(this)
                        if this.disabled then return end
                        the.ActiveHex = this
                    end
                    self.hexmap.hexes[i][j].OnMouseHover = function(this)
                        if this.disabled then return end
                        if not curvisited[tostring(this.coords.q)..tostring(this.coords.r)] then
                            this:SetColor(math.abs(this.origcolor[1]-255), math.abs(this.origcolor[1]-255),math.abs(this.origcolor[1]-255), 255)
                        end
                        if the.mouse:justPressed() then
                            --self.translate.x = this.x
                            --self.translate.y = this.y
                            local visited,hexes,strata = self.hexmap:FindAllInRange(this.coords.q, this.coords.r, 2)
                            self.hexmap:ClearColor()
                            for _, hex in pairs(hexes) do
                                hex:SetOrigColor(0,255,0,100)
                                hex:SetColor(0,255,0,100)
                            end
                        end
                    end
                    self.hexmap.hexes[i][j].OnMouseExit = function(this)
                        if this.disabled then return end
                        this:SetColor(this.origcolor[1], this.origcolor[2],this.origcolor[3], this.origcolor[4])
                    end
                end
            end
        end
    end
}