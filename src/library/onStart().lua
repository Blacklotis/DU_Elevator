Planet = {}
function Planet:new(system,id,surfaceArea,center,radius)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    self.system = system
    self.id = id
    self.surfaceArea = surfaceArea or 0
    self.center = center or vec3(0,0,0)
    self.radius = radius or 0
    return o
end

AutoPilot = {}
function AutoPilot:new(enabled)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    self.enabled = enabled
    self.currentPlanet = nil
    self.currentPosition = 0
    self.currentAltitude = 0
    self.currentTarget = vec3(0,0,0)
    self.positionHoldEnabled = false
    self.targetAltitude = 200
    self.altitudePID = pid.new(0.1,0.00001,0.5)
    self.thrustUp = unit.getEngineThrust("thrustUp")
    self.thrustDown = unit.getEngineThrust("thrustDown")
    self.thrustRight = unit.getEngineThrust("thrustRight")
    self.thrustLeft = unit.getEngineThrust("thrustLeft")
    self.thrustForwards = unit.getEngineThrust("thrustForwards")
    self.thrustBack = unit.getEngineThrust("thrustBack")
    self.brakeInput = brakeInput
    self.pitchSpeedFactor = 0
    self.yawSpeedFactor = 0
    self.rollSpeedFactor = 0
    self.torqueFactor = 0
    self.brakeSpeedFactor = 0
    self.brakeFlatFactor = 0
    self.autoRollFactor = 0
    self.turnAssistFactor = 0
    self.forwardInput = system.getControlDeviceForwardInput()
    self.yawInput = system.getControlDeviceYawInput()
    self.leftRightInput = system.getControlDeviceLeftRightInput()
    self.keepCollinearity = 1 -- for easier reading
    self.dontKeepCollinearity = 0 -- for easier reading
    self.tolerancePercentToSkipOtherPriorities = 1 -- if we are within this tolerance (in%), we don't go to the next priorities
    return o
end

function timeToTarget(distance, currentSpeed)
    return distannce/currentspeed
end

function stoppingDistance(velocity, gravity, friction)
    return math.pow(velocity,2) / 2 * friction * gravity
end

function round(num, precision)
    local mult = 10^(precision or 0)
    return math.floor(num * mult + 0.5) / mult
end 

function getAltitude(currentPosition, currentPlanet)
    local coords = currentPosition - currentPlanet.center
    local distance = coords:len()
    return distance - currentPlanet.radius  
end

function getDestination(center, location, height)
	local dx = location.x - center.x
	local dy = location.y - center.y
	local dz = location.z - center.z
	local k = math.sqrt( (height^2) / ((dx^2)+ (dy^2)+(dz^2)) )
	local x3 = location.x + dx * k;
	local y3 = location.y + dy * k;
	local z3 = location.z + dz * k;
	return vec3({x3,y3,z3})
end

function getSystemPosition(currentPosition)
    local coords = currentPosition - Alioth.center
    local distance = coords:len()
    local altitude = distance - Alioth.radius
    local latitude = 0
    local longitude = 0
    local phi = math.atan(coords.y, coords.x)
    longitude = phi >= 0 and phi or (2 * math.pi + phi)
    latitude = math.pi / 2 - math.acos(coords.z / distance)
    return "::pos{0,2,"..math.deg(latitude)..","..math.deg(longitude)..","..altitude.."}"
end

--Prints tables that only contain numbers
function printNumericTable(o, precision)
   if type(o) == 'table' then
      local s = ''
      for k,v in pairs(o) do
          s = s .. printNumericTable(round(v, 2), precision) .. ', '
      end
      return s
   else
      return tostring(o)
   end
end

--Prints JSON style objects from a table
function printTable(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. printTable(v) .. ', '
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

renderScript = [[

	newState = {
		pos1 = 1,
		pos2 = 2,
		pos3 = 3,
		pos4 = 4,
		pos5 = 5,
        diagnostics = false,
        clickX = 0,
        clickY = 0,
	}

    local json = require('dkjson')
    newState = json.decode(getInput()) or {}
    local rx, ry = getResolution()
    local deltaT = getDeltaTime()

    local symbols = {}
    
    --local fascia = loadImage("assets.prod.novaquark.com/59180/5cef1cfc-444d-4d4e-af78-0a82c2c93ce3.png")

    if not init then
        init = true
        blinkCounter = 0
        blinkOn = true
    end

	local top_layer = createLayer()
	local font = loadFont('Play-Bold', 14)

	setNextStrokeWidth(top_layer, 1) 
	setNextStrokeColor(top_layer, 0, 255, 255, 0.8)
	setNextShadow(top_layer, 5, 0, 255, 255, .5)
	addLine(top_layer, 140, (ry/2) + (imageSize/2), rx-140, (ry/2) + (imageSize/2))

	setNextStrokeWidth(top_layer, 1) 
	setNextStrokeColor(top_layer, 0, 255, 255, 0.8) 
	setNextShadow(top_layer, 5, 0, 255, 255, .5)
	addLine(top_layer, 140, (ry/2) - (imageSize/2), rx-140, (ry/2) - (imageSize/2))

	-- add line select triangles
	 local font1 = loadFont('Play-Bold', 30)
     local font2 = loadFont('Play-Bold', 20)
     addText(top_layer, font2, newState.pos1, .32*rx, .945*ry)
     addText(top_layer, font2, newState.pos2, .75*rx, .945*ry)
     setNextTextAlign(top_layer, AlignH_Center, AlignV_Middle)
	 addText(top_layer, font2, newState.pos3, rx/2, .83*ry)
     addText(top_layer, font1, newState.pos4, rx-40, .08*ry)
	
     if newState.diagnostics then
         addText(top_layer, font, "CLICK:(" .. newState.clickX .. "," .. newState.clickY.. ")", 100, ry-80)
     end
     
	--addImage(top_layer, fascia, 0, 0, rx, ry)

	-- render cost profiler 
	if newState.diagnostics then 
	 local layer = createLayer() 
	 local font = loadFont('Play-Bold', 14) 
	 setNextFillColor(layer, 1, 1, 1, 1) 
	 addText(layer, font, string.format('render cost : %d / %d',  getRenderCost(), getRenderCostMax()), 8, 16) 
	end

	requestAnimationFrame(1)
]]