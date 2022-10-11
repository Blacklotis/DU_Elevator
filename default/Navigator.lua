-- ################################################################################
-- #                  Copyright 2014-2018 Novaquark SAS                           #
-- ################################################################################

vec3             = require("cpml/vec3")
utils            = require("cpml/utils")
constants        = require("cpml/constants")

-----------------------------------------------------------------------------------
-- Navigator Lua Object                                
--
-- The Navigator offers several navigation utilities and helpers
--
-- It also centralizes the different setEngineCommand version and deals with default 
-- parameters before sending the command to the engine
--
-- This object also contains the AxisManager object that will deal more directly 
-- with commands along the different axis
-----------------------------------------------------------------------------------

Navigator = {}
Navigator.__index = Navigator;

function Navigator.new(system, core, control)
    local self = setmetatable({}, Navigator)
    self.system = system
    self.core = core
    self.control = control
    self.construct = DUConstruct
    self.boosterState = 0
    self.boosterStateHasChanged = false

    self.mass = self.construct.getMass()
    self.imass = self.construct.getInertialMass()

    self.orient = {
        -- Convenient accessors for orientation in construct local coordinates
        up = function() return self.construct.getOrientationUp() end,
        forward = function() return self.construct.getOrientationForward() end,
        right = function() return self.construct.getOrientationRight() end,

        -- Convenient accessors for orientation in world coordinates
        worldUp = function() return self.construct.getWorldOrientationUp() end,
        worldForward = function() return self.construct.getWorldOrientationForward() end,
        worldRight = function() return self.construct.getWorldOrientationRight() end,
    }

    self.axisCommandManager = AxisCommandManager.new(system, control, core)

    return self
end

function Navigator.toggleBoosters(self)
    self.boosterStateHasChanged = true
    self.boosterState = 1 - self.boosterState
end

function Navigator.setBoosterCommand(self, tags)
    if self.boosterStateHasChanged then
        self.boosterStateHasChanged = false        
        if (self.boosterState == 1 and self.axisCommandManager:getMasterMode() == controlMasterModeId.cruise) then
            -- The rocket engines are not included in the cruise control
            -- because we don't want the cruise control to counter the sudden thrust, we go back to travel mode
            self.control.cancelCurrentControlMasterMode()
        end
        self.control.setEngineThrust(tags, self.boosterState)
    end
end

function Navigator.update(self)
    -- Forward the control master mode (Travel Mode / Cruise Control) to the axisManager
    self.axisCommandManager:setMasterMode(self.control.getControlMode())
    -- The longitudinal axis is our main axis that we control with the mouse
    self.axisCommandManager:updateCommandFromMouseWheel(axisCommandId.longitudinal, self.system.getThrottleInputFromMouseWheel())
end

function Navigator.maxForceForward(self)
    local axisCRefDirection = vec3(self.construct.getOrientationForward())
    local longitudinalEngineTags = 'thrust analog longitudinal'
    local maxKPAlongAxis = self.construct.getMaxThrustAlongAxis(longitudinalEngineTags, {axisCRefDirection:unpack()})
    if self.control.getAtmosphereDensity() <= constants.epsilon then -- we are in space
        return maxKPAlongAxis[3]
    else
        return maxKPAlongAxis[1]
    end
end

function Navigator.maxForceBackward(self)
    local axisCRefDirection = vec3(self.construct.getOrientationForward())
    local longitudinalEngineTags = 'thrust analog longitudinal'
    local maxKPAlongAxis = self.construct.getMaxThrustAlongAxis(longitudinalEngineTags, {axisCRefDirection:unpack()})
    if self.control.getAtmosphereDensity() <= constants.epsilon then -- we are in space
        return maxKPAlongAxis[4]
    else
        return maxKPAlongAxis[2]
    end
end

function Navigator.isCruiseMode(self)
    return self.axisCommandManager.axisCommands[axisCommandId.longitudinal].commandType == axisCommandType.byTargetSpeed
end

function Navigator.isTravelMode(self)
    return self.axisCommandManager.axisCommands[axisCommandId.longitudinal].commandType == axisCommandType.byThrottle
end

function Navigator.getTargetGroundAltitude(self)
    return self.axisCommandManager.targetGroundAltitude
end

function Navigator.setEngineCommand(self, tags, acceleration, angularAcceleration, 
                                    keepForceColinearity, keepTorqueColinearity, 
                                    priority1SubTags, priority2SubTags, priority3SubTags, 
                                    tolerancePercentToSkipOtherPriorities)
    if keepForceColinearity == nil then
        keepForceColinearity = 1
    end

    if keepTorqueColinearity == nil then
        keepTorqueColinearity = 1
    end

    if priority1SubTags == nil then
        priority1SubTags = ""
    end
    
    if priority2SubTags == nil then
        priority2SubTags = ""
    end

    if priority3SubTags == nil then
        priority3SubTags = ""
    end    

    if tolerancePercentToSkipOtherPriorities == nil then
        tolerancePercentToSkipOtherPriorities = .1
    end

    -- issues the actual command to the Inertial Control Command
    self.control.setEngineCommand(tags,
                                 {acceleration:unpack()},
                                 {angularAcceleration:unpack()},
                                 keepForceColinearity, 
                                 keepTorqueColinearity,
                                 priority1SubTags,
                                 priority2SubTags,
                                 priority3SubTags, 
                                 tolerancePercentToSkipOtherPriorities / 100.)
end

function Navigator.setEngineForceCommand(self, tags, acceleration, 
                                        keepForceColinearity, 
                                        priority1SubTags, priority2SubTags, priority3SubTags, 
                                        tolerancePercentToSkipOtherPriorities)
                                        
    self:setEngineCommand(tags,
                            acceleration,
                            vec3(0., 0., 0.),
                            keepForceColinearity, 
                            1,
                            priority1SubTags,
                            priority2SubTags,
                            priority3SubTags,
                            tolerancePercentToSkipOtherPriorities)
end

function Navigator.setEngineTorqueCommand(self, tags, angularAcceleration, 
                                            keepTorqueColinearity, 
                                            priority1SubTags, priority2SubTags, priority3SubTags, 
                                            tolerancePercentToSkipOtherPriorities)                                                 
    self:setEngineCommand(tags,
                            vec3(0., 0., 0.),
                            angularAcceleration,
                            1, 
                            keepTorqueColinearity,
                            priority1SubTags,
                            priority2SubTags,
                            priority3SubTags, 
                            tolerancePercentToSkipOtherPriorities)
end