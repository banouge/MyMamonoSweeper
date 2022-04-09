local module = {}

module.isDone = false

local assets
local width = 1
local height = 1
local mines
local minefield
local marks
local markQualifiers
local visibility
local health
local maxHealth
local healthRatio
local experience
local level
local levelCap
local yields
local thresholds
local experienceRatio
local numToReveal
local title
local squareScale
local squareSize
local isDone

function loadAssets()
	assets = {}
	
	assets.hidden = love.graphics.newImage("Assets/Hidden.png")
	assets.revealed = love.graphics.newImage("Assets/Revealed.png")
	
	assets.greater = love.graphics.newImage("Assets/Greater.png")
	assets.less = love.graphics.newImage("Assets/Less.png")
	assets.guess = love.graphics.newImage("Assets/Guess.png")
	
	assets["00"] = love.graphics.newImage("Assets/00.png")
	assets["10"] = love.graphics.newImage("Assets/10.png")
	assets["20"] = love.graphics.newImage("Assets/20.png")
	assets["30"] = love.graphics.newImage("Assets/30.png")
	assets["40"] = love.graphics.newImage("Assets/40.png")
	assets["50"] = love.graphics.newImage("Assets/50.png")
	assets["60"] = love.graphics.newImage("Assets/60.png")
	assets["70"] = love.graphics.newImage("Assets/70.png")
	assets["80"] = love.graphics.newImage("Assets/80.png")
	assets["90"] = love.graphics.newImage("Assets/90.png")
	
	assets["0"] = love.graphics.newImage("Assets/0.png")
	assets["1"] = love.graphics.newImage("Assets/1.png")
	assets["2"] = love.graphics.newImage("Assets/2.png")
	assets["3"] = love.graphics.newImage("Assets/3.png")
	assets["4"] = love.graphics.newImage("Assets/4.png")
	assets["5"] = love.graphics.newImage("Assets/5.png")
	assets["6"] = love.graphics.newImage("Assets/6.png")
	assets["7"] = love.graphics.newImage("Assets/7.png")
	assets["8"] = love.graphics.newImage("Assets/8.png")
	assets["9"] = love.graphics.newImage("Assets/9.png")
end

