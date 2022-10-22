--tickDisplay(TickRate:0.5)

--initalize
if not displayInit then
    displayInit = true
    renderScript = [[

        local json = require('dkjson')
        newState = json.decode(getInput()) or {
            targetAlt = 0,
            currentAlt = 0,
            deviationX = 0,
            deviationY = 0,
            heading = 0,
            vertThrust = 0,
            longitudinalThrust = 0,
            lateralThrust = 0,
            homeAlt = 0,
            floor2Alt = 0,
            floor3Alt = 0,
            diagnostics = false,
            clickX = 0,
            clickY = 0,
        }

        local rx, ry = getResolution() -- gets dimensions of screen
        local deltaT = getDeltaTime() -- time between frames, if we need to know this

        local fascia = loadImage("assets.prod.novaquark.com/59180/967e8212-093b-47c2-b48f-cd159c473d45.jpg")
        local token = loadImage("assets.prod.novaquark.com/59180/098fca40-a42e-431a-a76b-8e16c7e47d8e.png")
        local top_layer = createLayer()

        function drawLocationInfo(theLayer, ix, iy)
            local fontLocInfo = loadFont('Play', 24)
            local spacing = 30
            local color = {r = 255, g = 0, b = 0, a = 1}
            -- setNextTextAlign(top_layer, AlignH_Center, AlignV_Middle)
            setNextFillColor(theLayer, color.r, color.g, color.b, color.a)
            addText(theLayer, fontLocInfo, "Target Altitude: ".. newState.targetAlt,                        ix, iy)
            setNextFillColor(theLayer, color.r, color.g, color.b, color.a)
            addText(theLayer, fontLocInfo, "Current Altitude: ".. newState.currentAlt,                      ix, iy + spacing * 1)
            setNextFillColor(theLayer, color.r, color.g, color.b, color.a)
            addText(theLayer, fontLocInfo, "Deviation: ".. newState.deviationX..", "..newState.deviationY,  ix, iy + spacing * 2)
            setNextFillColor(theLayer, color.r, color.g, color.b, color.a)
            addText(theLayer, fontLocInfo, "Heading: ".. newState.heading,                                  ix, iy + spacing * 3)
            setNextFillColor(theLayer, color.r, color.g, color.b, color.a)
            addText(theLayer, fontLocInfo, "Vert: ".. newState.vertThrust,                                  ix, iy + spacing * 4)
            setNextFillColor(theLayer, color.r, color.g, color.b, color.a)
            addText(theLayer, fontLocInfo, "Long: ".. newState.longitudinalThrust,                          ix, iy + spacing * 5)
            setNextFillColor(theLayer, color.r, color.g, color.b, color.a)
            addText(theLayer, fontLocInfo, "Lat: ".. newState.lateralThrust,                                ix, iy + spacing * 6)

            --setNextStrokeColor(theLayer, Shape_Line, 1, 1, 1, 0.5)
            --setNextShadow(theLayer, 64, 255, 0, 0, 0.1)
            --setNextFillColor(theLayer, 255, 0, 0, 1.0)
            --addBoxRounded(theLayer, ix, iy, 150, 100, 8)
        end

        function drawFloorButton(theLayer, floorName, floorAlt, ix, iy)
            local fontFloorButton = loadFont('Play-Bold', 40)
            local fontFloorButtonDesc = loadFont('Play', 28)
            local color = {r = 255, g = 0, b = 0, a = 1}
            local color2 = {r = 255, g = 255, b = 255, a = 1}
            local color3 = {r = 255, g = 255, b = 255, a = 1}
            setNextFillColor(theLayer, color.r, color.g, color.b, color.a)
            addText(theLayer, fontFloorButton, floorName, ix, iy)
            setNextFillColor(theLayer, color2.r, color2.g, color2.b, color2.a)
            addText(theLayer, fontFloorButtonDesc, floorAlt, ix + 80, iy)
            setNextFillColor(theLayer, color3.r, color3.g, color3.b, color3.a)
            addCircle(theLayer, ix+10, iy-10, 40)
        end

        function drawToken(theLayer)
            addImage(top_layer, token, rx/1.5, ry/2, 50, 50)
        end

        --setNextStrokeWidth(top_layer, 1) 
        --setNextStrokeColor(top_layer, 0, 255, 255, 0.8)
        --setNextShadow(top_layer, 5, 0, 255, 255, .5)
        --addLine(top_layer, 140, (ry/2) + (10/2), rx-140, (ry/2) + (10/2))

        --setDefaultStrokeColor(layer, Shape_Line, 1, 1, 1, 0.5)
        --setNextShadow(layer, 64, color.r, color.g, color.b, 0.4)
        --setNextFillColor(layer, color.r, color.g, color.b, 1.0)
        --addBoxRounded(layer, (rx-sx-16)/2, (ry-sy-16)/2, sx+16, sy+16, 8)

        drawLocationInfo(top_layer, 100, ry/2)
        drawFloorButton(top_layer, "L", newState.homeAlt, rx-300, ry-100)
        drawFloorButton(top_layer, "2", newState.floor2Alt, rx-300, ry-300)
        drawFloorButton(top_layer, "3", newState.floor3Alt, rx-300, ry-500)
        drawToken(top_layer)

        addImage(top_layer, fascia, 0, 0, rx, ry)

        -- render cost profiler 
        if newState.diagnostics then 
        local layer = createLayer() 
        local font = loadFont('Play-Bold', 14) 
        setNextFillColor(layer, 1, 1, 1, 1) 
        addText(layer, font, string.format('render cost : %d / %d',  getRenderCost(), getRenderCostMax()), 8, 16) 
        end

        requestAnimationFrame(1)
    ]]

    screenMain.setRenderScript(renderScript)
end

local newScreenValues = {
    targetAlt =  string.format("%.2f",ap.targetAltitude),
    currentAlt =  string.format("%.2f",ap.currentAltitude),
    deviationX =  string.format("%.2f",ap.deviation.x),
    deviationY = string.format("%.2f",ap.deviation.y),
    heading = string.format("%.2f",ap.heading),
    vertThrust = string.format("%.2f",ap.verticalAcceleration),
    longitudinalThrust = string.format("%.2f",ap.longitudinalAcceleration),
    lateralThrust = string.format("%.2f",ap.lateralAcceleration),
    homeAlt = string.format("%.2f",homeAltitude),
    floor2Alt = floor2,
    floor3Alt = floor3,
    diagnostics = false,
    clickX = 0,
    clickY = 0,
}

screenMain.setScriptInput(json.encode(newScreenValues))
