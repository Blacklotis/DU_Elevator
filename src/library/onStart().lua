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
    self.currentVelocity = 0
    self.currentAcceleration = 0
    self.currentPlanetPos = vec3(0,0,0)
    self.targetPlanetPos = vec3(0,0,0)
    self.heading = 0
    self.currentTarget = vec3(0,0,0)
    self.targetHeading = 0
    self.positionHoldEnabled = false
    self.targetAltitude = 130
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
    self.lateralAcceleration = 0
    self.verticalAcceleration = 0
    self.longitudinalAcceleration = 0
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

function getSystemPositionString(currentPosition)
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

function getSystemPosition(currentPosition)
    local coords = currentPosition - Alioth.center
    local distance = coords:len()
    local altitude = distance - Alioth.radius
    local latitude = 0
    local longitude = 0
    local phi = math.atan(coords.y, coords.x)
    longitude = phi >= 0 and phi or (2 * math.pi + phi)
    latitude = math.pi / 2 - math.acos(coords.z / distance)
    return vec3(latitude, longitude, altitude)
end

function getHeading(forward) -- code provided by tomisunlucky   
    local up = -vec3(core.getWorldVertical())
    forward = forward - forward:project_on(up)
    local north = vec3(0, 0, 1)
    north = north - north:project_on(up)
    local east = north:cross(up)
    local angle = north:angle_between(forward) * constants.rad2deg
    if forward:dot(east) < 0 then
        angle = 360-angle
    end
    return angle
end