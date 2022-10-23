if isClickWithin(sX, sY, 750, 50, 850, 150) then
    -- L clicked
    travelDir = "3"
elseif isClickWithin(sX, sY, 750, 613/2-50, 850, 613/2+50) then
    travelDir = "2"
elseif isClickWithin(sX, sY, 750, 613-150, 850, 613-50) then
    travelDir = "L"
end

travelDir = sX..sY