_autoconf = {}
_autoconf.panels = {}
_autoconf.panels_size = 0
_autoconf.displayCategoryPanel = function(elements, size, title, type, widgetPerData)
    widgetPerData = widgetPerData or false     if size > 0 then
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

atmofueltank = {}
atmofueltank[1] = atmofueltank_1
atmofueltank_size = 1

spacefueltank = {}
spacefueltank_size = 0

rocketfueltank = {}
rocketfueltank_size = 0

weapon = {}
weapon_size = 0

radar = {}
radar_size = 0
pitchInput = 0
rollInput = 0
yawInput = 0
brakeInput = 0

Nav = Navigator.new(system, core, unit)
Nav.axisCommandManager:setupCustomTargetSpeedRanges(axisCommandId.longitudinal, {1000, 5000, 10000, 20000, 30000})
Nav.axisCommandManager:setTargetGroundAltitude(0)

parentingPanelId = system.createWidgetPanel("Docking")
parentingWidgetId = system.createWidget(parentingPanelId,"parenting")
system.addDataToWidget(unit.getWidgetDataId(),parentingWidgetId)

coreCombatStressPanelId = system.createWidgetPanel("Core combat stress")
coreCombatStressgWidgetId = system.createWidget(coreCombatStressPanelId,"core_stress")
system.addDataToWidget(core.getWidgetDataId(),coreCombatStressgWidgetId)

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
if placeRadar then     _autoconf.displayCategoryPanel(radar, radar_size, "Radar", "radar")
    placeRadar = false
end
if antigrav ~= nil then antigrav.showWidget() end
if warpdrive ~= nil then warpdrive.showWidget() end
if gyro ~= nil then gyro.showWidget() end
if shield ~= nil then shield.showWidget() end

if unit.isRemoteControlled() == 1 then
    player.freeze(1)
end

gearExtended = (unit.isAnyLandingGearDeployed() == 1) if gearExtended then
    unit.deployLandingGears()
else
    unit.retractLandingGears()
end

atlas = require("atlas")
ap = AutoPilot:new(false)

unit.setTimer("tickAltitude", 0.1)
unit.setTimer("tickDisplay", 0.5)

