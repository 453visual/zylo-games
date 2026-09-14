-- =========================================================================
--  ZYLOHUB - PET TEAM MANAGER MODULE (OFFICIAL EXTENSION - PART 1)
--  Repository: zylo-games/PetTeamManager.lua
--  Theme: Deep Obsidian Black (#070912) & Cosmic Purple (#8A2BE2)
--  STATUS: 100% PRESERVED PET TEAM MANAGER ENGINE + MULTI-PASS UNEQUIP
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

    -- Inisialisasi State Khusus Pet Team Manager
    State.ActiveTeam = State.ActiveTeam or "Main Team"
    State.TeamDelayEquip = State.TeamDelayEquip or { ["Main Team"] = 0, ["Bronto Team"] = 0, ["Hatch Team"] = 0, ["Sell Team"] = 0 }
    State.TeamDelayUnequip = State.TeamDelayUnequip or { ["Main Team"] = 1, ["Bronto Team"] = 1, ["Hatch Team"] = 1, ["Sell Team"] = 1 }
    State.SelectedPets = State.SelectedPets or { ["Main Team"] = {}, ["Bronto Team"] = {}, ["Hatch Team"] = {}, ["Sell Team"] = {} }
    State.TeamSearchQuery = State.TeamSearchQuery or ""
    State.IsTeamRunning = (State.IsTeamRunning ~= nil) and State.IsTeamRunning or false

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
                    local numWeight = 0
                    if PetUtilities and PetUtilities.CalculateWeight and petData.BaseWeight then
                        local calcW = PetUtilities:CalculateWeight(petData.BaseWeight, level) * 100
                        numWeight = math.round(calcW) / 100
                        weight = string.format("%.2f", numWeight)
                    elseif petData.BaseWeight then
                        numWeight = tonumber(petData.BaseWeight) or 0
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
                        NumericWeight = numWeight,
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
                            local weightStr = item.Name:match("%[([%d%.]+)%s*KG%]") or item.Name:match("([%d%.]+)%s*KG") or "?"
                            local numW = tonumber(weightStr) or 0
                            local age = item.Name:match("%[Age%s*(%d+)%]") or item.Name:match("Age%s*(%d+)") or "?"
                            local isFav = IsPetFavorited(cleanUUID, item)
                            local isInGarden = (equippedMap[cleanUUID] == true) or (equippedMap[strippedUUID] == true)
                            local displayTitle = string.format("%s | Age %s | %s KG", cleanSpecies, tostring(age), tostring(weightStr))

                            table.insert(pets, {
                                Tool = item,
                                UUID = cleanUUID,
                                FullName = item.Name,
                                Name = cleanSpecies,
                                Species = cleanSpecies,
                                Nickname = "",
                                Weight = weightStr,
                                NumericWeight = numW,
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

    -- LOGIKA TOMBOL STOP DENGAN MULTI-PASS SWEEP AGAR TAK ADA SATU PET PUN TERTINGGAL
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
        TeamCard = TeamCard,
        ConfigContainer = ConfigContainer,
        SubTabRow = SubTabRow,
        SubTabBtns = subTabBtns,
        UpdateSubTabs = updateSubTabs,
        ExecutePetTeam = ExecutePetTeam,
        GetEquippedPetsInGarden = GetEquippedPetsInGarden,
        UnequipPetByUUID = UnequipPetByUUID,
        GetAllPetsList = GetAllPetsList,
        GetFarm = GetFarm,
        GetFarmPetArea = GetFarmPetArea,
        EquipCheck = EquipCheck,
        IsPetFavorited = IsPetFavorited
    }
end
