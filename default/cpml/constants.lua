-- @module constants

local constants = {}

-- NQ
constants.deg2rad = 0.0174532925199
constants.rad2deg = 57.2957795130

constants.epsilon = 0.000001

constants.m2kph = 3.6
constants.kph2m = 0.27777777777

-- same as C's FLT_EPSILON
constants.FLT_EPSILON = 1.19209290e-07

-- used for quaternion.slerp
constants.DOT_THRESHOLD = 0.9995

--Protect constants from modification
return setmetatable({}, {
    __index = constants,
    __newindex = function(table, key, value)
        error("Can't modify a constant value.")
    end
})
