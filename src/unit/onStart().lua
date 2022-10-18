-- category panel display helpers
_autoconf = {}
_autoconf.panels = {}
_autoconf.panels_size = 0
_autoconf.displayCategoryPanel = function(elements, size, title, type, widgetPerData)
    -- default to one widget for all data
    widgetPerData = widgetPerData or false 
    if size > 0 then
        local panel = system.createWidgetPanel(title)
        local widget
        if not widgetPerData then
            widget = system.createWidget(panel, type)
        end
        for i = 1, size do
            if widgetPerData then
                widget = system.createWidget(panel, type)
            end
            system.addDataToWidget(elements[i].getWidgetDataId(), widget)
        end
        _autoconf.panels_size = _autoconf.panels_size + 1
        _autoconf.panels[_autoconf.panels_size] = panel
    end
end
_autoconf.hideCategoryPanels = function()
    for i=1,_autoconf.panels_size do
        system.destroyWidgetPanel(_autoconf.panels[i])
    end
end
-- Proxy array to access auto-plugged slots programmatically

atmofueltank = {}
atmofueltank[1] = atmofueltank_1
atmofueltank[2] = atmofueltank_2
atmofueltank_size = 2

spacefueltank = {}
spacefueltank[1] = spacefueltank_1
spacefueltank[2] = spacefueltank_2
spacefueltank_size = 2

rocketfueltank = {}
rocketfueltank_size = 0

weapon = {}
weapon_size = 0

radar = {}
radar_size = 0
-- End of auto-generated code
pitchInput = 0
rollInput = 0
yawInput = 0
brakeInput = 0

Nav = Navigator.new(system, core, unit)
Nav.axisCommandManager:setupCustomTargetSpeedRanges(axisCommandId.longitudinal, {1000, 5000, 10000, 20000, 30000})
Nav.axisCommandManager:setTargetGroundAltitude(0)

-- Parenting widget
parentingPanelId = system.createWidgetPanel("Docking")
parentingWidgetId = system.createWidget(parentingPanelId,"parenting")
system.addDataToWidget(unit.getWidgetDataId(),parentingWidgetId)

-- Combat stress widget
coreCombatStressPanelId = system.createWidgetPanel("Core combat stress")
coreCombatStressgWidgetId = system.createWidget(coreCombatStressPanelId,"core_stress")
system.addDataToWidget(core.getWidgetDataId(),coreCombatStressgWidgetId)

-- element widgets
-- For now we have to alternate between PVP and non-PVP widgets to have them on the same side.
_autoconf.displayCategoryPanel(weapon, weapon_size, "Weapons", "weapon", true)
core.showWidget()
_autoconf.displayCategoryPanel(radar, radar_size, "Periscope", "periscope")
placeRadar = true
if atmofueltank_size > 0 then
    _autoconf.displayCategoryPanel(atmofueltank, atmofueltank_size, "Atmo Fuel", "fuel_container")
    if placeRadar then
        _autoconf.displayCategoryPanel(radar, radar_size, "Radar", "radar")
        placeRadar = false
    end
end
if spacefueltank_size > 0 then
    _autoconf.displayCategoryPanel(spacefueltank, spacefueltank_size, "Space Fuel", "fuel_container")
    if placeRadar then
        _autoconf.displayCategoryPanel(radar, radar_size, "Radar", "radar")
        placeRadar = false
    end
end
_autoconf.displayCategoryPanel(rocketfueltank, rocketfueltank_size, "Rocket Fuel", "fuel_container")
-- We either have only rockets or no fuel tanks at all, uncommon for usual vessels
if placeRadar then 
    _autoconf.displayCategoryPanel(radar, radar_size, "Radar", "radar")
    placeRadar = false
end
if antigrav ~= nil then antigrav.showWidget() end
if warpdrive ~= nil then warpdrive.showWidget() end
if gyro ~= nil then gyro.showWidget() end
if shield ~= nil then shield.showWidget() end

-- freeze the player in he is remote controlling the construct
if unit.isRemoteControlled() == 1 then
    player.freeze(1)
end

-- landing gear
-- make sure every gears are synchonized with the first
-- make sure it's a lua boolean
gearExtended = (unit.isAnyLandingGearDeployed() == 1)
if gearExtended then
    unit.deployLandingGears()
else
    unit.retractLandingGears()
end


Alioth = Planet:new(0, 0, 199718.78, vec3(-8.0000, -8.0000, -126303.0000), 126067.8984375)
ap = AutoPilot:new(false)
ap.currentPlanet = Alioth
ap.currentTarget = getDestination(ap.currentPlanet.center, vec3(construct.getWorldPosition()), ap.targetAltitude)
ap.headingTarget = getHeading(vec3(construct.getWorldOrientationForward()))
ap.positionHoldEnabled = true

unit.setTimer("tickAltitude", 0.05)
unit.setTimer("tickDisplay", 0.5)