function plantMines()
	local positions = {}
	
	for x = 1, width do
		for y = 1, height do
			positions[#positions + 1] = {
				x = x,
				y = y
			}
		end
	end
	
	for magnitude, amount in pairs(mines) do
		for m = 1, amount do
			local index = love.math.random(#positions)
			
			minefield[positions[index].x][positions[index].y] = magnitude
			
			positions[index] = positions[#positions]
			positions[#positions] = nil
		end
	end
end

function loadMinefield(settings)
	width = settings.width
	height = settings.height
	mines = settings.mines
	minefield = {}
	marks = {}
	markQualifiers = {}
	visibility = {}
	health = settings.health
	maxHealth = health
	healthRatio = health / maxHealth
	experience = 0
	level = settings.level
	levelCap = settings.levelCap
	yields = settings.yields
	thresholds = settings.thresholds
	experienceRatio = experience / thresholds[1]
	numToReveal = width * height
	
	if level == 0 then
		for magnitude, amount in pairs(mines) do
			numToReveal = numToReveal - amount
		end
		
		thresholds[0] = math.huge
	end
	
	for x = 1, width do
		minefield[x] = {}
		marks[x] = {}
		markQualifiers[x] = {}
		visibility[x] = {}
		
		for y = 1, height do
			minefield[x][y] = 0
			marks[x][y] = 0
		end
	end
	
	plantMines()
end

function updateTitle()
	local titleLeft = "Level: " .. level .. ", Health: " .. health .. ", Experience: " .. experience .. ", Threshold: " .. thresholds[level] .. "\n"
	local titleRight = ""
	
	for magnitude, amount in pairs(mines) do
		if amount ~= 0 then
			titleRight = titleRight .. ", Lvl " .. magnitude .. ": " .. amount
		end
	end
	
	title = titleLeft .. titleRight:sub(3)
end

function getNumAdjacentMines(x, y)
	local numAdjacent = 0
	
	for u = math.max(x - 1, 1), math.min(x + 1, width) do
		for v = math.max(y - 1, 1), math.min(y + 1, height) do
			numAdjacent = numAdjacent + minefield[u][v]
		end
	end
	
	return numAdjacent
end

function endGame()
	isDone = true
	
	for x, column in pairs(minefield) do
		for y, magnitude in pairs(column) do
			if not visibility[x][y] then
				marks[x][y] = magnitude
				markQualifiers[x][y] = nil
			end
		end
	end
end

function fight(x, y)
	local enemyHealth = minefield[x][y]
	
	while health > 0 and enemyHealth > 0 do
		enemyHealth = enemyHealth - level
		health = health - minefield[x][y]
	end
	
	if enemyHealth <= 0 then
		if minefield[x][y] > 0 then
			health = health + minefield[x][y]
			healthRatio = health / maxHealth
			experience = experience + yields[minefield[x][y]]
			mines[minefield[x][y]] = mines[minefield[x][y]] - 1
			minefield[x][y] = 0
			
			if thresholds[level] <= experience then
				level = level + 1
			end
			
			experienceRatio = experience / thresholds[level]
		end
		
		if not visibility[x][y] then
			numToReveal = numToReveal - 1
			visibility[x][y] = true
			markQualifiers[x][y] = nil
		end
		
		for u = math.max(x - 1, 1), math.min(x + 1, width) do
			for v = math.max(y - 1, 1), math.min(y + 1, height) do
				if visibility[u][v] then
					local originalNumAdjacentMines = marks[u][v]
					
					marks[u][v] = getNumAdjacentMines(u, v)
					
					if marks[u][v] == 0 and originalNumAdjacentMines > 0 then
						dig(u, v)
					end
				end
			end
		end
		
		if numToReveal > 0 then
			return true
		end
	
		title = "You win!"
	else
		healthRatio = 0
		title = "You lose..."
	end
	
	endGame()
	return false
end

function dig(x, y)
	if fight(x, y) then
		if getNumAdjacentMines(x, y) == 0 then
			for u = math.max(x - 1, 1), math.min(x + 1, width) do
				for v = math.max(y - 1, 1), math.min(y + 1, height) do
					if not visibility[u][v] and marks[u][v] == 0 then
						dig(u, v)
					end
				end
			end
		end
	end
end

function module.load(settings)
	if not assets then
		loadAssets()
	end
	
	loadMinefield(settings)
	updateTitle()
	
	squareScale = math.min(love.graphics.getWidth() / (27 * width + 54), love.graphics.getHeight() / (27 * height + 27))
	squareSize = 27 * squareScale
	isDone = false
end

function module.draw()
	for x = 1, width do
		for y = 1, height do
			if visibility[x][y] then
				love.graphics.draw(assets.revealed, x * squareSize - squareSize, y * squareSize - squareSize, 0, squareScale)
			else
				love.graphics.draw(assets.hidden, x * squareSize - squareSize, y * squareSize - squareSize, 0, squareScale)
			end
			
			if marks[x][y] > 0 then
				if markQualifiers[x][y] then
					love.graphics.draw(assets[markQualifiers[x][y]], x * squareSize - squareSize, y * squareSize - squareSize, 0, squareScale)
				else
					love.graphics.draw(assets[(math.floor(marks[x][y] / 10)) .. "0"], x * squareSize - squareSize, y * squareSize - squareSize, 0, squareScale)
				end
				
				love.graphics.draw(assets[(marks[x][y] % 10) .. ""], x * squareSize - squareSize, y * squareSize - squareSize, 0, squareScale)
			end
		end
	end
	
	love.graphics.setColor(1, 0, 0)
	love.graphics.rectangle("fill", width * squareSize, height * squareSize * (1 - healthRatio), squareSize, height * squareSize * healthRatio)
	
	love.graphics.setColor(0, 0, 1)
	love.graphics.rectangle("fill", width * squareSize + squareSize, height * squareSize * (1 - experienceRatio), squareSize, height * squareSize * experienceRatio)
	
	love.graphics.setColor(1, 1, 1)
	love.graphics.printf(title, 0, height * squareSize, width * squareSize, "center")
end

function module.mousepressed(x, y, button, isTouch, numPresses)
	if isDone then
		module.isDone = true
		return
	end
	
	x = math.floor(x / squareSize) + 1
	y = math.floor(y / squareSize) + 1
	
	if x >= 1 and x <= width and y >= 1 and y <= height then
		if not visibility[x][y] and marks[x][y] <= level and not markQualifiers[x][y] then
			if marks[x][y] > 0 then
				mines[marks[x][y]] = mines[marks[x][y]] + 1
			end
			
			dig(x, y)
		end
	end
	
	if not isDone then
		updateTitle()
	end
end

function module.mousemoved(x, y, dx, dy, isTouch)
	
end

function module.mousereleased(x, y, button, isTouch, numPresses)
	
end

function module.keypressed(key)
	if isDone then
		module.isDone = true
		return
	end
	
	local x, y = love.mouse.getPosition()
	
	x = math.floor(x / squareSize) + 1
	y = math.floor(y / squareSize) + 1
	
	if x >= 1 and x <= width and y >= 1 and y <= height and not visibility[x][y] then
		if key == "0" then
			if marks[x][y] > 0 and not markQualifiers[x][y] then
				mines[marks[x][y]] = mines[marks[x][y]] + 1
			end
			
			marks[x][y] = 0
			markQualifiers[x][y] = nil
		elseif key == "1" then
			if not markQualifiers[x][y] then
				if marks[x][y] > 0 then
					mines[marks[x][y]] = mines[marks[x][y]] + 1
				end
				
				mines[1] = mines[1] - 1
			end
			
			marks[x][y] = 1
		elseif key == "2" then
			if not markQualifiers[x][y] then
				if marks[x][y] > 0 then
					mines[marks[x][y]] = mines[marks[x][y]] + 1
				end
				
				mines[2] = mines[2] - 1
			end
			
			marks[x][y] = 2
		elseif key == "3" then
			if not markQualifiers[x][y] then
				if marks[x][y] > 0 then
					mines[marks[x][y]] = mines[marks[x][y]] + 1
				end
				
				mines[3] = mines[3] - 1
			end
			
			marks[x][y] = 3
		elseif key == "4" then
			if not markQualifiers[x][y] then
				if marks[x][y] > 0 then
					mines[marks[x][y]] = mines[marks[x][y]] + 1
				end
				
				mines[4] = mines[4] - 1
			end
			
			marks[x][y] = 4
		elseif key == "5" then
			if not markQualifiers[x][y] then
				if marks[x][y] > 0 then
					mines[marks[x][y]] = mines[marks[x][y]] + 1
				end
				
				mines[5] = mines[5] - 1
			end
			
			marks[x][y] = 5
		elseif key == "6" then
			if not markQualifiers[x][y] then
				if marks[x][y] > 0 then
					mines[marks[x][y]] = mines[marks[x][y]] + 1
				end
				
				mines[6] = mines[6] - 1
			end
			
			marks[x][y] = 6
		elseif key == "7" then
			if not markQualifiers[x][y] then
				if marks[x][y] > 0 then
					mines[marks[x][y]] = mines[marks[x][y]] + 1
				end
				
				mines[7] = mines[7] - 1
			end
			
			marks[x][y] = 7
		elseif key == "8" then
			if not markQualifiers[x][y] then
				if marks[x][y] > 0 then
					mines[marks[x][y]] = mines[marks[x][y]] + 1
				end
				
				mines[8] = mines[8] - 1
			end
			
			marks[x][y] = 8
		elseif key == "9" then
			if not markQualifiers[x][y] then
				if marks[x][y] > 0 then
					mines[marks[x][y]] = mines[marks[x][y]] + 1
				end
				
				mines[9] = mines[9] - 1
			end
			
			marks[x][y] = 9
		elseif key == "." then
			if markQualifiers[x][y] == "greater" then
				markQualifiers[x][y] = nil
				mines[marks[x][y]] = mines[marks[x][y]] - 1
			elseif marks[x][y] > 0 then
				if not markQualifiers[x][y] then
					mines[marks[x][y]] = mines[marks[x][y]] + 1
				end
				
				markQualifiers[x][y] = "greater"
			end
		elseif key == "," then
			if markQualifiers[x][y] == "less" then
				markQualifiers[x][y] = nil
				mines[marks[x][y]] = mines[marks[x][y]] - 1
			elseif marks[x][y] > 0 then
				if not markQualifiers[x][y] then
					mines[marks[x][y]] = mines[marks[x][y]] + 1
				end
				
				markQualifiers[x][y] = "less"
			end
		elseif key == "/" then
			if markQualifiers[x][y] == "guess" then
				markQualifiers[x][y] = nil
				mines[marks[x][y]] = mines[marks[x][y]] - 1
			elseif marks[x][y] > 0 then
				if not markQualifiers[x][y] then
					mines[marks[x][y]] = mines[marks[x][y]] + 1
				end
				
				markQualifiers[x][y] = "guess"
			end
		end
	end
	
	if not isDone then
		updateTitle()
	end
end

function module.resize(w, h)
	squareScale = math.min(w / (27 * width + 54), h / (27 * height + 27))
	squareSize = 27 * squareScale
end

return module