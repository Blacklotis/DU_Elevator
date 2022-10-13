--tickAltitude(TickRate:0.1)

--initalize
if not altitudeInit then
    altitudeInit = true
    ap.targetAltitude = 7000
    ap.currentPosition = vec3(construct.getWorldPosition())
    ap.currentAltitude = getAltitude(ap.currentPosition, ap.currentPlanet)
    ap.targetPlanetPos = getSystemPosition(ap.currentPosition) + vec3(0, 0, ap.targetAltitude - ap.currentAltitude)
    verticalThrustSolution = vec3(0,0,0)
end
testAlt = 0
testDest = 0
testVector = 0
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
    ap.pitchSpeedFactor = 0
    ap.yawSpeedFactor = 0
    ap.rollSpeedFactor = 0
    ap.torqueFactor = 0
    ap.brakeSpeedFactor = 0
    ap.brakeFlatFactor = 0
    ap.autoRollFactor = 0
    ap.turnAssistFactor = 0
    ap.forwardInput = system.getControlDeviceForwardInput()
    ap.yawInput = system.getControlDeviceYawInput()
    ap.leftRightInput = system.getControlDeviceLeftRightInput()
    ap.longitudinalAcceleration = 0
    ap.lateralAcceleration = 0
    ap.verticalAcceleration = 0
    ap.brakeInput = brakeInput

    -- figure out verticalThrustSolution, right now, just thrust at your height delta, works fine lol
    local goingUp = ap.currentAltitude < ap.targetAltitude
    heightDelta = ap.targetAltitude - ap.currentAltitude
    lateralDelta = ap.targetPlanetPos.y - ap.currentPlanetPos.y
    longitudinalDelta = ap.targetPlanetPos.x - ap.currentPlanetPos.x
    rotationDelta = ap.heading - ap.targetHeading

    --testAlt =   vec3().dist(Alioth.center, ap.currentPosition) - Alioth.radius
    --testDest = ((ap.currentPosition - Alioth.center).normalize_inplace() * 1000) + ap.currentPosition
    --testVector = testDest - ap.currentPosition

    -- clamp speed limits
    ap.verticalAcceleration = utils.clamp(heightDelta, -1200, 1200)
    ap.lateralAcceleration = math.min(lateralDelta*100000, 10)
    ap.longitudinalAcceleration = math.min(longitudinalDelta*100000, 10)
    if (not goingUp) and (ap.currentAltitude < 1000) then ap.verticalAcceleration = utils.clamp(heightDelta, -200, 200) end

end

