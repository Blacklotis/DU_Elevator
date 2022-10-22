local function composeAxisAccelerationFromTargetSpeed(commandAxis, targetSpeed)

    local axisCRefDirection = vec3()
    local axisWorldDirection = vec3()

    if (commandAxis == axisCommandId.longitudinal) then
        axisCRefDirection = vec3(construct.getOrientationForward())
        axisWorldDirection = vec3(construct.getWorldOrientationForward())
    elseif (commandAxis == axisCommandId.vertical) then
        axisCRefDirection = vec3(construct.getOrientationUp())
        axisWorldDirection = vec3(construct.getWorldOrientationUp())
    elseif (commandAxis == axisCommandId.lateral) then
        axisCRefDirection = vec3(construct.getOrientationRight())
        axisWorldDirection = vec3(construct.getWorldOrientationRight())
    else
        return vec3()
    end

    local gravityAcceleration = vec3(core.getWorldGravity())
    local gravityAccelerationCommand = gravityAcceleration:dot(axisWorldDirection)
    local coreVelocity = vec3(core.getVelocity())

    local airResistanceAcceleration = vec3(core.getWorldAirFrictionAcceleration())
    local airResistanceAccelerationCommand = airResistanceAcceleration:dot(axisWorldDirection)

    local currentAxisSpeedMS = coreVelocity:dot(axisCRefDirection)

    local targetAxisSpeedMS = targetSpeed * constants.kph2m

    if targetSpeedPIDLat == nil then -- Changed first param from 1 to 10...
        targetSpeedPIDLat = pid.new(10, 0, 10.0) -- The PID used to compute acceleration to reach target speed
    end

    if targetSpeedPIDLon == nil then -- Changed first param from 1 to 10...
        targetSpeedPIDLon = pid.new(10, 0, 10.0) -- The PID used to compute acceleration to reach target speed
    end

    if targetSpeedPIDVert == nil then -- Changed first param from 1 to 10...
        targetSpeedPIDVert = pid.new(10, 0, 10.0) -- The PID used to compute acceleration to reach target speed
    end

    local accelerationCommand = 0
    if (commandAxis == axisCommandId.longitudinal) then
        targetSpeedPIDLon:inject(targetAxisSpeedMS - currentAxisSpeedMS) -- update PID
        accelerationCommand = targetSpeedPIDLon:get()
    elseif (commandAxis == axisCommandId.vertical) then
        targetSpeedPIDVert:inject(targetAxisSpeedMS - currentAxisSpeedMS) -- update PID
        accelerationCommand = targetSpeedPIDVert:get()
    elseif (commandAxis == axisCommandId.lateral) then
        targetSpeedPIDLat:inject(targetAxisSpeedMS - currentAxisSpeedMS) -- update PID
        accelerationCommand = targetSpeedPIDLat:get()
    end

    local finalAcceleration = (accelerationCommand - airResistanceAccelerationCommand - gravityAccelerationCommand) * axisWorldDirection  -- Try to compensate air friction

    return finalAcceleration
end

-- constants: use 'myvar = defaultValue --export: description' to expose the variable in context menu

local pitchSpeedFactor = 0.8 --export: This factor will increase/decrease the player input along the pitch axis<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01
local yawSpeedFactor =  1 --export: This factor will increase/decrease the player input along the yaw axis<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01
local rollSpeedFactor = 1.5 --export: This factor will increase/decrease the player input along the roll axis<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01
local brakeSpeedFactor = 3 --export: When braking, this factor will increase the brake force by brakeSpeedFactor * velocity<br>Valid values: Superior or equal to 0.01
local brakeFlatFactor = 1 --export: When braking, this factor will increase the brake force by a flat brakeFlatFactor * velocity direction><br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01
local autoRoll = false --export: [Only in atmosphere]<br>When the pilot stops rolling,  flight model will try to get back to horizontal (no roll)
local autoRollFactor = 2 --export: [Only in atmosphere]<br>When autoRoll is engaged, this factor will increase to strength of the roll back to 0<br>Valid values: Superior or equal to 0.01
local turnAssist = true --export: [Only in atmosphere]<br>When the pilot is rolling, the flight model will try to add yaw and pitch to make the construct turn better<br>The flight model will start by adding more yaw the more horizontal the construct is and more pitch the more vertical it is
local turnAssistFactor = 2 --export: [Only in atmosphere]<br>This factor will increase/decrease the turnAssist effect<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01
local torqueFactor = 2 -- Force factor applied to reach rotationSpeed<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01

