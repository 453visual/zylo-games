-- =========================================================================
--  ZYLOHUB - GROW A GARDEN (v3.5 - OFFICIAL PetEggService EDITION + PET TEAM EXTENSION)
--  Theme: Deep Obsidian Black (#070912) & Cosmic Purple (#8A2BE2)
--  STATUS: AUTO FARM & AUTO PLACE EGG LOCKED (100% PRESERVED)
-- =========================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- [A] LOAD ZYLOLIB FRAMEWORK
local ZyloLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/ranklee26-glitch/zylo-games/main/ZyloLib.lua"))()
local C = ZyloLib.Colors

-- [B] SERVICES & REMOTES RESMI DARI DECOMPILE
local GameEvents = ReplicatedStorage:WaitForChild("GameEvents", 10)
local Plant_RE = GameEvents and GameEvents:WaitForChild("Plant_RE", 5)
local Sell_Inventory = GameEvents and GameEvents:WaitForChild("Sell_Inventory", 5)
local BuySeedStock = GameEvents and GameEvents:WaitForChild("BuySeedStock", 5)
local PetEggService = GameEvents and GameEvents:WaitForChild("PetEggService", 5)
local PetsServiceRemote = GameEvents and GameEvents:WaitForChild("PetsService", 5)
local Farms = workspace:WaitForChild("Farm", 10)

local State = {
    -- [LOCKED] Auto Farm & Egg States
    AutoPlant = false,
    PlantMode = "UnderPlayer",
    AutoHarvest = false,
    AutoSell = false,
    SelectedSeed = "",
    SearchSeedQuery = "",
    SellThreshold = 15,
    
    SelectedEgg = "All Eggs",
    PlacePosition = "Good Position",
    AutoPlaceEgg = false,
    MaxEggPlace = 13,
    FarmEggCount = 0,
    
    AutoHatch = false,
    PetMinigames = false,
    AutoPickUpPet = false,
    AutoPlacePet = false,
    AutoNightmare = false,
    AutoElephant = false,
    AutoPetBoost = false,
    
    Walkspeed = false,
    InfJump = false,
    Noclip = false,
    AntiAfk = true,
    SpeedVal = 42,

    -- [NEW EXTENSION] Pet Team Manager States
    ActiveTeam = "Main Team",
    TeamDelayEquip = { ["Main Team"] = 0, ["Bronto Team"] = 0, ["Hatch Team"] = 0, ["Sell Team"] = 0 },
    TeamDelayUnequip = { ["Main Team"] = 1, ["Bronto Team"] = 1, ["Hatch Team"] = 1, ["Sell Team"] = 1 },
    SelectedPets = { ["Main Team"] = {}, ["Bronto Team"] = {}, ["Hatch Team"] = {}, ["Sell Team"] = {} },
    TeamSearchQuery = "",
    IsTeamRunning = false
}

-- =========================================================================
-- [C] DETEKSI LAHAN & Can_Plant [LOCKED - DO NOT MODIFY]
-- =========================================================================
local function GetFarm()
    if not Farms then return nil end
    for _, farm in ipairs(Farms:GetChildren()) do
        local imp = farm:FindFirstChild("Important")
        local data = imp and imp:FindFirstChild("Data")
        local owner = data and data:FindFirstChild("Owner")
        if owner and (owner.Value == LocalPlayer.Name or owner.Value == LocalPlayer.UserId) then
            return farm
        end
    end
    return nil
end

local function GetCanPlantParts()
    local parts = {}
    local farm = GetFarm()
    if not farm then return parts end

    local imp = farm:FindFirstChild("Important")
    local plantLocs = imp and imp:FindFirstChild("Plant_Locations")
    if not plantLocs then return parts end

    for _, obj in ipairs(plantLocs:GetChildren()) do
        if obj.Name == "Can_Plant" and obj:IsA("BasePart") then
            table.insert(parts, obj)
        elseif obj:IsA("BasePart") then
            table.insert(parts, obj)
        end
    end
    return parts
end

-- =========================================================================
-- [D] 13 TITIK SLOT TELUR & OVERLAP PREVENTION [LOCKED - DO NOT MODIFY]
-- =========================================================================
local function Generate13EggPositions(mode)
    local positions = {}
    local canPlants = GetCanPlantParts()
    if #canPlants == 0 then return positions end

    table.sort(canPlants, function(a, b) return a.Position.X < b.Position.X end)

    local targetLands = {}
    if mode == "Left" and #canPlants >= 2 then
        table.insert(targetLands, canPlants[1])
    elseif mode == "Right" and #canPlants >= 2 then
        table.insert(targetLands, canPlants[#canPlants])
    else
        targetLands = canPlants
    end

    local totalSlots = 13
    local slotsPerLand = math.ceil(totalSlots / #targetLands)

    for landIdx, land in ipairs(targetLands) do
        local cf = land.CFrame
        local size = land.Size
        local topY = (size.Y / 2) + 0.15
        local safeX = (size.X / 2) - 1.8
        local safeZ = (size.Z / 2) - 1.8

        local countForThis = math.min(slotsPerLand, totalSlots - #positions)
        if landIdx == #targetLands then countForThis = totalSlots - #positions end

        if countForThis > 0 then
            local zStep = (safeZ * 2) / (countForThis + 1)
            local localX = (landIdx == 1) and (safeX - 0.5) or (-safeX + 0.5)
            for i = 1, countForThis do
                local localZ = -safeZ + (i * zStep)
                local worldPoint = cf:PointToWorldSpace(Vector3.new(localX, topY, localZ))
                table.insert(positions, worldPoint)
                if #positions >= 13 then break end
            end
        end
        if #positions >= 13 then break end
    end
    return positions
end

local function GetPlacedEggsInFarm()
    local placed = {}
    local farm = GetFarm()
    if not farm then return placed end
    local imp = farm:FindFirstChild("Important")
    local objPhysical = imp and imp:FindFirstChild("Objects_Physical")
    if not objPhysical then return placed end

    for _, obj in ipairs(objPhysical:GetChildren()) do
        if obj.Name == "PetEgg" or obj.Name:lower():find("egg") then
            local pos = nil
            local hitBox = obj:FindFirstChild("HitBox")
            if hitBox and hitBox:IsA("BasePart") then pos = hitBox.Position
            elseif obj:IsA("BasePart") then pos = obj.Position
            else pos = obj:GetPivot().Position end
            if pos then table.insert(placed, { Instance = obj, Position = pos }) end
        end
    end
    return placed
end

-- =========================================================================
-- [E] FILTER BENIH & TELUR [LOCKED - DO NOT MODIFY]
-- =========================================================================
local BLACKLISTED_KEYWORDS = {
    "shard", "pack", "bundle", "crate", "chest", "box", "gift", "present",
    "ticket", "token", "pass", "badge", "coupon", "potion", "elixir", 
    "scroll", "book", "tome", "watering can", "sprinkler", "shovel", 
    "trowel", "sickle", "hoe", "basket", "fishing rod", "rod", "bug net", 
    "net", "fertilizer", "key", "lantern", "scythe", "shears", "gloves", 
    "sword", "hammer", "pickaxe"
}

local function isPureSeed(tool)
    if not tool:IsA("Tool") then return false end
    if tool:FindFirstChild("Item_String") then return false end
    if tool:FindFirstChild("EggData") or tool:FindFirstChild("PetData") then return false end
    local nameLower = tool.Name:lower()
    if nameLower:find("pet") and not nameLower:find("petunia") then return false end
    if nameLower:find("egg") and not nameLower:find("eggplant") then return false end
    for _, kw in ipairs(BLACKLISTED_KEYWORDS) do if nameLower:find(kw) then return false end end
    return true
end

local function GetSeedInfo(tool)
    if not isPureSeed(tool) then return nil end
    local plantNameVal = tool:FindFirstChild("Plant_Name")
    local numbersVal = tool:FindFirstChild("Numbers")
    local cleanName = ""
    local count = 1

    if plantNameVal and plantNameVal:IsA("ValueBase") and tostring(plantNameVal.Value) ~= "" then
        cleanName = tostring(plantNameVal.Value)
    elseif tool:GetAttribute("Plant_Name") then
        cleanName = tostring(tool:GetAttribute("Plant_Name"))
    elseif tool:GetAttribute("Seed") then
        cleanName = tostring(tool:GetAttribute("Seed"))
    else
        cleanName = tool.Name:gsub("%[.-%]", ""):gsub(" Seed", ""):gsub("Seed", ""):gsub("^%s*(.-)%s*$", "%1")
    end

    if cleanName == "" or cleanName:lower():find("shard") or cleanName:lower():find("pack") then return nil end
    if numbersVal and numbersVal:IsA("ValueBase") and tonumber(numbersVal.Value) then
        count = tonumber(numbersVal.Value)
    else
        local bracketCount = tool.Name:match("%[X(%d+)%]") or tool.Name:match("%[(%d+)%]")
        if bracketCount then count = tonumber(bracketCount) or 1 end
    end
    return cleanName, count
end

local function GetOwnedSeeds()
    local seeds = {}
    local function scan(parent)
        if not parent then return end
        for _, tool in ipairs(parent:GetChildren()) do
            if tool:IsA("Tool") then
                local plantName, count = GetSeedInfo(tool)
                if plantName then
                    seeds[plantName] = { Name = plantName, ToolName = tool.Name, Count = count, Tool = tool }
                end
            end
        end
    end
    scan(LocalPlayer:FindFirstChild("Backpack"))
    scan(LocalPlayer.Character)
    return seeds
end

local function isPureEgg(tool)
    if not tool:IsA("Tool") then return false end
    local nameLower = tool.Name:lower()
    if nameLower:find("seed") then return false end
    if tool:FindFirstChild("Plant_Name") or tool:GetAttribute("Plant_Name") or tool:GetAttribute("Seed") then return false end
    if tool:FindFirstChild("Item_String") then return false end
    if nameLower:find("eggfruit") or nameLower:find("eggplant") then return false end
    for _, kw in ipairs(BLACKLISTED_KEYWORDS) do if nameLower:find(kw) then return false end end
    return tool:FindFirstChild("PetEggToolLocal") or tool:FindFirstChild("EggData") or nameLower:find("egg")
end

local function cleanEggTitle(rawName)
    return rawName:gsub("%[.-%]", ""):gsub("%s*[xX]%d+$", ""):gsub("^%s*(.-)%s*$", "%1")
end

local function GetPureEggsInBackpack()
    local eggs = {}
    local bp, ch = LocalPlayer:FindFirstChild("Backpack"), LocalPlayer.Character
    local function check(p)
        if not p then return end
        for _, item in ipairs(p:GetChildren()) do
            if isPureEgg(item) then table.insert(eggs, item) end
        end
    end
    check(bp) check(ch)
    return eggs
end

local function EquipCheck(Tool)
    local Character = LocalPlayer.Character
    if not Character then return end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local Backpack = LocalPlayer:FindFirstChild("Backpack")
    if not Humanoid or not Backpack or not Tool then return end
    if Tool.Parent == Backpack then
        Humanoid:EquipTool(Tool)
        task.wait(0.12)
    end
end

-- =========================================================================
-- [F] WORKER THREADS (FARM & EGG PLACE ENGINE) [LOCKED - DO NOT MODIFY]
-- =========================================================================
local isPlacingEgg = false
task.spawn(function()
    while true do
        local placed = GetPlacedEggsInFarm()
        State.FarmEggCount = #placed

        if State.AutoPlaceEgg and not isPlacingEgg then
            local maxLimit = State.MaxEggPlace
            if State.FarmEggCount < maxLimit then
                local eggs = GetPureEggsInBackpack()
                local canPlants = GetCanPlantParts()

                if #eggs > 0 and #canPlants > 0 and PetEggService then
                    local targetSlots = Generate13EggPositions(State.PlacePosition)
                    local currentPlaced = GetPlacedEggsInFarm()
                    local activeTool = nil
                    for _, tool in ipairs(eggs) do
                        local cTitle = cleanEggTitle(tool.Name)
                        if State.SelectedEgg == "All Eggs" or cTitle:lower() == State.SelectedEgg:lower() then
                            activeTool = tool
                            break
                        end
                    end

                    if activeTool then
                        local targetPos = nil
                        for _, slotPos in ipairs(targetSlots) do
                            local occupied = false
                            for _, egg in ipairs(currentPlaced) do
                                local dx = egg.Position.X - slotPos.X
                                local dz = egg.Position.Z - slotPos.Z
                                if (dx * dx + dz * dz) < (2.2 * 2.2) then occupied = true break end
                            end
                            if not occupied then targetPos = slotPos break end
                        end

                        if targetPos then
                            isPlacingEgg = true
                            EquipCheck(activeTool)
                            PetEggService:FireServer("CreateEgg", targetPos)
                            task.wait(0.4)
                            isPlacingEgg = false
                        else task.wait(0.5) end
                    else task.wait(0.5) end
                else task.wait(0.5) end
            else task.wait(0.6) end
        else task.wait(0.3) end

        -- Auto Hatch
        if State.AutoHatch then
            local farm = GetFarm()
            local imp = farm and farm:FindFirstChild("Important")
            local objPhysical = imp and imp:FindFirstChild("Objects_Physical")
            if objPhysical then
                for _, eggModel in ipairs(objPhysical:GetChildren()) do
                    if not State.AutoHatch then break end
                    local prompt = eggModel:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and prompt.Enabled then
                        prompt.HoldDuration = 0
                        fireproximityprompt(prompt)
                        task.wait(0.1)
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        if State.AutoPlant then
            local owned = GetOwnedSeeds()
            local activeData = nil
            if State.SelectedSeed ~= "" and owned[State.SelectedSeed] and owned[State.SelectedSeed].Count > 0 then
                activeData = owned[State.SelectedSeed]
            else
                for sName, sData in pairs(owned) do
                    if sData.Count > 0 then State.SelectedSeed = sName activeData = sData break end
                end
            end

            if activeData and activeData.Tool and activeData.Count > 0 then
                EquipCheck(activeData.Tool)
                if State.PlantMode == "UnderPlayer" then
                    local char = LocalPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if root and Plant_RE then
                        Plant_RE:FireServer(Vector3.new(root.Position.X, 0.135, root.Position.Z), activeData.Name)
                    end
                elseif State.PlantMode == "RandomFarm" then
                    local canPlants = GetCanPlantParts()
                    if #canPlants > 0 and Plant_RE then
                        local land = canPlants[math.random(1, #canPlants)]
                        local cf = land.CFrame
                        local sz = land.Size
                        local rx = (math.random() - 0.5) * (sz.X - 2)
                        local rz = (math.random() - 0.5) * (sz.Z - 2)
                        local randPoint = cf:PointToWorldSpace(Vector3.new(rx, (sz.Y / 2) + 0.135, rz))
                        Plant_RE:FireServer(randPoint, activeData.Name)
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    while true do
        if State.AutoHarvest then
            local farm = GetFarm()
            local imp = farm and farm:FindFirstChild("Important")
            local plantsPhysical = imp and imp:FindFirstChild("Plants_Physical")
            if plantsPhysical then
                local readyPrompts = {}
                for _, plant in ipairs(plantsPhysical:GetChildren()) do
                    if not State.AutoHarvest then break end
                    local prompt = plant:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and prompt.Enabled then table.insert(readyPrompts, prompt) end
                end

                for _, prompt in ipairs(readyPrompts) do
                    if not State.AutoHarvest then break end
                    if prompt and prompt.Parent and prompt.Enabled then
                        prompt.HoldDuration = 0
                        prompt.RequiresLineOfSight = false
                        pcall(function() fireproximityprompt(prompt) end)
                        task.wait(0.015)
                    end
                end
            end
        end
        task.wait(0.15)
    end
end)

local IsSelling = false
local function SellInventory()
    if IsSelling or not Sell_Inventory or not State.AutoSell then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local sheckles = leaderstats and leaderstats:FindFirstChild("Sheckles")
    if not root then return end

    IsSelling = true
    local oldPos = root.CFrame
    local prevCash = sheckles and sheckles.Value or 0

    root.CFrame = CFrame.new(62, 4, -26)
    task.wait(0.2)

    local tries = 0
    while tries < 8 and State.AutoSell do
        Sell_Inventory:FireServer()
        task.wait(0.2)
        if sheckles and sheckles.Value ~= prevCash then break end
        tries = tries + 1
    end

    root.CFrame = oldPos
    task.wait(0.2)
    IsSelling = false
end

local function getCropCount()
    local count = 0
    local bp, ch = LocalPlayer:FindFirstChild("Backpack"), LocalPlayer.Character
    if bp then for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") and t:FindFirstChild("Item_String") then count = count + 1 end end end
    if ch then for _, t in ipairs(ch:GetChildren()) do if t:IsA("Tool") and t:FindFirstChild("Item_String") then count = count + 1 end end end
    return count
end

task.spawn(function()
    while true do
        if State.AutoSell and not IsSelling then
            if getCropCount() >= State.SellThreshold then SellInventory() end
        end
        task.wait(1)
    end
end)

RunService.Stepped:Connect(function()
    if State.Noclip and LocalPlayer.Character then
        for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if State.InfJump and LocalPlayer.Character then
        local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

LocalPlayer.Idled:Connect(function()
    if State.AntiAfk then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- =============================================================
-- [*] REAL PET SCANNER & TEAM ENGINE (FROM DECOMPILED PETSSERVICE)
-- =============================================================
local function GetFarmPetArea()
    local farm = GetFarm()
    if not farm then return nil end
    return farm:FindFirstChild("PetArea")
end

local function IsPetFavorited(item)
    if not item then return false end
    -- Check common attributes and child values for favorite in Roblox
    local isFavAttr = item:GetAttribute("IsFavorite") or item:GetAttribute("Favorite") or item:GetAttribute("FAVORITE") or item:GetAttribute("IsFav") or item:GetAttribute("Fav")
    if isFavAttr == true or isFavAttr == 1 or isFavAttr == "true" then
        return true
    end
    local favVal = item:FindFirstChild("IsFavorite") or item:FindFirstChild("Favorite") or item:FindFirstChild("FAVORITE") or item:FindFirstChild("Fav")
    if favVal and (favVal.Value == true or favVal.Value == 1) then
        return true
    end
    -- Check PetData folder if present
    local petData = item:FindFirstChild("PetData")
    if petData then
        local pFav = petData:FindFirstChild("IsFavorite") or petData:FindFirstChild("Favorite") or petData:FindFirstChild("Fav")
        if pFav and (pFav.Value == true or pFav.Value == 1) then
            return true
        end
    end
    -- Check visual heart/favorite indicator inside tool
    if item:FindFirstChild("FavoriteIcon") or item:FindFirstChild("FavIcon") or item:FindFirstChild("FavoriteGui") then
        return true
    end
    return false
end

local function GetEquippedPetsInGarden()
    local equipped = {}
    local farm = GetFarm()
    if not farm then return equipped end
    
    -- Cek PetArea atau Important.Objects_Physical
    local containers = { farm:FindFirstChild("PetArea"), farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Objects_Physical") }
    for _, cont in ipairs(containers) do
        if cont then
            for _, obj in ipairs(cont:GetChildren()) do
                local owner = obj:GetAttribute("OWNER") or (obj:FindFirstChild("Owner") and obj.Owner.Value)
                local uuid = obj:GetAttribute("UUID") or obj:GetAttribute("PET_UUID")
                if (not owner or owner == LocalPlayer.Name) and uuid then
                    local nameOnly = obj.Name:gsub("%s*%[.-%]", ""):gsub("^%s*(.-)%s*$", "%1")
                    local weight = obj.Name:match("%[([%d%.]+)%s*KG%]") or obj.Name:match("([%d%.]+)%s*KG") or "?"
                    local age = obj.Name:match("%[Age%s*(%d+)%]") or obj.Name:match("Age%s*(%d+)") or "?"
                    table.insert(equipped, {
                        Model = obj,
                        UUID = uuid,
                        FullName = obj.Name,
                        Name = nameOnly,
                        Weight = weight,
                        Age = age,
                        DisplayTitle = nameOnly .. " | Age " .. tostring(age) .. " | " .. tostring(weight) .. " KG",
                        InGarden = true,
                        IsFavorite = IsPetFavorited(obj)
                    })
                end
            end
        end
    end
    return equipped
end

local function GetAllPetsInBackpack(includeGarden)
    local pets = {}
    local seenUUIDs = {}

    local function scan(container)
        if not container then return end
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") then
                local uuid = item:GetAttribute("PET_UUID")
                local hasPetTool = item:FindFirstChild("PetToolLocal")
                local hasPetData = item:FindFirstChild("PetData")
                if uuid or hasPetTool or hasPetData then
                    local petUUID = uuid or (item:FindFirstChild("PET_UUID") and item.PET_UUID.Value) or item.Name
                    local nameOnly = item.Name:gsub("%s*%[.-%]", ""):gsub("^%s*(.-)%s*$", "%1")
                    local weight = item.Name:match("%[([%d%.]+)%s*KG%]") or item.Name:match("([%d%.]+)%s*KG") or "?"
                    local age = item.Name:match("%[Age%s*(%d+)%]") or item.Name:match("Age%s*(%d+)") or "?"
                    local isFav = IsPetFavorited(item)
                    
                    if not seenUUIDs[petUUID] then
                        seenUUIDs[petUUID] = true
                        table.insert(pets, {
                            Tool = item,
                            UUID = petUUID,
                            FullName = item.Name,
                            Name = nameOnly,
                            Weight = weight,
                            Age = age,
                            DisplayTitle = nameOnly .. " | Age " .. tostring(age) .. " | " .. tostring(weight) .. " KG",
                            InGarden = false,
                            IsFavorite = isFav
                        })
                    end
                end
            end
        end
    end
    scan(LocalPlayer:FindFirstChild("Backpack"))
    scan(LocalPlayer.Character)

    -- Permintaan 3: Sertakan pet yang sedang aktif di kebun jika includeGarden == true
    if includeGarden then
        local gardenPets = GetEquippedPetsInGarden()
        for _, gPet in ipairs(gardenPets) do
            if not seenUUIDs[gPet.UUID] then
                seenUUIDs[gPet.UUID] = true
                table.insert(pets, gPet)
            else
                -- Update flag jika sudah ada di list
                for _, p in ipairs(pets) do
                    if p.UUID == gPet.UUID then
                        p.InGarden = true
                        break
                    end
                end
            end
        end
    end

    return pets
end

local function UnequipPetByUUID(uuid)
    if PetsServiceRemote and uuid then
        pcall(function()
            PetsServiceRemote:FireServer("UnequipPet", uuid)
        end)
    end
end

local function EquipPetByToolOrUUID(petInfo, targetCF)
    if not petInfo then return end
    local petArea = GetFarmPetArea()
    local targetPos = targetCF or (petArea and petArea.CFrame) or (LocalPlayer.Character and LocalPlayer.Character:GetPivot()) or CFrame.new(0, 5, 0)
    
    if PetsServiceRemote and petInfo.UUID then
        pcall(function()
            PetsServiceRemote:FireServer("EquipPet", petInfo.UUID, targetPos)
        end)
    end
    if petInfo.Tool and petInfo.Tool.Parent == LocalPlayer:FindFirstChild("Backpack") then
        EquipCheck(petInfo.Tool)
    end
end

-- =============================================================
-- [G] MEMBANGUN UI DENGAN ZYLOLIB (100% UTUH TANPA PENGURANGAN)
-- =============================================================
local Window = ZyloLib:CreateWindow()
local Main = Window.Main

-- 9 Tabs Resmi ZyloHub (Canvas PagePets ditingkatkan agar muat mulus)
local PageHome      = Window:CreateTab("Home", "🏠", 1)
local PageFarm      = Window:CreateTab("Farm", "🍃", 2, 480)
local PagePets      = Window:CreateTab("Pets", "🐾", 3, 1100)
local PageUtility   = Window:CreateTab("Utility", "🔧", 4, 240)
local PageShop      = Window:CreateTab("Shop", "🛒", 5)
local PageConfig    = Window:CreateTab("Config", "⚙️", 6)
local PageEvent     = Window:CreateTab("Event", "⭐", 7)
local PageInventory = Window:CreateTab("Inventory", "🎒", 8)
local PageWebhook   = Window:CreateTab("Webhook", "🔗", 9)

-- =============================================================
-- [PETS PAGE CONTENT - AUTO PLACE EGG & ACCORDIONS LENGKAP]
-- =============================================================
local accPlaceEgg, bodyPlaceEgg = ZyloLib:CreateAccordion(PagePets, "Auto Place Egg", true, 200)

local peLayout = Instance.new("UIListLayout", bodyPlaceEgg)
peLayout.SortOrder = Enum.SortOrder.LayoutOrder
peLayout.Padding = UDim.new(0, 1)

-- Row 1: Select Egg
local rowSelectEgg = Instance.new("Frame", bodyPlaceEgg)
rowSelectEgg.Size = UDim2.new(1, 0, 0, 38)
rowSelectEgg.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
rowSelectEgg.BorderSizePixel = 0
rowSelectEgg.LayoutOrder = 1

local seLbl = Instance.new("TextLabel", rowSelectEgg)
seLbl.Position = UDim2.new(0, 12, 0, 0)
seLbl.Size = UDim2.new(0.45, 0, 1, 0)
seLbl.BackgroundTransparency = 1
seLbl.Text = "Select Egg"
seLbl.TextColor3 = C.TEXT_W
seLbl.Font = Enum.Font.GothamBold
seLbl.TextSize = 10
seLbl.TextXAlignment = Enum.TextXAlignment.Left

local seBtn = Instance.new("TextButton", rowSelectEgg)
seBtn.Position = UDim2.new(1, -165, 0.5, -13)
seBtn.Size = UDim2.new(0, 155, 0, 26)
seBtn.BackgroundColor3 = Color3.fromRGB(18, 22, 42)
seBtn.Text = "Select Options  v"
seBtn.TextColor3 = Color3.fromRGB(175, 185, 215)
seBtn.Font = Enum.Font.GothamBold
seBtn.TextSize = 9
Instance.new("UICorner", seBtn).CornerRadius = UDim.new(0, 6)
local seStroke = Instance.new("UIStroke", seBtn)
seStroke.Color = Color3.fromRGB(45, 52, 80)

local seDropFrame = Instance.new("Frame", Main)
seDropFrame.Size = UDim2.new(0, 175, 0, 135)
seDropFrame.BackgroundColor3 = Color3.fromRGB(14, 18, 36)
seDropFrame.Visible = false
seDropFrame.ZIndex = 50
Instance.new("UICorner", seDropFrame).CornerRadius = UDim.new(0, 8)
local seDfStroke = Instance.new("UIStroke", seDropFrame)
seDfStroke.Color = C.PURPLE
seDfStroke.Thickness = 1.5

local seDropScroll = Instance.new("ScrollingFrame", seDropFrame)
seDropScroll.Size = UDim2.new(1, 0, 1, 0)
seDropScroll.BackgroundTransparency = 1
seDropScroll.ScrollBarThickness = 2
seDropScroll.ZIndex = 51
local seDropList = Instance.new("UIListLayout", seDropScroll)
seDropList.Padding = UDim.new(0, 2)
Instance.new("UIPadding", seDropScroll).PaddingTop = UDim.new(0, 4)

local function refreshEggOptions()
    for _, c in ipairs(seDropScroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end

    local eggs = GetPureEggsInBackpack()
    local eggCounts = {}
    local eggOrder = { "All Eggs" }

    for _, egg in ipairs(eggs) do
        local cleanName = cleanEggTitle(egg.Name)
        if not eggCounts[cleanName] then
            eggCounts[cleanName] = 0
            table.insert(eggOrder, cleanName)
        end

        local numVal = egg:FindFirstChild("Numbers")
        local cnt = 1
        if numVal and numVal:IsA("ValueBase") and tonumber(numVal.Value) then
            cnt = tonumber(numVal.Value)
        else
            local b = egg.Name:match("%[X(%d+)%]") or egg.Name:match("%[(%d+)%]") or egg.Name:match("[xX](%d+)")
            if b then cnt = tonumber(b) or 1 end
        end
        eggCounts[cleanName] = eggCounts[cleanName] + cnt
    end

    for _, opt in ipairs(eggOrder) do
        local displayTitle = opt
        if opt ~= "All Eggs" and eggCounts[opt] then
            displayTitle = opt .. " x" .. tostring(eggCounts[opt])
        end

        local b = Instance.new("TextButton", seDropScroll)
        b.Size = UDim2.new(1, -8, 0, 24)
        b.Position = UDim2.new(0, 4, 0, 0)
        b.BackgroundColor3 = (State.SelectedEgg == opt) and C.PURPLE or Color3.fromRGB(22, 28, 52)
        b.Text = "  " .. displayTitle
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Font = Enum.Font.GothamMedium
        b.TextSize = 8.5
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.ZIndex = 52
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)

        b.MouseButton1Click:Connect(function()
            State.SelectedEgg = opt
            seBtn.Text = (opt == "All Eggs" and "Select Options  v" or (displayTitle .. "  v"))
            seDropFrame.Visible = false
        end)
    end
    seDropScroll.CanvasSize = UDim2.new(0, 0, 0, #eggOrder * 26 + 8)
end

seBtn.MouseButton1Click:Connect(function()
    refreshEggOptions()
    local absPos = seBtn.AbsolutePosition
    local mainPos = Main.AbsolutePosition
    seDropFrame.Position = UDim2.new(0, absPos.X - mainPos.X - 10, 0, absPos.Y - mainPos.Y + 30)
    seDropFrame.Visible = not seDropFrame.Visible
end)

-- Row 2: Select Place Position
local rowSelectPos = Instance.new("Frame", bodyPlaceEgg)
rowSelectPos.Size = UDim2.new(1, 0, 0, 38)
rowSelectPos.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
rowSelectPos.BorderSizePixel = 0
rowSelectPos.LayoutOrder = 2

local spLbl = Instance.new("TextLabel", rowSelectPos)
spLbl.Position = UDim2.new(0, 12, 0, 0)
spLbl.Size = UDim2.new(0.45, 0, 1, 0)
spLbl.BackgroundTransparency = 1
spLbl.Text = "Select Place Position"
spLbl.TextColor3 = C.TEXT_W
spLbl.Font = Enum.Font.GothamBold
spLbl.TextSize = 10
spLbl.TextXAlignment = Enum.TextXAlignment.Left

local spBtn = Instance.new("TextButton", rowSelectPos)
spBtn.Position = UDim2.new(1, -165, 0.5, -13)
spBtn.Size = UDim2.new(0, 155, 0, 26)
spBtn.BackgroundColor3 = Color3.fromRGB(18, 22, 42)
spBtn.Text = "Good Position  v"
spBtn.TextColor3 = Color3.fromRGB(245, 247, 255)
spBtn.Font = Enum.Font.GothamBold
spBtn.TextSize = 9
Instance.new("UICorner", spBtn).CornerRadius = UDim.new(0, 6)
local spStroke = Instance.new("UIStroke", spBtn)
spStroke.Color = Color3.fromRGB(45, 52, 80)

local posOptions = { "Good Position", "Right", "Left" }
local posIndex = 1
spBtn.MouseButton1Click:Connect(function()
    posIndex = posIndex + 1
    if posIndex > #posOptions then posIndex = 1 end
    State.PlacePosition = posOptions[posIndex]
    spBtn.Text = State.PlacePosition .. "  v"
end)

-- Row 3: Auto Place Egg Toggle
local rowAutoPlace = Instance.new("Frame", bodyPlaceEgg)
rowAutoPlace.Size = UDim2.new(1, 0, 0, 38)
rowAutoPlace.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
rowAutoPlace.BorderSizePixel = 0
rowAutoPlace.LayoutOrder = 3

local apLbl = Instance.new("TextLabel", rowAutoPlace)
apLbl.Position = UDim2.new(0, 12, 0, 0)
apLbl.Size = UDim2.new(0.5, 0, 1, 0)
apLbl.BackgroundTransparency = 1
apLbl.Text = "Auto Place Egg"
apLbl.TextColor3 = C.TEXT_W
apLbl.Font = Enum.Font.GothamBold
apLbl.TextSize = 10
apLbl.TextXAlignment = Enum.TextXAlignment.Left

local apSw = ZyloLib:CreatePillSwitch(rowAutoPlace, State.AutoPlaceEgg, function(v) State.AutoPlaceEgg = v end)
apSw.Position = UDim2.new(1, -48, 0.5, -10)

-- Row 4: Max Egg Place (Custom)
local rowMaxEgg = Instance.new("Frame", bodyPlaceEgg)
rowMaxEgg.Size = UDim2.new(1, 0, 0, 44)
rowMaxEgg.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
rowMaxEgg.BorderSizePixel = 0
rowMaxEgg.LayoutOrder = 4

local meTitle = Instance.new("TextLabel", rowMaxEgg)
meTitle.Position = UDim2.new(0, 12, 0, 6)
meTitle.Size = UDim2.new(0.6, 0, 0, 14)
meTitle.BackgroundTransparency = 1
meTitle.Text = "Max Egg Place (Custom)"
meTitle.TextColor3 = C.TEXT_W
meTitle.Font = Enum.Font.GothamBold
meTitle.TextSize = 10
meTitle.TextXAlignment = Enum.TextXAlignment.Left

local meSub = Instance.new("TextLabel", rowMaxEgg)
meSub.Position = UDim2.new(0, 12, 0, 22)
meSub.Size = UDim2.new(0.6, 0, 0, 14)
meSub.BackgroundTransparency = 1
meSub.Text = "Maksimal 13 butir telur sesuai slot lahan."
meSub.TextColor3 = Color3.fromRGB(120, 180, 255)
meSub.Font = Enum.Font.GothamMedium
meSub.TextSize = 8.5
meSub.TextXAlignment = Enum.TextXAlignment.Left

local meBox = Instance.new("TextBox", rowMaxEgg)
meBox.Position = UDim2.new(1, -165, 0.5, -13)
meBox.Size = UDim2.new(0, 155, 0, 26)
meBox.BackgroundColor3 = Color3.fromRGB(14, 17, 34)
meBox.Text = "13"
meBox.TextColor3 = Color3.fromRGB(245, 247, 255)
meBox.Font = Enum.Font.GothamBold
meBox.TextSize = 10
Instance.new("UICorner", meBox).CornerRadius = UDim.new(0, 6)
local meStroke = Instance.new("UIStroke", meBox)
meStroke.Color = Color3.fromRGB(45, 52, 80)

meBox:GetPropertyChangedSignal("Text"):Connect(function()
    local val = tonumber(meBox.Text)
    if val then State.MaxEggPlace = val end
end)

task.spawn(function()
    while true do
        if meSub and meSub.Parent then
            local count = State.FarmEggCount
            local maxStr = tostring(State.MaxEggPlace)
            meSub.Text = "Di Kebun: " .. tostring(count) .. " / " .. maxStr .. " telur (PetEggService Active)"
            meSub.TextColor3 = (count >= State.MaxEggPlace) and Color3.fromRGB(0, 255, 170) or Color3.fromRGB(120, 180, 255)
        end
        task.wait(0.3)
    end
end)

-- [ACCORDION 2: AUTO HATCH]
local accHatch, bodyHatch = ZyloLib:CreateAccordion(PagePets, "Auto Hatch", false, 435)
local ahRow = Instance.new("Frame", bodyHatch)
ahRow.Size = UDim2.new(1, -24, 0, 28)
ahRow.Position = UDim2.new(0, 12, 0, 6)
ahRow.BackgroundColor3 = C.CARD_2
Instance.new("UICorner", ahRow).CornerRadius = UDim.new(0, 6)
local ahLbl = Instance.new("TextLabel", ahRow)
ahLbl.Position = UDim2.new(0, 8, 0, 0)
ahLbl.Size = UDim2.new(1, -45, 1, 0)
ahLbl.BackgroundTransparency = 1
ahLbl.Text = "Otomatis Tetaskan & Claim Telur Siap Panen"
ahLbl.TextColor3 = C.TEXT_W
ahLbl.Font = Enum.Font.GothamMedium
ahLbl.TextSize = 8.5
ahLbl.TextXAlignment = Enum.TextXAlignment.Left
local ahSw = ZyloLib:CreatePillSwitch(ahRow, State.AutoHatch, function(v) State.AutoHatch = v end)
ahSw.Position = UDim2.new(1, -40, 0.5, -10)

-- =============================================================
-- [NEW FEATURE UI: PET TEAM MANAGER SESUAI GAMBAR REFERENSI]
-- Terintegrasi di dalam Accordion Auto Hatch (Collapsible / Hide & Show)
-- Tema Warna: Diadaptasi 100% Selaras Tema ZyloHub (Obsidian Black & Cosmic Purple)
-- =============================================================
local TeamCard = Instance.new("Frame", bodyHatch)
TeamCard.Name = "PetTeamManagerCard"
TeamCard.Position = UDim2.new(0, 12, 0, 40)
TeamCard.Size = UDim2.new(1, -24, 0, 350)
TeamCard.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
Instance.new("UICorner", TeamCard).CornerRadius = UDim.new(0, 8)
local tcStroke = Instance.new("UIStroke", TeamCard)
tcStroke.Color = C.STROKE
tcStroke.Thickness = 1

-- Sub-Tabs Row
local SubTabRow = Instance.new("ScrollingFrame", TeamCard)
SubTabRow.Position = UDim2.new(0, 10, 0, 10)
SubTabRow.Size = UDim2.new(1, -20, 0, 30)
SubTabRow.BackgroundTransparency = 1
SubTabRow.ScrollBarThickness = 0
SubTabRow.CanvasSize = UDim2.new(0, 480, 0, 0)

local stLayout = Instance.new("UIListLayout", SubTabRow)
stLayout.FillDirection = Enum.FillDirection.Horizontal
stLayout.Padding = UDim.new(0, 6)

local subTabs = { "Main Team", "Bronto Team", "Hatch Team", "Sell Team", "Config" }
local subTabBtns = {}
local DelayHeaderLbl = nil
local SelPetTitle = nil
local eqBox = nil
local uqBox = nil
local refreshPetSelectionUI = nil

local function updateSubTabs()
    for name, btn in pairs(subTabBtns) do
        local isAct = (State.ActiveTeam == name)
        btn.BackgroundColor3 = isAct and Color3.fromRGB(42, 20, 70) or Color3.fromRGB(16, 21, 42)
        btn.TextColor3 = isAct and Color3.fromRGB(255, 255, 255) or C.TEXT_M
        local stroke = btn:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = isAct and C.PURPLE_L or C.STROKE
            stroke.Thickness = isAct and 1.5 or 1
        end
    end
    if DelayHeaderLbl then
        DelayHeaderLbl.Text = "( " .. State.ActiveTeam .. " ) Delay Settings"
    end
    if SelPetTitle then
        SelPetTitle.Text = "Select Pet (" .. State.ActiveTeam .. ")"
    end
    if eqBox and State.TeamDelayEquip[State.ActiveTeam] ~= nil then
        eqBox.Text = tostring(State.TeamDelayEquip[State.ActiveTeam])
    end
    if uqBox and State.TeamDelayUnequip[State.ActiveTeam] ~= nil then
        uqBox.Text = tostring(State.TeamDelayUnequip[State.ActiveTeam])
    end
    if refreshPetSelectionUI then
        refreshPetSelectionUI()
    end
end

for _, tabName in ipairs(subTabs) do
    local sBtn = Instance.new("TextButton", SubTabRow)
    sBtn.Size = UDim2.new(0, (tabName == "Config") and 68 or 88, 1, 0)
    sBtn.BackgroundColor3 = (State.ActiveTeam == tabName) and Color3.fromRGB(42, 20, 70) or Color3.fromRGB(16, 21, 42)
    sBtn.Text = tabName
    sBtn.TextColor3 = (State.ActiveTeam == tabName) and Color3.fromRGB(255, 255, 255) or C.TEXT_M
    sBtn.Font = Enum.Font.GothamBold
    sBtn.TextSize = 9.5
    Instance.new("UICorner", sBtn).CornerRadius = UDim.new(1, 0)
    local bStroke = Instance.new("UIStroke", sBtn)
    bStroke.Color = (State.ActiveTeam == tabName) and C.PURPLE_L or C.STROKE

    sBtn.MouseButton1Click:Connect(function()
        State.ActiveTeam = tabName
        updateSubTabs()
    end)
    subTabBtns[tabName] = sBtn
end

local GearBtn = Instance.new("TextButton", SubTabRow)
GearBtn.Size = UDim2.new(0, 32, 1, 0)
GearBtn.BackgroundColor3 = Color3.fromRGB(16, 21, 42)
GearBtn.Text = "⚙"
GearBtn.TextColor3 = C.TEXT_M
GearBtn.Font = Enum.Font.GothamBold
GearBtn.TextSize = 12
Instance.new("UICorner", GearBtn).CornerRadius = UDim.new(1, 0)
local gbStroke = Instance.new("UIStroke", GearBtn)
gbStroke.Color = C.STROKE

-- Delay Settings Header
local DelayHeader = Instance.new("Frame", TeamCard)
DelayHeader.Position = UDim2.new(0, 10, 0, 46)
DelayHeader.Size = UDim2.new(1, -20, 0, 26)
DelayHeader.BackgroundColor3 = Color3.fromRGB(16, 21, 42)
Instance.new("UICorner", DelayHeader).CornerRadius = UDim.new(0, 6)
local dhStroke = Instance.new("UIStroke", DelayHeader)
dhStroke.Color = C.STROKE
dhStroke.Thickness = 1

DelayHeaderLbl = Instance.new("TextLabel", DelayHeader)
DelayHeaderLbl.Position = UDim2.new(0, 10, 0, 0)
DelayHeaderLbl.Size = UDim2.new(1, -35, 1, 0)
DelayHeaderLbl.BackgroundTransparency = 1
DelayHeaderLbl.Text = "( " .. State.ActiveTeam .. " ) Delay Settings"
DelayHeaderLbl.TextColor3 = C.PURPLE_L
DelayHeaderLbl.Font = Enum.Font.GothamBold
DelayHeaderLbl.TextSize = 9.5
DelayHeaderLbl.TextXAlignment = Enum.TextXAlignment.Left

local DhArrow = Instance.new("TextLabel", DelayHeader)
DhArrow.Position = UDim2.new(1, -22, 0, 0)
DhArrow.Size = UDim2.new(0, 16, 1, 0)
DhArrow.BackgroundTransparency = 1
DhArrow.Text = "▼"
DhArrow.TextColor3 = C.PURPLE_L
DhArrow.Font = Enum.Font.GothamBold
DhArrow.TextSize = 8

-- Status Counter Row
local CounterRow = Instance.new("Frame", TeamCard)
CounterRow.Position = UDim2.new(0, 12, 0, 76)
CounterRow.Size = UDim2.new(1, -24, 0, 18)
CounterRow.BackgroundTransparency = 1

local cntLayout = Instance.new("UIListLayout", CounterRow)
cntLayout.FillDirection = Enum.FillDirection.Horizontal
cntLayout.Padding = UDim.new(0, 12)

local function makeCounterLabel(icon, name, count)
    local lbl = Instance.new("TextLabel", CounterRow)
    lbl.Size = UDim2.new(0, 78, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = icon .. " " .. name .. " (" .. tostring(count) .. ")"
    lbl.TextColor3 = C.TEXT_M
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 9
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    return lbl
end

local cMain   = makeCounterLabel("🦹", "Main", 0)
local cBronto = makeCounterLabel("🦕", "Bronto", 0)
local cHatch  = makeCounterLabel("🥚", "Hatch", 0)
local cSell   = makeCounterLabel("💰", "Sell", 0)

-- Delay Equip
local RowEquip = Instance.new("Frame", TeamCard)
RowEquip.Position = UDim2.new(0, 12, 0, 98)
RowEquip.Size = UDim2.new(1, -24, 0, 24)
RowEquip.BackgroundTransparency = 1

local eqLbl = Instance.new("TextLabel", RowEquip)
eqLbl.Size = UDim2.new(0.6, 0, 1, 0)
eqLbl.BackgroundTransparency = 1
eqLbl.Text = "Delay Equip (sec)"
eqLbl.TextColor3 = C.TEXT_M
eqLbl.Font = Enum.Font.GothamMedium
eqLbl.TextSize = 9.5
eqLbl.TextXAlignment = Enum.TextXAlignment.Left

eqBox = Instance.new("TextBox", RowEquip)
eqBox.Position = UDim2.new(1, -75, 0, 0)
eqBox.Size = UDim2.new(0, 75, 1, 0)
eqBox.BackgroundColor3 = Color3.fromRGB(14, 18, 36)
eqBox.Text = "0"
eqBox.TextColor3 = C.TEXT_W
eqBox.Font = Enum.Font.GothamBold
eqBox.TextSize = 9.5
Instance.new("UICorner", eqBox).CornerRadius = UDim.new(0, 6)
local eqBoxStroke = Instance.new("UIStroke", eqBox)
eqBoxStroke.Color = C.STROKE

eqBox:GetPropertyChangedSignal("Text"):Connect(function()
    local val = tonumber(eqBox.Text)
    if val and State.TeamDelayEquip[State.ActiveTeam] then
        State.TeamDelayEquip[State.ActiveTeam] = val
    end
end)

-- Delay Unequip
local RowUnequip = Instance.new("Frame", TeamCard)
RowUnequip.Position = UDim2.new(0, 12, 0, 126)
RowUnequip.Size = UDim2.new(1, -24, 0, 24)
RowUnequip.BackgroundTransparency = 1

local uqLbl = Instance.new("TextLabel", RowUnequip)
uqLbl.Size = UDim2.new(0.6, 0, 1, 0)
uqLbl.BackgroundTransparency = 1
uqLbl.Text = "Delay Unequip (sec)"
uqLbl.TextColor3 = C.TEXT_M
uqLbl.Font = Enum.Font.GothamMedium
uqLbl.TextSize = 9.5
uqLbl.TextXAlignment = Enum.TextXAlignment.Left

uqBox = Instance.new("TextBox", RowUnequip)
uqBox.Position = UDim2.new(1, -75, 0, 0)
uqBox.Size = UDim2.new(0, 75, 1, 0)
uqBox.BackgroundColor3 = Color3.fromRGB(14, 18, 36)
uqBox.Text = "1"
uqBox.TextColor3 = C.TEXT_W
uqBox.Font = Enum.Font.GothamBold
uqBox.TextSize = 9.5
Instance.new("UICorner", uqBox).CornerRadius = UDim.new(0, 6)
local uqBoxStroke = Instance.new("UIStroke", uqBox)
uqBoxStroke.Color = C.STROKE

uqBox:GetPropertyChangedSignal("Text"):Connect(function()
    local val = tonumber(uqBox.Text)
    if val and State.TeamDelayUnequip[State.ActiveTeam] then
        State.TeamDelayUnequip[State.ActiveTeam] = val
    end
end)

-- Select Pet Frame
SelPetTitle = Instance.new("TextLabel", TeamCard)
SelPetTitle.Position = UDim2.new(0, 12, 0, 154)
SelPetTitle.Size = UDim2.new(1, -24, 0, 16)
SelPetTitle.BackgroundTransparency = 1
SelPetTitle.Text = "Select Pet (" .. State.ActiveTeam .. ")"
SelPetTitle.TextColor3 = C.TEXT_M
SelPetTitle.Font = Enum.Font.GothamMedium
SelPetTitle.TextSize = 9.5
SelPetTitle.TextXAlignment = Enum.TextXAlignment.Left

local PetListFrame = Instance.new("Frame", TeamCard)
PetListFrame.Position = UDim2.new(0, 10, 0, 172)
PetListFrame.Size = UDim2.new(1, -20, 0, 128)
PetListFrame.BackgroundColor3 = Color3.fromRGB(7, 9, 18)
Instance.new("UICorner", PetListFrame).CornerRadius = UDim.new(0, 6)
local plStroke = Instance.new("UIStroke", PetListFrame)
plStroke.Color = C.STROKE

local PetSearchBox = Instance.new("TextBox", PetListFrame)
PetSearchBox.Position = UDim2.new(0, 8, 0, 6)
PetSearchBox.Size = UDim2.new(1, -16, 0, 22)
PetSearchBox.BackgroundColor3 = Color3.fromRGB(14, 18, 36)
PetSearchBox.PlaceholderText = "Search pet in backpack..."
PetSearchBox.PlaceholderColor3 = Color3.fromRGB(110, 120, 150)
PetSearchBox.Text = ""
PetSearchBox.TextColor3 = C.TEXT_W
PetSearchBox.Font = Enum.Font.GothamMedium
PetSearchBox.TextSize = 9
Instance.new("UICorner", PetSearchBox).CornerRadius = UDim.new(0, 5)

local PetScroll = Instance.new("ScrollingFrame", PetListFrame)
PetScroll.Position = UDim2.new(0, 8, 0, 32)
PetScroll.Size = UDim2.new(1, -16, 1, -38)
PetScroll.BackgroundTransparency = 1
PetScroll.ScrollBarThickness = 2
PetScroll.CanvasSize = UDim2.new(0, 0, 0, 90)

local psLayout = Instance.new("UIListLayout", PetScroll)
psLayout.Padding = UDim.new(0, 3)

local function updateCounterLabels()
    cMain.Text = "🦹 Main (" .. tostring(#(State.SelectedPets["Main Team"] or {})) .. ")"
    cBronto.Text = "🦕 Bronto (" .. tostring(#(State.SelectedPets["Bronto Team"] or {})) .. ")"
    cHatch.Text = "🥚 Hatch (" .. tostring(#(State.SelectedPets["Hatch Team"] or {})) .. ")"
    cSell.Text = "💰 Sell (" .. tostring(#(State.SelectedPets["Sell Team"] or {})) .. ")"
end

refreshPetSelectionUI = function()
    for _, child in ipairs(PetScroll:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    
    -- Permintaan 3: Ambil pet dari backpack + pet yang sedang aktif di kebun
    local allPets = GetAllPetsInBackpack(true)
    local curTeam = State.ActiveTeam or "Main Team"
    if not State.SelectedPets[curTeam] then
        State.SelectedPets[curTeam] = {}
    end
    local selectedList = State.SelectedPets[curTeam]
    local filter = (State.TeamSearchQuery or ""):lower()

    -- Map pencarian cepat UUID terpilih
    local selectedMap = {}
    for _, selUUID in ipairs(selectedList) do
        selectedMap[selUUID] = true
    end

    -- Permintaan 2: Filter hanya pet yang sudah difavoritkan (IsFavorite)
    -- Jika user sedang memilih pet atau pet sudah masuk team, tetap ditampilkan
    local filteredPets = {}
    local anyFavoritedFound = false
    for _, pet in ipairs(allPets) do
        if pet.IsFavorite then
            anyFavoritedFound = true
            break
        end
    end

    for _, pet in ipairs(allPets) do
        -- Jika ada pet favorit, hanya ambil yang favorit atau yang sedang terpilih
        -- Jika game belum memfavoritkan apapun, tampilkan pet agar pengguna tetap bisa memilih
        local allowPet = true
        if anyFavoritedFound then
            allowPet = (pet.IsFavorite == true) or (selectedMap[pet.UUID] == true)
        end

        if allowPet then
            local displayStr = pet.DisplayTitle
            if filter == "" or displayStr:lower():find(filter) or pet.Name:lower():find(filter) then
                table.insert(filteredPets, pet)
            end
        end
    end

    -- Permintaan 1: Pet yang dipilih/aktif LANGSUNG PINDAH KE ATAS
    table.sort(filteredPets, function(a, b)
        local aSel = selectedMap[a.UUID] or false
        local bSel = selectedMap[b.UUID] or false
        if aSel ~= bSel then
            return aSel == true -- Yang terpilih (true) ditaruh di paling atas
        end
        -- Prioritas kedua: pet yang aktif di kebun
        if (a.InGarden or false) ~= (b.InGarden or false) then
            return (a.InGarden or false) == true
        end
        return (a.Name or "") < (b.Name or "")
    end)

    local matchedCount = 0
    for _, pet in ipairs(filteredPets) do
        matchedCount = matchedCount + 1
        local isSelected = selectedMap[pet.UUID] or false
        local isInGarden = pet.InGarden or false

        local statusPrefix = isSelected and "  [✓] " or "  [  ] "
        local gardenBadge = isInGarden and " 🌟 [ACTIVE]" or ""
        local favBadge = pet.IsFavorite and " ⭐" or ""
        local displayStr = statusPrefix .. pet.DisplayTitle .. gardenBadge .. favBadge

        local petItem = Instance.new("TextButton", PetScroll)
        petItem.Size = UDim2.new(1, -4, 0, 24)
        petItem.BackgroundColor3 = isSelected and Color3.fromRGB(36, 18, 58) or (isInGarden and Color3.fromRGB(20, 24, 48) or Color3.fromRGB(16, 21, 42))
        petItem.Text = displayStr
        petItem.TextColor3 = isSelected and C.PURPLE_L or (isInGarden and Color3.fromRGB(180, 210, 255) or C.TEXT_M)
        petItem.Font = Enum.Font.GothamMedium
        petItem.TextSize = 8.5
        petItem.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", petItem).CornerRadius = UDim.new(0, 4)
        local itemStroke = Instance.new("UIStroke", petItem)
        itemStroke.Color = isSelected and C.PURPLE or (isInGarden and Color3.fromRGB(70, 90, 160) or C.STROKE)
        itemStroke.Thickness = isSelected and 1.5 or 1

        petItem.MouseButton1Click:Connect(function()
            local alreadyIdx = nil
            for idx, selUUID in ipairs(selectedList) do
                if selUUID == pet.UUID then
                    alreadyIdx = idx
                    break
                end
            end

            if alreadyIdx then
                table.remove(selectedList, alreadyIdx)
            else
                if #selectedList >= 8 then
                    print("[ZyloHub] Maksimal 8 pet per team sudah tercapai!")
                else
                    table.insert(selectedList, pet.UUID)
                end
            end
            updateCounterLabels()
            refreshPetSelectionUI()
        end)
    end

    if matchedCount == 0 then
        local emptyLbl = Instance.new("TextLabel", PetScroll)
        emptyLbl.Size = UDim2.new(1, 0, 1, 0)
        emptyLbl.BackgroundTransparency = 1
        emptyLbl.Text = (filter ~= "") and ("Tidak ada pet cocok: '" .. State.TeamSearchQuery .. "'") or "Tidak ada pet favorit ditemukan di Backpack!"
        emptyLbl.TextColor3 = Color3.fromRGB(255, 120, 120)
        emptyLbl.Font = Enum.Font.GothamMedium
        emptyLbl.TextSize = 9
        PetScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    else
        PetScroll.CanvasSize = UDim2.new(0, 0, 0, matchedCount * 27)
    end
    updateCounterLabels()
end

PetSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    State.TeamSearchQuery = PetSearchBox.Text
    refreshPetSelectionUI()
end)

task.defer(refreshPetSelectionUI)

-- Auto refresh list secara berkala agar status pet di kebun [ACTIVE] selalu sinkron real-time
task.spawn(function()
    while true do
        task.wait(2.5)
        if refreshPetSelectionUI and PetScroll and PetScroll.Parent then
            pcall(refreshPetSelectionUI)
        end
    end
end)

-- Action Buttons (START & STOP)
local BtnRow = Instance.new("Frame", TeamCard)
BtnRow.Position = UDim2.new(0, 10, 1, -40)
BtnRow.Size = UDim2.new(1, -20, 0, 30)
BtnRow.BackgroundTransparency = 1

local StartBtn = Instance.new("TextButton", BtnRow)
StartBtn.Size = UDim2.new(0, 85, 1, 0)
StartBtn.BackgroundColor3 = C.PURPLE
StartBtn.Text = "⚡ START"
StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StartBtn.Font = Enum.Font.GothamBold
StartBtn.TextSize = 10
Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(1, 0)
local sbStroke = Instance.new("UIStroke", StartBtn)
sbStroke.Color = C.PURPLE_L
sbStroke.Thickness = 1.5

local StopBtn = Instance.new("TextButton", BtnRow)
StopBtn.Position = UDim2.new(0, 93, 0, 0)
StopBtn.Size = UDim2.new(0, 72, 1, 0)
StopBtn.BackgroundColor3 = Color3.fromRGB(16, 21, 42)
StopBtn.Text = "STOP"
StopBtn.TextColor3 = C.TEXT_M
StopBtn.Font = Enum.Font.GothamBold
StopBtn.TextSize = 10
Instance.new("UICorner", StopBtn).CornerRadius = UDim.new(1, 0)
local stpStroke = Instance.new("UIStroke", StopBtn)
stpStroke.Color = C.STROKE

local isExecutingTeam = false
local function ExecutePetTeam(teamName)
    if isExecutingTeam then return end
    isExecutingTeam = true
    
    local targetUUIDs = State.SelectedPets[teamName] or {}
    local delayEq = tonumber(State.TeamDelayEquip[teamName]) or 0
    local delayUneq = tonumber(State.TeamDelayUnequip[teamName]) or 1
    
    -- 1. Unequip pet yang ada di garden jika tidak termasuk target team
    local targetLookup = {}
    for _, uuid in ipairs(targetUUIDs) do targetLookup[uuid] = true end
    
    local inGarden = GetEquippedPetsInGarden()
    for _, gPet in ipairs(inGarden) do
        if not targetLookup[gPet.UUID] then
            UnequipPetByUUID(gPet.UUID)
            if delayUneq > 0 then
                task.wait(delayUneq)
            else
                task.wait(0.1)
            end
        end
    end
    
    -- 2. Equip pet terpilih yang ada di Backpack
    local allBackpackPets = GetAllPetsInBackpack()
    local backpackLookup = {}
    for _, p in ipairs(allBackpackPets) do
        backpackLookup[p.UUID] = p
    end
    
    for _, uuid in ipairs(targetUUIDs) do
        if not State.IsTeamRunning then break end
        local pInfo = backpackLookup[uuid]
        if pInfo then
            EquipPetByToolOrUUID(pInfo)
            if delayEq > 0 then
                task.wait(delayEq)
            else
                task.wait(0.15)
            end
        end
    end
    
    isExecutingTeam = false
end

StartBtn.MouseButton1Click:Connect(function()
    State.IsTeamRunning = true
    StartBtn.BackgroundColor3 = C.PURPLE_L
    StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    sbStroke.Color = Color3.fromRGB(220, 150, 255)
    StopBtn.BackgroundColor3 = Color3.fromRGB(16, 21, 42)
    StopBtn.TextColor3 = C.TEXT_M
    stpStroke.Color = C.STROKE
    
    task.spawn(function()
        ExecutePetTeam(State.ActiveTeam or "Main Team")
    end)
end)

StopBtn.MouseButton1Click:Connect(function()
    State.IsTeamRunning = false
    StartBtn.BackgroundColor3 = C.PURPLE
    StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    sbStroke.Color = C.PURPLE_L
    StopBtn.BackgroundColor3 = Color3.fromRGB(36, 18, 28)
    StopBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    stpStroke.Color = Color3.fromRGB(200, 60, 60)
end)

-- =============================================================
-- [ACCORDION PET ASLI LAINNYA - 100% UTUH TANPA DIHAPUS]
-- =============================================================
local accMini, bodyMini = ZyloLib:CreateAccordion(PagePets, "Pet Minigames", false, 85)
local accTeam, bodyTeam = ZyloLib:CreateAccordion(PagePets, "Pet Team", false, 85)
local teamBtn1 = Instance.new("TextButton", bodyTeam)
teamBtn1.Position = UDim2.new(0, 12, 0, 6)
teamBtn1.Size = UDim2.new(0.46, 0, 0, 28)
teamBtn1.BackgroundColor3 = C.PURPLE
teamBtn1.Text = "⚡ Equip Best Team"
teamBtn1.TextColor3 = Color3.fromRGB(255, 255, 255)
teamBtn1.Font = Enum.Font.GothamBold
teamBtn1.TextSize = 8.5
Instance.new("UICorner", teamBtn1).CornerRadius = UDim.new(0, 6)

local teamBtn2 = Instance.new("TextButton", bodyTeam)
teamBtn2.Position = UDim2.new(0.52, 0, 0, 6)
teamBtn2.Size = UDim2.new(0.46, 0, 0, 28)
teamBtn2.BackgroundColor3 = C.CARD_2
teamBtn2.Text = "🔄 Unequip All"
teamBtn2.TextColor3 = C.TEXT_M
teamBtn2.Font = Enum.Font.GothamBold
teamBtn2.TextSize = 8.5
Instance.new("UICorner", teamBtn2).CornerRadius = UDim.new(0, 6)

-- Pet Team Accordion Buttons Integration
teamBtn1.MouseButton1Click:Connect(function()
    ExecutePetTeam(State.ActiveTeam or "Main Team")
end)

teamBtn2.MouseButton1Click:Connect(function()
    local inGarden = GetEquippedPetsInGarden()
    for _, gPet in ipairs(inGarden) do
        UnequipPetByUUID(gPet.UUID)
        task.wait(0.15)
    end
end)

local accPick, bodyPick = ZyloLib:CreateAccordion(PagePets, "Auto Pick Place", false, 85)
local accNight, bodyNight = ZyloLib:CreateAccordion(PagePets, "Auto Nightmare", false, 85)
local accEle, bodyEle = ZyloLib:CreateAccordion(PagePets, "Auto Elephant", false, 85)
local accPetMg, bodyPetMg = ZyloLib:CreateAccordion(PagePets, "Pet", false, 85)
local accBoost, bodyBoost = ZyloLib:CreateAccordion(PagePets, "Pet Boost", false, 85)

-- =============================================================
-- [FARM PAGE CONTENT - 100% PERSIS KODE ASLI & LOCKED]
-- =============================================================
local FarmCard1 = Instance.new("Frame", PageFarm)
FarmCard1.Size = UDim2.new(1, 0, 0, 300)
FarmCard1.BackgroundColor3 = C.CARD
Instance.new("UICorner", FarmCard1).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", FarmCard1).Color = C.STROKE

local FcTitle = Instance.new("TextLabel", FarmCard1)
FcTitle.Position = UDim2.new(0, 12, 0, 10)
FcTitle.Size = UDim2.new(1, -24, 0, 14)
FcTitle.BackgroundTransparency = 1
FcTitle.Text = "🌱  AUTO PLANT & HARVEST ENGINE"
FcTitle.TextColor3 = C.PURPLE_L
FcTitle.Font = Enum.Font.GothamBold
FcTitle.TextSize = 11
FcTitle.TextXAlignment = Enum.TextXAlignment.Left

local FarmDetect = Instance.new("TextLabel", FarmCard1)
FarmDetect.Position = UDim2.new(0, 12, 0, 26)
FarmDetect.Size = UDim2.new(1, -24, 0, 16)
FarmDetect.BackgroundTransparency = 1
local mFarm = GetFarm()
if mFarm then
    FarmDetect.Text = "✅ Lahan: " .. mFarm.Name .. " (Can_Plant Terhubung)"
    FarmDetect.TextColor3 = Color3.fromRGB(0, 255, 170)
else
    FarmDetect.Text = "⚠️ Lahan Belum Ditemukan di Workspace.Farm"
    FarmDetect.TextColor3 = Color3.fromRGB(255, 100, 100)
end
FarmDetect.Font = Enum.Font.GothamBold
FarmDetect.TextSize = 9.5
FarmDetect.TextXAlignment = Enum.TextXAlignment.Left

local PlantRow = Instance.new("Frame", FarmCard1)
PlantRow.Position = UDim2.new(0, 12, 0, 46)
PlantRow.Size = UDim2.new(1, -24, 0, 30)
PlantRow.BackgroundColor3 = C.CARD_2
Instance.new("UICorner", PlantRow).CornerRadius = UDim.new(0, 6)

local PrLabel = Instance.new("TextLabel", PlantRow)
PrLabel.Position = UDim2.new(0, 10, 0, 0)
PrLabel.Size = UDim2.new(1, -50, 1, 0)
PrLabel.BackgroundTransparency = 1
PrLabel.Text = "Auto Plant (Tanam + Auto Equip Tool Benih)"
PrLabel.TextColor3 = C.TEXT_W
PrLabel.Font = Enum.Font.GothamMedium
PrLabel.TextSize = 9
PrLabel.TextXAlignment = Enum.TextXAlignment.Left
local PrSwitch = ZyloLib:CreatePillSwitch(PlantRow, State.AutoPlant, function(v) State.AutoPlant = v end)
PrSwitch.Position = UDim2.new(1, -40, 0.5, -10)

local ModeRow = Instance.new("Frame", FarmCard1)
ModeRow.Position = UDim2.new(0, 12, 0, 80)
ModeRow.Size = UDim2.new(1, -24, 0, 28)
ModeRow.BackgroundTransparency = 1

local ModeBtn1 = Instance.new("TextButton", ModeRow)
ModeBtn1.Size = UDim2.new(0.485, 0, 1, 0)
ModeBtn1.BackgroundColor3 = (State.PlantMode == "UnderPlayer") and C.PURPLE or C.CARD_2
ModeBtn1.Text = "📍 Di Bawah Karakter"
ModeBtn1.TextColor3 = (State.PlantMode == "UnderPlayer") and Color3.fromRGB(255, 255, 255) or C.TEXT_M
ModeBtn1.Font = Enum.Font.GothamBold
ModeBtn1.TextSize = 9
Instance.new("UICorner", ModeBtn1).CornerRadius = UDim.new(0, 6)
local MbStroke1 = Instance.new("UIStroke", ModeBtn1)
MbStroke1.Color = (State.PlantMode == "UnderPlayer") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(45, 55, 80)

local ModeBtn2 = Instance.new("TextButton", ModeRow)
ModeBtn2.Position = UDim2.new(0.515, 0, 0, 0)
ModeBtn2.Size = UDim2.new(0.485, 0, 1, 0)
ModeBtn2.BackgroundColor3 = (State.PlantMode == "RandomFarm") and C.PURPLE or C.CARD_2
ModeBtn2.Text = "🎲 Random di Kebun"
ModeBtn2.TextColor3 = (State.PlantMode == "RandomFarm") and Color3.fromRGB(255, 255, 255) or C.TEXT_M
ModeBtn2.Font = Enum.Font.GothamBold
ModeBtn2.TextSize = 9
Instance.new("UICorner", ModeBtn2).CornerRadius = UDim.new(0, 6)
local MbStroke2 = Instance.new("UIStroke", ModeBtn2)
MbStroke2.Color = (State.PlantMode == "RandomFarm") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(45, 55, 80)

local function updateModeButtons()
    ModeBtn1.BackgroundColor3 = (State.PlantMode == "UnderPlayer") and C.PURPLE or C.CARD_2
    ModeBtn1.TextColor3 = (State.PlantMode == "UnderPlayer") and Color3.fromRGB(255, 255, 255) or C.TEXT_M
    MbStroke1.Color = (State.PlantMode == "UnderPlayer") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(45, 55, 80)

    ModeBtn2.BackgroundColor3 = (State.PlantMode == "RandomFarm") and C.PURPLE or C.CARD_2
    ModeBtn2.TextColor3 = (State.PlantMode == "RandomFarm") and Color3.fromRGB(255, 255, 255) or C.TEXT_M
    MbStroke2.Color = (State.PlantMode == "RandomFarm") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(45, 55, 80)
end

ModeBtn1.MouseButton1Click:Connect(function() State.PlantMode = "UnderPlayer" updateModeButtons() end)
ModeBtn2.MouseButton1Click:Connect(function() State.PlantMode = "RandomFarm" updateModeButtons() end)

local HarRow = Instance.new("Frame", FarmCard1)
HarRow.Position = UDim2.new(0, 12, 0, 114)
HarRow.Size = UDim2.new(1, -24, 0, 30)
HarRow.BackgroundColor3 = C.CARD_2
Instance.new("UICorner", HarRow).CornerRadius = UDim.new(0, 6)

local HrLabel = Instance.new("TextLabel", HarRow)
HrLabel.Position = UDim2.new(0, 10, 0, 0)
HrLabel.Size = UDim2.new(1, -50, 1, 0)
HrLabel.BackgroundTransparency = 1
HrLabel.Text = "Auto Harvest (Panen Cepat & Mulus Tanpa Lag)"
HrLabel.TextColor3 = C.TEXT_W
HrLabel.Font = Enum.Font.GothamMedium
HrLabel.TextSize = 9
HrLabel.TextXAlignment = Enum.TextXAlignment.Left
local HrSwitch = ZyloLib:CreatePillSwitch(HarRow, State.AutoHarvest, function(v) State.AutoHarvest = v end)
HrSwitch.Position = UDim2.new(1, -40, 0.5, -10)

local SeedHeaderRow = Instance.new("Frame", FarmCard1)
SeedHeaderRow.Position = UDim2.new(0, 12, 0, 150)
SeedHeaderRow.Size = UDim2.new(1, -24, 0, 24)
SeedHeaderRow.BackgroundTransparency = 1

local SeedSelectTitle = Instance.new("TextLabel", SeedHeaderRow)
SeedSelectTitle.Size = UDim2.new(0.55, 0, 1, 0)
SeedSelectTitle.BackgroundTransparency = 1
SeedSelectTitle.Text = "Pilih Benih dari Inventory (Klik):"
SeedSelectTitle.TextColor3 = C.CYAN
SeedSelectTitle.Font = Enum.Font.GothamBold
SeedSelectTitle.TextSize = 9.5
SeedSelectTitle.TextXAlignment = Enum.TextXAlignment.Left

local SearchBox = Instance.new("TextBox", SeedHeaderRow)
SearchBox.Position = UDim2.new(0.55, 5, 0, 0)
SearchBox.Size = UDim2.new(0.45, -5, 1, 0)
SearchBox.BackgroundColor3 = C.CARD_2
SearchBox.PlaceholderText = "🔍 Search seed..."
SearchBox.PlaceholderColor3 = C.TEXT_M
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.Font = Enum.Font.GothamMedium
SearchBox.TextSize = 9
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 6)
local SbStroke = Instance.new("UIStroke", SearchBox)
SbStroke.Color = Color3.fromRGB(60, 70, 100)

local SeedScroll = Instance.new("ScrollingFrame", FarmCard1)
SeedScroll.Position = UDim2.new(0, 12, 0, 178)
SeedScroll.Size = UDim2.new(1, -24, 0, 78)
SeedScroll.BackgroundColor3 = C.CARD_2
SeedScroll.ScrollBarThickness = 3
SeedScroll.ScrollBarImageColor3 = C.PURPLE
Instance.new("UICorner", SeedScroll).CornerRadius = UDim.new(0, 6)

local SclLayout = Instance.new("UIListLayout", SeedScroll)
SclLayout.FillDirection = Enum.FillDirection.Horizontal
SclLayout.Padding = UDim.new(0, 6)
local SclPad = Instance.new("UIPadding", SeedScroll)
SclPad.PaddingTop = UDim.new(0, 8)
SclPad.PaddingLeft = UDim.new(0, 8)
SclPad.PaddingRight = UDim.new(0, 8)

local function refreshSeedChips()
    for _, c in ipairs(SeedScroll:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
    end

    local owned = GetOwnedSeeds()
    local count = 0
    local query = State.SearchSeedQuery:lower()

    for sName, sData in pairs(owned) do
        if query == "" or sName:lower():find(query) or sData.ToolName:lower():find(query) then
            count = count + 1
            local isSelected = (State.SelectedSeed == sName) or (State.SelectedSeed == "" and count == 1)
            if isSelected and State.SelectedSeed == "" then State.SelectedSeed = sName end

            local chip = Instance.new("TextButton", SeedScroll)
            chip.Size = UDim2.new(0, 120, 0, 56)
            chip.BackgroundColor3 = isSelected and C.PURPLE or Color3.fromRGB(24, 30, 48)
            chip.Text = ""
            Instance.new("UICorner", chip).CornerRadius = UDim.new(0, 6)
            local cStroke = Instance.new("UIStroke", chip)
            cStroke.Color = isSelected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(45, 55, 80)

            local icon = Instance.new("TextLabel", chip)
            icon.Position = UDim2.new(0, 6, 0, 8)
            icon.Size = UDim2.new(0, 16, 0, 16)
            icon.BackgroundTransparency = 1
            icon.Text = "🌱"
            icon.TextSize = 12

            local nameL = Instance.new("TextLabel", chip)
            nameL.Position = UDim2.new(0, 24, 0, 6)
            nameL.Size = UDim2.new(1, -28, 0, 24)
            nameL.BackgroundTransparency = 1
            nameL.Text = sData.ToolName
            nameL.TextColor3 = C.TEXT_W
            nameL.Font = Enum.Font.GothamBold
            nameL.TextSize = 8.5
            nameL.TextWrapped = true
            nameL.TextXAlignment = Enum.TextXAlignment.Left

            local qtyL = Instance.new("TextLabel", chip)
            qtyL.Position = UDim2.new(0, 24, 0, 32)
            qtyL.Size = UDim2.new(1, -28, 0, 14)
            qtyL.BackgroundTransparency = 1
            qtyL.Text = "Stok: " .. tostring(sData.Count) .. "x"
            qtyL.TextColor3 = isSelected and Color3.fromRGB(220, 240, 255) or C.TEXT_M
            qtyL.Font = Enum.Font.Gotham
            qtyL.TextSize = 8
            qtyL.TextXAlignment = Enum.TextXAlignment.Left

            chip.MouseButton1Click:Connect(function()
                State.SelectedSeed = sName
                refreshSeedChips()
            end)
        end
    end

    if count == 0 then
        local empty = Instance.new("TextLabel", SeedScroll)
        empty.Size = UDim2.new(1, 0, 1, 0)
        empty.BackgroundTransparency = 1
        empty.Text = (query ~= "") and "Tidak ada benih cocok: '" .. State.SearchSeedQuery .. "'" or "Tidak ada benih murni di Backpack."
        empty.TextColor3 = Color3.fromRGB(255, 120, 120)
        empty.Font = Enum.Font.GothamMedium
        empty.TextSize = 8.5
        SeedScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    else
        SeedScroll.CanvasSize = UDim2.new(0, count * 128, 0, 0)
    end
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    State.SearchSeedQuery = SearchBox.Text
    refreshSeedChips()
end)

task.defer(refreshSeedChips)

local RefSeedBtn = Instance.new("TextButton", FarmCard1)
RefSeedBtn.Position = UDim2.new(0, 12, 0, 264)
RefSeedBtn.Size = UDim2.new(1, -24, 0, 24)
RefSeedBtn.BackgroundColor3 = Color3.fromRGB(22, 28, 44)
RefSeedBtn.Text = "🔄 Refresh Inventaris Benih Sekarang"
RefSeedBtn.TextColor3 = C.CYAN
RefSeedBtn.Font = Enum.Font.GothamBold
RefSeedBtn.TextSize = 9
Instance.new("UICorner", RefSeedBtn).CornerRadius = UDim.new(0, 6)
RefSeedBtn.MouseButton1Click:Connect(refreshSeedChips)

local FarmCard2 = Instance.new("Frame", PageFarm)
FarmCard2.Size = UDim2.new(1, 0, 0, 125)
FarmCard2.BackgroundColor3 = C.CARD
Instance.new("UICorner", FarmCard2).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", FarmCard2).Color = C.STROKE

local SellTitle = Instance.new("TextLabel", FarmCard2)
SellTitle.Position = UDim2.new(0, 12, 0, 10)
SellTitle.Size = UDim2.new(1, -24, 0, 14)
SellTitle.BackgroundTransparency = 1
SellTitle.Text = "💰  AUTO SELL & MERCHANT ENGINE"
SellTitle.TextColor3 = C.CYAN
SellTitle.Font = Enum.Font.GothamBold
SellTitle.TextSize = 11
SellTitle.TextXAlignment = Enum.TextXAlignment.Left

local SellRow = Instance.new("Frame", FarmCard2)
SellRow.Position = UDim2.new(0, 12, 0, 32)
SellRow.Size = UDim2.new(1, -24, 0, 32)
SellRow.BackgroundColor3 = C.CARD_2
Instance.new("UICorner", SellRow).CornerRadius = UDim.new(0, 6)

local SrLabel = Instance.new("TextLabel", SellRow)
SrLabel.Position = UDim2.new(0, 10, 0, 0)
SrLabel.Size = UDim2.new(1, -50, 1, 0)
SrLabel.BackgroundTransparency = 1
SrLabel.Text = "Auto Sell Saat Panenan Mencapai Batas (Threshold)"
SrLabel.TextColor3 = C.TEXT_W
SrLabel.Font = Enum.Font.GothamMedium
SrLabel.TextSize = 9.5
SrLabel.TextXAlignment = Enum.TextXAlignment.Left
local SrSwitch = ZyloLib:CreatePillSwitch(SellRow, State.AutoSell, function(v) State.AutoSell = v end)
SrSwitch.Position = UDim2.new(1, -40, 0.5, -10)

local ManualSellBtn = Instance.new("TextButton", FarmCard2)
ManualSellBtn.Position = UDim2.new(0, 12, 0, 74)
ManualSellBtn.Size = UDim2.new(1, -24, 0, 34)
ManualSellBtn.BackgroundColor3 = Color3.fromRGB(24, 32, 54)
ManualSellBtn.Text = "⚡ Jual Semua Hasil Panen Sekarang (Teleport NPC & Balik)"
ManualSellBtn.TextColor3 = C.CYAN
ManualSellBtn.Font = Enum.Font.GothamBold
ManualSellBtn.TextSize = 10
Instance.new("UICorner", ManualSellBtn).CornerRadius = UDim.new(0, 6)
local MsStroke = Instance.new("UIStroke", ManualSellBtn)
MsStroke.Color = Color3.fromRGB(0, 180, 200)

ManualSellBtn.MouseButton1Click:Connect(function()
    State.AutoSell = true
    SellInventory()
end)

-- Default Active: Tab Pets
Window:SelectTab("Pets")

print("[ZyloHub v3.5] Official PetEggService Edition + Pet Team Extension Loaded & Verified!")
