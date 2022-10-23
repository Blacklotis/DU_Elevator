--tickDisplay(TickRate:0.5)

--initalize
if not displayInit then
    displayInit = true
    travelDir = "Stop"
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
            travelDir = "Stop",
            diagnostics = false,
            clickX = 0,
            clickY = 0,
        }

        local rx, ry = getResolution() -- gets dimensions of screen
        local deltaT = getDeltaTime() -- time between frames, if we need to know this

        local fascia = loadImage("assets.prod.novaquark.com/59180/967e8212-093b-47c2-b48f-cd159c473d45.jpg")
        local token = loadImage("assets.prod.novaquark.com/59180/098fca40-a42e-431a-a76b-8e16c7e47d8e.png")
        local fontButtonDesc = loadFont('Play', 28)
        local top_layer = createLayer()

        function drawLocationInfo(theLayer, ix, iy)
            local spacing = 30
            local color = {r = 1, g = 0, b = 0, a = 1}
            setNextFillColor(theLayer, color.r, color.g, color.b, color.a)
            addText(theLayer, fontButtonDesc, "Target Altitude: ".. newState.targetAlt,                        ix, iy)
            setNextFillColor(theLayer, color.r, color.g, color.b, color.a)
            addText(theLayer, fontButtonDesc, "Current Altitude: ".. newState.currentAlt,                      ix, iy + spacing * 1)
            setNextFillColor(theLayer, color.r, color.g, color.b, color.a)
            addText(theLayer, fontButtonDesc, "Deviation: ".. newState.deviationX..", "..newState.deviationY,  ix, iy + spacing * 2)
            setNextFillColor(theLayer, color.r, color.g, color.b, color.a)
            addText(theLayer, fontButtonDesc, "Heading: ".. newState.heading,                                  ix, iy + spacing * 3)
            setNextFillColor(theLayer, color.r, color.g, color.b, color.a)
            addText(theLayer, fontButtonDesc, "Vert: ".. newState.vertThrust,                                  ix, iy + spacing * 4)
            setNextFillColor(theLayer, color.r, color.g, color.b, color.a)
            addText(theLayer, fontButtonDesc, "Long: ".. newState.longitudinalThrust,                          ix, iy + spacing * 5)
            setNextFillColor(theLayer, color.r, color.g, color.b, color.a)
            addText(theLayer, fontButtonDesc, "Lat: ".. newState.lateralThrust,                                ix, iy + spacing * 6)
            setNextFillColor(theLayer, color.r, color.g, color.b, color.a)
            addText(theLayer, fontButtonDesc, "Travel Dir: ".. newState.travelDir,                             ix, iy + spacing * 7)
        end

        function drawFloorButton(theLayer, floorName, floorAlt, ix, iy)
            local fontFloorButton = loadFont('Play-Bold', 40)
            local color = {r = 1, g = 0, b = 0, a = 1}
            local color2 = {r = 1, g = 1, b = 1, a = 1}
            local color3 = {r = 1, g = 1, b = 1, a = 1}
            setNextFillColor(theLayer, color.r, color.g, color.b, color.a)
            setNextTextAlign(theLayer, AlignH_Center, AlignV_Middle)
            addText(theLayer, fontFloorButton, floorName, ix, iy)
            setNextFillColor(theLayer, color2.r, color2.g, color2.b, color2.a)
            setNextTextAlign(theLayer, AlignH_Left, AlignV_Middle)
            addText(theLayer, fontButtonDesc, floorAlt, ix + 60, iy)
            setNextFillColor(theLayer, color3.r, color3.g, color3.b, color3.a)
            addCircle(theLayer, ix, iy, 40)
        end

        function drawClickRegions(theLayer)
            setNextFillColor(theLayer, 1, 1, 1, 0)
            setNextStrokeWidth(theLayer, 1)
            setNextStrokeColor(theLayer, Shape_Line, 1, 1, 1, 1)
            addBox(theLayer, 750,50,100,100)
            setNextFillColor(theLayer, 1, 1, 1, 0)
            setNextStrokeWidth(theLayer, 1)
            setNextStrokeColor(theLayer, Shape_Line, 1, 1, 1, 1)
            addBox(theLayer, 750,613-150,100,100)
            setNextFillColor(theLayer, 1, 1, 1, 0)
            setNextStrokeWidth(theLayer, 1)
            setNextStrokeColor(theLayer, Shape_Line, 1, 1, 1, 1)
            addBox(theLayer, 750,613/2-50,100,100)
        end

        function drawToken(theLayer, tx, ty)
            if newState.travelDir == "Stop" then
                setNextStrokeColor(theLayer, Shape_Line, 1, 1, 1, 1)
                setNextStrokeWidth(theLayer, 3)
                setNextFillColor(theLayer, 0, 0, 0, 0)
                addBoxRounded(theLayer, tx, ty, 50, 50, 2)
            end
            addImage(theLayer, token, tx, ty, 50, 50)
            setNextTextAlign(theLayer, AlignH_Right, AlignV_Middle)
            addText(theLayer, fontButtonDesc, newState.currentAlt, tx - 10, ty + 25)
        end

        drawLocationInfo(top_layer, 100, ry/2)
        drawFloorButton(top_layer, "L", newState.homeAlt, 800, ry-100)
        drawFloorButton(top_layer, "2", newState.floor2Alt, 800, ry/2)
        drawFloorButton(top_layer, "3", newState.floor3Alt, 800, 100)
        drawToken(top_layer, rx/1.5, ry - 125)

        addImage(top_layer, fascia, 0, 0, rx, ry)

        -- render cost profiler 
        if newState.diagnostics then 
        drawClickRegions(top_layer)
        local layer = createLayer() 
        local font = loadFont('Play-Bold', 14) 
        setNextFillColor(layer, 1, 1, 1, 1) 
        addText(layer, font, string.format('render cost : %d / %d : x,y %d, %d',  getRenderCost(), getRenderCostMax(), rx, ry), 8, 16) 
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
    travelDir = travelDir,
    diagnostics = true,
    clickX = 0,
    clickY = 0,
}

screenMain.setScriptInput(json.encode(newScreenValues))
