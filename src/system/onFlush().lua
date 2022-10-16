
local pitchSpeedFactor = 0.8 
local yawSpeedFactor =  1 
local rollSpeedFactor = 1.5 
local brakeSpeedFactor = 3 
local brakeFlatFactor = 1 
local autoRoll = false 
local autoRollFactor = 2 
local turnAssist = true 
local turnAssistFactor = 2 
local torqueFactor = 2 

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

pitchSpeedFactor = math.max(pitchSpeedFactor, 0.01)
yawSpeedFactor = math.max(yawSpeedFactor, 0.01)
rollSpeedFactor = math.max(rollSpeedFactor, 0.01)
torqueFactor = math.max(torqueFactor, 0.01)
brakeSpeedFactor = math.max(brakeSpeedFactor, 0.01)
brakeFlatFactor = math.max(brakeFlatFactor, 0.01)
autoRollFactor = math.max(autoRollFactor, 0.01)
turnAssistFactor = math.max(turnAssistFactor, 0.01)

local finalPitchInput = pitchInput + system.getControlDeviceForwardInput()
local finalRollInput = rollInput + system.getControlDeviceYawInput()
local finalYawInput = yawInput - system.getControlDeviceLeftRightInput()
local finalBrakeInput = brakeInput


local worldVertical = vec3(core.getWorldVertical()) local constructUp = vec3(construct.getWorldOrientationUp())
local constructForward = vec3(construct.getWorldOrientationForward())
local constructRight = vec3(construct.getWorldOrientationRight())
local constructVelocity = vec3(construct.getWorldVelocity())
local constructVelocityDir = vec3(construct.getWorldVelocity()):normalize()
local currentRollDeg = getRoll(worldVertical, constructForward, constructRight)
local currentRollDegAbs = math.abs(currentRollDeg)
local currentRollDegSign = utils.sign(currentRollDeg)

local constructAngularVelocity = vec3(construct.getWorldAngularVelocity())
local targetAngularVelocity = finalPitchInput * pitchSpeedFactor * constructRight
                                + finalRollInput * rollSpeedFactor * constructForward
                                + finalYawInput * yawSpeedFactor * constructUp

if worldVertical:len() > 0.01 and unit.getAtmosphereDensity() > 0.0 then
    local autoRollRollThreshold = 1.0
        if autoRoll == true and currentRollDegAbs > autoRollRollThreshold and finalRollInput == 0 then
        local targetRollDeg = utils.clamp(0,currentRollDegAbs-30, currentRollDegAbs+30)
            if (rollPID == nil) then
            rollPID = pid.new(autoRollFactor * 0.01, 0, autoRollFactor * 0.1)         end
        rollPID:inject(targetRollDeg - currentRollDeg)
        local autoRollInput = rollPID:get()

        targetAngularVelocity = targetAngularVelocity + autoRollInput * constructForward
    end
    local turnAssistRollThreshold = 20.0
        if turnAssist == true and currentRollDegAbs > turnAssistRollThreshold and finalPitchInput == 0 and finalYawInput == 0 then
        local rollToPitchFactor = turnAssistFactor * 0.1         local rollToYawFactor = turnAssistFactor * 0.025 
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

local keepCollinearity = 1 local dontKeepCollinearity = 0 local tolerancePercentToSkipOtherPriorities = 1 
if ap.enabled
then
    keepCollinearity = ap.keepCollinearity
    dontKeepCollinearity = ap.dontKeepCollinearity
    tolerancePercentToSkipOtherPriorities = ap.tolerancePercentToSkipOtherPriorities
end

local angularAcceleration = torqueFactor * (targetAngularVelocity - constructAngularVelocity)
if (ap.enabled) then
    angularAcceleration = torqueFactor * (ap.thrustVector.z - constructAngularVelocity)
end
local airAcceleration = vec3(construct.getWorldAirFrictionAngularAcceleration())
angularAcceleration = angularAcceleration Nav:setEngineTorqueCommand('torque', angularAcceleration, keepCollinearity, 'airfoil', '', '', tolerancePercentToSkipOtherPriorities)

