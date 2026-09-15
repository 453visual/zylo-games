-- =========================================================================
--  ZYLOHUB - PET SKILL MODULE (PNP & AUTO PET BOOST)
--  Theme: Deep Obsidian Black (#070912) & Cosmic Purple (#8A2BE2)
--  STATUS: 100% PRECISE LOGIC & PRESERVED DATASET INTEGRATION
--  BASED ON OFFICIAL GAME DECOMPILE: ActivePetsUIController & PetBoostLocalScript
-- =========================================================================

local PetSkillModule = {}

function PetSkillModule.Init(ParentContainer, State, ZyloLib, MainScreen)
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

    -- Inisialisasi State Khusus Pet Skill
    State.PNP = State.PNP or {
        Enabled = false,
        SelectedPet = "All Equipped Pets",
        DelaySeconds = 0.5,
    }

    State.PetBoost = State.PetBoost or {
        Enabled = false,
        SelectedPet = "All Equipped Pets",
        SelectedBoostItem = "All Toys & Boosts",
    }

    -- [2] HELPER PEMBERSIH NAMA PET
    local function cleanPetName(rawName)
        if type(rawName) ~= "string" then return "Unknown" end
        local s = rawName
        s = s:gsub("%s*%[[^%]]*%]", "") -- buang tag ukuran/level
        s = s:gsub("%s*%[[^%]]*$", "")
        s = s:gsub("%s*%([^%)]*%)", "")
        s = s:gsub("^[hH][uU][gG][eE]%s+", "")
        s = s:gsub("^GIANT%s+", "")
        s = s:gsub("^%s+", ""):gsub("%s+$", "")
        return s
    end

    -- [3] GET ALL EQUIPPED PETS IN GARDEN (DENGAN UUID & TOOL)
    local function GetEquippedGardenPets()
        local equipped = {}
        local seenUUID = {}

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

        local containers = { LocalPlayer.Character, LocalPlayer:FindFirstChild("Backpack") }
        for _, container in ipairs(containers) do
            if container then
                for _, item in ipairs(container:GetChildren()) do
                    if item:IsA("Tool") then
                        local uuidAttr = item:GetAttribute("UUID") or item:GetAttribute("PetUUID") or item:GetAttribute("petId") or item:GetAttribute("Id")
                        local speciesAttr = item:GetAttribute("Species") or item:GetAttribute("PetType")
                        local isPet = item:FindFirstChild("PetToolLocal") or item:FindFirstChild("PetData") or item:GetAttribute("PET_UUID") ~= nil or speciesAttr ~= nil

                        if isPet and uuidAttr then
                            local uStr = tostring(uuidAttr)
                            local spName = speciesAttr or cleanPetName(item.Name)
                            local found = false
                            for _, p in ipairs(equipped) do
                                if p.UUID == uStr then
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

    -- [4] HELPER MENCARI TOOL PET DI BACKPACK BERDASARKAN UUID
    local function FindPetToolInBackpack(uuid, species)
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if not bp then return nil end

        local targetClean = species and cleanPetName(species):lower() or nil

        -- Prioritas 1: Berdasarkan UUID
        if uuid then
            for _, tool in ipairs(bp:GetChildren()) do
                if tool:IsA("Tool") then
                    local u = tool:GetAttribute("UUID") or tool:GetAttribute("PetUUID") or tool:GetAttribute("petId") or tool:GetAttribute("Id")
                    if u and tostring(u) == tostring(uuid) then
                        return tool
                    end
                end
            end
        end

        -- Prioritas 2: Berdasarkan nama spesies
        if targetClean then
            for _, tool in ipairs(bp:GetChildren()) do
                if tool:IsA("Tool") then
                    local isPet = tool:FindFirstChild("PetToolLocal") or tool:FindFirstChild("PetData") or tool:GetAttribute("PET_UUID") ~= nil
                    if isPet then
                        local tClean = cleanPetName(tool.Name):lower()
                        if tClean == targetClean then
                            return tool
                        end
                    end
                end
            end
        end

        return nil
    end

    -- [5] HELPER DETEKSI ITEM BOOST / TOY DI BACKPACK
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

    -- =====================================================================
    -- [LOGIKA 1: EKSEKUTOR FITUR PNP (PICK AND PLACE)]
    -- =====================================================================
    local isPnPBusy = {}
    local previousCooldowns = {}

    local function ExecutePickAndPlace(petUUID, petSpecies)
        if not State.PNP.Enabled or isPnPBusy[petUUID] then return end
        isPnPBusy[petUUID] = true

        task.spawn(function()
            print(string.format("[ZyloHub PNP] ⚡ Pet %s (%s) menggunakan skill pasif! Memulai Pick & Place...", petSpecies or "Unknown", tostring(petUUID)))

            -- 1. PICK UP (Ambil pet ke tas)
            if PetsServiceRemote then
                PetsServiceRemote:FireServer("UnequipPet", petUUID)
                pcall(function() PetsServiceRemote:FireServer("Unequip", petUUID) end)
            end

            -- 2. JEDA (Waktu delay yang diatur pengguna)
            local delaySec = math.max(0.1, tonumber(State.PNP.DelaySeconds) or 0.5)
            task.wait(delaySec)

            -- 3. PLACE (Taruh pet kembali ke kebun secara instan via Equip)
            local petTool = FindPetToolInBackpack(petUUID, petSpecies)
            if petTool and LocalPlayer.Character then
                local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid and petTool.Parent == LocalPlayer:FindFirstChild("Backpack") then
                    humanoid:EquipTool(petTool)
                    print(string.format("[ZyloHub PNP] ✅ Pet %s berhasil ditaruh kembali ke kebun!", petSpecies or petUUID))
                end
            end

            task.wait(0.2)
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

                -- Jika cooldown melompat dari <= 0 (atau nil) menjadi > 0, berarti skill baru saja aktif!
                if (oldTime == nil or oldTime <= 0) and curTime > 0 then
                    local matchesTarget = false
                    if State.PNP.SelectedPet == "All Equipped Pets" then
                        matchesTarget = true
                    else
                        local gardenPets = GetEquippedGardenPets()
                        for _, gPet in ipairs(gardenPets) do
                            if gPet.UUID == uStr and (gPet.Species:lower() == State.PNP.SelectedPet:lower() or State.PNP.SelectedPet:lower():find(gPet.Species:lower())) then
                                matchesTarget = true
                                break
                            end
                        end
                    end

                    if matchesTarget then
                        ExecutePickAndPlace(uStr, pName)
                    end
                end

                prev[pName] = curTime
            end
            previousCooldowns[uStr] = prev
        end)
    end

    -- =====================================================================
    -- [LOGIKA 2: EKSEKUTOR FITUR AUTO PET BOOST & TOYS]
    -- =====================================================================
    local isApplyingBoost = false
    local function ExecuteAutoPetBoost()
        if isApplyingBoost or not State.PetBoost.Enabled or not PetBoostService then return end

        local targetPets = GetEquippedGardenPets()
        if #targetPets == 0 then return end

        local boostItems = GetOwnedBoostTools()
        if #boostItems == 0 then return end

        -- Saring item boost berdasarkan opsi pengguna
        local chosenToolData = nil
        local selectedFilter = State.PetBoost.SelectedBoostItem or "All Toys & Boosts"

        for _, itemData in ipairs(boostItems) do
            local nameLower = itemData.Name:lower()
            if selectedFilter == "All Toys & Boosts" then
                chosenToolData = itemData
                break
            elseif selectedFilter == "Pet Toys (Passive Boost)" and (nameLower:find("toy") or itemData.BoostType == "PASSIVE_BOOST") then
                chosenToolData = itemData
                break
            elseif selectedFilter == "Pet Treats (XP Boost)" and (nameLower:find("treat") or itemData.BoostType == "PET_XP_BOOST") then
                chosenToolData = itemData
                break
            elseif selectedFilter == "Chews (Ability Refresh)" and (nameLower:find("chew") or itemData.BoostType == "ABILITY_REFRESH") then
                chosenToolData = itemData
                break
            elseif selectedFilter == "Lollipops (Level Boost)" and (nameLower:find("lollipop") or itemData.BoostType == "LEVEL_BOOST") then
                chosenToolData = itemData
                break
            elseif itemData.CleanName:lower() == selectedFilter:lower() or nameLower:find(selectedFilter:lower()) then
                chosenToolData = itemData
                break
            end
        end

        if not chosenToolData then return end

        -- Tentukan pet mana yang akan di-boost
        local petTargetsToApply = {}
        if State.PetBoost.SelectedPet == "All Equipped Pets" then
            petTargetsToApply = targetPets
        else
            for _, p in ipairs(targetPets) do
                if p.Species:lower() == State.PetBoost.SelectedPet:lower() or State.PetBoost.SelectedPet:lower():find(p.Species:lower()) then
                    table.insert(petTargetsToApply, p)
                end
            end
        end

        if #petTargetsToApply == 0 then return end

        isApplyingBoost = true
        task.spawn(function()
            local char = LocalPlayer.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            local boostTool = chosenToolData.Tool

            if humanoid and boostTool and boostTool.Parent then
                -- 1. Pegang alat boost di tangan karakter
                if boostTool.Parent == LocalPlayer:FindFirstChild("Backpack") then
                    humanoid:EquipTool(boostTool)
                    task.wait(0.12)
                end

                -- 2. Tembakkan Remote PetBoostService untuk masing-masing pet target
                for _, targetPet in ipairs(petTargetsToApply) do
                    if not State.PetBoost.Enabled then break end
                    PetBoostService:FireServer("ApplyBoost", targetPet.UUID)
                    print(string.format("[ZyloHub Boost] 🍖 Memberikan %s ke Pet %s!", chosenToolData.CleanName, targetPet.Species))
                    task.wait(0.2)
                end

                -- 3. Kembalikan tool ke Backpack
                if boostTool.Parent == char then
                    boostTool.Parent = LocalPlayer:FindFirstChild("Backpack")
                end
            end

            task.wait(1.5)
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
    btnPetPNP.Position = UDim2.new(1, -155, 0.5, -12)
    btnPetPNP.Size = UDim2.new(0, 145, 0, 24)
    btnPetPNP.BackgroundColor3 = Color3.fromRGB(12, 16, 32)
    btnPetPNP.Text = (State.PNP.SelectedPet or "All Equipped Pets") .. "  v"
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
    boxDelayPNP.Text = tostring(State.PNP.DelaySeconds or 0.5)
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
    btnPetBoost.Position = UDim2.new(1, -155, 0.5, -12)
    btnPetBoost.Size = UDim2.new(0, 145, 0, 24)
    btnPetBoost.BackgroundColor3 = Color3.fromRGB(12, 16, 32)
    btnPetBoost.Text = (State.PetBoost.SelectedPet or "All Equipped Pets") .. "  v"
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
    btnItemBoost.Position = UDim2.new(1, -155, 0.5, -12)
    btnItemBoost.Size = UDim2.new(0, 145, 0, 24)
    btnItemBoost.BackgroundColor3 = Color3.fromRGB(12, 16, 32)
    btnItemBoost.Text = (State.PetBoost.SelectedBoostItem or "All Toys & Boosts") .. "  v"
    btnItemBoost.TextColor3 = Color3.fromRGB(195, 205, 235)
    btnItemBoost.Font = Enum.Font.GothamBold
    btnItemBoost.TextSize = 8.5
    Instance.new("UICorner", btnItemBoost).CornerRadius = UDim.new(0, 5)
    local bStroke4 = Instance.new("UIStroke", btnItemBoost)
    bStroke4.Color = Color3.fromRGB(45, 55, 85)

    -- =====================================================================
    -- [BAGIAN 4: MODAL POPUP SELEKSI PET & BOOST ITEM]
    -- =====================================================================
    local ModalFrame = Instance.new("Frame", MainScreen or ParentContainer)
    ModalFrame.Size = UDim2.new(0, 260, 0, 280)
    ModalFrame.Position = UDim2.new(0.5, -130, 0.5, -140)
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
    mTitle.Text = "Select Target"
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
    mClose.MouseButton1Click:Connect(function() ModalFrame.Visible = false end)

    local mSearch = Instance.new("TextBox", ModalFrame)
    mSearch.Position = UDim2.new(0, 10, 0, 36)
    mSearch.Size = UDim2.new(1, -20, 0, 24)
    mSearch.BackgroundColor3 = Color3.fromRGB(16, 21, 42)
    mSearch.PlaceholderText = "Search..."
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
    mScroll.Size = UDim2.new(1, -20, 1, -74)
    mScroll.BackgroundTransparency = 1
    mScroll.ScrollBarThickness = 3
    mScroll.ScrollBarImageColor3 = C.PURPLE
    mScroll.ZIndex = 101

    local mLayout = Instance.new("UIListLayout", mScroll)
    mLayout.Padding = UDim.new(0, 4)

    local currentModalMode = "PNP_PET"

    local function populateModalOptions()
        for _, c in ipairs(mScroll:GetChildren()) do
            if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
        end

        local filter = mSearch.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
        local options = {}

        if currentModalMode == "PNP_PET" or currentModalMode == "BOOST_PET" then
            mTitle.Text = (currentModalMode == "PNP_PET") and "Select Target Pet for PNP" or "Select Target Pet for Boost"
            table.insert(options, "All Equipped Pets")

            local gPets = GetEquippedGardenPets()
            local seen = {}
            for _, p in ipairs(gPets) do
                if not seen[p.Species] then
                    seen[p.Species] = true
                    table.insert(options, p.Species)
                end
            end
        elseif currentModalMode == "BOOST_ITEM" then
            mTitle.Text = "Select Toy / XP Boost Item"
            table.insert(options, "All Toys & Boosts")
            table.insert(options, "Pet Toys (Passive Boost)")
            table.insert(options, "Pet Treats (XP Boost)")
            table.insert(options, "Chews (Ability Refresh)")
            table.insert(options, "Lollipops (Level Boost)")

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
                local btn = Instance.new("TextButton", mScroll)
                btn.Size = UDim2.new(1, -4, 0, 24)
                btn.BackgroundColor3 = Color3.fromRGB(16, 21, 42)
                btn.Text = "  " .. opt
                btn.TextColor3 = Color3.fromRGB(240, 245, 255)
                btn.Font = Enum.Font.GothamBold
                btn.TextSize = 8.5
                btn.TextXAlignment = Enum.TextXAlignment.Left
                btn.ZIndex = 102
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
                local bSt = Instance.new("UIStroke", btn)
                bSt.Color = Color3.fromRGB(35, 42, 70)

                btn.MouseButton1Click:Connect(function()
                    if currentModalMode == "PNP_PET" then
                        State.PNP.SelectedPet = opt
                        btnPetPNP.Text = opt .. "  v"
                    elseif currentModalMode == "BOOST_PET" then
                        State.PetBoost.SelectedPet = opt
                        btnPetBoost.Text = opt .. "  v"
                    elseif currentModalMode == "BOOST_ITEM" then
                        State.PetBoost.SelectedBoostItem = opt
                        btnItemBoost.Text = opt .. "  v"
                    end
                    ModalFrame.Visible = false
                end)
            end
        end

        mScroll.CanvasSize = UDim2.new(0, 0, 0, count * 28 + 8)
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
