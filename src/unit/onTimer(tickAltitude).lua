
if not altitudeInit then
    altitudeInit = true
    ap.currentPlanet = atlas[2]
    ap.startingPosition = vec3(construct.getWorldPosition())
    ap.currentPosition = vec3(construct.getWorldPosition())
    ap.currentAltitude = getAltitude(ap.currentPosition)
    ap.targetPosition = vec3(ap.currentPosition.x, ap.currentPosition.y, ap.currentPosition.z + 150)
end

if ap.enabled then
    ap.currentPosition = vec3(construct.getWorldPosition())
    ap.currentAltitude = getAltitude(ap.currentPosition)
    ap.brakeInput = brakeInput
    adjustedPosition = vec3(ap.targetPosition - ap.currentPosition)
    ap.thrustVector = calculateThrustVector(adjustedPosition)
    ap.heading = ap.thrustVector.y
    ap.pitch = ap.thrustVector.y
    ap.magnitude = ap.thrustVector.x
end