local brakeAcceleration = -finalBrakeInput * (brakeSpeedFactor * constructVelocity + brakeFlatFactor * constructVelocityDir)
Nav:setEngineForceCommand('brake', brakeAcceleration)

local autoNavigationEngineTags = ''
local autoNavigationAcceleration = vec3()
local autoNavigationUseBrake = false

local longitudinalEngineTags = 'thrust analog longitudinal'
local longitudinalCommandType = Nav.axisCommandManager:getAxisCommandType(axisCommandId.longitudinal)
local longitudinalAcceleration = 0
if ap.enabled then
    local axisCRefDirection = vec3(self.construct.getOrientationForward())
    local maxKPAlongAxis = self.construct.getMaxThrustAlongAxis(longitudinalEngineTags, {axisCRefDirection:unpack()})
    local forceCorrespondingToThrottle = 0
    if (inspace == 0) then
        if (ap.thrustVector.x > 0) then
            local maxAtmoForceForward = maxKPAlongAxis[1]
            forceCorrespondingToThrottle = ap.thrustVector.x * maxAtmoForceForward
        else
            local maxAtmoForceForward = maxKPAlongAxis[2]
            forceCorrespondingToThrottle = -ap.thrustVector.x * maxAtmoForceForward
        end
    else
        if (ap.thrustVector.x > 0) then
            local maxSpaceForceForward = maxKPAlongAxis[3]
            forceCorrespondingToThrottle = ap.thrustVector.x * maxSpaceForceForward
        else
            local maxSpaceForceForward = maxKPAlongAxis[4]
            forceCorrespondingToThrottle = -ap.thrustVector.x * maxSpaceForceForward
        end
    end
    longitudinalAcceleration = forceCorrespondingToThrottle / self.mass * vec3(self.construct.getWorldOrientationForward()) + accelerationFromGravity
    ap.longitudinalAcceleration = longitudinalAcceleration
    autoNavigationAcceleration = autoNavigationAcceleration + longitudinalAcceleration
else
    longitudinalAcceleration = Nav.axisCommandManager:composeAxisAccelerationFromThrottle(longitudinalEngineTags,axisCommandId.longitudinal)
end

if (longitudinalCommandType == axisCommandType.byThrottle) then
    Nav:setEngineForceCommand(longitudinalEngineTags, longitudinalAcceleration, keepCollinearity)
elseif  (longitudinalCommandType == axisCommandType.byTargetSpeed) then
        autoNavigationEngineTags = autoNavigationEngineTags .. ' , ' .. longitudinalEngineTags
    end

if (Nav.axisCommandManager:getTargetSpeed(axisCommandId.longitudinal) == 0 or 
    Nav.axisCommandManager:getCurrentToTargetDeltaSpeed(axisCommandId.longitudinal) < - Nav.axisCommandManager:getTargetSpeedCurrentStep(axisCommandId.longitudinal) * 0.5) then
    autoNavigationUseBrake = true
    ap.brakeInput = true
end

