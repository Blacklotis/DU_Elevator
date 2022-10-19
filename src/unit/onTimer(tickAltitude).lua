--tickAltitude(TickRate:0.1)

--initalize
if not altitudeInit then
    altitudeInit = true
    homePosition = vec3(data.getFloatValue("homeX"),data.getFloatValue("homeY"),data.getFloatValue("homeZ"))
    homeAltitude = data.getFloatValue("homeH")
    homeHeading = data.getFloatValue("homeHeading")
    ap.targetAltitude = homeAltitude
    ap.currentPosition = vec3(construct.getWorldPosition())
    ap.currentAltitude = getAltitude(ap.currentPosition, ap.currentPlanet)
    ap.targetPlanetPos = getSystemPosition(homePosition) + vec3(0, 0, ap.targetAltitude - ap.currentAltitude)
end

-- only do calculations when ap is on
if ap.enabled then
    ap.currentPosition = vec3(construct.getWorldPosition())
    ap.currentAltitude = getAltitude(ap.currentPosition, ap.currentPlanet)
    ap.currentVelocity = construct.getWorldAbsoluteVelocity()
    ap.currentAcceleration = construct.getWorldAcceleration()
    ap.currentPlanetPos = getSystemPosition(ap.currentPosition)
    ap.heading = getHeading(vec3(construct.getWorldOrientationForward()))
    ap.thrustUp = unit.getEngineThrust("thrustUp")
    ap.thrustDown = unit.getEngineThrust("thrustDown")
    ap.thrustRight = unit.getEngineThrust("thrustRight")
    ap.thrustLeft = unit.getEngineThrust("thrustLeft")
    ap.thrustForwards = unit.getEngineThrust("thrustForwards")
    ap.thrustBack = unit.getEngineThrust("thrustBack")
    ap.forwardInput = system.getControlDeviceForwardInput()
    ap.yawInput = system.getControlDeviceYawInput()
    ap.leftRightInput = system.getControlDeviceLeftRightInput()
    ap.longitudinalAcceleration = 0
    ap.lateralAcceleration = 0
    ap.verticalAcceleration = 0
    ap.brakeInput = brakeInput
    ap.worldToCref, ap.crefToWorld = Transform.makeCoordinateConverters(core)
    ap.deviation = ap.worldToCref(ap.currentPosition - ((homePosition - Alioth.center):normalize_inplace() * (ap.currentAltitude - homeAltitude) + homePosition))

    -- figure out verticalThrustSolution, right now, just thrust at your height delta, works fine lol
    local goingUp = ap.currentAltitude < ap.targetAltitude
    heightDelta = ap.targetAltitude - ap.currentAltitude

    if ap.currentAltitude < 12000 then heightDelta = utils.clamp(heightDelta, -1200, 1200) end
    if math.abs(heightDelta) < 1000 then heightDelta = utils.clamp(heightDelta, -200, 200) end
    
    heightDelta = utils.clamp(heightDelta, -4000, 4000)
    ap.verticalAcceleration = heightDelta

    -- stay on path
    lateralDelta = -ap.deviation.x
    longitudinalDelta = -ap.deviation.y
    ap.lateralAcceleration = utils.clamp(lateralDelta, -20, 20)
    ap.longitudinalAcceleration = utils.clamp(longitudinalDelta, -20, 20)

    rotationDelta = ap.heading - ap.targetHeading

end
