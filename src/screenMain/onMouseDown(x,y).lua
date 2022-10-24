if isClickWithin(x, y, 750/1024, 50/613, 850/1024, 150/613) then
    travelDir = "3"
    ap.targetAltitude = floor3
elseif isClickWithin(x, y, 750/1024, (613/2-50)/613, 850/1024, (613/2+50)/613) then
    travelDir = "2"
    ap.targetAltitude = floor2
elseif isClickWithin(x, y, 750/1024, (613-150)/613, 850/1024, (613-50)/613) then
    travelDir = "L"
    ap.targetAltitude = homeAltitude
end