local finalPitchInput = 0
local finalRollInput = 0
local finalYawInput = 0
local finalBrakeInput =  brakeInput

if not homeHeading then homeHeading = 0 end

-- validate params
pitchSpeedFactor = math.max(pitchSpeedFactor, 0.01)
yawSpeedFactor = math.max(yawSpeedFactor, 0.01)
rollSpeedFactor = math.max(rollSpeedFactor, 0.01)
torqueFactor = math.max(torqueFactor, 0.01)
brakeSpeedFactor = math.max(brakeSpeedFactor, 0.01)
brakeFlatFactor = math.max(brakeFlatFactor, 0.01)
autoRollFactor = math.max(autoRollFactor, 0.01)
turnAssistFactor = math.max(turnAssistFactor, 0.01)

-- final inputs
if ap.enabled
then
    finalPitchInput = pitchInput + ap.forwardInput
    finalRollInput = rollInput + ap.yawInput
    finalYawInput = yawInput - ap.leftRightInput
    finalBrakeInput =  brakeInput
else
    finalPitchInput = pitchInput + system.getControlDeviceForwardInput()
    finalRollInput = rollInput + system.getControlDeviceYawInput()
    finalYawInput = yawInput - system.getControlDeviceLeftRightInput()
    finalBrakeInput = brakeInput
end


-- Axis
local worldVertical = vec3(core.getWorldVertical()) -- along gravity
local worldUp = vec3(construct.getWorldOrientationUp())
local worldForward = vec3(construct.getWorldOrientationForward())
local worldRight = vec3(construct.getWorldOrientationRight())
local worldVertical = vec3(core.getWorldVertical())
local constructUp = vec3(construct.getWorldOrientationUp())
local constructForward = vec3(construct.getWorldOrientationForward())
local constructRight = vec3(construct.getWorldOrientationRight())
local constructVelocity = vec3(construct.getWorldVelocity())
local constructVelocityDir = vec3(construct.getWorldVelocity()):normalize()
local currentRollDeg = getRoll(worldVertical, constructForward, constructRight)
local currentRollDegAbs = math.abs(currentRollDeg)
local currentRollDegSign = utils.sign(currentRollDeg)
local currentYawDeg = getHeading(vec3(construct.getWorldOrientationForward()))
local currentPitchDeg = -math.asin(worldForward:dot(worldVertical)) * constants.rad2deg

-- Rotation
local constructAngularVelocity = vec3(construct.getWorldAngularVelocity())
local targetAngularVelocity = finalPitchInput * pitchSpeedFactor * constructRight
                                + finalRollInput * rollSpeedFactor * constructForward
                                + finalYawInput * yawSpeedFactor * constructUp


-- are we in deep space or are we near a planet ?
local planetInfluence = unit.getClosestPlanetInfluence()
if ap.enabled
then
    -- stabilize orientation along the gravity, and yaw along starting yaw
    if (rollPID == nil) then
        rollPID = pid.new(0.1, 0, 2)
        pitchPID = pid.new(0.1, 0, 2)
        yawPID = pid.new(0.1, 0, 2)
    end


    yawDelta = homeHeading - currentYawDeg

    rollPID:inject(-currentRollDeg)
    pitchPID:inject(-currentPitchDeg)
    yawPID:inject(-yawDelta)
    angularAcceleration = rollPID:get() * worldForward + pitchPID:get() * worldRight + yawPID:get() * worldUp
