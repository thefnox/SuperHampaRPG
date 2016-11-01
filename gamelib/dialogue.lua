the.DialogueSpeed = 0.05
the.DialogueFont = love.graphics.newFont("fonts/coolvetica rg.ttf", 18)
the.DialogueQueue = {}

local function NextOfQueue()
	local tbl = the.DialogueQueue[1]
	if not tbl then
		KillDialogueDisplay()
	else
		table.remove(the.DialogueQueue,1)
		if tbl.type == "text" then
			if tbl.side ~= "n" then
				if not the.DialogueImagePanel then
					the.DialogueImagePanel = loveframes.Create("panel")
					the.DialogueImagePanel:SetSize(the.app.width/5, the.app.height/3)
					the.DialogueImage = loveframes.Create("image", the.DialogueImagePanel)
					the.DialogueImage:SetPos(5, 5)
					the.DialogueImage:SetSize(the.app.width/5, the.app.height/3)
				end
				the.DialogueImage:SetImage(tbl.img or "images/tuky.png")
				the.DialogueImage:SetScaleX((the.app.width/5-5) / the.DialogueImage:GetImageWidth())
				the.DialogueImage:SetScaleY((the.app.height/3-5) / the.DialogueImage:GetImageHeight())
				if tbl.side == "r" then
					the.DialogueImagePanel:SetPos(the.app.width*4/5-50, 50)
				else
					the.DialogueImagePanel:SetPos(50, 50)
				end
			else
				if the.DialogueImagePanel then
					the.DialogueImagePanel:SetVisible(false)
					the.DialogueImagePanel = nil
				end
			end
			the.DialoguePanel.promise = DisplayText( tbl.str )
		elseif tbl.type == "choice" then
			if the.DialogueImagePanel then
				the.DialogueImagePanel:SetVisible(false)
				the.DialogueImagePanel = nil
			end
			if not the.DialoguePanel then
				the.DialoguePanel = loveframes.Create("panel")
				the.DialoguePanel.finished = Promise:new()
				the.DialoguePanel:SetSize(the.app.width-100, the.app.height / 3 - 50)
				the.DialoguePanel:SetPos(50, the.app.height*2/3-50)
			end
			the.DialoguePanel.promise = DisplayOption( tbl.str, tbl.args )			
		end
	end
end

function DisplayText( str, sound )

	if not the.DialoguePanel then return end

	local promise = Promise:new()
	local cur = 1
	local source
	if not sound then
		local soundtmr = Timer:new()
		the.view:add(soundtmr)
		soundtmr:every(math.max(the.DialogueSpeed, 0.1), function()
			if not the.DialoguePanel or promise ~= the.DialoguePanel.promise then return end
			if not the.DialoguePanel.WaitingForInput then playSound('sounds/talk3.wav') end
			if the.DialoguePanel.InputReceived then
				soundtmr:stop()
				the.view:remove(soundtmr)
			end
		end)
	else
		source:playSound(sound)
	end

	promise:andThen(function() NextOfQueue() end)

	the.DialoguePanel:SetVisible(true)
	if not the.DialogueText then
		the.DialogueText = loveframes.Create("text", the.DialoguePanel)
		the.DialogueText:SetPos(10,10)
		the.DialogueText:SetSize(the.app.width-110, the.app.height / 3 - 60)
		the.DialogueText:SetFont(the.DialogueFont)
		the.DialogueText:SetShadowColor(200, 200, 200, 255)
	else
		the.DialogueText:SetText("")
	end

	local tmr = Timer:new()
	the.view:add(tmr)

	tmr:every(the.DialogueSpeed, function()
		if not the.DialoguePanel or promise ~= the.DialoguePanel.promise then return end
		if the.keys:pressed(" ") or the.keys:pressed("enter") then
			cur = cur + 5
		else
			cur = cur + 1 
		end
		the.DialogueText:SetText(string.sub(str, 1, cur))
		if cur > string.len(str) then
			the.DialoguePanel.WaitingForInput = true
			the.DialogueText:SetText(str)
		end
		if the.DialoguePanel.InputReceived then
			if source then
				source:stop()
			end
			the.DialoguePanel.WaitingForInput = false
			the.DialoguePanel.InputReceived = false
			tmr:stop()
			the.view:remove(tmr)
			if promise.state == "unfulfilled" then promise:fulfill() 
			else
				KillDialogueDisplay()
			end
		end
	end)

	return promise
