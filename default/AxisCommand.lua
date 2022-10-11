-- ################################################################################
-- #                  Copyright 2014-2018 Novaquark SAS                           #
-- ################################################################################

vec3      = require("cpml/vec3")
utils     = require("cpml/utils")
constants = require("cpml/constants")
pid       = require("cpml/pid")

controlMasterModeId = 
{
    travel = 0,
    cruise = 1,
}

axisCommandId = 
{
    longitudinal = 0,
    lateral = 1,
    vertical = 2,
}

axisCommandType = 
{
    byThrottle = 0,
    byTargetSpeed = 1,
    unused = 2,
}

-----------------------------------------------------------------------------------
-- AxisCommand Lua Object                                
--
-- The AxisCommand is a helper 'class' to deal with the command along an axis
--
-- It deals with:
--       * Command by Throttle / TargetSpeed
--       * Keyboard button repeat / Mouse Wheel 
--       * Computing resulting acceleration needed for Throttle / TargetSpeed
--       
-----------------------------------------------------------------------------------

AxisCommand = {}
AxisCommand.__index = AxisCommand

function AxisCommand.new(commandAxis, control, core, system)
    local self = setmetatable({}, AxisCommand)

    self.control = control
    self.system = system
    self.core = core
    self.construct = DUConstruct
    self.mass = self.construct.getMass()

    self.commandAxis = commandAxis -- The axis type (longitudinal, vertical, lateral)
    self.commandType = axisCommandType.byThrottle -- The current control type (Throttle / TargetSpeed)

    self.actionRepeatDelay = 0.6 -- Keyboard action repeat delay
    self.actionTriggeredTime = 0 -- To compute the repeat delay
    self.mouseBackToNeutralDuration = 0.5 -- Duration to setup the following countdown
    self.mouseBackToNeutralCountdown = 0 -- When the mouse wheel is back to 0, we start this countdown to know if the next wheel values should be considered as the same sequence or a new one
    
    -- An input sequence is considered as a keyboard action + repeats OR mouse wheel inputs without mouseBackToNeutralCountdown reaching 0
    self.updateSequenceStartValue = 0 -- The value of the command at the start of the sequence (We will use this value to stop the sequence at 0)

    self.throttle = 0 -- The command value as throttle
    self.throttleAtomicStepValue = 0 -- The throttle increase / decrease per steps
    self.throttleMouseStepScale = 1 -- The mouse will apply throttleMouseStepScale * throttleAtomicStepValue per increment

    self.targetSpeed = 0  -- The command value as target speed
    self.targetSpeedPID = pid.new(1, 0, 10.0) -- The PID used to compute acceleration to reach target speed
    self.customTargetSpeedRanges = {} -- custom ranges given by the .conf will be used to fill targetSpeedRanges
    self.targetSpeedRanges = {} -- The target speed ranges that will be used by the cruise control mode (only useful for longitudinal axis)
    self.targetSpeedMaxRange = 30000 -- The last entry in targetSpeedRanges
    self.targetSpeedAtomicStepValue = 0 -- The target speed increase / decrease per step. It's the default value as it might increase depending of the speed range we are in
    self.lastCurrentSpeed = 0 -- Last current speed registered (along this axis)
    
    if (self.commandAxis == axisCommandId.longitudinal) then
        -- Longitudinal axis is the primary axis with more precise control
        self.throttleAtomicStepValue = 0.05 -- 5%
        self.throttleMouseStepScale = 2 -- 10% per mouse wheel increment
        self.targetSpeedAtomicStepValue = 10. -- 10 km/h
    elseif (self.commandAxis == axisCommandId.vertical) then
        -- Vertical is a secondary axis without much control.
        -- It's all or nothing
        self.throttleAtomicStepValue = 1 -- 100%
        self.targetSpeedAtomicStepValue = 50.
    elseif (self.commandAxis == axisCommandId.lateral) then
        -- Lateral is a secondary axis without much control.
        -- It's all or nothing
        self.throttleAtomicStepValue = 1 -- 100%
        self.targetSpeedAtomicStepValue = 50.
    end

    return self
