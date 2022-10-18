local finalPitchInput = 0
local finalRollInput = 0
local finalYawInput = 0
local finalBrakeInput =  brakeInput

local inspace = 0
if (unit.getAtmosphereDensity() <= constants.epsilon) then
    inspace = 1
end

local worldGravity = vec3(self.core.getWorldGravity())
local gravityDot = worldGravity:dot(axisWorldDirection)
if utils.sign(ap.thrustVector.x) == utils.sign(gravityDot) then
    else
        accelerationFromGravity = -vec3(self.core.getWorldGravity())
end

local worldVertical = vec3(core.getWorldVertical()) -- along gravity

local currentRollDeg = getRoll(worldVertical, constructForward, constructRight)
local currentRollDegAbs = math.abs(currentRollDeg)
local currentRollDegSign = utils.sign(currentRollDeg)

-- stabilize orientation along the gravity, and yaw along starting yaw
if (rollPID == nil) then
    rollPID = pid.new(0.1, 0, 2)
    pitchPID = pid.new(0.1, 0, 2)
    yawPID = pid.new(0.1, 0, 2)
end

if ap.heading < 180 then
    yawDelta = ap.heading - 360
else
    yawDelta = ap.heading
end

rollPID:inject(-currentRollDeg)
pitchPID:inject(-ap.pitch)
yawPID:inject(-yawDelta)
angularAcceleration = rollPID:get() * ap.thrustVector + pitchPID:get() * ap.thrustVector + yawPID:get() * ap.thrustVector
Nav:setEngineTorqueCommand('torque', angularAcceleration, ap.keepCollinearity, 'airfoil', '', '', ap.tolerancePercentToSkipOtherPriorities)

local brakeAcceleration = -finalBrakeInput * (brakeSpeedFactor * constructVelocity + brakeFlatFactor * constructVelocityDir)
Nav:setEngineForceCommand('brake', brakeAcceleration)

local longitudinalEngineTags = 'thrust analog longitudinal'
local longitudinalAcceleration = 0
if ap.enabled then
    ap.longitudinalAcceleration = calculateAxisThrust(self.construct.getOrientationForward(), self.construct.getWorldOrientationForward(), "forward")
    Nav:setEngineForceCommand(longitudinalEngineTags, ap.longitudinalAcceleration, ap.keepCollinearity)
else
    longitudinalAcceleration = Nav.axisCommandManager:composeAxisAccelerationFromThrottle(longitudinalEngineTags,axisCommandId.longitudinal)
    Nav:setEngineForceCommand(longitudinalEngineTags, longitudinalAcceleration, keepCollinearity)
end

if (Nav.axisCommandManager:getCurrentToTargetDeltaSpeed(axisCommandId.longitudinal) < - Nav.axisCommandManager:getTargetSpeedCurrentStep(axisCommandId.longitudinal) * 0.5) then
    ap.brakeInput = true
end

local lateralStrafeEngineTags = 'thrust analog lateral'
local lateralStrafeAcceleration = 0
if ap.enabled then
    ap.lateralStrafeAcceleration = calculateAxisThrust(self.construct.getOrientationUp(), self.construct.getWorldOrientationUp(), "up")
    Nav:setEngineForceCommand(lateralStrafeEngineTags, ap.lateralStrafeAcceleration, ap.keepCollinearity)
else
    lateralStrafeAcceleration =  Nav.axisCommandManager:composeAxisAccelerationFromThrottle(lateralStrafeEngineTags,axisCommandId.lateral)
    Nav:setEngineForceCommand(lateralStrafeEngineTags, lateralStrafeAcceleration, keepCollinearity)
end

local verticalStrafeEngineTags = 'thrust analog vertical'
local verticalStrafeAcceleration = 0
if ap.enabled then
    ap.verticalStrafeAcceleration = calculateAxisThrust(self.construct.getOrientationRight(), self.construct.getWorldOrientationRight(), "right")
    Nav:setEngineForceCommand(verticalStrafeEngineTags, ap.verticalStrafeAcceleration, ap.keepCollinearity, 'airfoil', 'ground', '', ap.tolerancePercentToSkipOtherPriorities)
else
    verticalStrafeAcceleration = Nav.axisCommandManager:composeAxisAccelerationFromThrottle(verticalStrafeEngineTags,axisCommandId.vertical)
    Nav:setEngineForceCommand(verticalStrafeEngineTags, verticalStrafeAcceleration, keepCollinearity, 'airfoil', 'ground', '', tolerancePercentToSkipOtherPriorities)
end

Nav:setBoosterCommand('rocket_engine')



-- Local functions and static variables for onFlush
local function composeAxisAccelerationFromTargetSpeedV(commandAxis, targetSpeed)

    local axisCRefDirection = vec3()
    local axisWorldDirection = vec3()

    if (commandAxis == axisCommandId.longitudinal) then
        axisCRefDirection = vec3(C.getOrientationForward())
        axisWorldDirection = constructForward
    elseif (commandAxis == axisCommandId.vertical) then
        axisCRefDirection = vec3(C.getOrientationUp())
        axisWorldDirection = constructUp
    elseif (commandAxis == axisCommandId.lateral) then
        axisCRefDirection = vec3(C.getOrientationRight())
        axisWorldDirection = constructRight
    else
        return vec3()
    end

    local gravityAcceleration = vec3(c.getWorldGravity())
    local gravityAccelerationCommand = gravityAcceleration:dot(axisWorldDirection)
    local airResistanceAcceleration = vec3(C.getWorldAirFrictionAcceleration())
    local airResistanceAccelerationCommand = airResistanceAcceleration:dot(axisWorldDirection)
    local currentAxisSpeedMS = coreVelocity:dot(axisCRefDirection)
    local targetAxisSpeedMS = targetSpeed * constants.kph2m

    if targetSpeedPID2 == nil then -- CHanged first param from 1 to 10...
        targetSpeedPID2 = pid.new(10, 0, 10.0) -- The PID used to compute acceleration to reach target speed
    end

    targetSpeedPID2:inject(targetAxisSpeedMS - currentAxisSpeedMS) -- update PID
    local accelerationCommand = targetSpeedPID2:get()
    local finalAcceleration = (accelerationCommand - airResistanceAccelerationCommand - gravityAccelerationCommand) * axisWorldDirection  -- Try to compensate air friction

    -- The hell are these? Uncommented recently just in case they were important
    --s.addMeasure("dynamic", "acceleration", "command", accelerationCommand)
    --s.addMeasure("dynamic", "acceleration", "intensity", finalAcceleration:len())

    return finalAcceleration
end