else
    -- cancel rotation
    local worldAngularVelocity = vec3(construct.getWorldAngularVelocity())
    angularAcceleration = - 10 * worldAngularVelocity
end

Nav:setEngineTorqueCommand('torque', angularAcceleration, keepCollinearity, 'airfoil', '', '', tolerancePercentToSkipOtherPriorities)

-- Engine commands
local keepCollinearity = 1 -- for easier reading
local dontKeepCollinearity = 0 -- for easier reading
local tolerancePercentToSkipOtherPriorities = 1 -- if we are within this tolerance (in%), we don't go to the next priorities

if ap.enabled
then
    keepCollinearity = ap.keepCollinearity
    dontKeepCollinearity = ap.dontKeepCollinearity
    tolerancePercentToSkipOtherPriorities = ap.tolerancePercentToSkipOtherPriorities
end

-- Brakes
local brakeAcceleration = -finalBrakeInput * (brakeSpeedFactor * constructVelocity + brakeFlatFactor * constructVelocityDir)
Nav:setEngineForceCommand('brake', brakeAcceleration)

-- Longitudinal Translation
local longitudinalEngineTags = 'thrust analog longitudinal'
local longitudinalCommandType = Nav.axisCommandManager:getAxisCommandType(axisCommandId.longitudinal)
if ap.enabled
then
    local longitudinalAcceleration = composeAxisAccelerationFromTargetSpeed(axisCommandId.longitudinal, ap.longitudinalAcceleration)
    Nav:setEngineForceCommand(longitudinalEngineTags, longitudinalAcceleration, keepCollinearity)
else
    local longitudinalAcceleration = Nav.axisCommandManager:composeAxisAccelerationFromThrottle(longitudinalEngineTags,axisCommandId.longitudinal)
    Nav:setEngineForceCommand(longitudinalEngineTags, longitudinalAcceleration, keepCollinearity)
end

-- Lateral Translation
local lateralStrafeEngineTags = 'thrust analog lateral'
local lateralCommandType = Nav.axisCommandManager:getAxisCommandType(axisCommandId.lateral)
if ap.enabled
then
    local lateralStrafeAcceleration =  composeAxisAccelerationFromTargetSpeed(axisCommandId.lateral, ap.lateralAcceleration)
    Nav:setEngineForceCommand(lateralStrafeEngineTags, lateralStrafeAcceleration, keepCollinearity)
else
    local lateralStrafeAcceleration =  Nav.axisCommandManager:composeAxisAccelerationFromThrottle(lateralStrafeEngineTags,axisCommandId.lateral)
    Nav:setEngineForceCommand(lateralStrafeEngineTags, lateralStrafeAcceleration, keepCollinearity)
end

-- Vertical Translation
local verticalStrafeEngineTags = 'thrust analog vertical'
local verticalCommandType = Nav.axisCommandManager:getAxisCommandType(axisCommandId.vertical)
if ap.enabled
then
    local verticalStrafeAcceleration = composeAxisAccelerationFromTargetSpeed(axisCommandId.vertical, ap.verticalAcceleration)
    Nav:setEngineForceCommand(verticalStrafeEngineTags, verticalStrafeAcceleration, keepCollinearity, 'airfoil', 'ground', '', tolerancePercentToSkipOtherPriorities)
else
    local verticalStrafeAcceleration = Nav.axisCommandManager:composeAxisAccelerationFromThrottle(verticalStrafeEngineTags,axisCommandId.vertical)
    Nav:setEngineForceCommand(verticalStrafeEngineTags, verticalStrafeAcceleration, keepCollinearity, 'airfoil', 'ground', '', tolerancePercentToSkipOtherPriorities)
end

-- Rockets
Nav:setBoosterCommand('rocket_engine')
