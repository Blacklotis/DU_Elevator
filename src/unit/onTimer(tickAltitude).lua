--tickAltitude(TickRate:0.1)

--initalize
if not altitudeInit then
    altitudeInit = true
    ap.targetAltitude = 3000
    ap.currentPosition = vec3(construct.getWorldPosition())
    ap.currentAltitude = getAltitude(ap.currentPosition, ap.currentPlanet)
    ap.targetPlanetPos = getSystemPosition(ap.currentPosition) + vec3(0, 0, ap.targetAltitude - ap.currentAltitude)
    verticalThrustSolution = vec3(0,0,0)
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
    heightDelta = ap.targetAltitude - ap.currentAltitude
    lateralDelta = ap.targetPlanetPos.x - ap.currentPlanetPos.x
    longitudinalDelta = ap.targetPlanetPos.y - ap.currentPlanetPos.y
    rotationDelta = ap.heading - ap.targetHeading

    -- clamp speed limits
    ap.verticalAcceleration = math.min(heightDelta, 1200)
    ap.lateralAcceleration = math.min(lateralDelta*10000, 10)
    ap.longitudinalAcceleration = math.min(longitudinalDelta*10000, 10)

    -- show stuffs
    screenMain.setCenteredText("Target POS: " .. tostring(ap.targetPlanetPos) .. [[

                               ]]..
                               "Heading: " .. ap.heading  .. [[
                                
                               ]]..
                               "TargetAltitude: " .. ap.targetAltitude .. [[
                                
                                ]]..
                               "CurrentAltitude: " .. ap.targetAltitude .. [[
                                
                                ]]..
                               "HeightDelta: " .. heightDelta .. [[
                                
                                ]]..
                               "Deviation: " .. tostring(ap.currentPlanetPos - ap.targetPlanetPos) .. [[
                                
                                ]]..
                               "Target Speed Up: " .. ap.verticalAcceleration .. [[
                                
                                ]]..
                               "Target Speed Forward: " .. ap.longitudinalAcceleration .. [[
                                
                                ]]..
                               "Target Speed Left: " .. ap.lateralAcceleration )

end

