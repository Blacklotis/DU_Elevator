if ap.enabled then 
    ap.enabled = false
    player.freeze(1)
else
    ap.enabled = true
    player.freeze(0)
end