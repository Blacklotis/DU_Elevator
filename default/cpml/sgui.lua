-- Basic UI library to create clickable areas in screen units

-- ClickableArea class
ClickableArea = {}
ClickableArea.__index = ClickableArea;

function ClickableArea.new(x, y, hx, hy, fun)
    local self = setmetatable({}, ClickableArea)
    self.x = x
    self.y = y
    self.hx = hx
    self.hy = hy
    self.fun = fun
    return self
end

function ClickableArea.contains(self, x, y)
	return x > self.x and x < self.x + self.hx and
	       y > self.y and y < self.y + self.hy
end

-- SGui class
SGui = {}
SGui.__index = SGui;

function SGui.new()
    local self = setmetatable({}, SGui)
    self.areas = {}
    return self
end

function SGui.createClickableArea(self, id, x, y, hx, hy, fun)
	self.areas[id] = ClickableArea.new(x, y, hx, hy, fun)
end

function SGui.deleteClickableArea(self, id)
	table.remove(self.areas, id)
end

function SGui.createButtonArea(self, screen, x, y, hx, hy, text, fun)
	button = "<div class='bootstrap' style='background:#FF0000;width:".. (hx*100) ..
	         "vw;height:" .. (hy*100) .."vh;overflow:hidden;font-size:".. (hy*50) ..
	         "vh;'>" .. text .. "</div>"
	id = screen.setContent(x * 100, y * 100, button)
	self:createClickableArea(id, x, y, hx, hy, fun)
	return id
end

function SGui.customizeButtonArea(self, screen, id, style)
	-- here we should retrive the content via the id, inject the style and update the content again
end

function SGui.deleteButtonArea(self, screen, id)
	screen.deleteContent(id)
	self:deleteClickableArea(id)
end

function SGui.process(self, x, y)
	for key, area in pairs(self.areas) do
		if area:contains(x, y) then
			area.fun()
		end
	end
end

sgui = SGui.new()