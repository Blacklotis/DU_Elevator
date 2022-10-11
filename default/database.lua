-- ################################################################################
-- #                  Copyright 2014-2022 Novaquark SAS                           #
-- ################################################################################

-----------------------------------------------------------------------------------
-- Database Lua library
--
-- The database library offers multiple useful functions to get all information
-- in one object about a player, a construct, an organization or an element.
-----------------------------------------------------------------------------------

database = {}

---Returns all info about a given player, identified by its id
---@param id integer the player Id
---@return table player structure
function database.getPlayer(id)
    return {
        id = id,
        name = DUSystem.getPlayerName(id),
        worldPos = DUSystem.getPlayerWorldPos(id)
    }
end

---Returns all informations about the player running the script.
---@return table player The player structure
function database.getMasterPlayer(unit)
    assert(unit ~= nil and unit.exit, "Invalid #1 parameter control unit expected")

    local _id = unit.getMasterPlayerId()
    return {
        id = _id,
        name = DUSystem.getPlayerName(_id),
        pos = unit.getMasterPlayerPosition(),
        worldPos = unit.getMasterPlayerWorldPosition(),
        orgs = unit.getMasterPlayerOrgIds(),
        transform = {
            foward = unit.getMasterPlayerForward(),
            right = unit.getMasterPlayerRight(),
            up = unit.getMasterPlayerUp(),
            worldFoward = unit.getMasterPlayerWorldForward(),
            worldRight = unit.getMasterPlayerWorldRight(),
            worldUp = unit.getMasterPlayerWorldUp()
        },
    }
end

---Returns all informations about the given organization, identified by its id.
---@param id integer The organization id
---@return table org The organization structure
function database.getOrganization(id)
    return {
        id = id,
        name = DUSystem.getOrganization(id).name,
        tag = DUSystem.getOrganization(id).tag
    }
end

---Returns all info about a given construct, identified by its id and seen from a radar.
---@param radar table the radar object
---@param id integer the construct Id
---@return table construct structure
function database.getConstruct(radar, id)
    assert(radar ~= nil and radar.getConstructIds, "Invalid #1 parameter radar unit expected")

    if radar.isOperational() == 0 then return nil end

    local _construct = {
        id = id,
        name = radar.getConstructName(id),
        size = radar.getConstructSize(id),
        type = radar.getConstructType(id),
        distance = radar.getConstructDistance(id),
        coreSize = radar.getConstructCoreSize(id),
        threatTo = radar.getThreatRateTo(id),
        threatFrom = radar.getThreatRateFrom(id),
        isIdentified = radar.isConstructIdentified(id) == 1,
        isAbandoned = radar.isConstructAbandoned(id) == 1,
        hasMatchingTransponder = radar.hasMatchingTransponder(id) == 1
    }

    if _construct.isIdentified then
        _construct.mass = radar.getConstructMass(id)
        _construct.infos = radar.getConstructInfos(id)
        _construct.speed = radar.getConstructSpeed(id)
        _construct.radialSpeed = radar.getConstructRadialSpeed(id)
        _construct.angularSpeed = radar.getConstructAngularSpeed(id)

        if _construct.hasMatchingTransponder then
            _construct.velocity = radar.getConstructVelocity(id)
            _construct.worldVelocity = radar.getConstructWorldVelocity(id)
        end
    end
    
    if _construct.hasMatchingTransponder then
        _construct.owner = radar.getConstructOwnerEntity(id)
        _construct.pos = radar.getConstructWorldPos(id)
        _construct.worldPos = radar.getConstructWorldPos(id)
    end

    return _construct
end

---Returns all info about a given element, identified by its id and coupled to a core unit
---@param core table the core unit object
---@param id integer the element ID
---@return table construct structure
function database.getElement(core, id)
    assert(core ~= nil and core.getElementTagsById, "Invalid #1 parameter core unit expected")

    local _element = {
        id = id,
        mass = core.getElementMassById(id),
        type = core.getElementClassById(id),
        name = core.getElementNameById(id),
        displayName = core.getElementDisplayNameById(id),
        pos = core.getElementPositionById(id),
        status = core.getElementIndustryStatus(id),
        tags = core.getElementTagsById(id),
        transform = {
            foward = core.getElementForwardById(id),
            right = core.getElementRightById(id),
            up = core.getElementUpById(id)
        },
        hitPoints = core.getElementHitPointsById(id),
        maxHitPoints = core.getElementMaxHitPointsById(id)
    }
    return _element
end