end

function DisplayOption(str, args)
	the.DialoguePanel.MaxOptions = #args

	local promise = Promise:new()
	local cur = 1

	promise:andThen(function() NextOfQueue() end)

	the.DialoguePanel:SetVisible(true)
	if not the.DialogueText then
		the.DialogueText = loveframes.Create("text", the.DialoguePanel)
		the.DialogueText:SetPos(10,10)
		the.DialogueText:SetSize(the.app.width-110, the.app.height / 3 - 60)
		the.DialogueText:SetFont(the.DialogueFont)
		the.DialogueText:SetShadowColor(200, 200, 200, 255)
	else
		the.DialogueText:SetText("")
	end

	local tmr = Timer:new()
	the.view:add(tmr)

	tmr:every(the.DialogueSpeed, function()
		if not the.DialoguePanel or promise ~= the.DialoguePanel.promise then return end
		if the.keys:pressed(" ") or the.keys:pressed("enter") then
			cur = cur + 5
		else
			cur = cur + 1 
		end
		the.DialogueText:SetText(string.sub(str, 1, cur))
		if cur > string.len(str) and not the.DialoguePanel.WaitingForInput then
			the.DialoguePanel.WaitingForInput = true
			the.DialoguePanel.SelectedOption = 1
			for i=1, the.DialoguePanel.MaxOptions do
				local text = loveframes.Create("text", the.DialoguePanel)
				text:SetPos(20, 45 + 20 * (i-1))
				text:SetSize(the.app.width-150, 20)
				text:SetFont(the.DialogueFont)
				text:SetShadowColor(200, 200, 200, 255)
				text:SetText(args[i][1])
				text.OnMouseEnter = function(object)
					the.DialoguePanel.SelectedOption = i
				end
				text.Update = function(object)
					if not the.DialoguePanel or promise ~= the.DialoguePanel.promise then text.visible = false return end
					if the.DialoguePanel.SelectedOption == i then
						text:SetText({{255,0,0,255}, args[i][1]})
					else
						text:SetText({{0,0,0,255}, args[i][1]})
					end
					if not text.done and the.mouse:pressed() and text.hover then
						args[i][2]()
						the.DialoguePanel.WaitingForInput = false
						the.DialoguePanel.InputReceived = false
						if promise.state == "unfulfilled" then promise:fulfill() 
						else KillDialogueDisplay() end
						tmr:stop()
						the.view:remove(tmr)
						text.done = true
					end
				end
			end
		end
		if the.DialoguePanel.InputReceived then
			args[the.DialoguePanel.SelectedOption][2]()
			the.DialoguePanel.WaitingForInput = false
			the.DialoguePanel.InputReceived = false
			if promise.state == "unfulfilled" then promise:fulfill() 
			else KillDialogueDisplay() end
			tmr:stop()
			the.view:remove(tmr)
		end
	end)

	local soundtmr = Timer:new()
	the.view:add(soundtmr)
	soundtmr:every(math.max(the.DialogueSpeed, 0.1), function()
		if not the.DialoguePanel or promise ~= the.DialoguePanel.promise then return end
		if not the.DialoguePanel.WaitingForInput then playSound('sounds/talk3.wav') end
		if the.DialoguePanel.InputReceived then
			soundtmr:stop()
			the.view:remove(soundtmr)
		end
	end)

	return promise

end

function KillDialogueDisplay()
	the.app.LockInput = false
	if the.DialoguePanel then
		if the.DialoguePanel.finished.state == "unfulfilled" then the.DialoguePanel.finished:fulfill() end
		the.DialoguePanel:SetVisible(false)
		the.DialoguePanel = nil
		if the.DialogueImagePanel then
			the.DialogueImagePanel:SetVisible(false)
			the.DialogueImagePanel = nil
			the.DialogueImage = nil
		end
		the.DialogueText = nil
		the.DialogueQueue = {}
	end
