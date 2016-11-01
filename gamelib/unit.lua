Unit = Animation:extend{
	dead = false,
	health = 1,
	abilitypower = 0,
	stats = {
		attack = 0,
		defense = 0,
		agility = 0,
		hp = 1,
		mp = 0,
		attackrange = 1,
		attacktype = "melee",
		moverange = 1
	},
	portrait = "",
	inventory = {},
	abilities = {},
	fullname = "",
	handler = "",
	battleimage = "images/battle_unit.png",
	isenemy = true,
	GetDamage = function(self)
		local base = self.stats["attack"]
		for k, item in pairs(self.inventory or {}) do
			if item.type == "equipment" and item.affectedstat == "attack" then
				base = base + item.increment
			end
		end
		return base
	end,
	GetDefense = function(self)
		local base = self.stats["defense"]
		for k, item in pairs(self.inventory or {}) do
			if item.type == "equipment" and item.affectedstat == "defense" then
				base = base + item.increment
			end
		end
		return base
	end,
}

EnemyUnit = Unit:extend{
	isenemy = true,
	personality = "aggressive",
	experiencereward = 10,
	goldreward = 0,
	itemreward = "",
	onDeath = function(self)

	end
}

PartyUnit = Unit:extend{
	isenemy = false,
	experience = 0,
	level = 1,
	progression = {},
	GainExperience = function(self, amount)
		self.experience = self.experience + 0
		if self.progression[self.level+1] and self.experience >= self.progression[self.level+1].experience then
			self.level = self.level + 1
			for stat, increase in pairs(progression[self.level].stats) do
				if self.stats[stat] then
					self.stats[stat] = self.stats[stat] + increase
				end
			end
			return true
		end
		return false
	end
}

--Aqui se calcula la formula de daño del juego
function CalculateDamage(unit, enemy, landbonus)
	local dmg = math.max(1, math.round((unit:GetDamage()-enemy:GetDefense())*(1-landbonus/100)*(1+0.1*math.random(-1,1))))
	if math.random(1, 16)==16 then
		return 0
	elseif math.random(1, 8)==8 then
		return math.round(dmg*1.5), true
	end
	return dmg
end

function PrettifyStat(stat)
	if stat == "attack" then return "Attack Damage" end
	if stat == "defense" then return "Defense" end
	if stat == "agility" then return "Agility" end
	if stat == "hp" then return "Health Points" end
	if stat == "mp" then return "Ability Points" end
	if stat == "attackrange" then return "Attack Range" end
	if stat == "attacktype" then return "Attack Type" end
	if stat == "health" then return "Health" end
	if stat == "abilitypower" then return "Ability Power" end
	return ""
end