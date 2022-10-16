--tickAltitude(TickRate:0.1)

--initalize
if not altitudeInit then
    altitudeInit = true
    ap.targetAltitude = 1000
    homePosition = vec3(-30896.334,101852.420,-58548.278)
    homeAltitude = getAltitude(homePosition, ap.currentPlanet)
    ap.currentPosition = vec3(construct.getWorldPosition())
    ap.currentAltitude = getAltitude(ap.currentPosition, ap.currentPlanet)
    ap.targetPlanetPos = getSystemPosition(homePosition) + vec3(0, 0, ap.targetAltitude - ap.currentAltitude)
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
    testDest = ((ap.currentPosition - Alioth.center):normalize_inplace() * 1000) + homePosition
    --testVector = ((ap.currentPosition - Alioth.center).normalize_inplace()) / vec3(1,1,1).normalize_inplace()
    --testAlt = testVector * vec3(0,0,1000)

    -- clamp speed limits
    ap.verticalAcceleration = utils.clamp(heightDelta, -1200, 1200)
    ap.lateralAcceleration = utils.clamp(lateralDelta*10000000, -10, 10)
    ap.longitudinalAcceleration = utils.clamp(longitudinalDelta*10000000, -10, 10)
    
    if math.abs(heightDelta) < 1000 then ap.verticalAcceleration = utils.clamp(heightDelta, -200, 200) end

end


