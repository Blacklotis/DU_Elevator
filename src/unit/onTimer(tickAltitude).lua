
if not altitudeInit then
    altitudeInit = true
    ap.currentPlanet = atlas[2]
    ap.startingPosition = vec3(construct.getWorldPosition())
    ap.currentPosition = vec3(construct.getWorldPosition())
    ap.currentAltitude = getAltitude(ap.currentPosition)
    ap.targetPosition = getDestination(vec3(-8.00, -8.00, -126303.00), vec3(construct.getWorldPosition()), ap.currentAltitude + 150)
end

if ap.enabled then
    ap.currentPosition = vec3(construct.getWorldPosition())
    ap.currentAltitude = getAltitude(ap.currentPosition)
    ap.brakeInput = brakeInput
    ap.thrustVector = calculateThrustVector()
    self.longitudinalAcceleration = 0
    self.lateralStrafeAcceleration = 0
    self.verticalStrafeAcceleration = 0
end

