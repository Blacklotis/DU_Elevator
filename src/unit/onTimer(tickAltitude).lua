--tickAltitude(TickRate:0.1)

--initalize
if not altitudeInit then
    altitudeInit = true

    verticalThrustSolution = vec3(0,0,0)
end

-- only do calculations when ap is on
if ap.enabled then
    
    ap.currentPosition = vec3(construct.getWorldPosition())
    ap.currentAltitude = getAltitude(ap.currentPosition, ap.currentPlanet)
    ap.currentVelocity = construct.getWorldAbsoluteVelocity()
    ap.currentAcceleration = construct.getWorldAcceleration()
    ap.altitudePID:inject(ap.targetAltitude - ap.currentAltitude)
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
    ap.longitudinalAcceleration = 10
    ap.lateralAcceleration = 10
    ap.verticalAcceleration = 10
    ap.brakeInput = brakeInput
    -- figure out verticalThrustSolution
end