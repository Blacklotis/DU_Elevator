--[[----------------------------------------------------------------------------
                        Novaquark Renderscript Library
                    Copyright (c) 2014-2022 Novaquark SAS
                             All rights reserved.
                                Version 1.1
----------------------------------------------------------------------------]]--

local rslib = { version = "1.1" }

-- draw a full-screen image loaded from the given url
function rslib.drawQuickImage (url)
    local rx, ry = getResolution()
    local layer = createLayer()
    local img = loadImage(url)
    addImage(layer, img, 0, 0, rx, ry)
end

-- draw a string of text with line breaks and word wrapping in the center of
-- the screen
-- options may contain any of the following
--    textColor : four-component RGBA table; e.g. red is {1, 0, 0, 1}
--      bgColor : three-component RGB table for background color
--     fontName : name of font (see render script docs)
--     fontSize : size of font, in vertical pixels
--  lineSpacing : spacing from one baseline to the next
--    wrapWidth : total width of the text region, as a fraction of screen width
function rslib.drawQuickText (text, options)
    local rx, ry = getResolution()

    -- config
    local options = options or {}
    local textColor = options.textColor or {1, 1, 1, 1}
    local bgColor = options.bgColor or {0, 0, 0}
    local fontName = options.fontName or 'Play-Bold'
    local fontSize = options.fontSize or 64
    local lineSpacing = options.lineSpacing or (fontSize + 2)
    local wrapWidth = (options.wrapWidth or 0.9) * rx

    -- compute line wrapping
    local font = loadFont(fontName, fontSize)
    local lines = rslib.getTextWrapped(font, text, wrapWidth)

    -- rendering
    setBackgroundColor(table.unpack(bgColor))
    local y = (ry - lineSpacing * (#lines - 1)) / 2
    local layer = createLayer()

    for i, line in ipairs(lines) do
        setNextFillColor(layer, table.unpack(textColor))
        setNextTextAlign(layer, AlignH_Center, AlignV_Middle)
        addText(layer, font, line, rx/2, y)
        y = y + lineSpacing
    end
end

-- draw a small render cost profiler at the bottom-left of the screen to show
-- the current render cost of the screen versus the maximum allowed cost
-- NOTE: displays render cost at the time of the function call, so you must
--       call at the end of your script to see the total cost!
function rslib.drawRenderCost ()
    local rx, ry = getResolution()
    local layer = createLayer()
    local font = loadFont('FiraMono-Bold', 16)
    local rc, rcm = getRenderCost(), getRenderCostMax()
    local text = string.format('render cost: %d / %d (%.1f%%)', rc, rcm, (rc/rcm) * 100)
    setNextFillColor(layer, 1, 1, 1, 1)
    setNextTextAlign(layer, AlignH_Left, AlignV_Descender)
    addText(layer, font, text, 16, ry - 8)
end

-- break the given text into a table of strings such that each element takes no
-- more than maxWidth horizontal pixels when rendered with the given font
function rslib.getTextWrapped (font, text, maxWidth)
    local out, line, lineW = {}, {}, 0
    for p in text:gmatch("([^\n]*)\n?") do
        out[#out+1] = {}
        for w in p:gmatch("%S+") do
            line = out[#out]
            local word = #line==0 and w or ' '..w
            local wordW, wordH = getTextBounds(font, word)
            if lineW + wordW < maxWidth then
                line[#line+1] = word
                lineW = lineW + wordW
            else
                out[#out] = table.concat(line)
                out[#out+1] = {w}
                lineW = getTextBounds(font, w)
                line = nil
            end
        end
        out[#out] = table.concat(out[#out])
        lineW = 0
    end
    return out
end

function rslib.drawGrid (size, opacity)
    local size = size or 64
    local opacity = opacity or 0.3

    local renderCost = getRenderCost()
    local rx, ry = getResolution()
    local layer = createLayer()
    setDefaultStrokeColor(layer, Shape_Line, 1, 1, 1, opacity)
    setDefaultFillColor(layer, Shape_Text, 1, 1, 1, opacity)
    local font = loadFont('FiraMono', 16)
    for i = 0, rx, size do
        addLine(layer, i, 0, i, ry)
        addText(layer, font, i, i + 5, 15)
    end
    for i = 0, ry, size do
        addLine(layer, 0, i, rx, i)
        addText(layer, font, i, 5, i - 5)
    end
end

-- like Lua print, but uses logMessage to print to the in-game Lua chat window
-- NOTE: only visible if 'enable logging' is on for this screen!
function rslib.print (...)
    local args = {...}
    local strs = {}
    for i, arg in ipairs(args) do
        strs[i] = tostring(arg)
    end
    logMessage(table.concat(strs, '\t'))
end

-- pretty print, like rslib.print, except using rslib.toString to see tables
function rslib.pprint (...)
    local args = {...}
    for k, v in pairs(args) do
        args[k] = rslib.toString(v)
    end
    rslib.print(table.unpack(args))
end

-- like Lua tostring, but recursively stringifies tables
function rslib.toString (x)
    if type(x) == 'table' then
        local elems = {}
        for k, v in pairs(x) do
            table.insert(elems, string.format('%s = %s', rslib.toString(k), rslib.toString(v)))
        end
        return string.format('{%s}', table.concat(elems, ', '))
    else
        return tostring(x)
    end
end

return rslib