end

function AxisCommand.setupCustomTargetSpeedRanges(self, customTargetSpeedRanges)
    self.customTargetSpeedRanges = customTargetSpeedRanges
end

function AxisCommand.getTargetSpeedCurrentStep(self)
    return self:computeTargetSpeedStepValue(self.lastCurrentSpeed, 0)    
end

-- Compute the TargetSpeedStepValue for the reference speed and wanting to apply commandStep
function AxisCommand.computeTargetSpeedStepValue(self, referenceSpeed, commandStep)    
    
    -- Here we do this little trip to make sure we have the same values going up or down
    -- Ex: If we want a step of 10km/h before 100km/k and 20km/h after.
    --     At speed 100km/h, we want a step of 20 in we go up and 10 if we go down
    local commandStepDirection = utils.sign(commandStep)    
    local referenceSpeedInDirection = referenceSpeed + commandStepDirection;

    if (self.commandAxis == axisCommandId.longitudinal) then
        for _,limit in pairs(self.targetSpeedRanges) do
            if referenceSpeedInDirection <= limit then 
                local targetSpeedStep = limit / 100
                -- we keep it a multiple of targetSpeedAtomicStepValue
                return math.ceil(targetSpeedStep / self.targetSpeedAtomicStepValue) * self.targetSpeedAtomicStepValue
            end
        end 
    end
    return self.targetSpeedAtomicStepValue
end

