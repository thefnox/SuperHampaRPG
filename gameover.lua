--Pantalla de fin de juego

function GameOver()
	the.app.view:fade({0,0,0},2):andThen(function()
		the.app.view = GameOverView:new()
	end)
end

GameOverView = View:extend
{
	onNew = function (self)
		self.titletext = Text:new{ text="GAME OVER", x=the.app.width/2-150, y=the.app.height/2-25, width=300, height=50, align = 'center', alpha=0, font={"fonts/28days.ttf", 48}}
		self:add(self.titletext)
		the.view.tween:start(self.titletext, 'alpha', 1, 2)
		:andThen(function()
			self.ListenToInput = true
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