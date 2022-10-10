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
    local finalPitchInput = pitchInput + ap.forwardInput
    local finalRollInput = rollInput + ap.yawInput
    local finalYawInput = yawInput - ap.leftRightInput
    local finalBrakeInput =  ap.brakeInput
else
    local finalPitchInput = pitchInput + system.getControlDeviceForwardInput()
    local finalRollInput = rollInput + system.getControlDeviceYawInput()
    local finalYawInput = yawInput - system.getControlDeviceLeftRightInput()
    local finalBrakeInput = brakeInput
end


-- Axis
local worldVertical = vec3(core.getWorldVertical()) -- along gravity
local constructUp = vec3(construct.getWorldOrientationUp())
local constructForward = vec3(construct.getWorldOrientationForward())
local constructRight = vec3(construct.getWorldOrientationRight())
local constructVelocity = vec3(construct.getWorldVelocity())
local constructVelocityDir = vec3(construct.getWorldVelocity()):normalize()
local currentRollDeg = getRoll(worldVertical, constructForward, constructRight)
local currentRollDegAbs = math.abs(currentRollDeg)
local currentRollDegSign = utils.sign(currentRollDeg)

-- Rotation
local constructAngularVelocity = vec3(construct.getWorldAngularVelocity())
local targetAngularVelocity = finalPitchInput * pitchSpeedFactor * constructRight
                                + finalRollInput * rollSpeedFactor * constructForward
                                + finalYawInput * yawSpeedFactor * constructUp

-- In atmosphere?
if worldVertical:len() > 0.01 and unit.getAtmosphereDensity() > 0.0 then
    local autoRollRollThreshold = 1.0
    -- autoRoll on AND currentRollDeg is big enough AND player is not rolling
    if autoRoll == true and currentRollDegAbs > autoRollRollThreshold and finalRollInput == 0 then
        local targetRollDeg = utils.clamp(0,currentRollDegAbs-30, currentRollDegAbs+30);  -- we go back to 0 within a certain limit
        if (rollPID == nil) then
            rollPID = pid.new(autoRollFactor * 0.01, 0, autoRollFactor * 0.1) -- magic number tweaked to have a default factor in the 1-10 range
        end
        rollPID:inject(targetRollDeg - currentRollDeg)
        local autoRollInput = rollPID:get()

        targetAngularVelocity = targetAngularVelocity + autoRollInput * constructForward
    end
    local turnAssistRollThreshold = 20.0
    -- turnAssist AND currentRollDeg is big enough AND player is not pitching or yawing
    if turnAssist == true and currentRollDegAbs > turnAssistRollThreshold and finalPitchInput == 0 and finalYawInput == 0 then
        local rollToPitchFactor = turnAssistFactor * 0.1 -- magic number tweaked to have a default factor in the 1-10 range
        local rollToYawFactor = turnAssistFactor * 0.025 -- magic number tweaked to have a default factor in the 1-10 range

        -- rescale (turnAssistRollThreshold -> 180) to (0 -> 180)
        local rescaleRollDegAbs = ((currentRollDegAbs - turnAssistRollThreshold) / (180 - turnAssistRollThreshold)) * 180
        local rollVerticalRatio = 0
        if rescaleRollDegAbs < 90 then
            rollVerticalRatio = rescaleRollDegAbs / 90
        elseif rescaleRollDegAbs < 180 then
            rollVerticalRatio = (180 - rescaleRollDegAbs) / 90
        end

        rollVerticalRatio = rollVerticalRatio * rollVerticalRatio

        local turnAssistYawInput = - currentRollDegSign * rollToYawFactor * (1.0 - rollVerticalRatio)
        local turnAssistPitchInput = rollToPitchFactor * rollVerticalRatio

        targetAngularVelocity = targetAngularVelocity
                            + turnAssistPitchInput * constructRight
                            + turnAssistYawInput * constructUp
    end
end

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

-- Rotation
local angularAcceleration = torqueFactor * (targetAngularVelocity - constructAngularVelocity)
local airAcceleration = vec3(construct.getWorldAirFrictionAngularAcceleration())
angularAcceleration = angularAcceleration - airAcceleration -- Try to compensate air friction
Nav:setEngineTorqueCommand('torque', angularAcceleration, keepCollinearity, 'airfoil', '', '', tolerancePercentToSkipOtherPriorities)

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
local longitudinalAcceleration = 0
if ap.enabled
then
    longitudinalAcceleration = ap.longitudinalAcceleration