function AxisCommand.onMasterModeChanged(self, masterModeId)    
    if masterModeId == controlMasterModeId.travel then
        -- When going from byTargetSpeed to byThrottle, we put throttle to 0
        self.commandType = axisCommandType.byThrottle
        self.control.setupAxisCommandProperties(self.commandAxis, self.commandType)
        self:setCommandByThrottle(0)
    else
        self.commandType = axisCommandType.byTargetSpeed
        
        local targetSpeedInSteps = 0

        -- When going from byThrottle to byTargetSpeed, we put the target speed to 0 for secondary axis (lateral / vertical)
        -- and we try to keep the same speed for the main axis (snapped on a targetSpeedStepValue grid)
        if (self.commandAxis == axisCommandId.longitudinal) then
            local currentVelocity = vec3(self.construct.getVelocity())
            local axisCRefDirection = vec3(self.construct.getOrientationForward())

            self.lastCurrentSpeed = currentVelocity:dot(axisCRefDirection) * constants.m2kph

            -- update the ranges before computing steps
            if next(self.customTargetSpeedRanges) == nil then
                self.targetSpeedRanges = {1000, 5000, 30000} 
            else
                self.targetSpeedRanges = self.customTargetSpeedRanges
            end

            self.targetSpeedMaxRange = self.targetSpeedRanges[#self.targetSpeedRanges]

            local targetSpeedStepValue = self:getTargetSpeedCurrentStep()
            -- we keep it a multiple of targetSpeedStepValue
            targetSpeedInSteps = math.ceil(self.lastCurrentSpeed / targetSpeedStepValue) * targetSpeedStepValue
        end
        
        self:setCommandByTargetSpeed(targetSpeedInSteps);
        self.control.setupAxisCommandProperties(self.commandAxis, self.commandType, self.targetSpeedRanges)
        self.targetSpeedPID:reset()
    end
end

function AxisCommand.resetCommand(self)
    if self.commandType == axisCommandType.byThrottle then
        self:setCommandByThrottle(0)
    elseif self.commandType == axisCommandType.byTargetSpeed then
        self:setCommandByTargetSpeed(0)
    end
    self.control.setAxisCommandValue(self.commandAxis, 0)
end

function AxisCommand.updateCommandFromMouseWheel(self, mouseWheelInc)
    if mouseWheelInc == 0 then
        -- Mouse wheel is at 0 ; we update our countdown
        if self.mouseBackToNeutralCountdown > 0 then
            self.mouseBackToNeutralCountdown = self.mouseBackToNeutralCountdown - self.system.getActionUpdateDeltaTime()
        end
    else
        if self.mouseBackToNeutralCountdown <= 0 then
            -- New sequence, we reset the start value
            self.updateSequenceStartValue = self:getCommandValue()
        end
        
        -- Start the countdown
        self.mouseBackToNeutralCountdown = self.mouseBackToNeutralDuration

        if self.commandType == axisCommandType.byThrottle then
            mouseWheelInc = mouseWheelInc * self.throttleMouseStepScale
        end

        -- We do each step one by one because the targetSpeedStepValue can changed during the steps
        for i = 1, math.abs(mouseWheelInc), 1 do
            self:updateCommandByStep(utils.sign(mouseWheelInc))
        end
    end
end

function AxisCommand.updateCommandFromActionStart(self, commandStep)
    if commandStep ~= 0 then
        self.actionTriggeredTime = self.system.getUtcTime()
        self.updateSequenceStartValue = self:getCommandValue()
        -- We do each step one by one because the targetSpeedStepValue can changed during the steps
        for i = 1, math.abs(commandStep), 1 do
            self:updateCommandByStep(utils.sign(commandStep))
        end
    end
end

function AxisCommand.updateCommandFromActionStop(self, commandStep)
    -- We do each step one by one because the targetSpeedStepValue can changed during the steps
    for i = 1, math.abs(commandStep), 1 do
        self:updateCommandByStep(utils.sign(commandStep))
    end
end

function AxisCommand.updateCommandFromActionLoop(self, commandStep)
    -- handle repeat delay
    local actionRepeatDelay = self.actionRepeatDelay
    if (self.system.getUtcTime() - self.actionTriggeredTime) > actionRepeatDelay then
        self.actionTriggeredTime = self.system.getUtcTime()
        self:updateCommandByStep(commandStep)
    end
end

function AxisCommand.getCommandValue(self)
    if self.commandType == axisCommandType.byTargetSpeed then
        return self.targetSpeed
    elseif self.commandType == axisCommandType.byThrottle then
        return self.throttle
    end
    return 0
end

function AxisCommand.updateCommandByStep(self, commandStep)

    -- During an input sequence, we make sure to block at 0
    -- Depending on the current value, we don't go over or under 0
    -- If the current value is 0, the first new value is used to know which side of 0 we are
    
    if self.commandType == axisCommandType.byTargetSpeed then

        local targetSpeedStepValue = self:computeTargetSpeedStepValue(self.targetSpeed, commandStep)
        local newTargetSpeed = self.targetSpeed + commandStep * targetSpeedStepValue

        if self.updateSequenceStartValue < 0 then
            newTargetSpeed = math.min(0, newTargetSpeed)
        elseif self.updateSequenceStartValue > 0 then
            newTargetSpeed = math.max(0, newTargetSpeed)
        else
            self.updateSequenceStartValue = newTargetSpeed
        end

        self:setCommandByTargetSpeed(newTargetSpeed)

    elseif self.commandType == axisCommandType.byThrottle then

        local newThrottle = self.throttle + commandStep * self.throttleAtomicStepValue

        if self.updateSequenceStartValue < 0 then
            newThrottle = math.min(0, newThrottle)
        elseif self.updateSequenceStartValue > 0 then
            newThrottle = math.max(0, newThrottle)
        else
            self.updateSequenceStartValue = newThrottle
        end

        self:setCommandByThrottle(newThrottle)
    end
end

function AxisCommand.setCommandByThrottle(self, throttle)
    if self.commandType == axisCommandType.byThrottle then
        self.throttle = utils.clamp(throttle, -1, 1)
        self.control.setAxisCommandValue(self.commandAxis, self.throttle)
    else
        self.system.logError('Trying to get a axis command by Throttle while not in by-Throttle mode')
    end
end

function AxisCommand.setCommandByTargetSpeed(self, targetSpeed)
    if self.commandType == axisCommandType.byTargetSpeed then
        self.targetSpeed = utils.clamp(targetSpeed, -self.targetSpeedMaxRange, self.targetSpeedMaxRange)
        self.control.setAxisCommandValue(self.commandAxis, self.targetSpeed)
    else
        self.system.logError('Trying to get a axis command by TargetSpeed while not in by-TargetSpeed mode')
    end
end

function AxisCommand.getAccelerationCommandToTargetSpeed(self, currentAxisSpeedMS)
    self.lastCurrentSpeed = currentAxisSpeedMS * constants.m2kph -- store last seen current speed 
    local targetAxisSpeedMS = self.targetSpeed * constants.kph2m
    self.targetSpeedPID:inject(targetAxisSpeedMS - currentAxisSpeedMS) -- update PID
    return self.targetSpeedPID:get();
end

function AxisCommand.composeAxisAccelerationFromThrottle(self, tags)

    if self.commandType ~= axisCommandType.byThrottle then
        self.system.logError('Trying to get a axis command by Throttle while not in by-Throttle mode')
        return vec3()
    end

    local axisThrottle = self.throttle

    local axisCRefDirection = vec3()
    local axisWorldDirection = vec3()
    local additionalAcceleration = vec3()

    if (self.commandAxis == axisCommandId.longitudinal) then
        axisCRefDirection = vec3(self.construct.getOrientationForward())
        axisWorldDirection = vec3(self.construct.getWorldOrientationForward())
    elseif (self.commandAxis == axisCommandId.vertical) then
        axisCRefDirection = vec3(self.construct.getOrientationUp())
        axisWorldDirection = vec3(self.construct.getWorldOrientationUp())
        -- compensates gravity?
        local worldGravity = vec3(self.core.getWorldGravity())
        local gravityDot = worldGravity:dot(axisWorldDirection)
        if utils.sign(axisThrottle) == utils.sign(gravityDot) then
            -- gravity is going in the same direction we want
        else
            -- gravity is going in the opposite direction we want
            additionalAcceleration = -vec3(self.core.getWorldGravity())
        end
    elseif (self.commandAxis == axisCommandId.lateral) then
        axisCRefDirection = vec3(self.construct.getOrientationRight())
        axisWorldDirection = vec3(self.construct.getWorldOrientationRight())
    else
        return vec3()
    end

    local inspace = 0
    if (self.control.getAtmosphereDensity() <= constants.epsilon) then
        inspace = 1
    end

    local maxKPAlongAxis = self.construct.getMaxThrustAlongAxis(tags, {axisCRefDirection:unpack()})

    local forceCorrespondingToThrottle = 0
    if (inspace == 0) then    
        if (axisThrottle > 0) then
            local maxAtmoForceForward = maxKPAlongAxis[1]
            forceCorrespondingToThrottle = axisThrottle * maxAtmoForceForward
        else
            local maxAtmoForceBackward = maxKPAlongAxis[2]
            forceCorrespondingToThrottle = -axisThrottle * maxAtmoForceBackward
        end
    else
        if (axisThrottle > 0) then
            local maxSpaceForceForward = maxKPAlongAxis[3]
            forceCorrespondingToThrottle = axisThrottle * maxSpaceForceForward
        else
            local maxSpaceForceBackward = maxKPAlongAxis[4]
            forceCorrespondingToThrottle = -axisThrottle * maxSpaceForceBackward
        end
    end

    local accelerationCommand = forceCorrespondingToThrottle / self.mass

    local finalAcceleration = accelerationCommand * axisWorldDirection + additionalAcceleration

    self.system.addMeasure("dynamic", "acceleration", "command", accelerationCommand)
    self.system.addMeasure("dynamic", "acceleration", "intensity", finalAcceleration:len())

    return finalAcceleration
end

function AxisCommand.composeAxisAccelerationFromTargetSpeed(self, tags)

    if self.commandType ~= axisCommandType.byTargetSpeed then
        self.system.logError('Trying to get a axis command by TargetSpeed while not in by-TargetSpeed mode')
        return vec3()
    end

    local axisCRefDirection = vec3()
    local axisWorldDirection = vec3()

    if (self.commandAxis == axisCommandId.longitudinal) then
        axisCRefDirection = vec3(self.construct.getOrientationForward())
        axisWorldDirection = vec3(self.construct.getWorldOrientationForward())
    elseif (self.commandAxis == axisCommandId.vertical) then
        axisCRefDirection = vec3(self.construct.getOrientationUp())
        axisWorldDirection = vec3(self.construct.getWorldOrientationUp())
    elseif (self.commandAxis == axisCommandId.lateral) then
        axisCRefDirection = vec3(self.construct.getOrientationRight())
        axisWorldDirection = vec3(self.construct.getWorldOrientationRight())
    else
        return vec3()
    end

    local gravityAcceleration = vec3(self.core.getWorldGravity())
    local gravityAccelerationCommand = gravityAcceleration:dot(axisWorldDirection)

    local airResistanceAcceleration = vec3(self.construct.getWorldAirFrictionAcceleration())
    local airResistanceAccelerationCommand = airResistanceAcceleration:dot(axisWorldDirection)

    local currentVelocity = vec3(self.construct.getVelocity())
    local currentAxisSpeedMS = currentVelocity:dot(axisCRefDirection)

    local accelerationCommand = self:getAccelerationCommandToTargetSpeed(currentAxisSpeedMS)

    local finalAcceleration = (accelerationCommand - airResistanceAccelerationCommand - gravityAccelerationCommand) * axisWorldDirection  -- Try to compensate air friction

    self.system.addMeasure("dynamic", "acceleration", "command", accelerationCommand)
    self.system.addMeasure("dynamic", "acceleration", "intensity", finalAcceleration:len())

    return finalAcceleration
end

-----------------------------------------------------------------------------------
-- AxisCommandManager Lua Object                                
--
-- The AxisCommandManager contains the 3 AxisCommand for each axis
--
-----------------------------------------------------------------------------------

AxisCommandManager = {}
AxisCommandManager.__index = AxisCommandManager

function AxisCommandManager.new(system, control, core)
    local self = setmetatable({}, AxisCommandManager)

    self.masterModeId = controlMasterModeId.travel
    self.control = control
    self.system = system

    self.axisCommands = {}
    self.axisCommands[axisCommandId.longitudinal] = AxisCommand.new(axisCommandId.longitudinal, control, core, system)
    self.axisCommands[axisCommandId.lateral] = AxisCommand.new(axisCommandId.lateral, control, core, system)
    self.axisCommands[axisCommandId.vertical] = AxisCommand.new(axisCommandId.vertical, control, core, system)

    self.targetGroundAltitudeTriggeredTime = 0
    self.targetGroundAltitudeActivated = true
    self.targetGroundAltitude = -1.0
	self.targetGroundAltitudeCapabilities = self.control.computeGroundEngineAltitudeStabilizationCapabilities()

    return self
end

function AxisCommandManager.getMasterMode(self)
    return self.currentControlMasterModeId
end

function AxisCommandManager.getAxisCommandType(self, commandAxis)
    return self.axisCommands[commandAxis].commandType
end

function AxisCommandManager.setMasterMode(self, masterModeId)
    if (masterModeId ~= nil and masterModeId ~= self.currentControlMasterModeId) then
        self.currentControlMasterModeId = masterModeId
        
        for k, axisCommand in pairs(self.axisCommands) do 
            axisCommand:onMasterModeChanged(masterModeId)
        end

        -- the control mode has changed, maybe the stabilization must be cut or re-engaged
        self:updateGroundEngineAltitudeStabilization();
    end
end

function AxisCommandManager.updateCommandFromMouseWheel(self, commandAxis, mouseWheelInc)
    self.axisCommands[commandAxis]:updateCommandFromMouseWheel(mouseWheelInc)
end

function AxisCommandManager.resetCommand(self, commandAxis)
    self.axisCommands[commandAxis]:resetCommand()
end

function AxisCommandManager.updateCommandFromActionStart(self, commandAxis, commandStep)
    self.axisCommands[commandAxis]:updateCommandFromActionStart(commandStep)
end

function AxisCommandManager.updateCommandFromActionStop(self, commandAxis, commandStep)
    self.axisCommands[commandAxis]:updateCommandFromActionStop(commandStep)
end

function AxisCommandManager.updateCommandFromActionLoop(self, commandAxis, commandStep)
    self.axisCommands[commandAxis]:updateCommandFromActionLoop(commandStep)
end

function AxisCommandManager.getThrottleCommand(self, commandAxis)
    return self.axisCommands[commandAxis].throttle
end

function AxisCommandManager.getTargetSpeed(self, commandAxis)
    return self.axisCommands[commandAxis].targetSpeed
end

function AxisCommandManager.setupCustomTargetSpeedRanges(self, commandAxis, customTargetSpeedRanges)
    return self.axisCommands[commandAxis]:setupCustomTargetSpeedRanges(customTargetSpeedRanges)
end

function AxisCommandManager.getTargetSpeedCurrentStep(self, commandAxis)
    return self.axisCommands[commandAxis]:getTargetSpeedCurrentStep()
end

function AxisCommandManager.getCurrentToTargetDeltaSpeed(self, commandAxis)
    if (self.axisCommands[commandAxis].targetSpeed < 0) then
        return - self.axisCommands[commandAxis].targetSpeed + self.axisCommands[commandAxis].lastCurrentSpeed
    else
        return self.axisCommands[commandAxis].targetSpeed - self.axisCommands[commandAxis].lastCurrentSpeed
    end
end

function AxisCommandManager.setThrottleCommand(self, commandAxis, throttle)
    self.axisCommands[commandAxis]:setCommandByThrottle(throttle)
end

function AxisCommandManager.setTargetSpeedCommand(self, commandAxis, throttle)
    self.axisCommands[commandAxis]:setCommandByTargetSpeed(throttle)
end

function AxisCommandManager.composeAxisAccelerationFromThrottle(self, tags, commandAxis)
    return self.axisCommands[commandAxis]:composeAxisAccelerationFromThrottle(tags)
end

function AxisCommandManager.composeAxisAccelerationFromTargetSpeed(self, commandAxis)
    return self.axisCommands[commandAxis]:composeAxisAccelerationFromTargetSpeed()
end

function AxisCommandManager.activateGroundEngineAltitudeStabilization(self)
    self.targetGroundAltitudeActivated = true;
    self:updateGroundEngineAltitudeStabilization();
end

function AxisCommandManager.deactivateGroundEngineAltitudeStabilization(self)
    self.targetGroundAltitudeActivated = false;
    self:updateGroundEngineAltitudeStabilization();
end

function AxisCommandManager.setTargetGroundAltitude(self, targetAltitude)
	-- GD:
	-- In the default script, changing the global target altitude is bound by the lowest maxDistanceToObstacle 
	-- of each installed surface engine in case it is different.
    self.targetGroundAltitude = utils.clamp(targetAltitude, 0, self.targetGroundAltitudeCapabilities[1]);
    self:updateGroundEngineAltitudeStabilization();
end

function AxisCommandManager.updateTargetGroundAltitudeFromActionStart(self, altitudeStabilizationInc)
    self.targetGroundAltitudeTriggeredTime = self.system.getUtcTime()
	self:setTargetGroundAltitude(self.targetGroundAltitude + altitudeStabilizationInc)
end

function AxisCommandManager.updateTargetGroundAltitudeFromActionLoop(self, altitudeStabilizationInc)
    -- handle repeat delay
    local actionRepeatDelay = 0.25
    if (self.system.getUtcTime() - self.targetGroundAltitudeTriggeredTime) > actionRepeatDelay then
        self.targetGroundAltitudeTriggeredTime = self.system.getUtcTime()
		self:setTargetGroundAltitude(self.targetGroundAltitude + altitudeStabilizationInc)
    end
end

function AxisCommandManager.updateGroundEngineAltitudeStabilization(self)
    local engageAltitudeStabilization = self.targetGroundAltitudeActivated

    if self.targetGroundAltitude < 0.0 then
        engageAltitudeStabilization = false;
    end

    if engageAltitudeStabilization then
        self.control.activateGroundEngineAltitudeStabilization(self.targetGroundAltitude);
    else
        self.control.deactivateGroundEngineAltitudeStabilization();
    end;
end