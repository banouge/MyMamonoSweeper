local Game = require("Game")
local Menu = require("Menu")

local activeModule

function love.load()
	activeModule = Menu
	activeModule.load()
end

function love.update()
	if Game.isDone then
		Game.isDone = false
		activeModule = Menu
		Menu.load()
	elseif Menu.isDone then
		Menu.isDone = false
		activeModule = Game
		Game.load(Menu.settings)
	end
end

function love.draw()
	activeModule.draw()
end

function love.mousepressed(x, y, button, isTouch, numPresses)
	activeModule.mousepressed(x, y, button, isTouch, numPresses)
end

function love.mousemoved(x, y, dx, dy, isTouch)
	activeModule.mousemoved(x, y, dx, dy, isTouch)
end

function love.mousereleased(x, y, button, isTouch, numPresses)
	activeModule.mousereleased(x, y, button, isTouch, numPresses)
end

function love.keypressed(key)
	activeModule.keypressed(key)
end

function love.resize(width, height)
	Game.resize(width, height)
	Menu.resize(width, height)
end