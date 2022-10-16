AutoPilot = {}
function AutoPilot:new(enabled)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    self.enabled = enabled
    self.brakeInput = 0
    self.currentAltitude = 0
    self.currentPlanet = 0
    self.currentPosition = vec3(0,0,0)
    self.dontKeepCollinearity = 0     
    self.heading = 0
    self.homePosition = vec3(0,0,0)
    self.keepCollinearity = 1     
    self.dontKeepCollinearity = 0
    self.magnitude = 0
    self.pitch = 0
    self.startingPosition = vec3(0,0,0)
    self.targetPosition = vec3(0,0,0)
    self.thrustVector = vec3(0,0,0)
    self.tolerancePercentToSkipOtherPriorities = 1
    self.longitudinalAcceleration = 0
    self.lateralStrafeAcceleration = 0
    self.verticalStrafeAcceleration = 0
    return o
end

function timeToTarget(distance, currentSpeed)
    return distannce/currentspeed
end

function stoppingDistance(velocity, gravity, friction)
    return math.pow(velocity,2) / 2 * friction * gravity
end

function getAltitude(currentPosition)
    local coords = currentPosition - vec3(-8.00, -8.00, -126303.00)
    local distance = coords:len()
    return distance - 126067.90  
end

function getDestination(center, location, height)
    local dx = location.x - center.x
    local dy = location.y - center.y
    local dz = location.z - center.z
    local k = math.sqrt( (height^2) / ((dx^2)+ (dy^2)+(dz^2)) )
    local x3 = location.x + dx * k;
    local y3 = location.y + dy * k;
    local z3 = location.z + dz * k;
    return vec3(x3,y3,z3)
end

function getSystemPosition(currentPosition, asString)
    local coords = currentPosition - vec3(-8.00, -8.00, -126303.00)
    local distance = coords:len()
    local altitude = distance - 126067.90
    local phi = math.atan(coords.y, coords.x)
    local latitude = math.pi / 2 - math.acos(coords.z / distance)
    local longitude = phi >= 0 and phi or (2 * math.pi + phi)
    if(asString) then
        return ("::pos{0,2,"..math.deg(latitude)..","..math.deg(longitude)..","..altitude.."}")
    else 
        return vec3(latitude, longitude, altitude)
    end
end

function calculateThrustVector()
    adjustedPosition = ap.targetPosition - ap.currentPosition
    local magnitude = adjustedPosition
    local heading = math.atan(adjustedPosition.z, adjustedPosition.x) * constants.rad2deg
    local xzPlane = math.sqrt(adjustedPosition.x * adjustedPosition.x + adjustedPosition.z * adjustedPosition.z)
    local pitch = math.atan(adjustedPosition.y, xzPlane) * constants.rad2deg
    return vec3(magnitude, heading, pitch)
end