end

function DisplayDialogue(str, img, side, sound)
	the.app.LockInput = true

	if not the.DialoguePanel then
		the.DialoguePanel = loveframes.Create("panel")
		the.DialoguePanel.finished = Promise:new()
		the.DialoguePanel:SetSize(the.app.width-100, the.app.height / 3 - 50)
		the.DialoguePanel:SetPos(50, the.app.height*2/3-50)
		the.DialoguePanel.Update = function( object )
			if the.DialoguePanel then
				if the.DialoguePanel.WaitingForInput then
					if not the.DialoguePanel.SelectedOption then the.DialoguePanel.SelectedOption = 1 end
					if the.keys:justPressed(" ") or the.keys:justPressed("enter") then
						the.DialoguePanel.WaitingForInput = false
						the.DialoguePanel.InputReceived = true
					elseif the.keys:justPressed("down") then
						the.DialoguePanel.SelectedOption = math.min(the.DialoguePanel.MaxOptions or 0, the.DialoguePanel.SelectedOption + 1 )
					elseif the.keys:justPressed("up") then
						the.DialoguePanel.SelectedOption = math.max(1, the.DialoguePanel.SelectedOption - 1)
					end
				end
			end
		end
		the.DialogueImagePanel = loveframes.Create("panel")
		the.DialogueImagePanel:SetSize(the.app.width/5, the.app.height/3)
		if side == "r" then
			the.DialogueImagePanel:SetPos(the.app.width*4/5-50, 50)
		else
			the.DialogueImagePanel:SetPos(50, 50)
		end
		the.DialogueImage = loveframes.Create("image", the.DialogueImagePanel)
		the.DialogueImage:SetPos(5, 5)
		the.DialogueImage:SetSize(the.app.width/5, the.app.height/3)
		the.DialogueImage:SetImage(img or "images/tuky.png")
		the.DialogueImage:SetScaleX((the.app.width/5-5) / the.DialogueImage:GetImageWidth())
		the.DialogueImage:SetScaleY((the.app.height/3-5) / the.DialogueImage:GetImageHeight())

		if side == "n" then
			if the.DialogueImagePanel then
				the.DialogueImagePanel:SetVisible(false)
				the.DialogueImagePanel = nil
			end
		end
		the.DialoguePanel.promise = DisplayText( str, sound )
	else
		table.insert(the.DialogueQueue, {["str"] = str, ["img"] = img, ["side"] = side, ["type"] = "text", ["sound"] = sound})
	end
	return the.DialoguePanel.finished
end

function DisplayDialogueOption(str, ...)
	local args = {...}
	the.app.LockInput = true
	if not the.DialoguePanel then
		the.DialoguePanel = loveframes.Create("panel")
		the.DialoguePanel.finished = Promise:new()
		the.DialoguePanel:SetSize(the.app.width-100, the.app.height / 3 - 50)
		the.DialoguePanel:SetPos(50, the.app.height*2/3-50)
		the.DialoguePanel.promise = DisplayOption( str, args )
		if the.DialogueImagePanel then
			the.DialogueImagePanel:SetVisible(false)
			the.DialogueImagePanel = nil
		end	
	else
		table.insert(the.DialogueQueue, {["str"] = str, ["args"] = args, ["type"] = "choice"})
	end
	return the.DialoguePanel.finished
end

DialogueTest = View:extend{
	onNew = function(self)
		DisplayDialogue("shit","images/babby.png", "l")
		DisplayDialogueOption("take a pick", {"option 1", function() DisplayDialogue("bien", "images/tuky.png", "r") DisplayDialogueOption("y ahora?", {"si", function() DisplayDialogue("bien de nuevo", "images/tuky.png", "r") end}, {"no", function() end}) end}, {"option 2", function() DisplayDialogue("shit","images/babby.png", "r") end}, {"fucking quit", function() end})
	end,
	onUpdate = function(self)
	end
}