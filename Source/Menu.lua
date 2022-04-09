local module = {}

module.isDone = false
module.settings = {}

local buttons
local sliders
local slider

function loadButtons()
	buttons = {}
	
	for b = 1, 6 do
		buttons[b] = {x = (b - 1) * 400 / 3, y = 560, width = 400 / 3}
	end
	
	buttons[1].text = "Small"
	buttons[2].text = "Medium"
	buttons[3].text = "Large"
	buttons[4].text = "Uniform"
	buttons[5].text = "Pacifist"
	buttons[6].text = "Start"
end

function loadSliders()
	sliders = {}
	slider = nil
	
	for s = 1, 9 do
		sliders[s] = {}
	end
	
	sliders[1].range = {min = 0, max = 1}
	sliders[2].range = {min = 2, max = 9}
	sliders[3].range = {min = 10, max = 50}
	sliders[4].range = {min = 10, max = 25}
	sliders[5].range = {min = 10, max = 30}
	sliders[6].range = {min = -5, max = 5}
	sliders[7].range = {min = 10, max = 100}
	sliders[8].range = {min = 50, max = 100}
	sliders[9].range = {min = 1, max = 30}
	
	sliders[1].value = 1
	sliders[2].value = 5
	sliders[3].value = 16
	sliders[4].value = 16
	sliders[5].value = 12
	sliders[6].value = -5
	sliders[7].value = 70
	sliders[8].value = 77
	sliders[9].value = 10
	
	for s = 1, 9 do
		sliders[s].line = {left = 0, right = 800, y = 60 * s - 15}
		sliders[s].point = (sliders[s].value - sliders[s].range.min) * 800 / (sliders[s].range.max - sliders[s].range.min)
		sliders[s].text = {x = 0, y = 60 * s - 45, width = 800}
	end
	
	sliders[1].text.text = "Initial Level: "
	sliders[2].text.text = "Level Cap: "
	sliders[3].text.text = "Map Width: "
	sliders[4].text.text = "Map Height: "
	sliders[5].text.text = "Monster Density: "
	sliders[6].text.text = "Monster Difficulty: "
	sliders[7].text.text = "Early Threshold: "
	sliders[8].text.text = "Middle Threshold: "
	sliders[9].text.text = "Health Points: "
	
	love.graphics.setLineWidth(3)
	love.graphics.setPointSize(9)
end

function slideSlider(x)
	slider.point = x
	slider.value = math.floor((slider.range.max - slider.range.min) * (x - slider.line.left) / (slider.line.right - slider.line.left) + slider.range.min + 0.5)
end

function getLevelDensity(level, levelCap, monsterDifficulty, slope, intercept, constant)
	local firstTerm = level * -slope * monsterDifficulty / 5
	local secondTerm = (constant - intercept) * monsterDifficulty / 5 + constant
	
	return firstTerm + secondTerm
end

function getMines()
	local mines = {0, 0, 0, 0, 0, 0, 0, 0, 0}
	
	local numMonsters = module.settings.width * module.settings.height * sliders[5].value / 100
	
	local levelCap = sliders[2].value
	local monsterDifficulty = sliders[6].value
	
	local slope = -2 / (levelCap * (levelCap + 1))
	local intercept = 2 / levelCap
	local constant = 1 / levelCap
	
	for l = 1, levelCap do
		mines[l] = math.floor(getLevelDensity(l, levelCap, monsterDifficulty, slope, intercept, constant) * numMonsters + 0.5)
	end
	
	return mines
end

function getThresholds()
	local thresholds = {math.huge, math.huge, math.huge, math.huge, math.huge, math.huge, math.huge, math.huge, math.huge}
	local availableExperience = {}
	
	local numThresholds = sliders[2].value - 1
	
	availableExperience[1] = module.settings.mines[1] * module.settings.yields[1]
	
	for l = 2, 9 do
		availableExperience[l] = module.settings.mines[l] * module.settings.yields[l] + availableExperience[l - 1]
	end
	
	if numThresholds > 1 then
		thresholds[1] = math.floor(availableExperience[1] * sliders[7].value / 100 + 0.5)
	else
		thresholds[1] = availableExperience[1]
	end
	
	for l = 2, math.ceil(numThresholds / 2) do
		thresholds[l] = math.floor(availableExperience[l] * sliders[8].value / 100 + 0.5)
	end
	
	for l = math.ceil(numThresholds / 2) + 1, numThresholds do
		thresholds[l] = availableExperience[l]
	end
	
	return thresholds
end

function setSliders(values)
	for s = 1, 9 do
		sliders[s].value = values[s]
		sliders[s].point = (sliders[s].value - sliders[s].range.min) * love.graphics.getWidth() / (sliders[s].range.max - sliders[s].range.min)
	end
end

function startGame()
	module.settings.width = sliders[3].value
	module.settings.height = sliders[4].value
	module.settings.mines = getMines()
	module.settings.health = sliders[9].value
	module.settings.level = sliders[1].value
	module.settings.levelCap = sliders[2].value
	module.settings.yields = {1, 2, 4, 8, 16, 32, 64, 128, 256}
	module.settings.thresholds = getThresholds()
	
	module.isDone = true
end

function module.load()
	if not buttons then
		loadButtons()
		loadSliders()
	end
end

function module.draw()
	local points = {}
	
	for b = 1, 6 do
		love.graphics.printf(buttons[b].text, buttons[b].x, buttons[b].y, buttons[b].width, "center")
	end
	
	for s = 1, 9 do
		love.graphics.printf(sliders[s].text.text .. sliders[s].value, sliders[s].text.x, sliders[s].text.y, sliders[s].text.width, "center")
		love.graphics.line(sliders[s].line.left, sliders[s].line.y, sliders[s].line.right, sliders[s].line.y)
		points[s] = {sliders[s].point, sliders[s].line.y}
	end
	
	love.graphics.points(points)
end

function module.mousepressed(x, y, button, isTouch, numPresses)
	y = math.floor(y * 10 / love.graphics.getHeight()) + 1
	
	if y > 0 and y < 10 then
		slider = sliders[y]
		slideSlider(x)
	elseif y == 10 then
		x = math.floor(x * 6 / love.graphics.getWidth()) + 1
		
		if x == 1 then
			setSliders({1, 5, 16, 16, 12, -5, 70, 77, 10})
		elseif x == 2 then
			setSliders({1, 5, 30, 16, 21, -5, 30, 57, 10})
		elseif x == 3 then
			setSliders({1, 9, 50, 25, 21, -5, 19, 66, 30})
		elseif x == 4 then
			setSliders({1, 5, 30, 16, 26, 0, 40, 67, 10})
		elseif x == 5 then
			setSliders({0, 5, 30, 16, 21, -5, 100, 100, 1})
		elseif x == 6 then
			startGame()
		end
	end
end

function module.mousemoved(x, y, dx, dy, isTouch)
	if slider then
		slideSlider(x)
	end
end

function module.mousereleased(x, y, button, isTouch, numPresses)
	slider = nil
end

function module.keypressed(key)
	if key == "return" then
		startGame()
	end
end

function module.resize(width, height)
	for b = 1, 6 do
		buttons[b] = {x = (b - 1) * width / 6, y = height * 0.95 - 10, width = width / 6, text = buttons[b].text}
	end
	
	for s = 1, 9 do
		sliders[s].line = {left = 0, right = width, y = s * height / 10 - 15}
		sliders[s].point = (sliders[s].value - sliders[s].range.min) * width / (sliders[s].range.max - sliders[s].range.min)
		sliders[s].text = {x = 0, y = s * height / 10 - 45, width = width, text = sliders[s].text.text}
	end
end

return module