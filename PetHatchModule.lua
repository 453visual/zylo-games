-- =========================================================================
--  ZYLOHUB - PET HATCH & TEAM MANAGER MODULE (OFFICIAL EXTENSION)
--  Repository: zylo-games/PetHatchModule.lua
--  Theme: Deep Obsidian Black (#070912) & Cosmic Purple (#8A2BE2)
--  STATUS: 100% PRESERVED & EXPANDABLE SELL CONFIG UI FULLY INTEGRATED
-- =========================================================================

return function(PagePets, State, ZyloLib, Main)
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

    local C = ZyloLib.Colors

    -- Services & Remotes
    local GameEvents = ReplicatedStorage:WaitForChild("GameEvents", 10)
    local PetsServiceRemote = GameEvents and GameEvents:WaitForChild("PetsService", 5)
    local Farms = workspace:WaitForChild("Farm", 10)

    local DataService = nil
    pcall(function()
        DataService = require(ReplicatedStorage:WaitForChild("Modules", 5):WaitForChild("DataService", 5))
    end)

    local PetsServiceMod = nil
    pcall(function()
        PetsServiceMod = require(ReplicatedStorage:WaitForChild("Modules", 5):WaitForChild("PetServices", 5):WaitForChild("PetsService", 5))
    end)

    local PetUtilities = nil
    pcall(function()
        PetUtilities = require(ReplicatedStorage:WaitForChild("Modules", 5):WaitForChild("PetServices", 5):WaitForChild("PetUtilities", 5))
    end)

    -- Inisialisasi State Config Telur & Jual
    State.AutoHatch = (State.AutoHatch ~= nil) and State.AutoHatch or false
    State.DontHatchIfNotAllDone = (State.DontHatchIfNotAllDone ~= nil) and State.DontHatchIfNotAllDone or false
    State.EggConfigExpanded = (State.EggConfigExpanded ~= nil) and State.EggConfigExpanded or false
    State.SellConfigExpanded = (State.SellConfigExpanded ~= nil) and State.SellConfigExpanded or false

    -- State Khusus Sell Config
    State.AutoSellThresholdCount = State.AutoSellThresholdCount or 24
    State.SellMode = State.SellMode or "Sell All" -- "Sell One By One" atau "Sell All"
    State.SellSearchQuery = State.SellSearchQuery or ""
    State.BulkKG = State.BulkKG or 3
    State.BulkAction = State.BulkAction or "sell"
    State.ApplyBulkList = (State.ApplyBulkList ~= nil) and State.ApplyBulkList or false

    -- Default List Pet Config yang biasa digunakan pemain
    State.SellPetRules = State.SellPetRules or {
        { Species = "Mimic Octopus", KG = 3, Action = "SELL" },
        { Species = "Peacock", KG = 3, Action = "SELL" },
        { Species = "Scarlet Macaw", KG = 3, Action = "SELL" },
        { Species = "Capybara", KG = 3, Action = "SELL" },
        { Species = "Ostrich", KG = 3, Action = "SELL" }
    }

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

    local function GetFarmPetArea()
        local farm = GetFarm()
        if not farm then return nil end
        return farm:FindFirstChild("PetArea")
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

    -- [PATEN]: LOOP AUTO HATCH DENGAN DUKUNGAN "DONT HATCH IF TIME NOT DONE" (SYNC HATCH)
    task.spawn(function()
        while true do
            if State.AutoHatch then
                local farm = GetFarm()
                local imp = farm and farm:FindFirstChild("Important")
                local objPhysical = imp and imp:FindFirstChild("Objects_Physical")
                
                if objPhysical then
                    local eggsInGarden = {}
                    for _, obj in ipairs(objPhysical:GetChildren()) do
                        local p = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                        local isEgg = false
                        local nameLower = obj.Name:lower()
                        if nameLower:find("egg") or (p and p.ActionText:lower():find("hatch")) then
                            isEgg = true
                        end
                        if isEgg and p then
                            table.insert(eggsInGarden, { Model = obj, Prompt = p })
                        end
                    end

                    local canHatchNow = true
                    if State.DontHatchIfNotAllDone and #eggsInGarden > 0 then
                        for _, egg in ipairs(eggsInGarden) do
                            local isPromptReady = egg.Prompt.Enabled
                            local billboard = egg.Model:FindFirstChildWhichIsA("BillboardGui", true)
                            local timeLabel = billboard and billboard:FindFirstChildWhichIsA("TextLabel", true)
                            if timeLabel and (timeLabel.Text:find(":") or timeLabel.Text:lower():find("m") or timeLabel.Text:lower():find("s")) and not timeLabel.Text:lower():find("ready") then
                                isPromptReady = false
                            end

                            if not isPromptReady then
                                canHatchNow = false
                                break
                            end
                        end
                    end

                    if canHatchNow and #eggsInGarden > 0 then
                        for _, egg in ipairs(eggsInGarden) do
                            if not State.AutoHatch then break end
                            local p = egg.Prompt
                            if p and p.Enabled then
                                p.HoldDuration = 0
                                p.RequiresLineOfSight = false
                                pcall(function() fireproximityprompt(p) end)
                                task.wait(0.08)
                            end
                        end
                    end
                end
            end
            task.wait(0.3)
        end
    end)

    -- Pengecekan Favorite Murni dari DataService
    local function IsPetFavorited(uuid, item)
        if not uuid and item then
            uuid = item:GetAttribute("PET_UUID") or (item:FindFirstChild("PET_UUID") and item.PET_UUID.Value)
        end
        
        if DataService and uuid then
            local ok, data = pcall(function() return DataService:GetData() end)
            if ok and data and data.PetsData and data.PetsData.PetInventory and data.PetsData.PetInventory.Data then
                local entry = data.PetsData.PetInventory.Data[uuid]
                if entry and entry.PetData and entry.PetData.IsFavorite ~= nil then
                    return entry.PetData.IsFavorite == true
                end
            end
        end

        if PetsServiceMod and PetsServiceMod.GetPlayerPetData and uuid then
            local ok, info = pcall(function() return PetsServiceMod:GetPlayerPetData(uuid) end)
            if ok and info and info.PetData and info.PetData.IsFavorite ~= nil then
                return info.PetData.IsFavorite == true
            end
        end

        if item then
            local isFavAttr = item:GetAttribute("IsFavorite") or item:GetAttribute("Favorite") or item:GetAttribute("FAVORITE") or item:GetAttribute("IsFav")
            if isFavAttr == true or isFavAttr == 1 or isFavAttr == "true" then return true end
            local favVal = item:FindFirstChild("IsFavorite") or item:FindFirstChild("Favorite") or item:FindFirstChild("Fav")
            if favVal and (favVal.Value == true or favVal.Value == 1) then return true end
            local petData = item:FindFirstChild("PetData")
            if petData then
                local pFav = petData:FindFirstChild("IsFavorite") or petData:FindFirstChild("Favorite") or petData:FindFirstChild("Fav")
                if pFav and (pFav.Value == true or pFav.Value == 1) then return true end
            end
        end
        return false
    end

    local function GetEquippedPetUUIDsMap()
        local map = {}
        if DataService then
            local ok, data = pcall(function() return DataService:GetData() end)
            if ok and data and data.PetsData and data.PetsData.EquippedPets then
                for _, u in ipairs(data.PetsData.EquippedPets) do
                    map[tostring(u)] = true
                    map[tostring(u):gsub("[{}]", "")] = true
                end
            end
        end

        local petsPhys = workspace:FindFirstChild("PetsPhysical")
        if petsPhys then
            for _, mover in ipairs(petsPhys:GetChildren()) do
                local mUuid = mover:GetAttribute("PET_UUID") or mover:GetAttribute("UUID")
                if not mUuid then
                    for _, ch in ipairs(mover:GetChildren()) do
                        local raw = ch.Name:gsub("[{}]", "")
                        if #raw > 20 and raw:find("-") then mUuid = ch.Name break end
                    end
                end
                if mUuid then
                    map[tostring(mUuid)] = true
                    map[tostring(mUuid):gsub("[{}]", "")] = true
                end
            end
        end
        return map
    end

    local function GetEquippedPetsInGarden()
        local equipped = {}
        local seenUUID = {}
        local farm = GetFarm()
        
        local function checkContainer(cont)
            if not cont then return end
            for _, obj in ipairs(cont:GetChildren()) do
                local owner = obj:GetAttribute("OWNER") or (obj:FindFirstChild("Owner") and obj.Owner.Value)
                local uuid = obj:GetAttribute("UUID") or obj:GetAttribute("PET_UUID")
                
                if not uuid then
                    for _, sub in ipairs(obj:GetChildren()) do
                        local sU = sub:GetAttribute("UUID") or sub:GetAttribute("PET_UUID")
                        if sU then uuid = sU break end
                    end
                end

                if (not owner or owner == LocalPlayer.Name or owner == LocalPlayer.UserId) and uuid then
                    local sUuid = tostring(uuid)
                    if not seenUUID[sUuid] and not seenUUID[sUuid:gsub("[{}]", "")] then
                        seenUUID[sUuid] = true
                        seenUUID[sUuid:gsub("[{}]", "")] = true

                        local nameOnly = obj.Name:gsub("%s*%[.-%]", ""):gsub("^%s*(.-)%s*$", "%1")
                        local weight = obj.Name:match("%[([%d%.]+)%s*KG%]") or obj.Name:match("([%d%.]+)%s*KG") or "?"
                        local age = obj.Name:match("%[Age%s*(%d+)%]") or obj.Name:match("Age%s*(%d+)") or "?"
                        table.insert(equipped, {
                            Model = obj,
                            UUID = sUuid,
                            FullName = obj.Name,
                            Name = nameOnly,
                            Weight = weight,
                            Age = age,
                            DisplayTitle = nameOnly .. " | Age " .. tostring(age) .. " | " .. tostring(weight) .. " KG",
                            InGarden = true,
                            IsFavorite = IsPetFavorited(uuid, obj)
                        })
                    end
                end
            end
        end

        if farm then
            checkContainer(farm:FindFirstChild("PetArea"))
            if farm:FindFirstChild("Important") then
                checkContainer(farm.Important:FindFirstChild("Objects_Physical"))
            end
        end
        
        checkContainer(workspace:FindFirstChild("PetsPhysical"))

        return equipped
    end

    local function GetAllPetsList()
        local pets = {}
        local seenUUIDs = {}
        local equippedMap = GetEquippedPetUUIDsMap()
        
        local toolLookup = {}
        local function registerTools(container)
            if not container then return end
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") then
                    local u = item:GetAttribute("PET_UUID") or (item:FindFirstChild("PET_UUID") and item.PET_UUID.Value)
                    if u then
                        local sU = tostring(u)
                        toolLookup[sU] = item
                        toolLookup[sU:gsub("[{}]", "")] = item
                    end
                end
            end
        end
        registerTools(LocalPlayer:FindFirstChild("Backpack"))
        registerTools(LocalPlayer.Character)

        if DataService then
            local ok, data = pcall(function() return DataService:GetData() end)
            if ok and data and data.PetsData and data.PetsData.PetInventory and data.PetsData.PetInventory.Data then
                for uuid, entry in pairs(data.PetsData.PetInventory.Data) do
                    local petData = entry.PetData or {}
                    local petType = entry.PetType or "Pet"
                    local cleanUUID = tostring(uuid)
                    local strippedUUID = cleanUUID:gsub("[{}]", "")
                    
                    local isInGarden = (equippedMap[cleanUUID] == true) or (equippedMap[strippedUUID] == true)
                    local isFav = (petData.IsFavorite == true)
                    
                    local customNickname = (petData.Name and petData.Name ~= "") and petData.Name or nil
                    local level = petData.Level or 1
                    local weight = "?"
                    if PetUtilities and PetUtilities.CalculateWeight and petData.BaseWeight then
                        local calcW = PetUtilities:CalculateWeight(petData.BaseWeight, level) * 100
                        weight = string.format("%.2f", math.round(calcW) / 100)
                    elseif petData.BaseWeight then
                        weight = tostring(petData.BaseWeight)
                    end

                    local toolObj = toolLookup[cleanUUID] or toolLookup[strippedUUID]
                    local speciesName = petType
                    if toolObj then
                        local cleanToolName = toolObj.Name:gsub("%s*%[.-%]", ""):gsub("^%s*(.-)%s*$", "%1")
                        if cleanToolName ~= "" and not cleanToolName:lower():find("tool") then
                            speciesName = cleanToolName
                        end
                    elseif petData.Mutation and petData.Mutation ~= "" then
                        speciesName = tostring(petData.Mutation) .. " " .. petType
                    end

                    local fullDisplayName = speciesName
                    if customNickname and customNickname:lower() ~= speciesName:lower() then
                        fullDisplayName = string.format("%s (%s)", speciesName, customNickname)
                    end
                    
                    local displayTitle = string.format("%s | Age %s | %s KG", fullDisplayName, tostring(level), tostring(weight))
                    
                    seenUUIDs[cleanUUID] = true
                    seenUUIDs[strippedUUID] = true
                    
                    table.insert(pets, {
                        UUID = cleanUUID,
                        FullName = displayTitle,
                        Name = fullDisplayName,
                        Species = speciesName,
                        Nickname = customNickname or "",
                        Weight = weight,
                        Age = level,
                        DisplayTitle = displayTitle,
                        InGarden = isInGarden,
                        IsFavorite = isFav,
                        Tool = toolObj
                    })
                end
            end
        end

        local function scanTools(container)
            if not container then return end
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") then
                    local uuid = item:GetAttribute("PET_UUID")
                    local hasPetTool = item:FindFirstChild("PetToolLocal")
                    local hasPetData = item:FindFirstChild("PetData")
                    if uuid or hasPetTool or hasPetData then
                        local petUUID = uuid or (item:FindFirstChild("PET_UUID") and item.PET_UUID.Value) or item.Name
                        local cleanUUID = tostring(petUUID)
                        local strippedUUID = cleanUUID:gsub("[{}]", "")
                        
                        local existing = nil
                        for _, p in ipairs(pets) do
                            if p.UUID == cleanUUID or p.UUID == strippedUUID then
                                existing = p
                                break
                            end
                        end

                        if existing then
                            existing.Tool = item
                        elseif not seenUUIDs[cleanUUID] and not seenUUIDs[strippedUUID] then
                            seenUUIDs[cleanUUID] = true
                            seenUUIDs[strippedUUID] = true
                            
                            local cleanSpecies = item.Name:gsub("%s*%[.-%]", ""):gsub("^%s*(.-)%s*$", "%1")
                            local weight = item.Name:match("%[([%d%.]+)%s*KG%]") or item.Name:match("([%d%.]+)%s*KG") or "?"
                            local age = item.Name:match("%[Age%s*(%d+)%]") or item.Name:match("Age%s*(%d+)") or "?"
                            local isFav = IsPetFavorited(cleanUUID, item)
                            local isInGarden = (equippedMap[cleanUUID] == true) or (equippedMap[strippedUUID] == true)
                            local displayTitle = string.format("%s | Age %s | %s KG", cleanSpecies, tostring(age), tostring(weight))

                            table.insert(pets, {
                                Tool = item,
                                UUID = cleanUUID,
                                FullName = item.Name,
                                Name = cleanSpecies,
                                Species = cleanSpecies,
                                Nickname = "",
                                Weight = weight,
                                Age = age,
                                DisplayTitle = displayTitle,
                                InGarden = isInGarden,
                                IsFavorite = isFav
                            })
                        end
                    end
                end
            end
        end
        scanTools(LocalPlayer:FindFirstChild("Backpack"))
        scanTools(LocalPlayer.Character)

        local gardenEquipped = GetEquippedPetsInGarden()
        for _, gPet in ipairs(gardenEquipped) do
            local cleanUUID = tostring(gPet.UUID)
            local strippedUUID = cleanUUID:gsub("[{}]", "")
            local found = false
            for _, p in ipairs(pets) do
                if p.UUID == cleanUUID or p.UUID == strippedUUID then
                    p.InGarden = true
                    found = true
                    break
                end
            end
            if not found and not seenUUIDs[cleanUUID] and not seenUUIDs[strippedUUID] then
                seenUUIDs[cleanUUID] = true
                seenUUIDs[strippedUUID] = true
                table.insert(pets, gPet)
            end
        end

        return pets
    end

    local function UnequipPetByUUID(uuid)
        if not uuid then return end
        local sUuid = tostring(uuid)
        local stripped = sUuid:gsub("[{}]", "")

        local containers = {}
        local farm = GetFarm()
        if farm then
            table.insert(containers, farm:FindFirstChild("PetArea"))
            if farm:FindFirstChild("Important") then
                table.insert(containers, farm.Important:FindFirstChild("Objects_Physical"))
            end
        end
        table.insert(containers, workspace:FindFirstChild("PetsPhysical"))

        for _, cont in ipairs(containers) do
            if cont then
                for _, obj in ipairs(cont:GetChildren()) do
                    local objUUID = obj:GetAttribute("UUID") or obj:GetAttribute("PET_UUID")
                    local match = false
                    if objUUID then
                        local oStr = tostring(objUUID)
                        if oStr == sUuid or oStr:gsub("[{}]", "") == stripped then
                            match = true
                        end
                    end
                    if not match then
                        for _, sub in ipairs(obj:GetChildren()) do
                            local subU = sub:GetAttribute("UUID") or sub:GetAttribute("PET_UUID")
                            if subU and (tostring(subU) == sUuid or tostring(subU):gsub("[{}]", "") == stripped) then
                                match = true
                                break
                            end
                        end
                    end

                    if match then
                        local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt and prompt.Parent then
                            prompt.HoldDuration = 0
                            prompt.RequiresLineOfSight = false
                            pcall(function() fireproximityprompt(prompt) end)
                        end
                    end
                end
            end
        end

        if PetsServiceMod and PetsServiceMod.UnequipPet then
            pcall(function() PetsServiceMod:UnequipPet(uuid) end)
            pcall(function() PetsServiceMod:UnequipPet(stripped) end)
        end
        if PetsServiceRemote then
            pcall(function() PetsServiceRemote:FireServer("UnequipPet", uuid) end)
            pcall(function() PetsServiceRemote:FireServer("UnequipPet", stripped) end)
        end
    end

    local function EquipPetByToolOrUUID(petInfo, targetCF)
        if not petInfo then return end
        local petArea = GetFarmPetArea()
        local targetPos = targetCF or (petArea and petArea.CFrame + Vector3.new(0, 2, 0)) or (LocalPlayer.Character and LocalPlayer.Character:GetPivot()) or CFrame.new(0, 5, 0)
        
        if PetsServiceMod and PetsServiceMod.EquipPet and petInfo.UUID then
            pcall(function() PetsServiceMod:EquipPet(petInfo.UUID, targetPos) end)
        end
        if PetsServiceRemote and petInfo.UUID then
            pcall(function() PetsServiceRemote:FireServer("EquipPet", petInfo.UUID, targetPos) end)
        end
        if petInfo.Tool and petInfo.Tool.Parent == LocalPlayer:FindFirstChild("Backpack") then
            EquipCheck(petInfo.Tool)
        end
    end

    -- =============================================================
    -- UI ACCORDION PET TEAM & CONFIG MANAGER
    -- =============================================================
    local accHatch, bodyHatch = ZyloLib:CreateAccordion(PagePets, "Auto Hatch & Pet Team Manager", true, 440)

    local TeamCard = Instance.new("Frame", bodyHatch)
    TeamCard.Name = "PetTeamManagerCard"
    TeamCard.Position = UDim2.new(0, 12, 0, 8)
    TeamCard.Size = UDim2.new(1, -24, 0, 395)
    TeamCard.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
    Instance.new("UICorner", TeamCard).CornerRadius = UDim.new(0, 8)
    local tcStroke = Instance.new("UIStroke", TeamCard)
    tcStroke.Color = C.STROKE
    tcStroke.Thickness = 1

    -- Sub-Tab Row
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

    -- Kontainer Tim Views vs Config Views
    local TeamViewsContainer = Instance.new("Frame", TeamCard)
    TeamViewsContainer.Position = UDim2.new(0, 0, 0, 44)
    TeamViewsContainer.Size = UDim2.new(1, 0, 1, -98)
    TeamViewsContainer.BackgroundTransparency = 1

    local ConfigContainer = Instance.new("ScrollingFrame", TeamCard)
    ConfigContainer.Position = UDim2.new(0, 0, 0, 44)
    ConfigContainer.Size = UDim2.new(1, 0, 1, -98)
    ConfigContainer.BackgroundTransparency = 1
    ConfigContainer.ScrollBarThickness = 3
    ConfigContainer.ScrollBarImageColor3 = C.PURPLE
    ConfigContainer.CanvasSize = UDim2.new(0, 0, 0, 320)
    ConfigContainer.Visible = false

    local function updateSubTabs()
        local isConfigActive = (State.ActiveTeam == "Config")
        TeamViewsContainer.Visible = not isConfigActive
        ConfigContainer.Visible = isConfigActive

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

        if not isConfigActive then
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

    GearBtn.MouseButton1Click:Connect(function()
        State.ActiveTeam = "Config"
        updateSubTabs()
    end)

    -- =============================================================
    -- [1] TEAM VIEWS CONTAINER
    -- =============================================================
    local DelayHeader = Instance.new("Frame", TeamViewsContainer)
    DelayHeader.Position = UDim2.new(0, 10, 0, 2)
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

    local CounterRow = Instance.new("Frame", TeamViewsContainer)
    CounterRow.Position = UDim2.new(0, 12, 0, 32)
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

    local RowEquip = Instance.new("Frame", TeamViewsContainer)
    RowEquip.Position = UDim2.new(0, 12, 0, 54)
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

    local RowUnequip = Instance.new("Frame", TeamViewsContainer)
    RowUnequip.Position = UDim2.new(0, 12, 0, 82)
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

    SelPetTitle = Instance.new("TextLabel", TeamViewsContainer)
    SelPetTitle.Position = UDim2.new(0, 12, 0, 110)
    SelPetTitle.Size = UDim2.new(1, -24, 0, 16)
    SelPetTitle.BackgroundTransparency = 1
    SelPetTitle.Text = "Select Pet (" .. State.ActiveTeam .. ")"
    SelPetTitle.TextColor3 = C.TEXT_M
    SelPetTitle.Font = Enum.Font.GothamMedium
    SelPetTitle.TextSize = 9.5
    SelPetTitle.TextXAlignment = Enum.TextXAlignment.Left

    local PetListFrame = Instance.new("Frame", TeamViewsContainer)
    PetListFrame.Position = UDim2.new(0, 10, 0, 128)
    PetListFrame.Size = UDim2.new(1, -20, 0, 122)
    PetListFrame.BackgroundColor3 = Color3.fromRGB(7, 9, 18)
    Instance.new("UICorner", PetListFrame).CornerRadius = UDim.new(0, 6)
    local plStroke = Instance.new("UIStroke", PetListFrame)
    plStroke.Color = C.STROKE

    local PetSearchBox = Instance.new("TextBox", PetListFrame)
    PetSearchBox.Position = UDim2.new(0, 8, 0, 6)
    PetSearchBox.Size = UDim2.new(1, -16, 0, 22)
    PetSearchBox.BackgroundColor3 = Color3.fromRGB(14, 18, 36)
    PetSearchBox.PlaceholderText = "Search by species (mimic, bald) or name..."
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
        
        local allPets = GetAllPetsList()
        local curTeam = State.ActiveTeam or "Main Team"
        if curTeam == "Config" then return end
        if not State.SelectedPets[curTeam] then
            State.SelectedPets[curTeam] = {}
        end
        local selectedList = State.SelectedPets[curTeam]
        local filter = (State.TeamSearchQuery or ""):lower()

        local selectedMap = {}
        for _, selUUID in ipairs(selectedList) do
            selectedMap[selUUID] = true
            selectedMap[selUUID:gsub("[{}]", "")] = true
        end

        local filteredPets = {}
        for _, pet in ipairs(allPets) do
            local isFav = (pet.IsFavorite == true)
            local isCurrentlySelected = (selectedMap[pet.UUID] == true) or (selectedMap[pet.UUID:gsub("[{}]", "")] == true)

            if isFav or isCurrentlySelected then
                local displayStr = pet.DisplayTitle
                local matchesQuery = (filter == "") 
                    or displayStr:lower():find(filter) 
                    or (pet.Name and pet.Name:lower():find(filter)) 
                    or (pet.Species and pet.Species:lower():find(filter)) 
                    or (pet.Nickname and pet.Nickname:lower():find(filter))

                if matchesQuery then
                    table.insert(filteredPets, pet)
                end
            end
        end

        table.sort(filteredPets, function(a, b)
            local aSel = (selectedMap[a.UUID] == true) or (selectedMap[a.UUID:gsub("[{}]", "")] == true)
            local bSel = (selectedMap[b.UUID] == true) or (selectedMap[b.UUID:gsub("[{}]", "")] == true)
            if aSel ~= bSel then
                return aSel == true
            end
            if (a.InGarden or false) ~= (b.InGarden or false) then
                return (a.InGarden or false) == true
            end
            return (a.Name or "") < (b.Name or "")
        end)

        local matchedCount = 0
        for _, pet in ipairs(filteredPets) do
            matchedCount = matchedCount + 1
            local isSelected = (selectedMap[pet.UUID] == true) or (selectedMap[pet.UUID:gsub("[{}]", "")] == true)
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
                    if selUUID == pet.UUID or selUUID:gsub("[{}]", "") == pet.UUID:gsub("[{}]", "") then
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
            emptyLbl.Text = (filter ~= "") and ("Tidak ada pet cocok: '" .. State.TeamSearchQuery .. "'") or "Hanya pet berstatus FAVORITE (⭐) yang dapat dipilih!"
            emptyLbl.TextColor3 = Color3.fromRGB(255, 120, 120)
            emptyLbl.Font = Enum.Font.GothamMedium
            emptyLbl.TextSize = 8.5
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

    task.spawn(function()
        while true do
            task.wait(6.0)
            if refreshPetSelectionUI and PetScroll and PetScroll.Parent and PetScroll.Visible and State.ActiveTeam ~= "Config" then
                pcall(refreshPetSelectionUI)
            end
        end
    end)

    -- =============================================================
    -- [2] CONFIG CONTAINER (EGG CONFIG & SELL CONFIG FULL UI)
    -- =============================================================
    local cfgLayout = Instance.new("UIListLayout", ConfigContainer)
    cfgLayout.Padding = UDim.new(0, 8)
    local cfgPad = Instance.new("UIPadding", ConfigContainer)
    cfgPad.PaddingTop = UDim.new(0, 4)
    cfgPad.PaddingLeft = UDim.new(0, 10)
    cfgPad.PaddingRight = UDim.new(0, 10)

    -- -------------------------------------------------------------
    -- [A] EGG CONFIG CARD (DROPDOWN HIDE / SHOW)
    -- -------------------------------------------------------------
    local EggConfigCard = Instance.new("Frame", ConfigContainer)
    EggConfigCard.Size = State.EggConfigExpanded and UDim2.new(1, 0, 0, 132) or UDim2.new(1, 0, 0, 38)
    EggConfigCard.BackgroundColor3 = Color3.fromRGB(14, 18, 36)
    Instance.new("UICorner", EggConfigCard).CornerRadius = UDim.new(0, 8)
    local eccStroke = Instance.new("UIStroke", EggConfigCard)
    eccStroke.Color = State.EggConfigExpanded and C.PURPLE_L or C.STROKE
    eccStroke.Thickness = 1.2

    local EggHeaderBtn = Instance.new("TextButton", EggConfigCard)
    EggHeaderBtn.Size = UDim2.new(1, 0, 0, 38)
    EggHeaderBtn.BackgroundTransparency = 1
    EggHeaderBtn.Text = ""

    local ehTitle = Instance.new("TextLabel", EggHeaderBtn)
    ehTitle.Position = UDim2.new(0, 12, 0, 0)
    ehTitle.Size = UDim2.new(1, -45, 1, 0)
    ehTitle.BackgroundTransparency = 1
    ehTitle.Text = "🥚  Egg Config"
    ehTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
    ehTitle.Font = Enum.Font.GothamBold
    ehTitle.TextSize = 10
    ehTitle.TextXAlignment = Enum.TextXAlignment.Left

    local ehArrow = Instance.new("TextLabel", EggHeaderBtn)
    ehArrow.Position = UDim2.new(1, -30, 0, 0)
    ehArrow.Size = UDim2.new(0, 20, 1, 0)
    ehArrow.BackgroundTransparency = 1
    ehArrow.Text = State.EggConfigExpanded and "▼" or "▶"
    ehArrow.TextColor3 = C.PURPLE_L
    ehArrow.Font = Enum.Font.GothamBold
    ehArrow.TextSize = 9.5

    local EggOptionsFrame = Instance.new("Frame", EggConfigCard)
    EggOptionsFrame.Position = UDim2.new(0, 8, 0, 42)
    EggOptionsFrame.Size = UDim2.new(1, -16, 0, 84)
    EggOptionsFrame.BackgroundTransparency = 1
    EggOptionsFrame.Visible = State.EggConfigExpanded

    local eoLayout = Instance.new("UIListLayout", EggOptionsFrame)
    eoLayout.Padding = UDim.new(0, 6)

    local rowHatch = Instance.new("Frame", EggOptionsFrame)
    rowHatch.Size = UDim2.new(1, 0, 0, 36)
    rowHatch.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
    Instance.new("UICorner", rowHatch).CornerRadius = UDim.new(0, 6)
    local rhStroke = Instance.new("UIStroke", rowHatch)
    rhStroke.Color = Color3.fromRGB(30, 38, 60)

    local rhLbl = Instance.new("TextLabel", rowHatch)
    rhLbl.Position = UDim2.new(0, 10, 0, 0)
    rhLbl.Size = UDim2.new(1, -55, 1, 0)
    rhLbl.BackgroundTransparency = 1
    rhLbl.Text = "Otomatis Tetaskan & Claim Telur Siap Panen"
    rhLbl.TextColor3 = C.TEXT_W
    rhLbl.Font = Enum.Font.GothamMedium
    rhLbl.TextSize = 8.5
    rhLbl.TextXAlignment = Enum.TextXAlignment.Left

    local hatchPill = ZyloLib:CreatePillSwitch(rowHatch, State.AutoHatch, function(v) State.AutoHatch = v end)
    hatchPill.Position = UDim2.new(1, -44, 0.5, -10)

    local rowSync = Instance.new("Frame", EggOptionsFrame)
    rowSync.Size = UDim2.new(1, 0, 0, 42)
    rowSync.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
    Instance.new("UICorner", rowSync).CornerRadius = UDim.new(0, 6)
    local rsStroke = Instance.new("UIStroke", rowSync)
    rsStroke.Color = Color3.fromRGB(30, 38, 60)

    local rsTitle = Instance.new("TextLabel", rowSync)
    rsTitle.Position = UDim2.new(0, 10, 0, 4)
    rsTitle.Size = UDim2.new(1, -55, 0, 16)
    rsTitle.BackgroundTransparency = 1
    rsTitle.Text = "Don't Hatch If Time Not Done"
    rsTitle.TextColor3 = C.TEXT_W
    rsTitle.Font = Enum.Font.GothamBold
    rsTitle.TextSize = 8.5
    rsTitle.TextXAlignment = Enum.TextXAlignment.Left

    local rsSub = Instance.new("TextLabel", rowSync)
    rsSub.Position = UDim2.new(0, 10, 0, 20)
    rsSub.Size = UDim2.new(1, -55, 0, 18)
    rsSub.BackgroundTransparency = 1
    rsSub.Text = "Tunggu semua telur selesai cooldown baru di-hatch barengan"
    rsSub.TextColor3 = C.TEXT_M
    rsSub.Font = Enum.Font.GothamMedium
    rsSub.TextSize = 7.5
    rsSub.TextXAlignment = Enum.TextXAlignment.Left

    local syncPill = ZyloLib:CreatePillSwitch(rowSync, State.DontHatchIfNotAllDone, function(v) State.DontHatchIfNotAllDone = v end)
    syncPill.Position = UDim2.new(1, -44, 0.5, -10)

    local function recalculateCanvasSize()
        local h = 80
        if State.EggConfigExpanded then h = h + 100 end
        if State.SellConfigExpanded then h = h + 450 end
        ConfigContainer.CanvasSize = UDim2.new(0, 0, 0, h)
    end

    EggHeaderBtn.MouseButton1Click:Connect(function()
        State.EggConfigExpanded = not State.EggConfigExpanded
        ehArrow.Text = State.EggConfigExpanded and "▼" or "▶"
        EggOptionsFrame.Visible = State.EggConfigExpanded
        EggConfigCard.Size = State.EggConfigExpanded and UDim2.new(1, 0, 0, 132) or UDim2.new(1, 0, 0, 38)
        eccStroke.Color = State.EggConfigExpanded and C.PURPLE_L or C.STROKE
        recalculateCanvasSize()
    end)

    -- -------------------------------------------------------------
    -- [B] SELL CONFIG CARD (DROPDOWN HIDE / SHOW DENGAN FULL UI FITUR)
    -- -------------------------------------------------------------
    local SellConfigCard = Instance.new("Frame", ConfigContainer)
    SellConfigCard.Size = State.SellConfigExpanded and UDim2.new(1, 0, 0, 460) or UDim2.new(1, 0, 0, 38)
    SellConfigCard.BackgroundColor3 = Color3.fromRGB(14, 18, 36)
    Instance.new("UICorner", SellConfigCard).CornerRadius = UDim.new(0, 8)
    local sccStroke = Instance.new("UIStroke", SellConfigCard)
    sccStroke.Color = State.SellConfigExpanded and C.PURPLE_L or C.STROKE
    sccStroke.Thickness = 1.2

    local SellHeaderBtn = Instance.new("TextButton", SellConfigCard)
    SellHeaderBtn.Size = UDim2.new(1, 0, 0, 38)
    SellHeaderBtn.BackgroundTransparency = 1
    SellHeaderBtn.Text = ""

    local shTitle = Instance.new("TextLabel", SellHeaderBtn)
    shTitle.Position = UDim2.new(0, 12, 0, 0)
    shTitle.Size = UDim2.new(1, -45, 1, 0)
    shTitle.BackgroundTransparency = 1
    shTitle.Text = "💰  Sell Config (Favorite Important Pets First)"
    shTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
    shTitle.Font = Enum.Font.GothamBold
    shTitle.TextSize = 9.5
    shTitle.TextXAlignment = Enum.TextXAlignment.Left

    local shArrow = Instance.new("TextLabel", SellHeaderBtn)
    shArrow.Position = UDim2.new(1, -30, 0, 0)
    shArrow.Size = UDim2.new(0, 20, 1, 0)
    shArrow.BackgroundTransparency = 1
    shArrow.Text = State.SellConfigExpanded and "▼" or "▶"
    shArrow.TextColor3 = C.PURPLE_L
    shArrow.Font = Enum.Font.GothamBold
    shArrow.TextSize = 9.5

    -- Kontainer Dropdown Opsi Sell Config
    local SellOptionsFrame = Instance.new("Frame", SellConfigCard)
    SellOptionsFrame.Position = UDim2.new(0, 8, 0, 42)
    SellOptionsFrame.Size = UDim2.new(1, -16, 0, 410)
    SellOptionsFrame.BackgroundTransparency = 1
    SellOptionsFrame.Visible = State.SellConfigExpanded

    local soLayout = Instance.new("UIListLayout", SellOptionsFrame)
    soLayout.Padding = UDim.new(0, 6)

    -- [1] Box PETUNJUK Aturan Main
    local ruleBox = Instance.new("Frame", SellOptionsFrame)
    ruleBox.Size = UDim2.new(1, 0, 0, 78)
    ruleBox.BackgroundColor3 = Color3.fromRGB(9, 12, 22)
    Instance.new("UICorner", ruleBox).CornerRadius = UDim.new(0, 6)
    local rbStroke = Instance.new("UIStroke", ruleBox)
    rbStroke.Color = Color3.fromRGB(35, 42, 65)

    local ruleText = Instance.new("TextLabel", ruleBox)
    ruleText.Position = UDim2.new(0, 8, 0, 4)
    ruleText.Size = UDim2.new(1, -16, 1, -8)
    ruleText.BackgroundTransparency = 1
    ruleText.Text = "<b><font color=\"#C084FC\">PETUNJUK</font></b>\n• Aturan ini <b>hanya diterapkan</b> pada pet yang tercantum di dalam List.\n• Pet yang tidak tercantum di dalam List dianggap <font color=\"#4ADE80\">AMAN</font> (tidak diproses/dijual).\n• <b>KG = 0</b> pet akan di <font color=\"#4ADE80\">KEEP</font>.\n• Apabila <b>KG > 0</b>: Weight < KG mengikuti KEEP/SELL, Weight >= KG <font color=\"#4ADE80\">KEEP (Bronto)</font>."
    ruleText.RichText = true
    ruleText.TextColor3 = Color3.fromRGB(200, 210, 235)
    ruleText.Font = Enum.Font.Gotham
    ruleText.TextSize = 7.5
    ruleText.TextWrapped = true
    ruleText.TextXAlignment = Enum.TextXAlignment.Left
    ruleText.TextYAlignment = Enum.TextYAlignment.Top

    -- [2] Baris Ambang Batas Jumlah Pet (Auto Sell Aktif Saat Total Pet)
    local rowThresh = Instance.new("Frame", SellOptionsFrame)
    rowThresh.Size = UDim2.new(1, 0, 0, 28)
    rowThresh.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
    Instance.new("UICorner", rowThresh).CornerRadius = UDim.new(0, 5)

    local rthLbl = Instance.new("TextLabel", rowThresh)
    rthLbl.Position = UDim2.new(0, 8, 0, 0)
    rthLbl.Size = UDim2.new(1, -65, 1, 0)
    rthLbl.BackgroundTransparency = 1
    rthLbl.Text = "Auto Sell Aktif Saat Total Pet ( Sesuai Config List Dibawah ) :"
    rthLbl.TextColor3 = Color3.fromRGB(255, 110, 110)
    rthLbl.Font = Enum.Font.GothamBold
    rthLbl.TextSize = 8
    rthLbl.TextXAlignment = Enum.TextXAlignment.Left

    local rthBox = Instance.new("TextBox", rowThresh)
    rthBox.Position = UDim2.new(1, -50, 0.5, -10)
    rthBox.Size = UDim2.new(0, 42, 0, 20)
    rthBox.BackgroundColor3 = Color3.fromRGB(16, 21, 42)
    rthBox.Text = tostring(State.AutoSellThresholdCount or 24)
    rthBox.TextColor3 = C.TEXT_W
    rthBox.Font = Enum.Font.GothamBold
    rthBox.TextSize = 9
    Instance.new("UICorner", rthBox).CornerRadius = UDim.new(0, 4)
    local rthStroke = Instance.new("UIStroke", rthBox)
    rthStroke.Color = C.STROKE

    rthBox:GetPropertyChangedSignal("Text"):Connect(function()
        local val = tonumber(rthBox.Text)
        if val then State.AutoSellThresholdCount = val end
    end)

    -- [3] Sell Mode Selector (Sell One By One vs Sell All)
    local rowMode = Instance.new("Frame", SellOptionsFrame)
    rowMode.Size = UDim2.new(1, 0, 0, 26)
    rowMode.BackgroundTransparency = 1

    local smLbl = Instance.new("TextLabel", rowMode)
    smLbl.Position = UDim2.new(0, 4, 0, 0)
    smLbl.Size = UDim2.new(0.35, 0, 1, 0)
    smLbl.BackgroundTransparency = 1
    smLbl.Text = "Sell Mode"
    smLbl.TextColor3 = C.TEXT_M
    smLbl.Font = Enum.Font.GothamMedium
    smLbl.TextSize = 9
    smLbl.TextXAlignment = Enum.TextXAlignment.Left

    local btnOneByOne = Instance.new("TextButton", rowMode)
    btnOneByOne.Position = UDim2.new(0.36, 0, 0, 0)
    btnOneByOne.Size = UDim2.new(0.31, 0, 1, 0)
    btnOneByOne.BackgroundColor3 = (State.SellMode == "Sell One By One") and C.PURPLE or Color3.fromRGB(16, 21, 42)
    btnOneByOne.Text = "Sell One By One"
    btnOneByOne.TextColor3 = (State.SellMode == "Sell One By One") and Color3.fromRGB(255, 255, 255) or C.TEXT_M
    btnOneByOne.Font = Enum.Font.GothamBold
    btnOneByOne.TextSize = 8
    Instance.new("UICorner", btnOneByOne).CornerRadius = UDim.new(0, 4)

    local btnSellAll = Instance.new("TextButton", rowMode)
    btnSellAll.Position = UDim2.new(0.69, 0, 0, 0)
    btnSellAll.Size = UDim2.new(0.31, 0, 1, 0)
    btnSellAll.BackgroundColor3 = (State.SellMode == "Sell All") and C.PURPLE or Color3.fromRGB(16, 21, 42)
    btnSellAll.Text = "Sell All"
    btnSellAll.TextColor3 = (State.SellMode == "Sell All") and Color3.fromRGB(255, 255, 255) or C.TEXT_M
    btnSellAll.Font = Enum.Font.GothamBold
    btnSellAll.TextSize = 8
    Instance.new("UICorner", btnSellAll).CornerRadius = UDim.new(0, 4)

    local function updateModeButtons()
        btnOneByOne.BackgroundColor3 = (State.SellMode == "Sell One By One") and C.PURPLE or Color3.fromRGB(16, 21, 42)
        btnOneByOne.TextColor3 = (State.SellMode == "Sell One By One") and Color3.fromRGB(255, 255, 255) or C.TEXT_M
        btnSellAll.BackgroundColor3 = (State.SellMode == "Sell All") and C.PURPLE or Color3.fromRGB(16, 21, 42)
        btnSellAll.TextColor3 = (State.SellMode == "Sell All") and Color3.fromRGB(255, 255, 255) or C.TEXT_M
    end

    btnOneByOne.MouseButton1Click:Connect(function()
        State.SellMode = "Sell One By One"
        updateModeButtons()
    end)
    btnSellAll.MouseButton1Click:Connect(function()
        State.SellMode = "Sell All"
        updateModeButtons()
    end)

    -- [4] Search Box Pet di Config
    local sellSearchBox = Instance.new("TextBox", SellOptionsFrame)
    sellSearchBox.Size = UDim2.new(1, 0, 0, 22)
    sellSearchBox.BackgroundColor3 = Color3.fromRGB(9, 12, 22)
    sellSearchBox.PlaceholderText = "Search..."
    sellSearchBox.PlaceholderColor3 = Color3.fromRGB(110, 120, 150)
    sellSearchBox.Text = ""
    sellSearchBox.TextColor3 = C.TEXT_W
    sellSearchBox.Font = Enum.Font.Gotham
    sellSearchBox.TextSize = 8.5
    Instance.new("UICorner", sellSearchBox).CornerRadius = UDim.new(0, 4)
    local ssbStroke = Instance.new("UIStroke", sellSearchBox)
    ssbStroke.Color = Color3.fromRGB(32, 38, 60)

    -- [5] Scroll List Tabel Rules Pet
    local sellListScroll = Instance.new("ScrollingFrame", SellOptionsFrame)
    sellListScroll.Size = UDim2.new(1, 0, 0, 130)
    sellListScroll.BackgroundColor3 = Color3.fromRGB(9, 12, 22)
    sellListScroll.ScrollBarThickness = 2
    sellListScroll.ScrollBarImageColor3 = C.PURPLE
    Instance.new("UICorner", sellListScroll).CornerRadius = UDim.new(0, 6)
    local slsStroke = Instance.new("UIStroke", sellListScroll)
    slsStroke.Color = Color3.fromRGB(30, 38, 60)

    local slsLayout = Instance.new("UIListLayout", sellListScroll)
    slsLayout.Padding = UDim.new(0, 4)
    local slsPad = Instance.new("UIPadding", sellListScroll)
    slsPad.PaddingTop = UDim.new(0, 4)
    slsPad.PaddingLeft = UDim.new(0, 4)
    slsPad.PaddingRight = UDim.new(0, 4)

    local renderSellRules = nil

    renderSellRules = function()
        for _, ch in ipairs(sellListScroll:GetChildren()) do
            if ch:IsA("Frame") then ch:Destroy() end
        end

        local filter = (State.SellSearchQuery or ""):lower()
        local count = 0

        for idx, rule in ipairs(State.SellPetRules) do
            if filter == "" or rule.Species:lower():find(filter) then
                count = count + 1
                local item = Instance.new("Frame", sellListScroll)
                item.Size = UDim2.new(1, 0, 0, 24)
                item.BackgroundColor3 = Color3.fromRGB(14, 18, 36)
                Instance.new("UICorner", item).CornerRadius = UDim.new(0, 4)

                local nameLbl = Instance.new("TextLabel", item)
                nameLbl.Position = UDim2.new(0, 6, 0, 0)
                nameLbl.Size = UDim2.new(0.32, 0, 1, 0)
                nameLbl.BackgroundTransparency = 1
                nameLbl.Text = rule.Species
                nameLbl.TextColor3 = Color3.fromRGB(240, 245, 255)
                nameLbl.Font = Enum.Font.GothamMedium
                nameLbl.TextSize = 8
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left

                local badgeLbl = Instance.new("TextLabel", item)
                badgeLbl.Position = UDim2.new(0.33, 0, 0, 0)
                badgeLbl.Size = UDim2.new(0.35, 0, 1, 0)
                badgeLbl.BackgroundTransparency = 1
                badgeLbl.RichText = true
                badgeLbl.Text = string.format("<font color=\"#F87171\">&lt; %s %s</font> | <font color=\"#4ADE80\">&gt;= %s BRONTO</font>", tostring(rule.KG), rule.Action, tostring(rule.KG))
                badgeLbl.Font = Enum.Font.GothamBold
                badgeLbl.TextSize = 7.5
                badgeLbl.TextXAlignment = Enum.TextXAlignment.Left

                local kgBox = Instance.new("TextBox", item)
                kgBox.Position = UDim2.new(0.69, 0, 0.5, -8)
                kgBox.Size = UDim2.new(0, 26, 0, 16)
                kgBox.BackgroundColor3 = Color3.fromRGB(9, 12, 22)
                kgBox.Text = tostring(rule.KG)
                kgBox.TextColor3 = C.TEXT_W
                kgBox.Font = Enum.Font.GothamBold
                kgBox.TextSize = 8
                Instance.new("UICorner", kgBox).CornerRadius = UDim.new(0, 3)

                kgBox:GetPropertyChangedSignal("Text"):Connect(function()
                    local val = tonumber(kgBox.Text)
                    if val then
                        rule.KG = val
                        badgeLbl.Text = string.format("<font color=\"#F87171\">&lt; %s %s</font> | <font color=\"#4ADE80\">&gt;= %s BRONTO</font>", tostring(rule.KG), rule.Action, tostring(rule.KG))
                    end
                end)

                local actBtn = Instance.new("TextButton", item)
                actBtn.Position = UDim2.new(0.79, 0, 0.5, -8)
                actBtn.Size = UDim2.new(0, 34, 0, 16)
                local isSell = (rule.Action == "SELL")
                actBtn.BackgroundColor3 = isSell and Color3.fromRGB(120, 24, 40) or Color3.fromRGB(24, 100, 50)
                actBtn.Text = rule.Action
                actBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                actBtn.Font = Enum.Font.GothamBold
                actBtn.TextSize = 7.5
                Instance.new("UICorner", actBtn).CornerRadius = UDim.new(0, 3)

                actBtn.MouseButton1Click:Connect(function()
                    rule.Action = (rule.Action == "SELL") and "KEEP" or "SELL"
                    actBtn.Text = rule.Action
                    actBtn.BackgroundColor3 = (rule.Action == "SELL") and Color3.fromRGB(120, 24, 40) or Color3.fromRGB(24, 100, 50)
                    badgeLbl.Text = string.format("<font color=\"#F87171\">&lt; %s %s</font> | <font color=\"#4ADE80\">&gt;= %s BRONTO</font>", tostring(rule.KG), rule.Action, tostring(rule.KG))
                end)

                local delBtn = Instance.new("TextButton", item)
                delBtn.Position = UDim2.new(1, -20, 0.5, -8)
                delBtn.Size = UDim2.new(0, 16, 0, 16)
                delBtn.BackgroundColor3 = Color3.fromRGB(140, 25, 35)
                delBtn.Text = "-"
                delBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                delBtn.Font = Enum.Font.GothamBold
                delBtn.TextSize = 9
                Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 3)

                delBtn.MouseButton1Click:Connect(function()
                    table.remove(State.SellPetRules, idx)
                    renderSellRules()
                end)
            end
        end

        sellListScroll.CanvasSize = UDim2.new(0, 0, 0, count * 28 + 4)
    end

    sellSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        State.SellSearchQuery = sellSearchBox.Text
        renderSellRules()
    end)

    renderSellRules()

    -- [6] Baris Bulk Pet Type Selection
    local rowBulkPet = Instance.new("Frame", SellOptionsFrame)
    rowBulkPet.Size = UDim2.new(1, 0, 0, 24)
    rowBulkPet.BackgroundTransparency = 1

    local bpLbl = Instance.new("TextLabel", rowBulkPet)
    bpLbl.Size = UDim2.new(0.4, 0, 1, 0)
    bpLbl.BackgroundTransparency = 1
    bpLbl.Text = "Select Pet Type"
    bpLbl.TextColor3 = C.TEXT_M
    bpLbl.Font = Enum.Font.GothamMedium
    bpLbl.TextSize = 8.5
    bpLbl.TextXAlignment = Enum.TextXAlignment.Left

    local bpDropdown = Instance.new("TextButton", rowBulkPet)
    bpDropdown.Position = UDim2.new(0.42, 0, 0, 0)
    bpDropdown.Size = UDim2.new(0.58, 0, 1, 0)
    bpDropdown.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
    bpDropdown.Text = "Select Pet... ▼"
    bpDropdown.TextColor3 = C.TEXT_W
    bpDropdown.Font = Enum.Font.GothamMedium
    bpDropdown.TextSize = 8.5
    Instance.new("UICorner", bpDropdown).CornerRadius = UDim.new(0, 4)
    local bpdStroke = Instance.new("UIStroke", bpDropdown)
    bpdStroke.Color = Color3.fromRGB(35, 42, 65)

    -- [7] Baris KG (Bulk)
    local rowBulkKG = Instance.new("Frame", SellOptionsFrame)
    rowBulkKG.Size = UDim2.new(1, 0, 0, 24)
    rowBulkKG.BackgroundTransparency = 1

    local bkgLbl = Instance.new("TextLabel", rowBulkKG)
    bkgLbl.Size = UDim2.new(0.6, 0, 1, 0)
    bkgLbl.BackgroundTransparency = 1
    bkgLbl.Text = "KG (Bulk)"
    bkgLbl.TextColor3 = C.TEXT_M
    bkgLbl.Font = Enum.Font.GothamMedium
    bkgLbl.TextSize = 8.5
    bkgLbl.TextXAlignment = Enum.TextXAlignment.Left

    local bkgBox = Instance.new("TextBox", rowBulkKG)
    bkgBox.Position = UDim2.new(1, -55, 0, 0)
    bkgBox.Size = UDim2.new(0, 55, 1, 0)
    bkgBox.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
    bkgBox.Text = tostring(State.BulkKG or 0)
    bkgBox.TextColor3 = C.TEXT_W
    bkgBox.Font = Enum.Font.GothamBold
    bkgBox.TextSize = 8.5
    Instance.new("UICorner", bkgBox).CornerRadius = UDim.new(0, 4)
    local bkgStroke = Instance.new("UIStroke", bkgBox)
    bkgStroke.Color = Color3.fromRGB(35, 42, 65)

    bkgBox:GetPropertyChangedSignal("Text"):Connect(function()
        local val = tonumber(bkgBox.Text)
        if val then State.BulkKG = val end
    end)

    -- [8] Baris Below KG Action (Bulk)
    local rowBulkAct = Instance.new("Frame", SellOptionsFrame)
    rowBulkAct.Size = UDim2.new(1, 0, 0, 24)
    rowBulkAct.BackgroundTransparency = 1

    local bkaLbl = Instance.new("TextLabel", rowBulkAct)
    bkaLbl.Size = UDim2.new(0.6, 0, 1, 0)
    bkaLbl.BackgroundTransparency = 1
    bkaLbl.Text = "Below KG Action (Bulk)"
    bkaLbl.TextColor3 = C.TEXT_M
    bkaLbl.Font = Enum.Font.GothamMedium
    bkaLbl.TextSize = 8.5
    bkaLbl.TextXAlignment = Enum.TextXAlignment.Left

    local bkaBtn = Instance.new("TextButton", rowBulkAct)
    bkaBtn.Position = UDim2.new(1, -75, 0, 0)
    bkaBtn.Size = UDim2.new(0, 75, 1, 0)
    bkaBtn.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
    bkaBtn.Text = State.BulkAction .. "  ▼"
    bkaBtn.TextColor3 = C.TEXT_W
    bkaBtn.Font = Enum.Font.GothamMedium
    bkaBtn.TextSize = 8.5
    Instance.new("UICorner", bkaBtn).CornerRadius = UDim.new(0, 4)
    local bkaStroke = Instance.new("UIStroke", bkaBtn)
    bkaStroke.Color = Color3.fromRGB(35, 42, 65)

    bkaBtn.MouseButton1Click:Connect(function()
        State.BulkAction = (State.BulkAction == "sell") and "keep" or "sell"
        bkaBtn.Text = State.BulkAction .. "  ▼"
    end)

    -- [9] Baris APPLY BULK LIST
    local rowBulkApply = Instance.new("Frame", SellOptionsFrame)
    rowBulkApply.Size = UDim2.new(1, 0, 0, 26)
    rowBulkApply.BackgroundTransparency = 1

    local baLbl = Instance.new("TextLabel", rowBulkApply)
    baLbl.Size = UDim2.new(0.7, 0, 1, 0)
    baLbl.BackgroundTransparency = 1
    baLbl.Text = "APPLY BULK LIST"
    baLbl.TextColor3 = C.TEXT_M
    baLbl.Font = Enum.Font.GothamBold
    baLbl.TextSize = 8.5
    baLbl.TextXAlignment = Enum.TextXAlignment.Left

    local bulkPill = ZyloLib:CreatePillSwitch(rowBulkApply, State.ApplyBulkList, function(v)
        State.ApplyBulkList = v
    end)
    bulkPill.Position = UDim2.new(1, -44, 0.5, -10)

    -- Logika Klik Dropdown: Hide / Show Sell Config
    SellHeaderBtn.MouseButton1Click:Connect(function()
        State.SellConfigExpanded = not State.SellConfigExpanded
        shArrow.Text = State.SellConfigExpanded and "▼" or "▶"
        SellOptionsFrame.Visible = State.SellConfigExpanded
        SellConfigCard.Size = State.SellConfigExpanded and UDim2.new(1, 0, 0, 460) or UDim2.new(1, 0, 0, 38)
        sccStroke.Color = State.SellConfigExpanded and C.PURPLE_L or C.STROKE
        recalculateCanvasSize()
    end)

    -- -------------------------------------------------------------
    -- [C] SWAP SKILL CONFIG BUTTON
    -- -------------------------------------------------------------
    local function makeSimpleConfigButton(title)
        local btn = Instance.new("TextButton", ConfigContainer)
        btn.Size = UDim2.new(1, 0, 0, 38)
        btn.BackgroundColor3 = Color3.fromRGB(14, 18, 36)
        btn.Text = ""
        btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        local stroke = Instance.new("UIStroke", btn)
        stroke.Color = C.STROKE
        stroke.Thickness = 1.2

        local tLbl = Instance.new("TextLabel", btn)
        tLbl.Position = UDim2.new(0, 12, 0, 0)
        tLbl.Size = UDim2.new(1, -45, 1, 0)
        tLbl.BackgroundTransparency = 1
        tLbl.Text = title
        tLbl.TextColor3 = Color3.fromRGB(240, 245, 255)
        tLbl.Font = Enum.Font.GothamBold
        tLbl.TextSize = 9.5
        tLbl.TextXAlignment = Enum.TextXAlignment.Left

        local arrow = Instance.new("TextLabel", btn)
        arrow.Position = UDim2.new(1, -30, 0, 0)
        arrow.Size = UDim2.new(0, 20, 1, 0)
        arrow.BackgroundTransparency = 1
        arrow.Text = "▶"
        arrow.TextColor3 = C.PURPLE_L
        arrow.Font = Enum.Font.GothamBold
        arrow.TextSize = 9.5

        return btn
    end

    makeSimpleConfigButton("🔄  Swap Skill Config")

    -- =============================================================
    -- [3] BOTTOM ACTION BAR (START & STOP MULTI-PASS RECALL) - POSISI PATEN
    -- =============================================================
    local BtnRow = Instance.new("Frame", TeamCard)
    BtnRow.Position = UDim2.new(0, 10, 1, -46)
    BtnRow.Size = UDim2.new(1, -20, 0, 34)
    BtnRow.BackgroundTransparency = 1

    local StartBtn = Instance.new("TextButton", BtnRow)
    StartBtn.Size = UDim2.new(0, 88, 1, 0)
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
    StopBtn.Position = UDim2.new(0, 96, 0, 0)
    StopBtn.Size = UDim2.new(0, 76, 1, 0)
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
        if isExecutingTeam or teamName == "Config" then return end
        isExecutingTeam = true
        
        local targetUUIDs = State.SelectedPets[teamName] or {}
        local delayEq = tonumber(State.TeamDelayEquip[teamName]) or 0
        local delayUneq = tonumber(State.TeamDelayUnequip[teamName]) or 1
        
        local targetLookup = {}
        for _, uuid in ipairs(targetUUIDs) do
            targetLookup[uuid] = true
            targetLookup[uuid:gsub("[{}]", "")] = true
        end
        
        local inGarden = GetEquippedPetsInGarden()
        for _, gPet in ipairs(inGarden) do
            local gUUID = gPet.UUID
            if not targetLookup[gUUID] and not targetLookup[gUUID:gsub("[{}]", "")] then
                UnequipPetByUUID(gUUID)
                if delayUneq > 0 then
                    task.wait(delayUneq)
                else
                    task.wait(0.1)
                end
            end
        end
        
        local allPets = GetAllPetsList()
        local petsLookup = {}
        for _, p in ipairs(allPets) do
            petsLookup[p.UUID] = p
            petsLookup[p.UUID:gsub("[{}]", "")] = p
        end
        
        for _, uuid in ipairs(targetUUIDs) do
            if not State.IsTeamRunning then break end
            local pInfo = petsLookup[uuid] or petsLookup[uuid:gsub("[{}]", "")]
            if pInfo and not pInfo.InGarden then
                EquipPetByToolOrUUID(pInfo)
                if delayEq > 0 then
                    task.wait(delayEq)
                else
                    task.wait(0.15)
                end
            end
        end
        
        isExecutingTeam = false
        if refreshPetSelectionUI then
            task.defer(refreshPetSelectionUI)
        end
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

    -- LOGIKA TOMBOL STOP DENGAN MULTI-PASS SWEEP
    local isStopping = false
    StopBtn.MouseButton1Click:Connect(function()
        State.IsTeamRunning = false
        StartBtn.BackgroundColor3 = C.PURPLE
        StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        sbStroke.Color = C.PURPLE_L
        
        StopBtn.BackgroundColor3 = Color3.fromRGB(48, 20, 32)
        StopBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
        stpStroke.Color = Color3.fromRGB(255, 70, 70)
        StopBtn.Text = "UNEQUIP..."

        task.spawn(function()
            if isStopping then return end
            isStopping = true

            local curTeam = State.ActiveTeam or "Main Team"
            local delayUneq = tonumber(State.TeamDelayUnequip[curTeam]) or 0.2
            if delayUneq <= 0 then delayUneq = 0.1 end

            local inGarden = GetEquippedPetsInGarden()
            for _, gPet in ipairs(inGarden) do
                UnequipPetByUUID(gPet.UUID)
                task.wait(delayUneq)
            end

            if DataService then
                local ok, data = pcall(function() return DataService:GetData() end)
                if ok and data and data.PetsData and data.PetsData.EquippedPets then
                    for _, u in ipairs(data.PetsData.EquippedPets) do
                        UnequipPetByUUID(tostring(u))
                        task.wait(delayUneq)
                    end
                end
            end

            task.wait(0.3)

            local remaining = GetEquippedPetsInGarden()
            for _, remPet in ipairs(remaining) do
                UnequipPetByUUID(remPet.UUID)
                if remPet.Model then
                    local p = remPet.Model:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if p then
                        p.HoldDuration = 0
                        pcall(function() fireproximityprompt(p) end)
                    end
                end
                task.wait(0.1)
            end

            isStopping = false
            StopBtn.Text = "STOP"
            StopBtn.BackgroundColor3 = Color3.fromRGB(16, 21, 42)
            StopBtn.TextColor3 = C.TEXT_M
            stpStroke.Color = C.STROKE

            if refreshPetSelectionUI then
                task.defer(refreshPetSelectionUI)
            end
        end)
    end)

    return {
        ExecutePetTeam = ExecutePetTeam,
        GetEquippedPetsInGarden = GetEquippedPetsInGarden,
        UnequipPetByUUID = UnequipPetByUUID
    }
end
