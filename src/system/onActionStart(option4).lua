newHome = vec3(construct.getWorldPosition())
newHeight = getAltitude(newHome, ap.currentPlanet)
newHeading = 180
data.setFloatValue("homeX", newHome.x)
data.setFloatValue("homeY", newHome.y)
data.setFloatValue("homeZ", newHome.z)
data.setFloatValue("homeH", newHeight)
data.setFloatValue("homeHeading", newHeading)