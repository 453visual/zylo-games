return function(PagePets, State, ZyloLib, Main)
    -- Otomatis load File 1 (Pet Team Manager)
    local raw1 = game:HttpGet("https://raw.githubusercontent.com/ranklee26-glitch/zylo-games/main/PetTeamManager.lua")
    local TeamMgr = loadstring(raw1)()(PagePets, State, ZyloLib, Main)

    -- Otomatis load File 2 (Auto Hatch & Sell)
    local raw2 = game:HttpGet("https://raw.githubusercontent.com/ranklee26-glitch/zylo-games/main/PetHatchAndSellModule.lua")
    local HatchSell = loadstring(raw2)()(PagePets, State, ZyloLib, Main, TeamMgr)

    return TeamMgr
end
