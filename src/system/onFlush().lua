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

if not initFlush then 
    Nav.axisCommandManager:setMasterMode(1) 
    initFlush = true
end

-- validate params
if ap.enabled
then
    pitchSpeedFactor = math.max(ap.pitchSpeedFactor, 0.01)
    yawSpeedFactor = math.max(ap.yawSpeedFactor, 0.01)
    rollSpeedFactor = math.max(ap.rollSpeedFactor, 0.01)
    torqueFactor = math.max(ap.torqueFactor, 0.01)
    brakeSpeedFactor = math.max(ap.brakeSpeedFactor, 0.01)
    brakeFlatFactor = math.max(ap.brakeFlatFactor, 0.01)
    autoRollFactor = math.max(ap.autoRollFactor, 0.01)
    turnAssistFactor = math.max(ap.turnAssistFactor, 0.01)
else
    pitchSpeedFactor = math.max(pitchSpeedFactor, 0.01)
    yawSpeedFactor = math.max(yawSpeedFactor, 0.01)
    rollSpeedFactor = math.max(rollSpeedFactor, 0.01)
    torqueFactor = math.max(torqueFactor, 0.01)
    brakeSpeedFactor = math.max(brakeSpeedFactor, 0.01)
    brakeFlatFactor = math.max(brakeFlatFactor, 0.01)
    autoRollFactor = math.max(autoRollFactor, 0.01)
    turnAssistFactor = math.max(turnAssistFactor, 0.01)
end

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
if planetInfluence > 0
then
    -- stabilize orientation along the gravity, and yaw along starting yaw
    if (rollPID == nil) then
        rollPID = pid.new(0.1, 0, 2)
        pitchPID = pid.new(0.1, 0, 2)
        yawPID = pid.new(0.1, 0, 2)
    end

    if currentYawDeg < 180 then
        yawDelta = currentYawDeg - 360
    else
        yawDelta = currentYawDeg
    end

    rollPID:inject(-currentRollDeg)
    pitchPID:inject(-currentPitchDeg)
    yawPID:inject(-yawDelta)
    angularAcceleration = rollPID:get() * worldForward + pitchPID:get() * worldRight + yawPID:get() * worldUp
else
    -- cancel rotation
    local worldAngularVelocity = vec3(construct.getWorldAngularVelocity())
    angularAcceleration = - power * worldAngularVelocity
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

-- AutoNavigation regroups all the axis command by 'TargetSpeed'
local autoNavigationEngineTags = ''
local autoNavigationAcceleration = vec3()
local autoNavigationUseBrake = false

-- Longitudinal Translation
local longitudinalEngineTags = 'thrust analog longitudinal'
local longitudinalCommandType = Nav.axisCommandManager:getAxisCommandType(axisCommandId.longitudinal)
if ap.enabled
then
    Nav.axisCommandManager:setTargetSpeedCommand(axisCommandId.longitudinal, ap.longitudinalAcceleration)
    autoNavigationAcceleration = autoNavigationAcceleration + Nav.axisCommandManager:composeAxisAccelerationFromTargetSpeed(axisCommandId.longitudinal)
    autoNavigationEngineTags = autoNavigationEngineTags .. ' , ' .. longitudinalEngineTags
else
    local longitudinalAcceleration = Nav.axisCommandManager:composeAxisAccelerationFromThrottle(longitudinalEngineTags,axisCommandId.longitudinal)
    Nav:setEngineForceCommand(longitudinalEngineTags, longitudinalAcceleration, keepCollinearity)
end

-- Lateral Translation
local lateralStrafeEngineTags = 'thrust analog lateral'
local lateralCommandType = Nav.axisCommandManager:getAxisCommandType(axisCommandId.lateral)
if ap.enabled
then
    Nav.axisCommandManager:setTargetSpeedCommand(axisCommandId.lateral, ap.lateralAcceleration)
    autoNavigationAcceleration = autoNavigationAcceleration + Nav.axisCommandManager:composeAxisAccelerationFromTargetSpeed(axisCommandId.lateral)
    autoNavigationEngineTags = autoNavigationEngineTags .. ' , ' .. lateralStrafeEngineTags
else
    local lateralStrafeAcceleration =  Nav.axisCommandManager:composeAxisAccelerationFromThrottle(lateralStrafeEngineTags,axisCommandId.lateral)
    Nav:setEngineForceCommand(lateralStrafeEngineTags, lateralStrafeAcceleration, keepCollinearity)
end

-- Vertical Translation
local verticalStrafeEngineTags = 'thrust analog vertical'
local verticalCommandType = Nav.axisCommandManager:getAxisCommandType(axisCommandId.vertical)
if ap.enabled
then
    Nav.axisCommandManager:setTargetSpeedCommand(axisCommandId.vertical, ap.verticalAcceleration)
    autoNavigationAcceleration = autoNavigationAcceleration + Nav.axisCommandManager:composeAxisAccelerationFromTargetSpeed(axisCommandId.vertical)
    autoNavigationEngineTags = autoNavigationEngineTags .. ' , ' .. verticalStrafeEngineTags
else
    local verticalStrafeAcceleration = Nav.axisCommandManager:composeAxisAccelerationFromThrottle(verticalStrafeEngineTags,axisCommandId.vertical)
    Nav:setEngineForceCommand(verticalStrafeEngineTags, verticalStrafeAcceleration, keepCollinearity, 'airfoil', 'ground', '', tolerancePercentToSkipOtherPriorities)
end

-- Auto Navigation (Cruise Control)
if (autoNavigationAcceleration:len() > constants.epsilon) then
    if (brakeInput ~= 0 or autoNavigationUseBrake or math.abs(constructVelocityDir:dot(constructForward)) < 0.95)  -- if the velocity is not properly aligned with the forward
    then
        autoNavigationEngineTags = autoNavigationEngineTags .. ', brake'
    end
    
    Nav:setEngineForceCommand(autoNavigationEngineTags, autoNavigationAcceleration, dontKeepCollinearity, '', '', '', tolerancePercentToSkipOtherPriorities)
end

-- Rockets
Nav:setBoosterCommand('rocket_engine')