local lateralStrafeEngineTags = 'thrust analog lateral'
local lateralCommandType = Nav.axisCommandManager:getAxisCommandType(axisCommandId.lateral)
local lateralStrafeAcceleration = 0
if ap.enabled
    then
        local axisCRefDirection = vec3(self.construct.getOrientationRight())
        local maxKPAlongAxis = self.construct.getMaxThrustAlongAxis(longitudinalEngineTags, {axisCRefDirection:unpack()})
        local forceCorrespondingToThrottle = 0
        if (inspace == 0) then
            if (ap.thrustVector.z > 0) then
                local maxAtmoForceForward = maxKPAlongAxis[1]
                forceCorrespondingToThrottle = ap.thrustVector.z * maxAtmoForceForward
            else
                local maxAtmoForceForward = maxKPAlongAxis[2]
                forceCorrespondingToThrottle = -ap.thrustVector.z * maxAtmoForceForward
            end
        else
            if (ap.thrustVector.z > 0) then
                local maxSpaceForceForward = maxKPAlongAxis[3]
                forceCorrespondingToThrottle = ap.thrustVector.z * maxSpaceForceForward
            else
                local maxSpaceForceForward = maxKPAlongAxis[4]
                forceCorrespondingToThrottle = -ap.thrustVector.z * maxSpaceForceForward
            end
        end
        lateralStrafeAcceleration = forceCorrespondingToThrottle / self.mass * vec3(self.construct.getWorldOrientationRight()) + accelerationFromGravity
        ap.lateralStrafeAcceleration = lateralStrafeAcceleration
        autoNavigationAcceleration = autoNavigationAcceleration + lateralStrafeAcceleration
    else
        lateralStrafeAcceleration =  Nav.axisCommandManager:composeAxisAccelerationFromThrottle(lateralStrafeEngineTags,axisCommandId.lateral)
    end
    if (lateralCommandType == axisCommandType.byThrottle) then
        Nav:setEngineForceCommand(lateralStrafeEngineTags, lateralStrafeAcceleration, keepCollinearity)
    elseif  (lateralCommandType == axisCommandType.byTargetSpeed) then
                autoNavigationEngineTags = autoNavigationEngineTags .. ' , ' .. lateralStrafeEngineTags
end

local verticalStrafeEngineTags = 'thrust analog vertical'
local verticalCommandType = Nav.axisCommandManager:getAxisCommandType(axisCommandId.vertical)
local verticalStrafeAcceleration = 0
if ap.enabled
    then
        local axisCRefDirection = vec3(self.construct.getOrientationRight())
        local maxKPAlongAxis = self.construct.getMaxThrustAlongAxis(longitudinalEngineTags, {axisCRefDirection:unpack()})
        local forceCorrespondingToThrottle = 0
        if (inspace == 0) then
            if (ap.thrustVector.y > 0) then
                local maxAtmoForceForward = maxKPAlongAxis[1]
                forceCorrespondingToThrottle = ap.thrustVector.y * maxAtmoForceForward
            else
                local maxAtmoForceForward = maxKPAlongAxis[2]
                forceCorrespondingToThrottle = -ap.thrustVector.y * maxAtmoForceForward
            end
        else
            if (ap.thrustVector.x > 0) then
                local maxSpaceForceForward = maxKPAlongAxis[3]
                forceCorrespondingToThrottle = ap.thrustVector.y * maxSpaceForceForward
            else
                local maxSpaceForceForward = maxKPAlongAxis[4]
                forceCorrespondingToThrottle = -ap.thrustVector.y * maxSpaceForceForward
            end
        end
        verticalStrafeAcceleration = forceCorrespondingToThrottle / self.mass * vec3(self.construct.getWorldOrientationRight()) + accelerationFromGravity
        ap.verticalStrafeAcceleration = verticalStrafeAcceleration
        autoNavigationAcceleration = autoNavigationAcceleration + verticalStrafeAcceleration
    else
        verticalStrafeAcceleration = Nav.axisCommandManager:composeAxisAccelerationFromThrottle(verticalStrafeEngineTags,axisCommandId.vertical)
    end
    if (verticalCommandType == axisCommandType.byThrottle) then
        Nav:setEngineForceCommand(verticalStrafeEngineTags, verticalStrafeAcceleration, keepCollinearity, 'airfoil', 'ground', '', tolerancePercentToSkipOtherPriorities)
    elseif  (verticalCommandType == axisCommandType.byTargetSpeed) then
                autoNavigationEngineTags = autoNavigationEngineTags .. ' , ' .. verticalStrafeEngineTags 
end

if (autoNavigationAcceleration:len() > constants.epsilon) then
    if (brakeInput ~= 0 or autoNavigationUseBrake or math.abs(constructVelocityDir:dot(constructForward)) < 0.95)      then
        autoNavigationEngineTags = autoNavigationEngineTags .. ', brake'
    else
        Nav:setEngineForceCommand(autoNavigationEngineTags, autoNavigationAcceleration, ap.dontKeepCollinearity, '', '', '', ap.tolerancePercentToSkipOtherPriorities)
    end
end

Nav:setBoosterCommand('rocket_engine')

