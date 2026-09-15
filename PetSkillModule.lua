-- =========================================================================
--  ZYLOHUB - PET SKILL MODULE (PNP & AUTO PET BOOST)
--  Theme: Deep Obsidian Black (#070912) & Cosmic Purple (#8A2BE2)
--  STATUS: 100% FIXED PNP PLACE LOGIC + MULTI-SELECTION FOR PETS & BOOSTS
--  BASED ON OFFICIAL GAME DECOMPILE: ActivePetsUIController & PetBoostLocalScript
-- =========================================================================

local PetSkillModule = {}

function PetSkillModule.Init(ParentContainer, State, ZyloLib, MainScreen)
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local VirtualUser = game:GetService("VirtualUser")
    local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

    local C = ZyloLib and ZyloLib.Colors or {
        BG_DARK = Color3.fromRGB(7, 9, 18),
        CARD = Color3.fromRGB(13, 17, 33),
        CARD_2 = Color3.fromRGB(18, 23, 45),
        PURPLE = Color3.fromRGB(138, 43, 226),
        PURPLE_L = Color3.fromRGB(175, 110, 255),
        CYAN = Color3.fromRGB(0, 220, 255),
        TEXT_W = Color3.fromRGB(245, 247, 255),
        TEXT_M = Color3.fromRGB(145, 155, 185),
        STROKE = Color3.fromRGB(35, 42, 70)
    }

    -- [1] SERVICES & REMOTES RESMI DARI DECOMPILE
    local GameEvents = ReplicatedStorage:WaitForChild("GameEvents", 10)
    local PetsServiceRemote = GameEvents and GameEvents:WaitForChild("PetsService", 5)
    local PetCooldownsUpdated = GameEvents and GameEvents:WaitForChild("PetCooldownsUpdated", 5)
    local PetBoostService = GameEvents and GameEvents:WaitForChild("PetBoostService", 5)
    local Farms = workspace:WaitForChild("Farm", 10)

    local PetsServiceMod = nil
    pcall(function()
        PetsServiceMod = require(ReplicatedStorage:WaitForChild("Modules", 5):WaitForChild("PetServices", 5):WaitForChild("PetsService", 5))
    end)

    -- [2] INISIALISASI & MIGRASI STATE (MENDUKUNG MULTI-SELECT)
    State.PNP = State.PNP or {}
    State.PNP.Enabled = (State.PNP.Enabled ~= nil) and State.PNP.Enabled or false
    State.PNP.DelaySeconds = State.PNP.DelaySeconds or 0.1

    -- Migrasi ke Table Multi-Select jika sebelumnya string
    if type(State.PNP.SelectedPets) ~= "table" then
        local prev = State.PNP.SelectedPet or "All Equipped Pets"
        State.PNP.SelectedPets = { [prev] = true }
    end

    State.PetBoost = State.PetBoost or {}
    State.PetBoost.Enabled = (State.PetBoost.Enabled ~= nil) and State.PetBoost.Enabled or false

    if type(State.PetBoost.SelectedPets) ~= "table" then
        local prev = State.PetBoost.SelectedPet or "All Equipped Pets"
        State.PetBoost.SelectedPets = { [prev] = true }
    end

    if type(State.PetBoost.SelectedBoostItems) ~= "table" then
        local prev = State.PetBoost.SelectedBoostItem or "All Toys & Boosts"
        State.PetBoost.SelectedBoostItems = { [prev] = true }
    end

    -- [3] HELPER DETEKSI FARM & PET AREA UNTUK PENEMPATAN ULANG (PLACE)
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

    -- [4] HELPER PEMBERSIH NAMA PET
    local function cleanPetName(rawName)
        if type(rawName) ~= "string" then return "Unknown" end
        local s = rawName
        s = s:gsub("%s*%[[^%]]*%]", "") -- buang tag [15.2 KG], [Age 10]
        s = s:gsub("%s*%[[^%]]*$", "")
        s = s:gsub("%s*%([^%)]*%)", "")
        s = s:gsub("^[hH][uU][gG][eE]%s+", "")
        s = s:gsub("^GIANT%s+", "")
        s = s:gsub("^%s+", ""):gsub("%s+$", "")
        return s
    end

    -- [5] GET ALL EQUIPPED PETS IN GARDEN (DENGAN UUID & TOOL)
    local function GetEquippedGardenPets()
        local equipped = {}
        local seenUUID = {}

        -- 1. DataService
        pcall(function()
            local DataService = require(ReplicatedStorage:WaitForChild("Modules", 2):WaitForChild("DataService", 2))
            local data = DataService and DataService:GetData()
            if data and data.PetsData then
                local eqList = data.PetsData.EquippedPets or {}
                local inv = data.PetsData.PetInventory and data.PetsData.PetInventory.Data or {}
                for _, uuid in ipairs(eqList) do
                    local pData = inv[uuid]
                    if pData and not seenUUID[uuid] then
                        seenUUID[uuid] = true
                        local species = cleanPetName(pData.PetType or pData.Species or pData.Name or "Pet")
                        table.insert(equipped, {
                            UUID = tostring(uuid),
                            Species = species,
                            Name = species
                        })
                    end
                end
            end
        end)

        -- 2. Character & Backpack
        local containers = { LocalPlayer.Character, LocalPlayer:FindFirstChild("Backpack") }
        for _, container in ipairs(containers) do
            if container then
                for _, item in ipairs(container:GetChildren()) do
                    if item:IsA("Tool") then
                        local uuidAttr = item:GetAttribute("UUID") 
                                      or item:GetAttribute("PET_UUID") 
                                      or item:GetAttribute("PetUUID") 
                                      or item:GetAttribute("petId") 
                                      or item:GetAttribute("Id")
                                      or (item:FindFirstChild("PET_UUID") and item.PET_UUID.Value)
                        local speciesAttr = item:GetAttribute("Species") or item:GetAttribute("PetType")
                        local isPet = item:FindFirstChild("PetToolLocal") or item:FindFirstChild("PetData") or item:GetAttribute("PET_UUID") ~= nil or speciesAttr ~= nil

                        if isPet and uuidAttr then
                            local uStr = tostring(uuidAttr)
                            local spName = speciesAttr or cleanPetName(item.Name)
                            local found = false
                            for _, p in ipairs(equipped) do
                                if p.UUID == uStr or p.UUID:gsub("[{}]", "") == uStr:gsub("[{}]", "") then
                                    p.Tool = item
                                    found = true
                                    break
                                end
                            end
                            if not found and not seenUUID[uStr] and container == LocalPlayer.Character then
                                seenUUID[uStr] = true
                                table.insert(equipped, {
                                    UUID = uStr,
                                    Species = spName,
                                    Name = spName,
                                    Tool = item
                                })
                            end
                        end
                    end
                end
            end
        end

        return equipped
    end

    -- [6] HELPER MENCARI TOOL PET DI BACKPACK BERDASARKAN UUID / SPESIES (DENGAN DUKUNGAN SEMUA ATRIBUT)
    local function FindPetToolInBackpack(uuid, species)
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if not bp then return nil end

        local cleanUUID = uuid and tostring(uuid):gsub("[{}]", ""):lower() or nil
        local targetClean = species and cleanPetName(species):lower() or nil

        -- Prioritas 1: Berdasarkan PET_UUID / UUID
        if cleanUUID then
            for _, tool in ipairs(bp:GetChildren()) do
                if tool:IsA("Tool") then
                    local u = tool:GetAttribute("PET_UUID") 
                           or tool:GetAttribute("UUID") 
                           or tool:GetAttribute("PetUUID") 
                           or tool:GetAttribute("petId") 
                           or tool:GetAttribute("Id")
                           or (tool:FindFirstChild("PET_UUID") and tool.PET_UUID.Value)
                    if u and tostring(u):gsub("[{}]", ""):lower() == cleanUUID then
                        return tool
                    end
                end
            end
        end

        -- Prioritas 2: Berdasarkan nama spesies
        if targetClean then
            for _, tool in ipairs(bp:GetChildren()) do
                if tool:IsA("Tool") then
                    local isPet = tool:FindFirstChild("PetToolLocal") 
                               or tool:FindFirstChild("PetData") 
                               or tool:GetAttribute("PET_UUID") ~= nil
                               or tool:GetAttribute("Species") ~= nil
                    if isPet then
                        local tClean = cleanPetName(tool.Name):lower()
                        if tClean == targetClean or tClean:find(targetClean, 1, true) or targetClean:find(tClean, 1, true) then
                            return tool
                        end
                    end
                end
            end
        end

        return nil
    end

    -- [7] HELPER DETEKSI ITEM BOOST / TOY DI BACKPACK
    local function GetOwnedBoostTools()
        local boostTools = {}
        local bp = LocalPlayer:FindFirstChild("Backpack")
        local ch = LocalPlayer.Character
        local containers = { bp, ch }

        for _, container in ipairs(containers) do
            if container then
                for _, item in ipairs(container:GetChildren()) do
                    if item:IsA("Tool") then
                        local isBoost = item:HasTag("PetBoost") 
                                     or item:GetAttribute("PetBoostType") ~= nil
                                     or item.Name:find("Toy") 
                                     or item.Name:find("Treat") 
                                     or item.Name:find("Chew") 
                                     or item.Name:find("Lollipop")
                                     or item.Name:find("Passive Boost")
                                     or item.Name:find("XP Boost")

                        if isBoost then
                            local bType = item:GetAttribute("PetBoostType") or "OTHER"
                            local cleanTitle = item.Name:gsub("%[.-%]", ""):gsub("^%s*(.-)%s*$", "%1")
                            table.insert(boostTools, {
                                Tool = item,
                                Name = item.Name,
                                CleanName = cleanTitle,
                                BoostType = bType
                            })
                        end
                    end
                end
            end
        end
        return boostTools
    end

    -- [8] HELPER VALIDASI MULTI-SELEKSI
    local function IsPetSelectedForPNP(species)
        local sel = State.PNP.SelectedPets or {}
        if sel["All Equipped Pets"] then return true end
        local clean = cleanPetName(species):lower()
        for sName, isAct in pairs(sel) do
            if isAct and (sName:lower() == clean or clean:find(sName:lower(), 1, true) or sName:lower():find(clean, 1, true)) then
                return true
            end
        end
        return false
    end

    local function IsPetSelectedForBoost(species)
        local sel = State.PetBoost.SelectedPets or {}
        if sel["All Equipped Pets"] then return true end
        local clean = cleanPetName(species):lower()
        for sName, isAct in pairs(sel) do
            if isAct and (sName:lower() == clean or clean:find(sName:lower(), 1, true) or sName:lower():find(clean, 1, true)) then
                return true
            end
        end
        return false
    end

    local function IsBoostItemSelected(itemData)
        local sel = State.PetBoost.SelectedBoostItems or {}
        if sel["All Toys & Boosts"] then return true end

        local nLower = itemData.Name:lower()
        local cLower = itemData.CleanName:lower()

        for fName, isAct in pairs(sel) do
            if isAct then
                if fName == "Pet Toys (Passive Boost)" and (nLower:find("toy") or itemData.BoostType == "PASSIVE_BOOST") then
                    return true
                elseif fName == "Pet Treats (XP Boost)" and (nLower:find("treat") or itemData.BoostType == "PET_XP_BOOST") then
                    return true
                elseif fName == "Chews (Ability Refresh)" and (nLower:find("chew") or itemData.BoostType == "ABILITY_REFRESH") then
                    return true
                elseif fName == "Lollipops (Level Boost)" and (nLower:find("lollipop") or itemData.BoostType == "LEVEL_BOOST") then
                    return true
                elseif cLower:find(fName:lower(), 1, true) or fName:lower():find(cLower, 1, true) or nLower:find(fName:lower(), 1, true) then
                    return true
                end
            end
        end
        return false
    end

    -- =====================================================================
    -- [LOGIKA 1: EKSEKUTOR FITUR PNP (PICK AND PLACE)]
    -- 100% TERJAMIN: MENUNGGU TOOL TIBA DI TAS + TRIPLE PLACE EXECUTION
    -- =====================================================================
    local isPnPBusy = {}
    local previousCooldowns = {}

    local function ExecutePickAndPlace(petUUID, petSpecies)
        if not State.PNP.Enabled or isPnPBusy[petUUID] then return end
        isPnPBusy[petUUID] = true

        task.spawn(function()
            local stripped = petUUID:gsub("[{}]", "")
            print(string.format("[ZyloHub PNP] ⚡ Pet %s (%s) skill aktif! Memulai Pick...", petSpecies or "Unknown", stripped))

            -- 1. TAHAP PICK (Ambil pet ke tas via Remote & Module)
            if PetsServiceMod and PetsServiceMod.UnequipPet then
                pcall(function() PetsServiceMod:UnequipPet(petUUID) end)
                pcall(function() PetsServiceMod:UnequipPet(stripped) end)
            end
            if PetsServiceRemote then
                pcall(function() PetsServiceRemote:FireServer("UnequipPet", petUUID) end)
                pcall(function() PetsServiceRemote:FireServer("UnequipPet", stripped) end)
                pcall(function() PetsServiceRemote:FireServer("Unequip", petUUID) end)
                pcall(function() PetsServiceRemote:FireServer("Unequip", stripped) end)
            end

            -- 2. TAHAP JEDA (Waktu jeda yang ditentukan pemain)
            local userDelay = math.max(0.05, tonumber(State.PNP.DelaySeconds) or 0.1)
            task.wait(userDelay)

            -- 3. TUNGGU TOOL MUNCUL DI TAS DENGAN LOOP RETRY (Mencegah gagal karena lag server)
            local petTool = nil
            local startWait = tick()
            while tick() - startWait < 3.0 do
                petTool = FindPetToolInBackpack(petUUID, petSpecies)
                if petTool then break end
                task.wait(0.08)
            end

            -- 4. TAHAP PLACE: KEMBALIKAN PET KE KEBUN DENGAN 3 LAPIS EKSEKUSI
            local farm = GetFarm()
            local petArea = farm and farm:FindFirstChild("PetArea")
            local targetPos = (petArea and petArea.CFrame + Vector3.new(0, 2, 0))
                or (LocalPlayer.Character and LocalPlayer.Character:GetPivot())
                or CFrame.new(0, 5, 0)

            -- Lapis 1: Remote resmi EquipPet ke CFrame kebun
            if PetsServiceRemote then
                pcall(function() PetsServiceRemote:FireServer("EquipPet", petUUID, targetPos) end)
                pcall(function() PetsServiceRemote:FireServer("EquipPet", stripped, targetPos) end)
                pcall(function() PetsServiceRemote:FireServer("Equip", petUUID, targetPos) end)
                pcall(function() PetsServiceRemote:FireServer("Equip", stripped, targetPos) end)
            end

            -- Lapis 2: Client Module PetsService
            if PetsServiceMod and PetsServiceMod.EquipPet then
                pcall(function() PetsServiceMod:EquipPet(petUUID, targetPos) end)
                pcall(function() PetsServiceMod:EquipPet(stripped, targetPos) end)
            end

            -- Lapis 3: Humanoid Equip & Tool Activate (Trigger penempatan fisik di kebun)
            if petTool and LocalPlayer.Character then
                local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid and petTool.Parent == LocalPlayer:FindFirstChild("Backpack") then
                    humanoid:EquipTool(petTool)
                    task.wait(0.1)
                    pcall(function() petTool:Activate() end)
                    pcall(function()
                        if VirtualUser then
                            VirtualUser:Button1Down(Vector2.new(0, 0))
                            task.wait(0.05)
                            VirtualUser:Button1Up(Vector2.new(0, 0))
                        end
                    end)
                    task.wait(0.1)
                    -- Jika masih tersisa di tangan karakter, kembalikan ke tas
                    if petTool.Parent == LocalPlayer.Character then
                        pcall(function() petTool.Parent = LocalPlayer:FindFirstChild("Backpack") end)
                    end
                end
            end

            print(string.format("[ZyloHub PNP] ✅ Pet %s berhasil ditaruh kembali ke kebun!", petSpecies or stripped))
            task.wait(0.3)
            isPnPBusy[petUUID] = nil
        end)
    end

    -- Listener resmi: GameEvents.PetCooldownsUpdated
    if PetCooldownsUpdated then
        PetCooldownsUpdated.OnClientEvent:Connect(function(petUUID, cooldownData)
            if not State.PNP.Enabled then return end
            if not petUUID or type(cooldownData) ~= "table" then return end

            local uStr = tostring(petUUID)
            local prev = previousCooldowns[uStr] or {}

            for _, cdInfo in ipairs(cooldownData) do
                local pName = cdInfo.Passive or "Skill"
                local curTime = tonumber(cdInfo.Time) or 0
                local oldTime = prev[pName]

                -- Jika cooldown melompat dari <= 0 (atau nil) menjadi > 0, berarti skill pasif baru saja aktif!
                if (oldTime == nil or oldTime <= 0) and curTime > 0 then
                    local gardenPets = GetEquippedGardenPets()
                    local matchedPet = nil
                    for _, gPet in ipairs(gardenPets) do
                        if gPet.UUID == uStr or gPet.UUID:gsub("[{}]", "") == uStr:gsub("[{}]", "") then
                            matchedPet = gPet
                            break
                        end
                    end

                    local speciesName = matchedPet and matchedPet.Species or pName
                    if IsPetSelectedForPNP(speciesName) then
                        ExecutePickAndPlace(uStr, speciesName)
                    end
                end

                prev[pName] = curTime
            end
            previousCooldowns[uStr] = prev
        end)
    end

    -- =====================================================================
    -- [LOGIKA 2: EKSEKUTOR FITUR AUTO PET BOOST & TOYS]
    -- MENDUKUNG MULTI-SELEKSI PET TARGET & MULTI-SELEKSI ITEM BOOST
    -- =====================================================================
    local isApplyingBoost = false
    local function ExecuteAutoPetBoost()
        if isApplyingBoost or not State.PetBoost.Enabled or not PetBoostService then return end

        local allGardenPets = GetEquippedGardenPets()
        if #allGardenPets == 0 then return end

        -- Saring pet berdasarkan multi-select pengguna
        local targetPets = {}
        for _, p in ipairs(allGardenPets) do
            if IsPetSelectedForBoost(p.Species) then
                table.insert(targetPets, p)
            end
        end
        if #targetPets == 0 then return end

        local boostItems = GetOwnedBoostTools()
        if #boostItems == 0 then return end

        -- Saring item boost berdasarkan multi-select pengguna
        local validBoostTools = {}
        for _, bItem in ipairs(boostItems) do
            if IsBoostItemSelected(bItem) then
                table.insert(validBoostTools, bItem)
            end
        end
        if #validBoostTools == 0 then return end

        isApplyingBoost = true
        task.spawn(function()
            local char = LocalPlayer.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")

            for _, bItem in ipairs(validBoostTools) do
                if not State.PetBoost.Enabled then break end
                local boostTool = bItem.Tool

                if humanoid and boostTool and boostTool.Parent then
                    -- 1. Pegang alat boost di tangan
                    if boostTool.Parent == LocalPlayer:FindFirstChild("Backpack") then
                        humanoid:EquipTool(boostTool)
                        task.wait(0.12)
                    end

                    -- 2. Tembakkan Remote PetBoostService untuk setiap pet target terpilih
                    for _, targetPet in ipairs(targetPets) do
                        if not State.PetBoost.Enabled then break end
                        PetBoostService:FireServer("ApplyBoost", targetPet.UUID)
                        print(string.format("[ZyloHub Boost] 🍖 Memberikan %s ke Pet %s!", bItem.CleanName, targetPet.Species))
                        task.wait(0.2)
                    end

                    -- 3. Kembalikan tool ke tas pemain
                    if boostTool.Parent == char then
                        pcall(function() boostTool.Parent = LocalPlayer:FindFirstChild("Backpack") end)
                    end
                    task.wait(0.1)
                end
            end

            task.wait(2.0)
            isApplyingBoost = false
        end)
    end

    -- Background loop untuk Auto Pet Boost
    task.spawn(function()
        while true do
            task.wait(2.5)
            if State.PetBoost.Enabled then
                pcall(ExecuteAutoPetBoost)
            end
        end
    end)

    -- =====================================================================
    -- [BAGIAN 3: MEMBANGUN UI CONTAINER]
    -- =====================================================================
    local SkillContainer = Instance.new("Frame")
    SkillContainer.Name = "PetSkillContainer"
    SkillContainer.Size = UDim2.new(1, 0, 0, 0)
    SkillContainer.AutomaticSize = Enum.AutomaticSize.Y
    SkillContainer.BackgroundTransparency = 1
    SkillContainer.Parent = ParentContainer

    local ListLayout = Instance.new("UIListLayout", SkillContainer)
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Padding = UDim.new(0, 10)

    -- [CARD 1: PNP PICK AND PLACE]
    local CardPNP = Instance.new("Frame", SkillContainer)
    CardPNP.Name = "CardPNP"
    CardPNP.Size = UDim2.new(1, 0, 0, 0)
    CardPNP.AutomaticSize = Enum.AutomaticSize.Y
    CardPNP.BackgroundColor3 = C.CARD
    CardPNP.BorderSizePixel = 0
    CardPNP.LayoutOrder = 1
    Instance.new("UICorner", CardPNP).CornerRadius = UDim.new(0, 8)
    local pnpStroke = Instance.new("UIStroke", CardPNP)
    pnpStroke.Color = C.STROKE

    local pnpPad = Instance.new("UIPadding", CardPNP)
    pnpPad.PaddingTop = UDim.new(0, 10)
    pnpPad.PaddingBottom = UDim.new(0, 10)
    pnpPad.PaddingLeft = UDim.new(0, 12)
    pnpPad.PaddingRight = UDim.new(0, 12)

    local pnpList = Instance.new("UIListLayout", CardPNP)
    pnpList.SortOrder = Enum.SortOrder.LayoutOrder
    pnpList.Padding = UDim.new(0, 8)

    local headerPNP = Instance.new("Frame", CardPNP)
    headerPNP.Size = UDim2.new(1, 0, 0, 24)
    headerPNP.BackgroundTransparency = 1
    headerPNP.LayoutOrder = 1

    local pnpTitle = Instance.new("TextLabel", headerPNP)
    pnpTitle.Size = UDim2.new(0.7, 0, 1, 0)
    pnpTitle.BackgroundTransparency = 1
    pnpTitle.Text = "⚡  PNP (Pick And Place) - Skill Refresh"
    pnpTitle.TextColor3 = C.PURPLE_L
    pnpTitle.Font = Enum.Font.GothamBold
    pnpTitle.TextSize = 10.5
    pnpTitle.TextXAlignment = Enum.TextXAlignment.Left

    local pnpToggle = ZyloLib:CreatePillSwitch(headerPNP, State.PNP.Enabled, function(v)
        State.PNP.Enabled = v
        print("[ZyloHub PNP] Status Toggle PNP:", v and "AKTIF" or "NON-AKTIF")
    end)
    pnpToggle.Position = UDim2.new(1, -38, 0.5, -9)

    local pnpDesc = Instance.new("TextLabel", CardPNP)
    pnpDesc.Size = UDim2.new(1, 0, 0, 26)
    pnpDesc.BackgroundTransparency = 1
    pnpDesc.Text = "Setiap pet yang selesai menggunakan skill pasif otomatis langsung diambil ke tas dan ditaruh kembali ke kebun secara instan."
    pnpDesc.TextColor3 = C.TEXT_M
    pnpDesc.Font = Enum.Font.Gotham
    pnpDesc.TextSize = 8.5
    pnpDesc.TextWrapped = true
    pnpDesc.TextXAlignment = Enum.TextXAlignment.Left
    pnpDesc.LayoutOrder = 2

    local rowPetPNP = Instance.new("Frame", CardPNP)
    rowPetPNP.Size = UDim2.new(1, 0, 0, 32)
    rowPetPNP.BackgroundColor3 = C.CARD_2
    rowPetPNP.BorderSizePixel = 0
    rowPetPNP.LayoutOrder = 3
    Instance.new("UICorner", rowPetPNP).CornerRadius = UDim.new(0, 6)

    local lblPetPNP = Instance.new("TextLabel", rowPetPNP)
    lblPetPNP.Position = UDim2.new(0, 10, 0, 0)
    lblPetPNP.Size = UDim2.new(0.45, 0, 1, 0)
    lblPetPNP.BackgroundTransparency = 1
    lblPetPNP.Text = "Target Pet PNP"
    lblPetPNP.TextColor3 = C.TEXT_W
    lblPetPNP.Font = Enum.Font.GothamBold
    lblPetPNP.TextSize = 9.5
    lblPetPNP.TextXAlignment = Enum.TextXAlignment.Left

    local btnPetPNP = Instance.new("TextButton", rowPetPNP)
    btnPetPNP.Position = UDim2.new(1, -165, 0.5, -12)
    btnPetPNP.Size = UDim2.new(0, 155, 0, 24)
    btnPetPNP.BackgroundColor3 = Color3.fromRGB(12, 16, 32)
    btnPetPNP.Text = "All Equipped Pets  v"
    btnPetPNP.TextColor3 = Color3.fromRGB(195, 205, 235)
    btnPetPNP.Font = Enum.Font.GothamBold
    btnPetPNP.TextSize = 8.5
    Instance.new("UICorner", btnPetPNP).CornerRadius = UDim.new(0, 5)
    local bStroke1 = Instance.new("UIStroke", btnPetPNP)
    bStroke1.Color = Color3.fromRGB(45, 55, 85)

    local rowDelayPNP = Instance.new("Frame", CardPNP)
    rowDelayPNP.Size = UDim2.new(1, 0, 0, 32)
    rowDelayPNP.BackgroundColor3 = C.CARD_2
    rowDelayPNP.BorderSizePixel = 0
    rowDelayPNP.LayoutOrder = 4
    Instance.new("UICorner", rowDelayPNP).CornerRadius = UDim.new(0, 6)

    local lblDelayPNP = Instance.new("TextLabel", rowDelayPNP)
    lblDelayPNP.Position = UDim2.new(0, 10, 0, 0)
    lblDelayPNP.Size = UDim2.new(0.55, 0, 1, 0)
    lblDelayPNP.BackgroundTransparency = 1
    lblDelayPNP.Text = "Jeda Pick & Place (Detik)"
    lblDelayPNP.TextColor3 = C.TEXT_W
    lblDelayPNP.Font = Enum.Font.GothamBold
    lblDelayPNP.TextSize = 9.5
    lblDelayPNP.TextXAlignment = Enum.TextXAlignment.Left

    local boxDelayPNP = Instance.new("TextBox", rowDelayPNP)
    boxDelayPNP.Position = UDim2.new(1, -75, 0.5, -12)
    boxDelayPNP.Size = UDim2.new(0, 65, 0, 24)
    boxDelayPNP.BackgroundColor3 = Color3.fromRGB(12, 16, 32)
    boxDelayPNP.Text = tostring(State.PNP.DelaySeconds or 0.1)
    boxDelayPNP.TextColor3 = C.CYAN
    boxDelayPNP.Font = Enum.Font.GothamBold
    boxDelayPNP.TextSize = 9.5
    Instance.new("UICorner", boxDelayPNP).CornerRadius = UDim.new(0, 5)
    local bStroke2 = Instance.new("UIStroke", boxDelayPNP)
    bStroke2.Color = Color3.fromRGB(45, 55, 85)

    boxDelayPNP:GetPropertyChangedSignal("Text"):Connect(function()
        local val = tonumber(boxDelayPNP.Text)
        if val and val >= 0.05 then
            State.PNP.DelaySeconds = val
        end
    end)

    -- [CARD 2: AUTO PET BOOST & TOYS]
    local CardBoost = Instance.new("Frame", SkillContainer)
    CardBoost.Name = "CardBoost"
    CardBoost.Size = UDim2.new(1, 0, 0, 0)
    CardBoost.AutomaticSize = Enum.AutomaticSize.Y
    CardBoost.BackgroundColor3 = C.CARD
    CardBoost.BorderSizePixel = 0
    CardBoost.LayoutOrder = 2
    Instance.new("UICorner", CardBoost).CornerRadius = UDim.new(0, 8)
    local boostStroke = Instance.new("UIStroke", CardBoost)
    boostStroke.Color = C.STROKE

    local boostPad = Instance.new("UIPadding", CardBoost)
    boostPad.PaddingTop = UDim.new(0, 10)
    boostPad.PaddingBottom = UDim.new(0, 10)
    boostPad.PaddingLeft = UDim.new(0, 12)
    boostPad.PaddingRight = UDim.new(0, 12)

    local boostList = Instance.new("UIListLayout", CardBoost)
    boostList.SortOrder = Enum.SortOrder.LayoutOrder
    boostList.Padding = UDim.new(0, 8)

    local headerBoost = Instance.new("Frame", CardBoost)
    headerBoost.Size = UDim2.new(1, 0, 0, 24)
    headerBoost.BackgroundTransparency = 1
    headerBoost.LayoutOrder = 1

    local boostTitle = Instance.new("TextLabel", headerBoost)
    boostTitle.Size = UDim2.new(0.7, 0, 1, 0)
    boostTitle.BackgroundTransparency = 1
    boostTitle.Text = "🍖  Auto Pet Boost & Toys"
    boostTitle.TextColor3 = C.CYAN
    boostTitle.Font = Enum.Font.GothamBold
    boostTitle.TextSize = 10.5
    boostTitle.TextXAlignment = Enum.TextXAlignment.Left

    local boostToggle = ZyloLib:CreatePillSwitch(headerBoost, State.PetBoost.Enabled, function(v)
        State.PetBoost.Enabled = v
        print("[ZyloHub Boost] Status Toggle Auto Boost:", v and "AKTIF" or "NON-AKTIF")
        if v then task.spawn(ExecuteAutoPetBoost) end
    end)
    boostToggle.Position = UDim2.new(1, -38, 0.5, -9)

    local boostDesc = Instance.new("TextLabel", CardBoost)
    boostDesc.Size = UDim2.new(1, 0, 0, 26)
    boostDesc.BackgroundTransparency = 1
    boostDesc.Text = "Otomatis menggunakan item Toy, XP Potion, dan Boost lainnya secara berkala ke pet yang dipilih."
    boostDesc.TextColor3 = C.TEXT_M
    boostDesc.Font = Enum.Font.Gotham
    boostDesc.TextSize = 8.5
    boostDesc.TextWrapped = true
    boostDesc.TextXAlignment = Enum.TextXAlignment.Left
    boostDesc.LayoutOrder = 2

    local rowPetBoost = Instance.new("Frame", CardBoost)
    rowPetBoost.Size = UDim2.new(1, 0, 0, 32)
    rowPetBoost.BackgroundColor3 = C.CARD_2
    rowPetBoost.BorderSizePixel = 0
    rowPetBoost.LayoutOrder = 3
    Instance.new("UICorner", rowPetBoost).CornerRadius = UDim.new(0, 6)

    local lblPetBoost = Instance.new("TextLabel", rowPetBoost)
    lblPetBoost.Position = UDim2.new(0, 10, 0, 0)
    lblPetBoost.Size = UDim2.new(0.45, 0, 1, 0)
    lblPetBoost.BackgroundTransparency = 1
    lblPetBoost.Text = "Target Pet"
    lblPetBoost.TextColor3 = C.TEXT_W
    lblPetBoost.Font = Enum.Font.GothamBold
    lblPetBoost.TextSize = 9.5
    lblPetBoost.TextXAlignment = Enum.TextXAlignment.Left

    local btnPetBoost = Instance.new("TextButton", rowPetBoost)
    btnPetBoost.Position = UDim2.new(1, -165, 0.5, -12)
    btnPetBoost.Size = UDim2.new(0, 155, 0, 24)
    btnPetBoost.BackgroundColor3 = Color3.fromRGB(12, 16, 32)
    btnPetBoost.Text = "All Equipped Pets  v"
    btnPetBoost.TextColor3 = Color3.fromRGB(195, 205, 235)
    btnPetBoost.Font = Enum.Font.GothamBold
    btnPetBoost.TextSize = 8.5
    Instance.new("UICorner", btnPetBoost).CornerRadius = UDim.new(0, 5)
    local bStroke3 = Instance.new("UIStroke", btnPetBoost)
    bStroke3.Color = Color3.fromRGB(45, 55, 85)

    local rowItemBoost = Instance.new("Frame", CardBoost)
    rowItemBoost.Size = UDim2.new(1, 0, 0, 32)
    rowItemBoost.BackgroundColor3 = C.CARD_2
    rowItemBoost.BorderSizePixel = 0
    rowItemBoost.LayoutOrder = 4
    Instance.new("UICorner", rowItemBoost).CornerRadius = UDim.new(0, 6)

    local lblItemBoost = Instance.new("TextLabel", rowItemBoost)
    lblItemBoost.Position = UDim2.new(0, 10, 0, 0)
    lblItemBoost.Size = UDim2.new(0.45, 0, 1, 0)
    lblItemBoost.BackgroundTransparency = 1
    lblItemBoost.Text = "Item Toy / Boost"
    lblItemBoost.TextColor3 = C.TEXT_W
    lblItemBoost.Font = Enum.Font.GothamBold
    lblItemBoost.TextSize = 9.5
    lblItemBoost.TextXAlignment = Enum.TextXAlignment.Left

    local btnItemBoost = Instance.new("TextButton", rowItemBoost)
    btnItemBoost.Position = UDim2.new(1, -165, 0.5, -12)
    btnItemBoost.Size = UDim2.new(0, 155, 0, 24)
    btnItemBoost.BackgroundColor3 = Color3.fromRGB(12, 16, 32)
    btnItemBoost.Text = "All Toys & Boosts  v"
    btnItemBoost.TextColor3 = Color3.fromRGB(195, 205, 235)
    btnItemBoost.Font = Enum.Font.GothamBold
    btnItemBoost.TextSize = 8.5
    Instance.new("UICorner", btnItemBoost).CornerRadius = UDim.new(0, 5)
    local bStroke4 = Instance.new("UIStroke", btnItemBoost)
    bStroke4.Color = Color3.fromRGB(45, 55, 85)

    -- [8] HELPER UPDATE LABEL TOMBOL DARI STATE MULTI-SELECT
    local function UpdateButtonLabels()
        -- 1. Tombol Pet PNP
        local pnpSel = State.PNP.SelectedPets or {}
        if pnpSel["All Equipped Pets"] then
            btnPetPNP.Text = "All Equipped Pets  v"
        else
            local list = {}
            for name, isAct in pairs(pnpSel) do
                if isAct then table.insert(list, name) end
            end
            if #list == 0 then
                btnPetPNP.Text = "None Selected  v"
            elseif #list == 1 then
                btnPetPNP.Text = list[1] .. "  v"
            else
                btnPetPNP.Text = string.format("%d Pets Selected  v", #list)
            end
        end

        -- 2. Tombol Pet Boost
        local boostSel = State.PetBoost.SelectedPets or {}
        if boostSel["All Equipped Pets"] then
            btnPetBoost.Text = "All Equipped Pets  v"
        else
            local list = {}
            for name, isAct in pairs(boostSel) do
                if isAct then table.insert(list, name) end
            end
            if #list == 0 then
                btnPetBoost.Text = "None Selected  v"
            elseif #list == 1 then
                btnPetBoost.Text = list[1] .. "  v"
            else
                btnPetBoost.Text = string.format("%d Pets Selected  v", #list)
            end
        end

        -- 3. Tombol Boost Items
        local itemSel = State.PetBoost.SelectedBoostItems or {}
        if itemSel["All Toys & Boosts"] then
            btnItemBoost.Text = "All Toys & Boosts  v"
        else
            local list = {}
            for name, isAct in pairs(itemSel) do
                if isAct then table.insert(list, name) end
            end
            if #list == 0 then
                btnItemBoost.Text = "None Selected  v"
            elseif #list == 1 then
                btnItemBoost.Text = list[1] .. "  v"
            else
                btnItemBoost.Text = string.format("%d Items Selected  v", #list)
            end
        end
    end

    UpdateButtonLabels()

    -- =====================================================================
    -- [BAGIAN 4: MODAL POPUP MULTI-SELEKSI DENGAN CHECKBOX & SEARCH]
    -- =====================================================================
    local ModalFrame = Instance.new("Frame", MainScreen or ParentContainer)
    ModalFrame.Size = UDim2.new(0, 270, 0, 310)
    ModalFrame.Position = UDim2.new(0.5, -135, 0.5, -155)
    ModalFrame.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
    ModalFrame.Visible = false
    ModalFrame.ZIndex = 100
    Instance.new("UICorner", ModalFrame).CornerRadius = UDim.new(0, 8)
    local mStroke = Instance.new("UIStroke", ModalFrame)
    mStroke.Color = C.PURPLE_L
    mStroke.Thickness = 1.5

    local mHeader = Instance.new("Frame", ModalFrame)
    mHeader.Size = UDim2.new(1, 0, 0, 32)
    mHeader.BackgroundTransparency = 1
    mHeader.ZIndex = 101

    local mTitle = Instance.new("TextLabel", mHeader)
    mTitle.Position = UDim2.new(0, 12, 0, 0)
    mTitle.Size = UDim2.new(1, -40, 1, 0)
    mTitle.BackgroundTransparency = 1
    mTitle.Text = "Select Target (Multi-Select)"
    mTitle.TextColor3 = Color3.fromRGB(245, 247, 255)
    mTitle.Font = Enum.Font.GothamBold
    mTitle.TextSize = 9.5
    mTitle.TextXAlignment = Enum.TextXAlignment.Left
    mTitle.ZIndex = 101

    local mClose = Instance.new("TextButton", mHeader)
    mClose.Position = UDim2.new(1, -28, 0, 6)
    mClose.Size = UDim2.new(0, 20, 0, 20)
    mClose.BackgroundColor3 = Color3.fromRGB(24, 28, 48)
    mClose.Text = "✕"
    mClose.TextColor3 = Color3.fromRGB(255, 120, 120)
    mClose.Font = Enum.Font.GothamBold
    mClose.TextSize = 9
    mClose.ZIndex = 102
    Instance.new("UICorner", mClose).CornerRadius = UDim.new(0, 4)
    mClose.MouseButton1Click:Connect(function()
        UpdateButtonLabels()
        ModalFrame.Visible = false
    end)

    local mSearch = Instance.new("TextBox", ModalFrame)
    mSearch.Position = UDim2.new(0, 10, 0, 36)
    mSearch.Size = UDim2.new(1, -20, 0, 24)
    mSearch.BackgroundColor3 = Color3.fromRGB(16, 21, 42)
    mSearch.PlaceholderText = "Search item or pet..."
    mSearch.PlaceholderColor3 = Color3.fromRGB(110, 120, 150)
    mSearch.Text = ""
    mSearch.TextColor3 = C.TEXT_W
    mSearch.Font = Enum.Font.Gotham
    mSearch.TextSize = 9
    mSearch.ClearTextOnFocus = false
    mSearch.ZIndex = 101
    Instance.new("UICorner", mSearch).CornerRadius = UDim.new(0, 5)
    local mSearchPad = Instance.new("UIPadding", mSearch)
    mSearchPad.PaddingLeft = UDim.new(0, 8)

    local mScroll = Instance.new("ScrollingFrame", ModalFrame)
    mScroll.Position = UDim2.new(0, 10, 0, 66)
    mScroll.Size = UDim2.new(1, -20, 1, -106)
    mScroll.BackgroundTransparency = 1
    mScroll.ScrollBarThickness = 3
    mScroll.ScrollBarImageColor3 = C.PURPLE
    mScroll.ZIndex = 101

    local mLayout = Instance.new("UIListLayout", mScroll)
    mLayout.Padding = UDim.new(0, 4)

    -- Bottom Bar: Tombol Selesai (Done)
    local mBottom = Instance.new("Frame", ModalFrame)
    mBottom.Position = UDim2.new(0, 10, 1, -34)
    mBottom.Size = UDim2.new(1, -20, 0, 26)
    mBottom.BackgroundTransparency = 1
    mBottom.ZIndex = 101

    local btnDone = Instance.new("TextButton", mBottom)
    btnDone.Size = UDim2.new(1, 0, 1, 0)
    btnDone.BackgroundColor3 = C.PURPLE
    btnDone.Text = "✓  Selesai Memilih"
    btnDone.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnDone.Font = Enum.Font.GothamBold
    btnDone.TextSize = 9.5
    btnDone.ZIndex = 102
    Instance.new("UICorner", btnDone).CornerRadius = UDim.new(0, 5)
    btnDone.MouseButton1Click:Connect(function()
        UpdateButtonLabels()
        ModalFrame.Visible = false
    end)

    local currentModalMode = "PNP_PET"

    local function populateModalOptions()
        for _, c in ipairs(mScroll:GetChildren()) do
            if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
        end

        local filter = mSearch.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
        local options = {}
        local selectedTable = nil

        if currentModalMode == "PNP_PET" then
            mTitle.Text = "Select Pets for PNP"
            table.insert(options, "All Equipped Pets")
            selectedTable = State.PNP.SelectedPets

            local gPets = GetEquippedGardenPets()
            local seen = {}
            for _, p in ipairs(gPets) do
                if not seen[p.Species] then
                    seen[p.Species] = true
                    table.insert(options, p.Species)
                end
            end
        elseif currentModalMode == "BOOST_PET" then
            mTitle.Text = "Select Pets for Auto Boost"
            table.insert(options, "All Equipped Pets")
            selectedTable = State.PetBoost.SelectedPets

            local gPets = GetEquippedGardenPets()
            local seen = {}
            for _, p in ipairs(gPets) do
                if not seen[p.Species] then
                    seen[p.Species] = true
                    table.insert(options, p.Species)
                end
            end
        elseif currentModalMode == "BOOST_ITEM" then
            mTitle.Text = "Select Toys & Boost Items"
            table.insert(options, "All Toys & Boosts")
            table.insert(options, "Pet Toys (Passive Boost)")
            table.insert(options, "Pet Treats (XP Boost)")
            table.insert(options, "Chews (Ability Refresh)")
            table.insert(options, "Lollipops (Level Boost)")
            selectedTable = State.PetBoost.SelectedBoostItems

            local boostItems = GetOwnedBoostTools()
            local seen = {}
            for _, b in ipairs(boostItems) do
                if not seen[b.CleanName] then
                    seen[b.CleanName] = true
                    table.insert(options, b.CleanName)
                end
            end
        end

        local count = 0
        for _, opt in ipairs(options) do
            if filter == "" or opt:lower():find(filter, 1, true) then
                count = count + 1
                local isChecked = (selectedTable and selectedTable[opt] == true)

                local btn = Instance.new("TextButton", mScroll)
                btn.Size = UDim2.new(1, -4, 0, 26)
                btn.BackgroundColor3 = isChecked and Color3.fromRGB(36, 18, 58) or Color3.fromRGB(16, 21, 42)
                btn.Text = (isChecked and "  [✓] " or "  [  ] ") .. opt
                btn.TextColor3 = isChecked and C.PURPLE_L or Color3.fromRGB(240, 245, 255)
                btn.Font = Enum.Font.GothamBold
                btn.TextSize = 8.5
                btn.TextXAlignment = Enum.TextXAlignment.Left
                btn.ZIndex = 102
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
                local bSt = Instance.new("UIStroke", btn)
                bSt.Color = isChecked and C.PURPLE or Color3.fromRGB(35, 42, 70)
                bSt.Thickness = isChecked and 1.2 or 1

                btn.MouseButton1Click:Connect(function()
                    if opt == "All Equipped Pets" or opt == "All Toys & Boosts" then
                        -- Jika opsi "All" dipilih, bersihkan opsi individual
                        table.clear(selectedTable)
                        selectedTable[opt] = true
                    else
                        -- Jika opsi individual dipilih, lepas centang opsi "All"
                        selectedTable["All Equipped Pets"] = nil
                        selectedTable["All Toys & Boosts"] = nil

                        if selectedTable[opt] then
                            selectedTable[opt] = nil
                        else
                            selectedTable[opt] = true
                        end

                        -- Jika tidak ada yang dicentang, kembalikan ke "All"
                        local anySelected = false
                        for _, v in pairs(selectedTable) do
                            if v == true then anySelected = true break end
                        end
                        if not anySelected then
                            if currentModalMode == "BOOST_ITEM" then
                                selectedTable["All Toys & Boosts"] = true
                            else
                                selectedTable["All Equipped Pets"] = true
                            end
                        end
                    end

                    populateModalOptions()
                    UpdateButtonLabels()
                end)
            end
        end

        mScroll.CanvasSize = UDim2.new(0, 0, 0, count * 30 + 6)
    end

    mSearch:GetPropertyChangedSignal("Text"):Connect(populateModalOptions)

    btnPetPNP.MouseButton1Click:Connect(function()
        currentModalMode = "PNP_PET"
        mSearch.Text = ""
        populateModalOptions()
        ModalFrame.Visible = true
    end)

    btnPetBoost.MouseButton1Click:Connect(function()
        currentModalMode = "BOOST_PET"
        mSearch.Text = ""
        populateModalOptions()
        ModalFrame.Visible = true
    end)

    btnItemBoost.MouseButton1Click:Connect(function()
        currentModalMode = "BOOST_ITEM"
        mSearch.Text = ""
        populateModalOptions()
        ModalFrame.Visible = true
    end)

    return {
        Container = SkillContainer,
        ExecutePickAndPlace = ExecutePickAndPlace,
        ExecuteAutoPetBoost = ExecuteAutoPetBoost
    }
end

return PetSkillModule
