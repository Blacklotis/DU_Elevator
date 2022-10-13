--tickDisplay(TickRate:0.5)

--initalize
if not displayInit then
    displayInit = true
    fontSize = ("2.1")
	heightDelta = 0
end

-- show stuffs
screenMain.setCenteredText(
    "World POS: " .. tostring(ap.currentPosition) .. [[
    ]]..
    "Target POS: " .. testAlt .. [[

    ]]..
    "Heading: " .. ap.heading  .. [[

    ]]..
    "TargetAltitude: " .. ap.targetAltitude .. [[

    ]]..
    "CurrentAltitude: " .. ap.currentAltitude .. [[

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

renderScript = [[

	newState = {
		pos1 = 1,
		pos2 = 2,
		pos3 = 3,
		pos4 = 4,
		pos5 = 5,
        diagnostics = false,
        clickX = 0,
        clickY = 0,
	}

    local json = require('dkjson')
    newState = json.decode(getInput()) or {}
    local rx, ry = getResolution()
    local deltaT = getDeltaTime()

    local symbols = {}
    
    --local fascia = loadImage("assets.prod.novaquark.com/59180/5cef1cfc-444d-4d4e-af78-0a82c2c93ce3.png")

    if not init then
        init = true
        blinkCounter = 0
        blinkOn = true
    end

	local top_layer = createLayer()
	local font = loadFont('Play-Bold', 14)

	setNextStrokeWidth(top_layer, 1) 
	setNextStrokeColor(top_layer, 0, 255, 255, 0.8)
	setNextShadow(top_layer, 5, 0, 255, 255, .5)
	addLine(top_layer, 140, (ry/2) + (imageSize/2), rx-140, (ry/2) + (imageSize/2))

	setNextStrokeWidth(top_layer, 1) 
	setNextStrokeColor(top_layer, 0, 255, 255, 0.8) 
	setNextShadow(top_layer, 5, 0, 255, 255, .5)
	addLine(top_layer, 140, (ry/2) - (imageSize/2), rx-140, (ry/2) - (imageSize/2))

	-- add line select triangles
	 local font1 = loadFont('Play-Bold', 30)
     local font2 = loadFont('Play-Bold', 20)
     addText(top_layer, font2, newState.pos1, .32*rx, .945*ry)
     addText(top_layer, font2, newState.pos2, .75*rx, .945*ry)
     setNextTextAlign(top_layer, AlignH_Center, AlignV_Middle)
	 addText(top_layer, font2, newState.pos3, rx/2, .83*ry)
     addText(top_layer, font1, newState.pos4, rx-40, .08*ry)
	
     if newState.diagnostics then
         addText(top_layer, font, "CLICK:(" .. newState.clickX .. "," .. newState.clickY.. ")", 100, ry-80)
     end
     
	--addImage(top_layer, fascia, 0, 0, rx, ry)

	-- render cost profiler 
	if newState.diagnostics then 
	 local layer = createLayer() 
	 local font = loadFont('Play-Bold', 14) 
	 setNextFillColor(layer, 1, 1, 1, 1) 
	 addText(layer, font, string.format('render cost : %d / %d',  getRenderCost(), getRenderCostMax()), 8, 16) 
	end

	requestAnimationFrame(1)
]]