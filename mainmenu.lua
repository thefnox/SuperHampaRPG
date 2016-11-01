--Menu Principal

MainMenuView = View:extend
{
	onNew = function(self)
		local maintitle = loveframes.Create("text")
		maintitle:SetPos(200, the.app.height/8)
		maintitle:CenterX()
		maintitle:SetText({255, 255, 255, 255}, "MAIN MENU:")
		
		local newgame = loveframes.Create("button")
		newgame:SetText("NEW GAME")
		newgame:SetClickable(true)
		newgame:SetWidth(150)
		newgame:SetPos(-150, the.app.height * (1/8))
		newgame.OnClick = function(object) object:SetText("hey") end

		the.view.tween:start(newgame, 'x',the.app.width - 200, 2, "quadOut")

		local contbutton = loveframes.Create("button")
		contbutton:SetText("CONTINUE")
		contbutton:SetClickable(true)
		contbutton:SetWidth(150)
		contbutton:SetPos(-150, the.app.height * (2/8))
		contbutton.OnClick = function(object) object:SetText("hey") end

		the.view.timer:after(0.5, function() the.view.tween:start(contbutton, 'x',the.app.width - 200, 2, "quadOut") end)


		local arcbutton = loveframes.Create("button")
		arcbutton:SetText("ARCADE MODE")
		arcbutton:SetClickable(true)
		arcbutton:SetWidth(150)
		arcbutton:SetPos(-150, the.app.height * (3/8))
		arcbutton.OnClick = function(object) 
			the.view:fade({0,0,0},2)
			:andThen(function()
				SwitchView(DebugPolygonView:new())
			end)
		end

		the.view.timer:after(1, function() the.view.tween:start(arcbutton, 'x',the.app.width - 200, 2, "quadOut") end)

		local optbutton = loveframes.Create("button")
		optbutton:SetText("OPTIONS")
		optbutton:SetClickable(true)
		optbutton:SetWidth(150)
		optbutton:SetPos(-150, the.app.height * (4/8))
		optbutton.OnClick = function(object) object:SetText("hey") end

		the.view.timer:after(1.5, function() the.view.tween:start(optbutton, 'x',the.app.width - 200, 2, "quadOut") end)

		local tutbutton = loveframes.Create("button")
		tutbutton:SetText("TUTORIAL")
		tutbutton:SetClickable(true)
		tutbutton:SetWidth(150)
		tutbutton:SetPos(-150, the.app.height * (5/8))
		tutbutton.OnClick = function(object) object:SetText("hey") end

		the.view.timer:after(2, function() the.view.tween:start(tutbutton, 'x',the.app.width - 200, 2, "quadOut") end)

		local credbutton = loveframes.Create("button")
		credbutton:SetText("CREDITS")
		credbutton:SetClickable(true)
		credbutton:SetWidth(150)
		credbutton:SetPos(-150, the.app.height * (6/8))
		credbutton.OnClick = function(object) object:SetText("hey") end

		the.view.timer:after(2.5, function() the.view.tween:start(credbutton, 'x',the.app.width - 200, 2, "quadOut") end)

	end,
	onUpdate = function(self)
		if the.keys:justPressed("escape") or the.keys:justPressed("backspace") then
			the.view:fade({0,0,0},2)
			:andThen(function()
				SwitchView(IntroView:new())
			end)
		end
	end
}