else
    longitudinalAcceleration = Nav.axisCommandManager:composeAxisAccelerationFromThrottle(longitudinalEngineTags,axisCommandId.longitudinal)
end

if (longitudinalCommandType == axisCommandType.byThrottle) then
    Nav:setEngineForceCommand(longitudinalEngineTags, longitudinalAcceleration, keepCollinearity)
elseif  (longitudinalCommandType == axisCommandType.byTargetSpeed) then
    longitudinalAcceleration = Nav.axisCommandManager:composeAxisAccelerationFromTargetSpeed(axisCommandId.longitudinal)
    autoNavigationEngineTags = autoNavigationEngineTags .. ' , ' .. longitudinalEngineTags
    autoNavigationAcceleration = autoNavigationAcceleration + longitudinalAcceleration
end

if (Nav.axisCommandManager:getTargetSpeed(axisCommandId.longitudinal) == 0 or -- we want to stop
    Nav.axisCommandManager:getCurrentToTargetDeltaSpeed(axisCommandId.longitudinal) < - Nav.axisCommandManager:getTargetSpeedCurrentStep(axisCommandId.longitudinal) * 0.5) -- if the longitudinal velocity would need some braking
then
    autoNavigationUseBrake = true
    ap.brakeInput = true
end

-- Lateral Translation
local lateralStrafeEngineTags = 'thrust analog lateral'
local lateralCommandType = Nav.axisCommandManager:getAxisCommandType(axisCommandId.lateral)
local lateralStrafeAcceleration = 0
if ap.enabled
then
    lateralStrafeAcceleration =  ap.lateralAcceleration
else
    lateralStrafeAcceleration =  Nav.axisCommandManager:composeAxisAccelerationFromThrottle(lateralStrafeEngineTags,axisCommandId.lateral)
end
if (lateralCommandType == axisCommandType.byThrottle) then
    Nav:setEngineForceCommand(lateralStrafeEngineTags, lateralStrafeAcceleration, keepCollinearity)
elseif  (lateralCommandType == axisCommandType.byTargetSpeed) then
    autoNavigationAcceleration = autoNavigationAcceleration + Nav.axisCommandManager:composeAxisAccelerationFromTargetSpeed(axisCommandId.lateral)
    autoNavigationEngineTags = autoNavigationEngineTags .. ' , ' .. lateralStrafeEngineTags
end

-- Vertical Translation
local verticalStrafeEngineTags = 'thrust analog vertical'
local verticalCommandType = Nav.axisCommandManager:getAxisCommandType(axisCommandId.vertical)
local verticalStrafeAcceleration = 0
if ap.enabled
then
    verticalStrafeAcceleration = ap.verticalAcceleration
else
    verticalStrafeAcceleration = Nav.axisCommandManager:composeAxisAccelerationFromThrottle(verticalStrafeEngineTags,axisCommandId.vertical)
end
if (verticalCommandType == axisCommandType.byThrottle) then
    Nav:setEngineForceCommand(verticalStrafeEngineTags, verticalStrafeAcceleration, keepCollinearity, 'airfoil', 'ground', '', tolerancePercentToSkipOtherPriorities)
elseif  (verticalCommandType == axisCommandType.byTargetSpeed) then
    autoNavigationAcceleration = autoNavigationAcceleration + Nav.axisCommandManager:composeAxisAccelerationFromTargetSpeed(axisCommandId.vertical)
    autoNavigationEngineTags = autoNavigationEngineTags .. ' , ' .. verticalStrafeEngineTags 
end

-- Auto Navigation (Cruise Control)
if (autoNavigationAcceleration:len() > constants.epsilon) then
    if (brakeInput ~= 0 or autoNavigationUseBrake or math.abs(constructVelocityDir:dot(constructForward)) < 0.95)  -- if the velocity is not properly aligned with the forward
    then
        autoNavigationEngineTags = autoNavigationEngineTags .. ', brake'
    end
    if ap.enabled
    then
        Nav:setEngineForceCommand(autoNavigationEngineTags, ap.NavigationAcceleration, dontKeepCollinearity, '', '', '', tolerancePercentToSkipOtherPriorities)
    else
        Nav:setEngineForceCommand(autoNavigationEngineTags, autoNavigationAcceleration, dontKeepCollinearity, '', '', '', tolerancePercentToSkipOtherPriorities)
    end
end

-- Rockets
Nav:setBoosterCommand('rocket_engine')

