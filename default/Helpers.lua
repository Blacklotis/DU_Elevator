-- ################################################################################
-- #                  Copyright 2014-2018 Novaquark SAS                           #
-- ################################################################################

vec3      = require("cpml/vec3")
utils     = require("cpml/utils")
constants = require("cpml/constants")

-- returns the angle made by 'right' against the plane defined by the orthogonal of 'gravityDirection'
-- 'forward' is used as a reference to build up the orthogonal plane.
function getRoll(gravityDirection, forward, right)
    local horizontalRight = gravityDirection:cross(forward):normalize_inplace()
    local roll = math.acos(utils.clamp(horizontalRight:dot(right), -1, 1)) * constants.rad2deg
    if horizontalRight:cross(right):dot(forward) < 0 then roll = -roll end
    return roll
end


-- give the axis and angle of the rotation that transforms oldDir into newDir
-- returns the angle and the axis of rotation
-- If oldDir and newDir are colinear, preferredAxis is returned as the zero rotation axis
function getAxisAngleRad(oldDir, newDir, preferredAxis)
    local axis = oldDir:cross(newDir)
    local axisLen = axis:len()
    local angle = 0
    axis = axis:normalize_inplace()
    if (axisLen > constants.epsilon)
    then
        angle = math.asin(utils.clamp(axisLen, 0, 1))
    else
        axis = preferredAxis
    end

    -- if angle > 90
    if oldDir:dot(newDir) < 0
    then
        angle = math.pi - angle;
    end

    return axis, angle
end
