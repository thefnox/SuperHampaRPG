--Menu introductorio

IntroView = View:extend
{
	onNew = function (self)
		self.titletext = Text:new{ text="SUPER HAMPA RPG", x=the.app.width/2-150, y=-50, width=300, height=50, align = 'center'}
		self:add(self.titletext)
		self.pressstart = Text:new{ text="PRESS START!", x=the.app.width/2-150, y=the.app.height*4/5, width=300, height=50, alpha=0, align = 'center'}
		self:add(self.pressstart)
		the.view.tween:start(self.titletext, 'y', the.app.height/5, 2)
		:andThen(function()
			self.ListenToInput = true
			the.view.tween:start(self.pressstart, 'alpha',1, 1):andThen(Tween.reverseForever)
		end)
	end,
	onUpdate = function (self)
		if self.ListenToInput and (the.keys:pressed(" ") or the.keys:pressed("return")) then
			self.ListenToInput = false
			the.view:fade({0,0,0},2)
			:andThen(function()
				SwitchView(MainMenuView:new())
			end)
		end
	end
}