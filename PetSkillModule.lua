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

    local DataService = nil
    pcall(function()
        DataService = require(ReplicatedStorage:WaitForChild("Modules", 5):WaitForChild("DataService", 5))
    end)

    local PetUtilities = nil
    pcall(function()
        PetUtilities = require(ReplicatedStorage:WaitForChild("Modules", 5):WaitForChild("PetServices", 5):WaitForChild("PetUtilities", 5))
    end)

    -- [2] INISIALISASI & MIGRASI STATE (MENDUKUNG MULTI-SELECT & INDIVIDUAL PET IDENTITY)
    State.PNP = State.PNP or {}
    State.PNP.Enabled = (State.PNP.Enabled ~= nil) and State.PNP.Enabled or false
    State.PNP.DelaySeconds = State.PNP.DelaySeconds or 0.5
    State.PNP.PetDelays = State.PNP.PetDelays or {}
    State.PNP.SelectedPetUUIDs = State.PNP.SelectedPetUUIDs or {}

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

    -- [4] HELPER PEMBERSIH NAMA PET (FILTER KERAS UNTUK PETMOVER & TOOLS LAIN)
    local function cleanPetName(rawName)
        if type(rawName) ~= "string" then return "Pet" end
        local s = rawName
        if s:lower():find("mover") then return "Pet" end
        s = s:gsub("%s*%[[^%]]*%]", "") -- buang tag [15.2 KG], [Age 10]
        s = s:gsub("%s*%[[^%]]*$", "")
        s = s:gsub("%s*%([^%)]*%)", "")
        s = s:gsub("^[hH][uU][gG][eE]%s+", "")
        s = s:gsub("^GIANT%s+", "")
        s = s:gsub("^%s+", ""):gsub("%s+$", "")
        if s == "" or s:lower():find("mover") then return "Pet" end
        return s
    end

    -- [5] GET ALL EQUIPPED PETS IN GARDEN (DENGAN |JENIS|PET|KG| & UUID UNIK & MODEL FISIK)
    local function GetEquippedGardenPets()
        local equipped = {}
        local seenUUID = {}

        if not DataService then
            pcall(function()
                DataService = require(ReplicatedStorage:WaitForChild("Modules", 2):WaitForChild("DataService", 2))
            end)
        end
        if not PetUtilities then
            pcall(function()
                PetUtilities = require(ReplicatedStorage:WaitForChild("Modules", 2):WaitForChild("PetServices", 2):WaitForChild("PetUtilities", 2))
            end)
        end

        -- 1. DATA RESMI DATASERVICE (Inventaris Lengkap & Daftar EquippedPets)
        local equippedMap = {}
        if DataService then
            pcall(function()
                local data = DataService:GetData()
                if data and data.PetsData then
                    local eqList = data.PetsData.EquippedPets or {}
                    local inv = data.PetsData.PetInventory and data.PetsData.PetInventory.Data or {}

                    for _, u in ipairs(eqList) do
                        local sU = tostring(u)
                        local cleanU = sU:gsub("[{}]", ""):lower()
                        equippedMap[cleanU] = true
                        equippedMap[sU:lower()] = true
                    end

                    for uuid, entry in pairs(inv) do
                        local sUuid = tostring(uuid)
                        local cleanU = sUuid:gsub("[{}]", ""):lower()
                        if (equippedMap[cleanU] or equippedMap[sUuid:lower()]) and not seenUUID[cleanU] then
                            seenUUID[cleanU] = true
                            local petData = entry.PetData or {}
                            local rawType = entry.PetType or petData.Species or petData.Name or "Pet"
                            local species = cleanPetName(rawType)
                            if species == "Pet" or species:lower():find("mover") then
                                species = (entry.PetType and cleanPetName(entry.PetType)) or "Mimic"
                            end

                            local customName = (petData.Name and petData.Name ~= "" and petData.Name ~= rawType) and petData.Name or species
                            local level = petData.Level or 1
                            local weightStr = "0.0"

                            if PetUtilities and PetUtilities.CalculateWeight and petData.BaseWeight then
                                local calcW = PetUtilities:CalculateWeight(petData.BaseWeight, level) * 100
                                calcW = math.round(calcW) / 100
                                weightStr = string.format("%.1f", calcW)
                            elseif petData.BaseWeight then
                                weightStr = string.format("%.1f", tonumber(petData.BaseWeight) or 0)
                            elseif petData.Weight then
                                weightStr = string.format("%.1f", tonumber(petData.Weight) or 0)
                            end

                            local displayKey = string.format("|%s|%s|%s|", species, customName, weightStr)
                            table.insert(equipped, {
                                UUID = sUuid,
                                CleanUUID = cleanU,
                                Species = species,
                                Nickname = customName,
                                Name = customName,
                                Weight = weightStr,
                                Age = level,
                                DisplayKey = displayKey,
                                InGarden = true
                            })
                        end
                    end
                end
            end)
        end

        -- 2. SCAN MODEL FISIK DI KEBUN (PetArea, Objects_Physical, PetsPhysical)
        local farm = GetFarm()
        local function scanGardenContainer(cont)
            if not cont then return end
            for _, obj in ipairs(cont:GetChildren()) do
                local rawObjName = obj.Name
                local isMoverName = rawObjName:lower():find("mover") ~= nil

                local owner = obj:GetAttribute("OWNER") or (obj:FindFirstChild("Owner") and obj.Owner.Value)
                local uuid = obj:GetAttribute("UUID") or obj:GetAttribute("PET_UUID")
                if not uuid then
                    for _, sub in ipairs(obj:GetChildren()) do
                        local sU = sub:GetAttribute("UUID") or sub:GetAttribute("PET_UUID")
                        if sU then uuid = sU break end
                        local rawSub = sub.Name:gsub("[{}]", "")
                        if #rawSub > 20 and rawSub:find("-") then uuid = sub.Name break end
                    end
                end

                if (not owner or owner == LocalPlayer.Name or owner == LocalPlayer.UserId) and uuid then
                    local sUuid = tostring(uuid)
                    local cleanU = sUuid:gsub("[{}]", ""):lower()

                    local existing = nil
                    for _, ep in ipairs(equipped) do
                        if ep.CleanUUID == cleanU then
                            existing = ep
                            break
                        end
                    end

                    if existing then
                        existing.Model = obj
                        pcall(function() existing.originalCFrame = obj:GetPivot() end)
                        if (existing.Species == "Pet" or existing.Species == "Unknown") and not isMoverName then
                            existing.Species = cleanPetName(rawObjName)
                            existing.DisplayKey = string.format("|%s|%s|%s|", existing.Species, existing.Nickname, existing.Weight)
                        end
                    elseif not seenUUID[cleanU] and (not isMoverName or owner ~= nil or equippedMap[cleanU]) then
                        seenUUID[cleanU] = true
                        local speciesName = isMoverName and "Mimic" or cleanPetName(rawObjName)
                        local weight = rawObjName:match("%[([%d%.]+)%s*KG%]") or rawObjName:match("([%d%.]+)%s*KG") or "0.0"
                        local age = rawObjName:match("%[Age%s*(%d+)%]") or rawObjName:match("Age%s*(%d+)") or "1"
                        local cf = nil
                        pcall(function() cf = obj:GetPivot() end)

                        local displayKey = string.format("|%s|%s|%s|", speciesName, speciesName, weight)
                        table.insert(equipped, {
                            UUID = sUuid,
                            CleanUUID = cleanU,
                            Model = obj,
                            FullName = rawObjName,
                            Name = speciesName,
                            Species = speciesName,
                            Nickname = speciesName,
                            Weight = weight,
                            Age = age,
                            DisplayKey = displayKey,
                            originalCFrame = cf,
                            InGarden = true
                        })
                    end
                end
            end
        end

        if farm then
            scanGardenContainer(farm:FindFirstChild("PetArea"))
            if farm:FindFirstChild("Important") then
                scanGardenContainer(farm.Important:FindFirstChild("Objects_Physical"))
            end
        end
        scanGardenContainer(workspace:FindFirstChild("PetsPhysical"))

        -- 3. SCAN CHARACTER & BACKPACK TOOLS (COCOKKAN DENGAN EQUIPPED PETS, ABAIKAN MOVER TOOLS)
        local containers = { LocalPlayer.Character, LocalPlayer:FindFirstChild("Backpack") }
        for _, container in ipairs(containers) do
            if container then
                for _, item in ipairs(container:GetChildren()) do
                    if item:IsA("Tool") and not item.Name:lower():find("mover") then
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
                            local cleanU = uStr:gsub("[{}]", ""):lower()
                            for _, p in ipairs(equipped) do
                                if p.CleanUUID == cleanU or p.UUID:gsub("[{}]", ""):lower() == cleanU then
                                    p.Tool = item
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end

        return equipped
    end

    -- [6] HELPER MENCARI MODEL FISIK PET DI KEBUN BERDASARKAN UUID
    local function FindPetModelInGarden(uuid)
        if not uuid then return nil end
        local sUuid = tostring(uuid):gsub("[{}]", ""):lower()
        local farm = GetFarm()
        local containers = {}
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
                    local owner = obj:GetAttribute("OWNER") or (obj:FindFirstChild("Owner") and obj.Owner.Value)
                    if not owner or owner == LocalPlayer.Name or owner == LocalPlayer.UserId then
                        local objUUID = obj:GetAttribute("UUID") or obj:GetAttribute("PET_UUID")
                        if not objUUID then
                            for _, sub in ipairs(obj:GetChildren()) do
                                local sU = sub:GetAttribute("UUID") or sub:GetAttribute("PET_UUID")
                                if sU then objUUID = sU break end
                            end
                        end
                        if objUUID and tostring(objUUID):gsub("[{}]", ""):lower() == sUuid then
                            return obj
                        end
                    end
                end
            end
        end
        return nil
    end

    -- [7] HELPER MEMBACA UUID TOOL PET DENGAN LENGKAP & PRESISI
    local function GetToolUUID(tool)
        if not tool or not tool:IsA("Tool") then return nil end

        -- Cek langsung atribut tool
        for _, attr in ipairs({"PET_UUID", "UUID", "PetUUID", "petId", "Id", "pet_uuid", "uuid"}) do
            local val = tool:GetAttribute(attr)
            if val then return tostring(val):gsub("[{}]", ""):lower() end
        end

        -- Cek semua atribut generik jika ada ID panjang
        for attrName, attrVal in pairs(tool:GetAttributes()) do
            local aLow = attrName:lower()
            if aLow:find("uuid") or aLow:find("id") then
                if type(attrVal) == "string" and #attrVal > 6 then
                    return tostring(attrVal):gsub("[{}]", ""):lower()
                end
            end
        end

        -- Cek di dalam PetData folder/configuration jika ada
        local pData = tool:FindFirstChild("PetData")
        if pData then
            for _, attr in ipairs({"PET_UUID", "UUID", "PetUUID", "petId", "Id", "pet_uuid", "uuid"}) do
                local val = pData:GetAttribute(attr)
                if val then return tostring(val):gsub("[{}]", ""):lower() end
            end
            for _, childName in ipairs({"PET_UUID", "UUID", "PetUUID", "petId", "Id"}) do
                local ch = pData:FindFirstChild(childName)
                if ch and ch:IsA("ValueBase") and ch.Value then
                    return tostring(ch.Value):gsub("[{}]", ""):lower()
                end
            end
        end

        -- Cek direct children ValueBase
        for _, ch in ipairs(tool:GetChildren()) do
            local n = ch.Name:lower()
            if (n:find("uuid") or n == "id" or n == "petid") and ch:IsA("ValueBase") and ch.Value then
                return tostring(ch.Value):gsub("[{}]", ""):lower()
            end
        end

        return nil
    end

    -- [8] HELPER MENCARI TOOL PET ASLI DI BACKPACK (100% AKURAT, ANTI SWAP DENGAN PET LAIN)
    local function FindExactPetTool(targetUUID, expectedFullName, expectedSpecies, toolsBefore)
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if not bp then return nil end

        local cleanTargetUUID = targetUUID and tostring(targetUUID):gsub("[{}]", ""):lower() or nil
        local cleanSpecies = expectedSpecies and cleanPetName(expectedSpecies):lower() or nil
        local cleanFullName = expectedFullName and expectedFullName:lower():gsub("%s+", " ") or nil

        local candidateTools = {}
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(candidateTools, item)
            end
        end
        if LocalPlayer.Character then
            for _, item in ipairs(LocalPlayer.Character:GetChildren()) do
                if item:IsA("Tool") then
                    table.insert(candidateTools, item)
                end
            end
        end

        -- TAHAP 1: MATCH BY EXACT UUID (Prioritas tertinggi dan mutlak)
        if cleanTargetUUID then
            for _, tool in ipairs(candidateTools) do
                local tUUID = GetToolUUID(tool)
                if tUUID and tUUID == cleanTargetUUID then
                    return tool
                end
            end
        end

        -- TAHAP 2: DELTA TRACKING (Tool yang baru saja tiba setelah unequip)
        -- Tool ini TIDAK ADA di tas sebelum unequip dilakukan.
        -- Syarat: Tidak boleh memiliki UUID yang berbeda dari cleanTargetUUID!
        if toolsBefore then
            for _, tool in ipairs(candidateTools) do
                if not toolsBefore[tool] then
                    local tUUID = GetToolUUID(tool)
                    -- Pastikan bukan pet lain yang memiliki UUID berbeda
                    if not tUUID or not cleanTargetUUID or tUUID == cleanTargetUUID then
                        local tName = tool.Name:lower():gsub("%s+", " ")
                        local tSpecies = cleanPetName(tool.Name):lower()
                        local matchesSpecies = cleanSpecies and (tSpecies == cleanSpecies or tSpecies:find(cleanSpecies, 1, true) or cleanSpecies:find(tSpecies, 1, true))
                        local matchesFullName = cleanFullName and (tName:find(cleanFullName, 1, true) or cleanFullName:find(tName, 1, true))
                        
                        if matchesFullName or matchesSpecies then
                            return tool
                        end
                    end
                end
            end
        end

        -- TAHAP 3: MATCH BY EXACT FULL NAME (Termasuk berat KG & Umur yang identik)
        -- Hanya jika nama persis sama dan UUID tidak bertabrakan dengan pet lain
        if cleanFullName then
            for _, tool in ipairs(candidateTools) do
                local tUUID = GetToolUUID(tool)
                if not tUUID or not cleanTargetUUID or tUUID == cleanTargetUUID then
                    local tName = tool.Name:lower():gsub("%s+", " ")
                    if tName == cleanFullName then
                        return tool
                    end
                end
            end
        end

        -- PERLINDUNGAN: Jangan pernah memilih tool acak yang sudah ada di tas sebelumnya!
        return nil
    end

    -- [9] HELPER DETEKSI ITEM BOOST / TOY DI BACKPACK
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

    -- [10] HELPER VALIDASI MULTI-SELEKSI
    local function IsPetSelectedForPNP(petUUID, species, petObj)
        local sel = State.PNP.SelectedPets or {}
        if sel["All Equipped Pets"] then return true end

        -- 1. Cek Presisi UUID Unik (Paling Akurat)
        if petUUID then
            local cleanU = tostring(petUUID):gsub("[{}]", ""):lower()
            if State.PNP.SelectedPetUUIDs and State.PNP.SelectedPetUUIDs[cleanU] then
                return true
            end
            for k, isAct in pairs(sel) do
                if isAct and tostring(k):gsub("[{}]", ""):lower() == cleanU then
                    return true
                end
            end
        end

        -- 2. Cek Presisi DisplayKey (|jenis|pet|Kg|)
        if petObj and petObj.DisplayKey and sel[petObj.DisplayKey] then
            return true
        end

        -- 3. Cek Spesies (Fallback jika pengguna memilih jenis)
        if species then
            local clean = cleanPetName(species):lower()
            for sName, isAct in pairs(sel) do
                if isAct then
                    local sClean = cleanPetName(tostring(sName)):lower()
                    if sClean == clean or clean:find(sClean, 1, true) or sClean:find(clean, 1, true) then
                        return true
                    end
                end
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
    -- 100% PRESISI & AKURAT: PET YANG DI-PICK ADALAH PET YANG SAMA SAAT DI-PLACE
    -- =====================================================================
    local isPnPBusy = {}
    local previousCooldowns = {}

    local function ExecutePickAndPlace(petUUID, petSpecies, petInfo)
        if not State.PNP.Enabled or not petUUID then return end
        local stripped = tostring(petUUID):gsub("[{}]", "")
        if isPnPBusy[stripped] or isPnPBusy[petUUID] then return end
        isPnPBusy[stripped] = true
        isPnPBusy[petUUID] = true

        task.spawn(function()
            -- Delay spesifik untuk pet ini jika disetel pengguna, atau delay default (0.5s)
            local targetDelay = (petInfo and petInfo.UUID and State.PNP.PetDelays and State.PNP.PetDelays[petInfo.UUID])
                or (State.PNP.PetDelays and State.PNP.PetDelays[stripped])
                or State.PNP.DelaySeconds
                or 0.5

            -- 1. IDENTIFIKASI MODEL PET DI KEBUN SEBELUM DI-PICK (Ambil CFrame asli & FullName)
            local petModel = (petInfo and petInfo.Model) or FindPetModelInGarden(petUUID)
            local originalCFrame = (petInfo and petInfo.originalCFrame)
            local petFullName = (petInfo and petInfo.FullName)
            if petModel then
                pcall(function()
                    originalCFrame = petModel:GetPivot()
                    petFullName = petModel.Name
                end)
            end

            -- Jika belum dapat FullName dari model fisik, ambil dari petInfo atau DataService
            if not petFullName and petInfo and petInfo.DisplayKey then
                petFullName = petInfo.DisplayKey
            elseif not petFullName then
                pcall(function()
                    local DataService = require(ReplicatedStorage:WaitForChild("Modules", 2):WaitForChild("DataService", 2))
                    local data = DataService and DataService:GetData()
                    if data and data.PetsData and data.PetsData.PetInventory and data.PetsData.PetInventory.Data then
                        local entry = data.PetsData.PetInventory.Data[petUUID] or data.PetsData.PetInventory.Data[stripped]
                        if entry then
                            local pData = entry.PetData or {}
                            local sp = entry.PetType or pData.Species or pData.Name
                            local bw = pData.BaseWeight or pData.Weight
                            if sp and bw then
                                petFullName = string.format("%s [%s KG]", sp, tostring(bw))
                            end
                        end
                    end
                end)
            end

            print(string.format("[ZyloHub PNP] ⚡ Pet %s (%s) skill aktif! Target: %s", petSpecies or "Unknown", stripped, petFullName or "Pet Model"))

            -- 2. SNAPSHOT TOOL TAS SEBELUM UNEQUIP (Untuk Delta Tracking)
            local toolsBefore = {}
            local bp = LocalPlayer:FindFirstChild("Backpack")
            if bp then
                for _, t in ipairs(bp:GetChildren()) do
                    if t:IsA("Tool") then toolsBefore[t] = true end
                end
            end
            if LocalPlayer.Character then
                for _, t in ipairs(LocalPlayer.Character:GetChildren()) do
                    if t:IsA("Tool") then toolsBefore[t] = true end
                end
            end

            -- 3. TAHAP PICK (Trigger ProximityPrompt model fisik asli + Remote + Module)
            if petModel then
                local prompt = petModel:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt and prompt.Parent then
                    prompt.HoldDuration = 0
                    prompt.RequiresLineOfSight = false
                    pcall(function() fireproximityprompt(prompt) end)
                end
            end

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

            -- 4. TAHAP JEDA (Waktu jeda pick and place yang ditentukan, default 0.5s)
            local userDelay = math.max(0.05, tonumber(targetDelay) or tonumber(State.PNP.DelaySeconds) or 0.5)
            task.wait(userDelay)

            -- 5. TUNGGU TOOL ASLI TIBA DI TAS DENGAN POLLING REAKTIF (Hingga 3.0 detik)
            local petTool = nil
            local startWait = tick()
            while tick() - startWait < 3.0 do
                petTool = FindExactPetTool(petUUID, petFullName, petSpecies, toolsBefore)
                if petTool then break end
                task.wait(0.08)
            end

            if petTool then
                print(string.format("[ZyloHub PNP] 🎯 Tool pet asli terverifikasi: %s", petTool.Name))
            else
                print(string.format("[ZyloHub PNP] ⚠️ Tool spesifik belum di tas, melanjutkan penempatan via Server Remote ke posisi semula..."))
            end

            -- 6. TAHAP PLACE: KEMBALIKAN PET KE POSISI ASLI KEBUN DENGAN MULTI-LAYER PRESISI
            local farm = GetFarm()
            local petArea = farm and farm:FindFirstChild("PetArea")
            local targetPos = originalCFrame
                or (petArea and petArea.CFrame + Vector3.new(0, 2, 0))
                or (LocalPlayer.Character and LocalPlayer.Character:GetPivot())
                or CFrame.new(0, 5, 0)

            -- Lapis 1: Remote resmi EquipPet langsung ke target CFrame
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

            -- Lapis 3: Humanoid Equip & Tool Placement jika tool ada di tas
            if petTool and LocalPlayer.Character then
                local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid and petTool.Parent == LocalPlayer:FindFirstChild("Backpack") then
                    humanoid:EquipTool(petTool)
                    task.wait(0.12)
                    if petTool.Parent == LocalPlayer.Character then
                        pcall(function() petTool:Activate() end)
                    end
                    task.wait(0.12)
                    -- Bersihkan dari tangan jika server sudah menempatkan pet
                    if petTool.Parent == LocalPlayer.Character then
                        pcall(function() petTool.Parent = LocalPlayer:FindFirstChild("Backpack") end)
                    end
                end
            end

            print(string.format("[ZyloHub PNP] ✅ Pet %s (%s) sukses ditaruh kembali dengan presisi!", petFullName or petSpecies or "Pet", stripped))
            task.wait(0.3)
            isPnPBusy[petUUID] = nil
            isPnPBusy[stripped] = nil
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
                    if not matchedPet or matchedPet.Species == "Pet" or matchedPet.Species == "Unknown" then
                        local m = FindPetModelInGarden(uStr)
                        if m then
                            speciesName = cleanPetName(m.Name)
                        end
                    end
                    if IsPetSelectedForPNP(uStr, speciesName, matchedPet) then
                        ExecutePickAndPlace(uStr, speciesName, matchedPet)
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
            for key, isAct in pairs(pnpSel) do
                if isAct and key ~= "All Equipped Pets" then
                    table.insert(list, key)
                end
            end
            if #list == 0 then
                local uuidCount = 0
                for _, isAct in pairs(State.PNP.SelectedPetUUIDs or {}) do
                    if isAct then uuidCount = uuidCount + 1 end
                end
                if uuidCount == 0 then
                    btnPetPNP.Text = "None Selected  v"
                elseif uuidCount == 1 then
                    btnPetPNP.Text = "1 Pet Active  v"
                else
                    btnPetPNP.Text = string.format("%d Pets Active  v", uuidCount)
                end
            elseif #list == 1 then
                btnPetPNP.Text = list[1] .. "  v"
            else
                btnPetPNP.Text = string.format("%d Pets Active  v", #list)
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
    -- [BAGIAN 4: MODAL POPUP MULTI-SELEKSI DENGAN FORMAT |JENIS|PET|KG| (TIME) ON/OFF]
    -- =====================================================================
    local ModalFrame = Instance.new("Frame", MainScreen or ParentContainer)
    ModalFrame.Size = UDim2.new(0, 310, 0, 330)
    ModalFrame.Position = UDim2.new(0.5, -155, 0.5, -165)
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
            if c:IsA("TextButton") or c:IsA("TextLabel") or c:IsA("Frame") then c:Destroy() end
        end

        local filter = mSearch.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")

        -- =================================================================
        -- MODE 1: PNP PET SELECTION DENGAN FORMAT |JENIS|PET|KG| (TIME) ON/OFF
        -- =================================================================
        if currentModalMode == "PNP_PET" then
            mTitle.Text = "Select Pets for PNP"
            local gPets = GetEquippedGardenPets()
            local isAllActive = (State.PNP.SelectedPets and State.PNP.SelectedPets["All Equipped Pets"] == true)

            local rowCount = 0

            -- Opsi Header: All Equipped Pets
            if filter == "" or ("all equipped pets"):find(filter, 1, true) or ("semua pet"):find(filter, 1, true) then
                rowCount = rowCount + 1
                local btnAll = Instance.new("TextButton", mScroll)
                btnAll.Size = UDim2.new(1, -4, 0, 28)
                btnAll.BackgroundColor3 = isAllActive and Color3.fromRGB(36, 18, 58) or Color3.fromRGB(16, 21, 42)
                btnAll.Text = (isAllActive and "  [✓] " or "  [  ] ") .. "All Equipped Pets (Semua Pet)"
                btnAll.TextColor3 = isAllActive and C.PURPLE_L or Color3.fromRGB(240, 245, 255)
                btnAll.Font = Enum.Font.GothamBold
                btnAll.TextSize = 8.5
                btnAll.TextXAlignment = Enum.TextXAlignment.Left
                btnAll.ZIndex = 102
                Instance.new("UICorner", btnAll).CornerRadius = UDim.new(0, 4)
                local bStAll = Instance.new("UIStroke", btnAll)
                bStAll.Color = isAllActive and C.PURPLE or Color3.fromRGB(35, 42, 70)
                bStAll.Thickness = isAllActive and 1.2 or 1

                btnAll.MouseButton1Click:Connect(function()
                    table.clear(State.PNP.SelectedPets)
                    table.clear(State.PNP.SelectedPetUUIDs)
                    State.PNP.SelectedPets["All Equipped Pets"] = true
                    populateModalOptions()
                    UpdateButtonLabels()
                end)
            end

            -- Opsi Pet Individual: |jenis|pet|Kg  (time pick and place)  On/Off
            for _, pet in ipairs(gPets) do
                local displayKey = pet.DisplayKey or string.format("|%s|%s|%s|", pet.Species, pet.Nickname or pet.Species, pet.Weight or "0.0")
                local cleanU = pet.CleanUUID or tostring(pet.UUID):gsub("[{}]", ""):lower()

                local matchesFilter = (filter == "")
                    or displayKey:lower():find(filter, 1, true)
                    or pet.Species:lower():find(filter, 1, true)
                    or (pet.Nickname and pet.Nickname:lower():find(filter, 1, true))
                    or (pet.Weight and tostring(pet.Weight):find(filter, 1, true))

                if matchesFilter then
                    rowCount = rowCount + 1
                    local isChecked = not isAllActive and ((State.PNP.SelectedPets and State.PNP.SelectedPets[displayKey] == true) 
                        or (State.PNP.SelectedPetUUIDs and State.PNP.SelectedPetUUIDs[cleanU] == true))

                    local row = Instance.new("Frame", mScroll)
                    row.Size = UDim2.new(1, -4, 0, 32)
                    row.BackgroundColor3 = isChecked and Color3.fromRGB(36, 18, 58) or Color3.fromRGB(16, 21, 42)
                    row.ZIndex = 102
                    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)
                    local rStroke = Instance.new("UIStroke", row)
                    rStroke.Color = isChecked and C.PURPLE or Color3.fromRGB(35, 42, 70)
                    rStroke.Thickness = isChecked and 1.2 or 1

                    -- 1. Bagian Kiri: |jenis|pet|Kg|
                    local lblPet = Instance.new("TextLabel", row)
                    lblPet.Position = UDim2.new(0, 8, 0, 0)
                    lblPet.Size = UDim2.new(1, -120, 1, 0)
                    lblPet.BackgroundTransparency = 1
                    lblPet.Text = displayKey
                    lblPet.TextColor3 = isChecked and C.PURPLE_L or Color3.fromRGB(240, 245, 255)
                    lblPet.Font = Enum.Font.GothamBold
                    lblPet.TextSize = 8.5
                    lblPet.TextXAlignment = Enum.TextXAlignment.Left
                    lblPet.TextTruncate = Enum.TextTruncate.AtEnd
                    lblPet.ZIndex = 102

                    -- 2. Bagian Tengah: (time pick and place) editable box
                    local petDelay = (State.PNP.PetDelays and State.PNP.PetDelays[pet.UUID])
                        or (State.PNP.PetDelays and State.PNP.PetDelays[cleanU])
                        or State.PNP.DelaySeconds
                        or 0.5

                    local boxTime = Instance.new("TextBox", row)
                    boxTime.Position = UDim2.new(1, -108, 0.5, -10)
                    boxTime.Size = UDim2.new(0, 48, 0, 20)
                    boxTime.BackgroundColor3 = Color3.fromRGB(10, 14, 28)
                    boxTime.Text = string.format("(%.1f)", tonumber(petDelay) or 0.5)
                    boxTime.TextColor3 = C.CYAN
                    boxTime.Font = Enum.Font.GothamBold
                    boxTime.TextSize = 8
                    boxTime.ClearTextOnFocus = false
                    boxTime.ZIndex = 104
                    Instance.new("UICorner", boxTime).CornerRadius = UDim.new(0, 4)
                    local tStroke = Instance.new("UIStroke", boxTime)
                    tStroke.Color = Color3.fromRGB(40, 50, 75)

                    boxTime.FocusLost:Connect(function()
                        local num = tonumber(boxTime.Text:match("[%d%.]+"))
                        if num and num >= 0.05 then
                            State.PNP.PetDelays[pet.UUID] = num
                            State.PNP.PetDelays[cleanU] = num
                            boxTime.Text = string.format("(%.1f)", num)
                        else
                            boxTime.Text = string.format("(%.1f)", tonumber(petDelay) or 0.5)
                        end
                    end)

                    -- 3. Bagian Kanan: Tombol On/Off
                    local btnToggle = Instance.new("TextButton", row)
                    btnToggle.Position = UDim2.new(1, -56, 0.5, -11)
                    btnToggle.Size = UDim2.new(0, 50, 0, 22)
                    btnToggle.BackgroundColor3 = isChecked and Color3.fromRGB(138, 43, 226) or Color3.fromRGB(24, 28, 48)
                    btnToggle.Text = isChecked and "ON" or "OFF"
                    btnToggle.TextColor3 = isChecked and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 140, 170)
                    btnToggle.Font = Enum.Font.GothamBold
                    btnToggle.TextSize = 8.5
                    btnToggle.ZIndex = 104
                    Instance.new("UICorner", btnToggle).CornerRadius = UDim.new(0, 4)
                    local tgStroke = Instance.new("UIStroke", btnToggle)
                    tgStroke.Color = isChecked and Color3.fromRGB(190, 120, 255) or Color3.fromRGB(45, 55, 85)

                    local function togglePet()
                        State.PNP.SelectedPets["All Equipped Pets"] = nil
                        if isChecked then
                            State.PNP.SelectedPets[displayKey] = nil
                            State.PNP.SelectedPetUUIDs[cleanU] = nil
                        else
                            State.PNP.SelectedPets[displayKey] = true
                            State.PNP.SelectedPetUUIDs[cleanU] = true
                        end

                        local anySelected = false
                        for _, v in pairs(State.PNP.SelectedPets) do
                            if v == true then anySelected = true break end
                        end
                        for _, v in pairs(State.PNP.SelectedPetUUIDs) do
                            if v == true then anySelected = true break end
                        end
                        if not anySelected then
                            State.PNP.SelectedPets["All Equipped Pets"] = true
                        end

                        populateModalOptions()
                        UpdateButtonLabels()
                    end

                    btnToggle.MouseButton1Click:Connect(togglePet)

                    local clickOverlay = Instance.new("TextButton", row)
                    clickOverlay.Size = UDim2.new(1, -112, 1, 0)
                    clickOverlay.BackgroundTransparency = 1
                    clickOverlay.Text = ""
                    clickOverlay.ZIndex = 103
                    clickOverlay.MouseButton1Click:Connect(togglePet)
                end
            end

            mScroll.CanvasSize = UDim2.new(0, 0, 0, rowCount * 36 + 10)
            return
        end

        -- =================================================================
        -- MODE 2 & 3: AUTO PET BOOST (TARGET PET & ITEMS)
        -- =================================================================
        local options = {}
        local selectedTable = nil

        if currentModalMode == "BOOST_PET" then
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
                        table.clear(selectedTable)
                        selectedTable[opt] = true
                    else
                        selectedTable["All Equipped Pets"] = nil
                        selectedTable["All Toys & Boosts"] = nil

                        if selectedTable[opt] then
                            selectedTable[opt] = nil
                        else
                            selectedTable[opt] = true
                        end

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
