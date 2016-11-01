Item = Class:extend{
	image = "",
	name = "Item",
	handle = "item",
	type = "equipment",
	increment = 0,
	affectedstat = "",
	onUse = function(self, target)
		if self.type == "equipment" then
			return false
		elseif self.type == "heal" and self.affectedstat == "health" then
			target.health = math.min(target.stats.hp, target.health+self.increment)
			return true, "Health", self.increment
		elseif self.type == "heal" and self.affectedstat == "abilitypower" then
			target.abilitypower = math.min(target.stats.mp, target.abilitypower+self.increment)
			return true, "Ability Power", self.increment
		elseif self.type == "buff" and target.stats[self.affectedstat] then
			target.stats[self.affectedstat] = target.stats[self.affectedstat] + self.increment
			return true, PrettifyStat(self.affectedstat), self.increment
		end
	end
}