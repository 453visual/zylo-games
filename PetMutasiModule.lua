-- =========================================================================
--  ZYLOHUB - AUTO MUTASI MODULE (OFFICIAL EXTENSION v4.3.0 - FIX WEBHOOK)
--  Repository: zylo-games/PetMutasiModule.lua
--  Theme: Deep Obsidian Black (#070912) & Cosmic Purple (#8A2BE2)
--  Sub-Tabs: Elephant > Machine > Nightmare > 100 Age > XP > GBXP > Config
--  Mode Pipeline: Modal Popup Selector (Mode A - F)
--  Perbaikan:
--    1. Webhook Engine Bawaan Langsung (Bypass loadstring failure)
--    2. Multi-Executor HTTP Request (Delta, Codex, Arceus X, Fluxus, Synapse)
--    3. Auto-Trim Link Webhook & Auto-Detect Link dari ZyloHub Global
--    4. Tombol TEST Responsif & Indikator Status Lengkap
--    5. Realtime Event Notifikasi (GBXP, XP, Elephant, 100 Age, Mesin, Nightmare, Clean Shard, Lulus)
-- =========================================================================

return function(ParentContainer, State, ZyloLib, Main)
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local CollectionService = game:GetService("CollectionService")
    local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
    local C = ZyloLib.Colors

    -- =====================================================================
    -- DATASET KAMUS MUTASI RESMI GAME
    -- =====================================================================
    local MUTATION_MAP = {
        ["@"]      = "Blossoming",
        ["J"]      = "Oxpecker",
        ["IN"]     = "Inferno",
        ["X"]      = "Venom",
        ["EM"]     = "Ember",
        ["EV"]     = "Everchanted",
        ["O"]      = "Forger",
        ["A"]      = "Nightmare",
        ["N"]      = "Lion",
        ["i"]      = "Mega",
        ["TS"]     = "Transcendent",
        ["Normal"] = "Normal"
    }

    local function getAutoMutationName(rawCode)
        if not rawCode or rawCode == "" then return "Normal" end
        if MUTATION_MAP[rawCode] then return MUTATION_MAP[rawCode] end
        for k, v in pairs(MUTATION_MAP) do
            if tostring(k):lower() == tostring(rawCode):lower() then return v end
            if tostring(v):lower() == tostring(rawCode):lower() then return v end
        end
        return tostring(rawCode)
    end

    -- =====================================================================
    -- SERVICES & REMOTES RESMI
    -- =====================================================================
    local GameEvents = ReplicatedStorage:WaitForChild("GameEvents", 10)
    local PetsServiceRemote = GameEvents and GameEvents:FindFirstChild("PetsService")
    local PetMutationMachineRemote = GameEvents and (
        GameEvents:FindFirstChild("PetMutationMachineService_RE") or
        (GameEvents:FindFirstChild("Events") and GameEvents.Events:FindFirstChild("SubmitPetToMachine"))
    )
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

    -- =====================================================================
    -- STATE INISIALISASI & AUTO-SYNC LINK WEBHOOK
    -- =====================================================================
    State.MutasiActiveCategory = State.MutasiActiveCategory or "Elephant"
    State.MutasiMode = State.MutasiMode or "Mode: A"
    State.MutasiRunning = State.MutasiRunning or false
    State.MutasiSearchQuery = State.MutasiSearchQuery or ""
    State.CompletedPets = State.CompletedPets or {}
    State.MutasiStatusText = "IDLE - Siap Memulai Pipeline"

    -- Deteksi link webhook otomatis jika sudah diinput di ZyloHub
    local detectedUrl = State.MutasiWebhookURL or State.WebhookUrl or State.EggWebhookUrl or (getgenv and getgenv().WebhookUrl) or ""
    State.MutasiWebhookURL = tostring(detectedUrl):gsub("%s+", "")
    State.MutasiWebhookEnabled = (State.MutasiWebhookEnabled ~= nil) and State.MutasiWebhookEnabled or false
    State.AutoCleanIfNotTarget = State.AutoCleanIfNotTarget or false
    State.MachineTargetMutation = State.MachineTargetMutation or "Any Mutation"
    State.NightmareTargetMutation = State.NightmareTargetMutation or "Any Mutation"

    State.GBXPMaxEquip = State.GBXPMaxEquip or 2
    State.GBXPSelectMode = State.GBXPSelectMode or "auto"

    State.MutasiTeamThresholds = State.MutasiTeamThresholds or {
        Elephant    = { EquipAge = 20, UnequipAge = 0 },
        Machine     = { EquipAge = 20, UnequipAge = 0 },
        Nightmare   = { EquipAge = 20, UnequipAge = 0 },
        ["100 Age"] = { EquipAge = 50, UnequipAge = 500 },
        XP          = { EquipAge = 0,  UnequipAge = 50 },
        GBXP        = { EquipAge = 0,  UnequipAge = 100 }
    }

    State.MutasiEquipAge = State.MutasiTeamThresholds[State.MutasiActiveCategory] and State.MutasiTeamThresholds[State.MutasiActiveCategory].EquipAge or 20
    State.MutasiUnequipAge = State.MutasiTeamThresholds[State.MutasiActiveCategory] and State.MutasiTeamThresholds[State.MutasiActiveCategory].UnequipAge or 0

    State.MutasiSelectedTeams = State.MutasiSelectedTeams or {
        Elephant    = {},
        Machine     = {},
        Nightmare   = {},
        ["100 Age"] = {},
        XP          = {},
        GBXP        = {}
    }

    -- Forward declarations
    local GetAllPets
    local SwitchCategory
    local updateThresholdTitle
    local updateActionButton
    local refreshPetList
    local updateTeamBadgesUI
    local updateStatusUI
    local UnequipPetByUUID
    local EquipPetByUUID
    local RecallAllPetsFromFarm
    local EquipSupportPets
    local UnequipSupportPets
    local GetMutationMachineInstance

    -- =====================================================================
    -- UNIVERSAL MULTI-EXECUTOR WEBHOOK SENDER ENGINE (INTERNAL & 100% PASTI)
    -- =====================================================================
    local function SendDiscordWebhookPayload(payloadTable)
        local rawUrl = tostring(State.MutasiWebhookURL or ""):gsub("%s+", "")
        if rawUrl == "" then
            return false, "URL Webhook masih kosong!"
        end
        if not (rawUrl:find("discord.com/api/webhooks") or rawUrl:find("discordapp.com/api/webhooks")) then
            return false, "URL tidak valid! Harus link discord.com/api/webhooks"
        end

        local jsonBody = ""
        local okJson, errJson = pcall(function()
            jsonBody = HttpService:JSONEncode(payloadTable)
        end)
        if not okJson then return false, "JSON Encode Error: " .. tostring(errJson) end

        local requestFunc = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
        if not requestFunc then
            return false, "Executor tidak mendukung fungsi HTTP Request"
        end

        local response = nil
        local okReq, reqErr = pcall(function()
            response = requestFunc({
                Url = rawUrl,
                url = rawUrl,
                Method = "POST",
                method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["content-type"] = "application/json"
                },
                headers = {
                    ["Content-Type"] = "application/json",
                    ["content-type"] = "application/json"
                },
                Body = jsonBody,
                body = jsonBody
            })
        end)

        if not okReq then
            return false, "HTTP Request Error: " .. tostring(reqErr)
        end

        local statusCode = response and (response.StatusCode or response.status_code or response.Status)
        if statusCode and (statusCode == 204 or statusCode == 200) then
            return true, "Success (HTTP " .. tostring(statusCode) .. ")"
        elseif statusCode then
            return false, "Discord menolak: HTTP " .. tostring(statusCode)
        end

        return true, "Success"
    end

    local function TriggerEventWebhook(eventType, data1, data2, data3)
        if not State.MutasiWebhookEnabled or not State.MutasiWebhookURL or State.MutasiWebhookURL == "" then
            return
        end

        task.spawn(function()
            local payload = nil

            if eventType == "TEST" then
                payload = {
                    username = "ZyloHub Mutasi Bot",
                    avatar_url = "https://i.imgur.com/8Qf9GkF.png",
                    embeds = {{
                        title = "🔔 Tes Koneksi Discord Webhook Berhasil!",
                        description = "ZyloHub Auto Mutasi telah terhubung aktif dengan Discord Anda dalam mode **Event-Based Realtime**.",
                        color = 9055202,
                        fields = {
                            { name = "👤 Akun Roblox", value = string.format("`%s` (@%s)", LocalPlayer.DisplayName, LocalPlayer.Name), inline = true },
                            { name = "⚡ Status", value = "`CONNECTED & ACTIVE`", inline = true }
                        },
                        footer = { text = "ZyloHub • Auto Mutasi System" },
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                    }}
                }

            elseif eventType == "BATCH_START" then
                local modeName, petsList = data1, data2
                local petDesc = {}
                for i, p in ipairs(petsList or {}) do
                    table.insert(petDesc, string.format("%d. **%s** | Age: `%s` | `%s KG` | Mutasi: `%s`", i, p.Name, tostring(p.Age), tostring(p.Weight), p.Mutation or "Normal"))
                end
                payload = {
                    username = "ZyloHub Mutasi Bot",
                    embeds = {{
                        title = "📦 [EVENT]: Rombongan Pet Baru Diambil dari GBXP",
                        description = string.format("Memulai estafet pet di **%s**.", tostring(modeName)),
                        color = 3447003,
                        fields = {
                            { name = "👤 Player", value = string.format("`%s`", LocalPlayer.Name), inline = true },
                            { name = "🎯 Mode", value = string.format("`%s`", tostring(modeName)), inline = true },
                            { name = string.format("🐾 Daftar Pet (%d)", #(petsList or {})), value = (#petDesc > 0 and table.concat(petDesc, "\n") or "Tidak ada pet") }
                        },
                        footer = { text = "ZyloHub • GBXP Supply" },
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                    }}
                }

            elseif eventType == "STAGE_CHANGE" then
                local stageName, targetAge, petsList = data1, data2, data3
                local petDesc = {}
                for i, p in ipairs(petsList or {}) do
                    table.insert(petDesc, string.format("• **%s** — Age `%s` (Target: Age `%d`)", p.Name, tostring(p.Age), tonumber(targetAge) or 500))
                end
                payload = {
                    username = "ZyloHub Mutasi Bot",
                    embeds = {{
                        title = string.format("🚀 [PERKEMBANGAN]: Masuk ke Tahap %s", tostring(stageName):upper()),
                        description = string.format("Booster tim **%s** dipasang di kebun. Rombongan mulai menaikkan level.", tostring(stageName)),
                        color = 10181046,
                        fields = {
                            { name = "📌 Tahap Aktif", value = string.format("`%s`", tostring(stageName)), inline = true },
                            { name = "🎯 Target Unequip", value = string.format("`Age %s`", tostring(targetAge)), inline = true },
                            { name = "🐾 Pet yang Diproses", value = (#petDesc > 0 and table.concat(petDesc, "\n") or "Proses") }
                        },
                        footer = { text = "ZyloHub • Stage Progress" },
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                    }}
                }

            elseif eventType == "MACHINE_START" then
                local pet, desiredTarget = data1, data2
                payload = {
                    username = "ZyloHub Mutasi Bot",
                    embeds = {{
                        title = "⚙️ [MESIN MUTASI]: Pet Masuk ke Mesin",
                        description = string.format("Pet **%s** telah dimasukkan ke Mesin Mutasi dan proses dimulai!", pet.Name),
                        color = 15105570,
                        fields = {
                            { name = "🐾 Nama Pet", value = string.format("`%s`", pet.Name), inline = true },
                            { name = "⚖️ Berat", value = string.format("`%s KG`", tostring(pet.Weight)), inline = true },
                            { name = "🎯 Target Mutasi", value = string.format("`%s`", tostring(desiredTarget)), inline = true },
                            { name = "🧬 Mutasi Saat Ini", value = string.format("`%s`", pet.Mutation or "Normal"), inline = true }
                        },
                        footer = { text = "ZyloHub • Mutation Machine" },
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                    }}
                }

            elseif eventType == "SUCCESS" then
                local pet, targetName, location = data1, data2, data3
                payload = {
                    username = "ZyloHub Mutasi Bot",
                    embeds = {{
                        title = "🎉 [TARGET TERCAPAI]: Mutasi Berhasil Diperoleh!",
                        description = string.format("Selamat! Pet **%s** berhasil mendapatkan mutasi sesuai target!", pet.Name),
                        color = 3066993,
                        fields = {
                            { name = "🐾 Nama Pet", value = string.format("`%s`", pet.Name), inline = true },
                            { name = "🧬 Mutasi Didapat", value = string.format("**%s**", tostring(pet.Mutation)), inline = true },
                            { name = "🎯 Target Pilihan", value = string.format("`%s`", tostring(targetName)), inline = true },
                            { name = "📍 Lokasi", value = string.format("`%s`", tostring(location or "Mesin Mutasi")), inline = true }
                        },
                        footer = { text = "ZyloHub • Success Mutation" },
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                    }}
                }

            elseif eventType == "CLEAN_LOG" then
                local pet, gotMutation, desiredTarget = data1, data2, data3
                payload = {
                    username = "ZyloHub Mutasi Bot",
                    embeds = {{
                        title = "🧪 [CLEAN SHARD]: Mutasi Belum Cocok, Mencuci Pet...",
                        description = string.format("Pet **%s** mendapat mutasi **%s** (Belum cocok target **%s**).\nClean Pet Shard otomatis digunakan untuk mereset mutasi pet!", pet.Name, tostring(gotMutation), tostring(desiredTarget)),
                        color = 15158332,
                        fields = {
                            { name = "🐾 Nama Pet", value = string.format("`%s`", pet.Name), inline = true },
                            { name = "❌ Mutasi Keluar", value = string.format("`%s`", tostring(gotMutation)), inline = true },
                            { name = "🎯 Target Diinginkan", value = string.format("`%s`", tostring(desiredTarget)), inline = true }
                        },
                        footer = { text = "ZyloHub • Auto Clean Shard" },
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                    }}
                }

            elseif eventType == "BATCH_COMPLETED" then
                local petsList = data1
                local petDesc = {}
                for i, p in ipairs(petsList or {}) do
                    table.insert(petDesc, string.format("✓ **%s** | Final Age: `%s` | Mutasi: `%s`", p.Name, tostring(p.Age), p.Mutation or "Normal"))
                end
                payload = {
                    username = "ZyloHub Mutasi Bot",
                    embeds = {{
                        title = "🏆 [ROMBONGAN TUNTAS]: Semua Tahapan Selesai!",
                        description = "Seluruh pet dalam rombongan ini telah lulus dari semua tahapan dan ditarik aman ke dalam tas.",
                        color = 15844367,
                        fields = {
                            { name = "🐾 Pet yang Diselesaikan", value = (#petDesc > 0 and table.concat(petDesc, "\n") or "Selesai") }
                        },
                        footer = { text = "ZyloHub • Batch Completed" },
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                    }}
                }
            end

            if payload then
                SendDiscordWebhookPayload(payload)
            end
        end)
    end

    -- Clean Mutasi Shard Helper Service
    local CleanMutasiService = nil
    local function GetCleanMutasiService()
        if not CleanMutasiService then
            pcall(function()
                CleanMutasiService = loadstring(game:HttpGet("https://raw.githubusercontent.com/ranklee26-glitch/zylo-games/main/CleanMutasi.lua"))()
            end)
        end
        return CleanMutasiService
    end

    local function GetTeamSelectedCount(catName)
        if catName == "Config" then return 0 end
        if catName == "GBXP" and State.GBXPSelectMode == "auto" then
            if GetAllPets then
                local allPets = GetAllPets()
                local count = 0
                local minAge = State.MutasiTeamThresholds.GBXP.EquipAge or 0
                local maxAge = State.MutasiTeamThresholds.GBXP.UnequipAge or 500
                for _, p in ipairs(allPets) do
                    if not p.IsFavorite and not State.CompletedPets[p.UUID] then
                        if p.Age >= minAge and p.Age <= maxAge then
                            count = count + 1
                        end
                    end
                end
                return count
            end
            return 0
        end

        local teamMap = State.MutasiSelectedTeams[catName]
        if not teamMap then return 0 end
        local count = 0
        local seen = {}
        for uuid, isSel in pairs(teamMap) do
            if isSel == true then
                local clean = tostring(uuid):gsub("[{}]", "")
                if not seen[clean] then
                    seen[clean] = true
                    count = count + 1
                end
            end
        end
        return count
    end

    -- =====================================================================
    -- CONTAINER UTAMA
    -- =====================================================================
    local MutasiWrapper = Instance.new("Frame", ParentContainer)
    MutasiWrapper.Size = UDim2.new(1, 0, 0, 520)
    MutasiWrapper.BackgroundTransparency = 1

    local MutasiLayout = Instance.new("UIListLayout", MutasiWrapper)
    MutasiLayout.SortOrder = Enum.SortOrder.LayoutOrder
    MutasiLayout.Padding = UDim.new(0, 6)

    -- =====================================================================
    -- 1. SUB-NAVIGASI KATEGORI
    -- =====================================================================
    local NavRow = Instance.new("Frame", MutasiWrapper)
    NavRow.Size = UDim2.new(1, 0, 0, 28)
    NavRow.BackgroundTransparency = 1
    NavRow.BorderSizePixel = 0
    NavRow.LayoutOrder = 1

    local PillsContainer = Instance.new("Frame", NavRow)
    PillsContainer.Size = UDim2.new(1, -32, 1, 0)
    PillsContainer.BackgroundTransparency = 1

    local NavList = Instance.new("UIListLayout", PillsContainer)
    NavList.FillDirection = Enum.FillDirection.Horizontal
    NavList.VerticalAlignment = Enum.VerticalAlignment.Center
    NavList.Padding = UDim.new(0, 5)

    local Categories = {
        { name = "Elephant",  weight = 1.05 },
        { name = "Machine",   weight = 1.05 },
        { name = "Nightmare", weight = 1.25 },
        { name = "100 Age",   weight = 1.05 },
        { name = "XP",        weight = 0.75 },
        { name = "GBXP",      weight = 0.85 },
        { name = "Config",    weight = 1.00 }
    }
    local totalWeight = 7.0
    local CategoryButtons = {}

    for _, catData in ipairs(Categories) do
        local catName = catData.name
        local wScale = catData.weight / totalWeight

        local btn = Instance.new("TextButton", PillsContainer)
        btn.Size = UDim2.new(wScale, -4, 0, 26)
        btn.BackgroundColor3 = (State.MutasiActiveCategory == catName) and Color3.fromRGB(48, 24, 80) or Color3.fromRGB(15, 18, 34)
        btn.Text = catName
        btn.TextColor3 = (State.MutasiActiveCategory == catName) and Color3.fromRGB(255, 255, 255) or C.TEXT_M
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 8.5
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 13)
        local stroke = Instance.new("UIStroke", btn)
        stroke.Color = (State.MutasiActiveCategory == catName) and C.PURPLE or Color3.fromRGB(38, 45, 70)
        stroke.Thickness = (State.MutasiActiveCategory == catName) and 1.5 or 1

        CategoryButtons[catName] = { btn = btn, stroke = stroke }

        btn.MouseButton1Click:Connect(function()
            SwitchCategory(catName)
        end)
    end

    local GearBtn = Instance.new("TextButton", NavRow)
    GearBtn.Size = UDim2.new(0, 26, 0, 26)
    GearBtn.Position = UDim2.new(1, -26, 0.5, -13)
    GearBtn.BackgroundColor3 = Color3.fromRGB(15, 18, 34)
    GearBtn.Text = "⚙"
    GearBtn.TextColor3 = C.TEXT_M
    GearBtn.Font = Enum.Font.GothamBold
    GearBtn.TextSize = 12
    Instance.new("UICorner", GearBtn).CornerRadius = UDim.new(0, 13)
    local gearStroke = Instance.new("UIStroke", GearBtn)
    gearStroke.Color = Color3.fromRGB(38, 45, 70)

    GearBtn.MouseButton1Click:Connect(function()
        SwitchCategory("Config")
    end)

    -- =====================================================================
    -- 2. DROPDOWN HEADER (TIM MUTASI)
    -- =====================================================================
    local ThreshHeader = Instance.new("TextButton", MutasiWrapper)
    ThreshHeader.Size = UDim2.new(1, 0, 0, 28)
    ThreshHeader.BackgroundColor3 = Color3.fromRGB(13, 16, 32)
    ThreshHeader.Text = ""
    ThreshHeader.LayoutOrder = 2
    ThreshHeader.Visible = (State.MutasiActiveCategory ~= "Config")
    Instance.new("UICorner", ThreshHeader).CornerRadius = UDim.new(0, 8)
    local thStroke = Instance.new("UIStroke", ThreshHeader)
    thStroke.Color = Color3.fromRGB(38, 45, 72)

    local thTitle = Instance.new("TextLabel", ThreshHeader)
    thTitle.Position = UDim2.new(0, 10, 0, 0)
    thTitle.Size = UDim2.new(1, -40, 1, 0)
    thTitle.BackgroundTransparency = 1
    thTitle.Text = "( " .. State.MutasiActiveCategory .. " Team ) Threshold Age & Kg"
    thTitle.TextColor3 = C.TEXT_W
    thTitle.Font = Enum.Font.GothamBold
    thTitle.TextSize = 9.5
    thTitle.TextXAlignment = Enum.TextXAlignment.Left

    updateThresholdTitle = function()
        thTitle.Text = "( " .. State.MutasiActiveCategory .. " Team ) Threshold Age & Kg"
    end

    local thArrow = Instance.new("TextLabel", ThreshHeader)
    thArrow.Position = UDim2.new(1, -26, 0, 0)
    thArrow.Size = UDim2.new(0, 20, 1, 0)
    thArrow.BackgroundTransparency = 1
    thArrow.Text = "▼"
    thArrow.TextColor3 = C.PURPLE_L
    thArrow.Font = Enum.Font.GothamBold
    thArrow.TextSize = 9

    -- =====================================================================
    -- 3. BODY: BADGES + THRESHOLDS + TARGET MUTASI + KONTROL GBXP
    -- =====================================================================
    local isGBXPActive = (State.MutasiActiveCategory == "GBXP")
    local isMachineActive = (State.MutasiActiveCategory == "Machine")
    local isNightmareActive = (State.MutasiActiveCategory == "Nightmare")

    local ThreshBody = Instance.new("Frame", MutasiWrapper)
    local initialHeight = 88
    if isGBXPActive then initialHeight = 148
    elseif isMachineActive or isNightmareActive then initialHeight = 118 end

    ThreshBody.Size = UDim2.new(1, 0, 0, initialHeight)
    ThreshBody.BackgroundTransparency = 1
    ThreshBody.LayoutOrder = 3
    ThreshBody.Visible = (State.MutasiActiveCategory ~= "Config")

    local TbLayout = Instance.new("UIListLayout", ThreshBody)
    TbLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TbLayout.Padding = UDim.new(0, 5)

    local isThreshOpen = true
    ThreshHeader.MouseButton1Click:Connect(function()
        isThreshOpen = not isThreshOpen
        ThreshBody.Visible = isThreshOpen
        thArrow.Text = isThreshOpen and "▼" or "▶"
    end)

    -- Badges
    local StatsScroll = Instance.new("ScrollingFrame", ThreshBody)
    StatsScroll.Size = UDim2.new(1, 0, 0, 24)
    StatsScroll.BackgroundColor3 = Color3.fromRGB(11, 14, 26)
    StatsScroll.ScrollBarThickness = 0
    StatsScroll.ScrollingDirection = Enum.ScrollingDirection.X
    StatsScroll.CanvasSize = UDim2.new(0, 540, 0, 24)
    StatsScroll.LayoutOrder = 1
    Instance.new("UICorner", StatsScroll).CornerRadius = UDim.new(0, 6)
    local stStroke = Instance.new("UIStroke", StatsScroll)
    stStroke.Color = Color3.fromRGB(28, 34, 56)

    local StatsLayout = Instance.new("UIListLayout", StatsScroll)
    StatsLayout.FillDirection = Enum.FillDirection.Horizontal
    StatsLayout.Padding = UDim.new(0, 6)
    StatsLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local StatPad = Instance.new("UIPadding", StatsScroll)
    StatPad.PaddingLeft = UDim.new(0, 6)
    StatPad.PaddingRight = UDim.new(0, 6)

    local TeamBadges = {}
    local function CreateTeamBadge(parent, icon, name, catKey, baseColor, itemWidth)
        local btn = Instance.new("TextButton", parent)
        btn.Size = UDim2.new(0, itemWidth or 86, 0, 20)
        btn.BackgroundColor3 = Color3.fromRGB(16, 20, 36)
        btn.Text = icon .. " " .. name .. " (0)"
        btn.TextColor3 = baseColor or C.TEXT_M
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 8.5
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
        local bStroke = Instance.new("UIStroke", btn)
        bStroke.Color = Color3.fromRGB(36, 44, 70)

        btn.MouseButton1Click:Connect(function()
            SwitchCategory(catKey)
        end)

        TeamBadges[catKey] = {
            btn = btn,
            stroke = bStroke,
            icon = icon,
            name = name,
            baseColor = baseColor
        }
        return btn
    end

    CreateTeamBadge(StatsScroll, "🐘", "Elephant", "Elephant", Color3.fromRGB(150, 210, 255), 88)
    CreateTeamBadge(StatsScroll, "⚙️", "Machine", "Machine", Color3.fromRGB(255, 185, 100), 84)
    CreateTeamBadge(StatsScroll, "🌙", "Nightmare", "Nightmare", C.PURPLE_L, 94)
    CreateTeamBadge(StatsScroll, "💯", "100 Age", "100 Age", C.CYAN, 86)
    CreateTeamBadge(StatsScroll, "📘", "XP", "XP", Color3.fromRGB(130, 200, 255), 72)
    CreateTeamBadge(StatsScroll, "🧪", "GBXP", "GBXP", Color3.fromRGB(180, 140, 255), 84)

    -- Row Equip Age
    local RowEq = Instance.new("Frame", ThreshBody)
    RowEq.Size = UDim2.new(1, 0, 0, 25)
    RowEq.BackgroundTransparency = 1
    RowEq.LayoutOrder = 2

    local EqLabel = Instance.new("TextLabel", RowEq)
    EqLabel.Position = UDim2.new(0, 4, 0, 0)
    EqLabel.Size = UDim2.new(0.6, 0, 1, 0)
    EqLabel.BackgroundTransparency = 1
    EqLabel.Text = "Equip Age (" .. State.MutasiActiveCategory .. ")"
    EqLabel.TextColor3 = C.TEXT_W
    EqLabel.Font = Enum.Font.GothamMedium
    EqLabel.TextSize = 9.5
    EqLabel.TextXAlignment = Enum.TextXAlignment.Left

    local EqBox = Instance.new("TextBox", RowEq)
    EqBox.Position = UDim2.new(1, -85, 0.5, -12)
    EqBox.Size = UDim2.new(0, 85, 0, 24)
    EqBox.BackgroundColor3 = Color3.fromRGB(16, 20, 36)
    EqBox.Text = tostring(State.MutasiEquipAge)
    EqBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    EqBox.Font = Enum.Font.GothamBold
    EqBox.TextSize = 9.5
    Instance.new("UICorner", EqBox).CornerRadius = UDim.new(0, 6)
    local eqStroke = Instance.new("UIStroke", EqBox)
    eqStroke.Color = Color3.fromRGB(42, 50, 78)

    EqBox:GetPropertyChangedSignal("Text"):Connect(function()
        local num = tonumber(EqBox.Text)
        if num then
            num = math.clamp(num, 0, 500)
            State.MutasiEquipAge = num
            if State.MutasiTeamThresholds[State.MutasiActiveCategory] then
                State.MutasiTeamThresholds[State.MutasiActiveCategory].EquipAge = num
            end
            if State.MutasiActiveCategory == "GBXP" and updateTeamBadgesUI then
                updateTeamBadgesUI()
            end
        end
    end)

    -- Row Unequip Age
    local RowUneq = Instance.new("Frame", ThreshBody)
    RowUneq.Size = UDim2.new(1, 0, 0, 25)
    RowUneq.BackgroundTransparency = 1
    RowUneq.LayoutOrder = 3

    local UneqLabel = Instance.new("TextLabel", RowUneq)
    UneqLabel.Position = UDim2.new(0, 4, 0, 0)
    UneqLabel.Size = UDim2.new(0.6, 0, 1, 0)
    UneqLabel.BackgroundTransparency = 1
    UneqLabel.Text = "Unequip Age (" .. State.MutasiActiveCategory .. ")"
    UneqLabel.TextColor3 = C.TEXT_W
    UneqLabel.Font = Enum.Font.GothamMedium
    UneqLabel.TextSize = 9.5
    UneqLabel.TextXAlignment = Enum.TextXAlignment.Left

    local UneqBox = Instance.new("TextBox", RowUneq)
    UneqBox.Position = UDim2.new(1, -85, 0.5, -12)
    UneqBox.Size = UDim2.new(0, 85, 0, 24)
    UneqBox.BackgroundColor3 = Color3.fromRGB(16, 20, 36)
    UneqBox.Text = tostring(State.MutasiUnequipAge)
    UneqBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    UneqBox.Font = Enum.Font.GothamBold
    UneqBox.TextSize = 9.5
    Instance.new("UICorner", UneqBox).CornerRadius = UDim.new(0, 6)
    local unStroke = Instance.new("UIStroke", UneqBox)
    unStroke.Color = Color3.fromRGB(42, 50, 78)

    UneqBox:GetPropertyChangedSignal("Text"):Connect(function()
        local num = tonumber(UneqBox.Text)
        if num then
            num = math.clamp(num, 0, 500)
            State.MutasiUnequipAge = num
            if State.MutasiTeamThresholds[State.MutasiActiveCategory] then
                State.MutasiTeamThresholds[State.MutasiActiveCategory].UnequipAge = num
            end
            if State.MutasiActiveCategory == "GBXP" and updateTeamBadgesUI then
                updateTeamBadgesUI()
            end
        end
    end)

    -- Row Target Mutasi (Machine & Nightmare)
    local RowTargetMut = Instance.new("Frame", ThreshBody)
    RowTargetMut.Size = UDim2.new(1, 0, 0, 25)
    RowTargetMut.BackgroundTransparency = 1
    RowTargetMut.LayoutOrder = 4
    RowTargetMut.Visible = (isMachineActive or isNightmareActive)

    local TargetMutLabel = Instance.new("TextLabel", RowTargetMut)
    TargetMutLabel.Position = UDim2.new(0, 4, 0, 0)
    TargetMutLabel.Size = UDim2.new(0.55, 0, 1, 0)
    TargetMutLabel.BackgroundTransparency = 1
    TargetMutLabel.Text = "Target Mutasi (" .. State.MutasiActiveCategory .. ")"
    TargetMutLabel.TextColor3 = C.TEXT_W
    TargetMutLabel.Font = Enum.Font.GothamMedium
    TargetMutLabel.TextSize = 9.5
    TargetMutLabel.TextXAlignment = Enum.TextXAlignment.Left

    local TargetMutBtn = Instance.new("TextButton", RowTargetMut)
    TargetMutBtn.Position = UDim2.new(1, -135, 0.5, -12)
    TargetMutBtn.Size = UDim2.new(0, 135, 0, 24)
    TargetMutBtn.BackgroundColor3 = Color3.fromRGB(16, 20, 36)
    TargetMutBtn.Text = (isMachineActive and State.MachineTargetMutation or State.NightmareTargetMutation) .. " ▾"
    TargetMutBtn.TextColor3 = C.CYAN
    TargetMutBtn.Font = Enum.Font.GothamBold
    TargetMutBtn.TextSize = 8.5
    Instance.new("UICorner", TargetMutBtn).CornerRadius = UDim.new(0, 6)
    local tmStroke = Instance.new("UIStroke", TargetMutBtn)
    tmStroke.Color = Color3.fromRGB(42, 50, 78)

    -- Popup Dropdown Target Mutasi
    local TargetDropdownPopup = Instance.new("Frame", ParentContainer)
    TargetDropdownPopup.Size = UDim2.new(0, 200, 0, 210)
    TargetDropdownPopup.Position = UDim2.new(0.5, -100, 0.5, -105)
    TargetDropdownPopup.BackgroundColor3 = Color3.fromRGB(11, 14, 28)
    TargetDropdownPopup.ZIndex = 50
    TargetDropdownPopup.Visible = false
    Instance.new("UICorner", TargetDropdownPopup).CornerRadius = UDim.new(0, 8)
    local tdpStroke = Instance.new("UIStroke", TargetDropdownPopup)
    tdpStroke.Color = C.PURPLE
    tdpStroke.Thickness = 1.5

    local TdpHeader = Instance.new("Frame", TargetDropdownPopup)
    TdpHeader.Size = UDim2.new(1, 0, 0, 28)
    TdpHeader.BackgroundColor3 = Color3.fromRGB(18, 22, 42)
    TdpHeader.ZIndex = 51
    Instance.new("UICorner", TdpHeader).CornerRadius = UDim.new(0, 8)

    local TdpTitle = Instance.new("TextLabel", TdpHeader)
    TdpTitle.Position = UDim2.new(0, 10, 0, 0)
    TdpTitle.Size = UDim2.new(1, -38, 1, 0)
    TdpTitle.BackgroundTransparency = 1
    TdpTitle.Text = "PILIH TARGET MUTASI"
    TdpTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    TdpTitle.Font = Enum.Font.GothamBold
    TdpTitle.TextSize = 9
    TdpTitle.TextXAlignment = Enum.TextXAlignment.Left
    TdpTitle.ZIndex = 52

    local TdpClose = Instance.new("TextButton", TdpHeader)
    TdpClose.Position = UDim2.new(1, -24, 0.5, -9)
    TdpClose.Size = UDim2.new(0, 18, 0, 18)
    TdpClose.BackgroundColor3 = Color3.fromRGB(30, 24, 42)
    TdpClose.Text = "✕"
    TdpClose.TextColor3 = Color3.fromRGB(220, 180, 255)
    TdpClose.Font = Enum.Font.GothamBold
    TdpClose.TextSize = 9
    TdpClose.ZIndex = 52
    Instance.new("UICorner", TdpClose).CornerRadius = UDim.new(0, 9)

    local TdpScroll = Instance.new("ScrollingFrame", TargetDropdownPopup)
    TdpScroll.Position = UDim2.new(0, 6, 0, 32)
    TdpScroll.Size = UDim2.new(1, -12, 1, -38)
    TdpScroll.BackgroundTransparency = 1
    TdpScroll.ScrollBarThickness = 3
    TdpScroll.ScrollBarImageColor3 = C.PURPLE
    TdpScroll.ZIndex = 51

    local TdpList = Instance.new("UIListLayout", TdpScroll)
    TdpList.SortOrder = Enum.SortOrder.LayoutOrder
    TdpList.Padding = UDim.new(0, 4)

    local MachineTargetOptions = { "Any Mutation", "Mega", "Transcendent", "Inferno", "Forger", "Oxpecker", "Lion" }
    local NightmareTargetOptions = { "Any Mutation", "Blossoming", "Venom", "Everchanted", "Ember", "Nightmare" }

    local function OpenTargetDropdown()
        for _, c in ipairs(TdpScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end

        local isMach = (State.MutasiActiveCategory == "Machine")
        local list = isMach and MachineTargetOptions or NightmareTargetOptions
        local current = isMach and State.MachineTargetMutation or State.NightmareTargetMutation
        TdpTitle.Text = "TARGET MUTASI (" .. State.MutasiActiveCategory:upper() .. ")"

        for idx, optionName in ipairs(list) do
            local isSel = (optionName == current)
            local itemBtn = Instance.new("TextButton", TdpScroll)
            itemBtn.Size = UDim2.new(1, -4, 0, 26)
            itemBtn.BackgroundColor3 = isSel and Color3.fromRGB(48, 24, 80) or Color3.fromRGB(15, 18, 36)
            itemBtn.Text = (isSel and "✓  " or "   ") .. optionName
            itemBtn.TextColor3 = isSel and C.PURPLE_L or Color3.fromRGB(220, 230, 255)
            itemBtn.Font = isSel and Enum.Font.GothamBold or Enum.Font.GothamMedium
            itemBtn.TextSize = 8.5
            itemBtn.TextXAlignment = Enum.TextXAlignment.Left
            itemBtn.ZIndex = 53
            Instance.new("UICorner", itemBtn).CornerRadius = UDim.new(0, 5)
            local ibStroke = Instance.new("UIStroke", itemBtn)
            ibStroke.Color = isSel and C.PURPLE or Color3.fromRGB(36, 44, 70)

            itemBtn.MouseButton1Click:Connect(function()
                if isMach then
                    State.MachineTargetMutation = optionName
                else
                    State.NightmareTargetMutation = optionName
                end
                TargetMutBtn.Text = optionName .. " ▾"
                TargetDropdownPopup.Visible = false
                updateStatusUI("Target Mutasi " .. State.MutasiActiveCategory .. " diatur ke: " .. optionName, false)
            end)
        end

        TdpScroll.CanvasSize = UDim2.new(0, 0, 0, #list * 30 + 10)
        TargetDropdownPopup.Visible = true
    end

    TargetMutBtn.MouseButton1Click:Connect(function()
        if TargetDropdownPopup.Visible then
            TargetDropdownPopup.Visible = false
        else
            OpenTargetDropdown()
        end
    end)

    TdpClose.MouseButton1Click:Connect(function()
        TargetDropdownPopup.Visible = false
    end)

    -- GBXP Controls
    local RowGBXPMax = Instance.new("Frame", ThreshBody)
    RowGBXPMax.Size = UDim2.new(1, 0, 0, 25)
    RowGBXPMax.BackgroundTransparency = 1
    RowGBXPMax.LayoutOrder = 5
    RowGBXPMax.Visible = isGBXPActive

    local GBXPMaxLabel = Instance.new("TextLabel", RowGBXPMax)
    GBXPMaxLabel.Position = UDim2.new(0, 4, 0, 0)
    GBXPMaxLabel.Size = UDim2.new(0.6, 0, 1, 0)
    GBXPMaxLabel.BackgroundTransparency = 1
    GBXPMaxLabel.Text = "GBXP Max Equip"
    GBXPMaxLabel.TextColor3 = C.TEXT_W
    GBXPMaxLabel.Font = Enum.Font.GothamMedium
    GBXPMaxLabel.TextSize = 9.5
    GBXPMaxLabel.TextXAlignment = Enum.TextXAlignment.Left

    local GBXPMaxBox = Instance.new("TextBox", RowGBXPMax)
    GBXPMaxBox.Position = UDim2.new(1, -85, 0.5, -12)
    GBXPMaxBox.Size = UDim2.new(0, 85, 0, 24)
    GBXPMaxBox.BackgroundColor3 = Color3.fromRGB(16, 20, 36)
    GBXPMaxBox.Text = tostring(State.GBXPMaxEquip)
    GBXPMaxBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    GBXPMaxBox.Font = Enum.Font.GothamBold
    GBXPMaxBox.TextSize = 9.5
    Instance.new("UICorner", GBXPMaxBox).CornerRadius = UDim.new(0, 6)

    GBXPMaxBox:GetPropertyChangedSignal("Text"):Connect(function()
        local num = tonumber(GBXPMaxBox.Text)
        if num and num >= 1 then
            State.GBXPMaxEquip = math.floor(num)
        end
    end)

    local RowGBXPMode = Instance.new("Frame", ThreshBody)
    RowGBXPMode.Size = UDim2.new(1, 0, 0, 25)
    RowGBXPMode.BackgroundTransparency = 1
    RowGBXPMode.LayoutOrder = 6
    RowGBXPMode.Visible = isGBXPActive

    local GBXPModeLabel = Instance.new("TextLabel", RowGBXPMode)
    GBXPModeLabel.Position = UDim2.new(0, 4, 0, 0)
    GBXPModeLabel.Size = UDim2.new(0.6, 0, 1, 0)
    GBXPModeLabel.BackgroundTransparency = 1
    GBXPModeLabel.Text = "GBXP Select Mode"
    GBXPModeLabel.TextColor3 = C.TEXT_W
    GBXPModeLabel.Font = Enum.Font.GothamMedium
    GBXPModeLabel.TextSize = 9.5
    GBXPModeLabel.TextXAlignment = Enum.TextXAlignment.Left

    local GBXPModeBtn = Instance.new("TextButton", RowGBXPMode)
    GBXPModeBtn.Position = UDim2.new(1, -125, 0.5, -12)
    GBXPModeBtn.Size = UDim2.new(0, 125, 0, 24)
    GBXPModeBtn.BackgroundColor3 = Color3.fromRGB(16, 20, 36)
    GBXPModeBtn.Text = tostring(State.GBXPSelectMode) .. " ▾"
    GBXPModeBtn.TextColor3 = (State.GBXPSelectMode == "auto") and C.CYAN or Color3.fromRGB(255, 200, 100)
    GBXPModeBtn.Font = Enum.Font.GothamBold
    GBXPModeBtn.TextSize = 9
    Instance.new("UICorner", GBXPModeBtn).CornerRadius = UDim.new(0, 6)

    GBXPModeBtn.MouseButton1Click:Connect(function()
        if State.GBXPSelectMode == "auto" then
            State.GBXPSelectMode = "manual"
        else
            State.GBXPSelectMode = "auto"
        end
        GBXPModeBtn.Text = tostring(State.GBXPSelectMode) .. " ▾"
        GBXPModeBtn.TextColor3 = (State.GBXPSelectMode == "auto") and C.CYAN or Color3.fromRGB(255, 200, 100)
        if updateTeamBadgesUI then updateTeamBadgesUI() end
        if refreshPetList then refreshPetList() end
    end)

    updateTeamBadgesUI = function()
        local activeCat = State.MutasiActiveCategory
        for catKey, data in pairs(TeamBadges) do
            local selCount = GetTeamSelectedCount(catKey)
            local isActive = (catKey == activeCat)

            data.btn.Text = string.format("%s %s (%d)", data.icon, data.name, selCount)

            if isActive then
                data.btn.BackgroundColor3 = Color3.fromRGB(45, 22, 75)
                data.btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                data.btn.Font = Enum.Font.GothamBold
                data.stroke.Color = C.PURPLE
                data.stroke.Thickness = 1.5
            elseif selCount > 0 then
                data.btn.BackgroundColor3 = Color3.fromRGB(20, 26, 48)
                data.btn.TextColor3 = data.baseColor or Color3.fromRGB(210, 225, 255)
                data.btn.Font = Enum.Font.GothamBold
                data.stroke.Color = Color3.fromRGB(90, 110, 180)
                data.stroke.Thickness = 1
            else
                data.btn.BackgroundColor3 = Color3.fromRGB(14, 18, 32)
                data.btn.TextColor3 = Color3.fromRGB(130, 142, 175)
                data.btn.Font = Enum.Font.GothamMedium
                data.stroke.Color = Color3.fromRGB(30, 36, 56)
                data.stroke.Thickness = 1
            end
        end
    end

    -- =====================================================================
    -- 4. SECTION HEADER: Select Pet (HANYA TIM PET)
    -- =====================================================================
    local PetListHeader = Instance.new("Frame", MutasiWrapper)
    PetListHeader.Size = UDim2.new(1, 0, 0, 20)
    PetListHeader.BackgroundTransparency = 1
    PetListHeader.LayoutOrder = 4
    PetListHeader.Visible = (State.MutasiActiveCategory ~= "Config")

    local ListTitle = Instance.new("TextLabel", PetListHeader)
    ListTitle.Position = UDim2.new(0, 4, 0, 0)
    ListTitle.Size = UDim2.new(1, -8, 1, 0)
    ListTitle.BackgroundTransparency = 1
    ListTitle.Text = "Select Pet " .. State.MutasiActiveCategory .. " Team"
    ListTitle.TextColor3 = C.TEXT_M
    ListTitle.Font = Enum.Font.GothamMedium
    ListTitle.TextSize = 9
    ListTitle.TextXAlignment = Enum.TextXAlignment.Left

    -- =====================================================================
    -- 5. SEARCH BAR (HANYA TIM PET)
    -- =====================================================================
    local SearchBarRow = Instance.new("Frame", MutasiWrapper)
    SearchBarRow.Size = UDim2.new(1, 0, 0, 28)
    SearchBarRow.BackgroundColor3 = Color3.fromRGB(13, 16, 32)
    SearchBarRow.LayoutOrder = 5
    SearchBarRow.Visible = (State.MutasiActiveCategory ~= "Config")
    Instance.new("UICorner", SearchBarRow).CornerRadius = UDim.new(0, 6)
    local sbBoxStroke = Instance.new("UIStroke", SearchBarRow)
    sbBoxStroke.Color = Color3.fromRGB(40, 48, 76)

    local SearchIcon = Instance.new("TextLabel", SearchBarRow)
    SearchIcon.Position = UDim2.new(0, 8, 0, 0)
    SearchIcon.Size = UDim2.new(0, 16, 1, 0)
    SearchIcon.BackgroundTransparency = 1
    SearchIcon.Text = "🔍"
    SearchIcon.TextColor3 = C.TEXT_M
    SearchIcon.Font = Enum.Font.GothamBold
    SearchIcon.TextSize = 11

    local SearchInput = Instance.new("TextBox", SearchBarRow)
    SearchInput.Position = UDim2.new(0, 28, 0, 0)
    SearchInput.Size = UDim2.new(1, -56, 1, 0)
    SearchInput.BackgroundTransparency = 1
    SearchInput.PlaceholderText = "Select Optional / Cari nama pet, KG, atau Age..."
    SearchInput.PlaceholderColor3 = Color3.fromRGB(115, 128, 160)
    SearchInput.Text = State.MutasiSearchQuery or ""
    SearchInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    SearchInput.Font = Enum.Font.GothamMedium
    SearchInput.TextSize = 9
    SearchInput.TextXAlignment = Enum.TextXAlignment.Left
    SearchInput.ClearTextOnFocus = false

    local ClearSearchBtn = Instance.new("TextButton", SearchBarRow)
    ClearSearchBtn.Position = UDim2.new(1, -24, 0.5, -9)
    ClearSearchBtn.Size = UDim2.new(0, 18, 0, 18)
    ClearSearchBtn.BackgroundColor3 = Color3.fromRGB(24, 28, 48)
    ClearSearchBtn.Text = "✕"
    ClearSearchBtn.TextColor3 = Color3.fromRGB(160, 175, 210)
    ClearSearchBtn.Font = Enum.Font.GothamBold
    ClearSearchBtn.TextSize = 9
    ClearSearchBtn.Visible = (SearchInput.Text ~= "")
    Instance.new("UICorner", ClearSearchBtn).CornerRadius = UDim.new(0, 9)

    ClearSearchBtn.MouseButton1Click:Connect(function()
        SearchInput.Text = ""
        State.MutasiSearchQuery = ""
        ClearSearchBtn.Visible = false
        if refreshPetList then refreshPetList() end
    end)

    SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        State.MutasiSearchQuery = SearchInput.Text:lower()
        ClearSearchBtn.Visible = (SearchInput.Text ~= "")
        if refreshPetList then refreshPetList() end
    end)

    -- =====================================================================
    -- 6. SCANNER SISTEM
    -- =====================================================================
    local function IsPetFavorited(uuid, item)
        if not uuid and item then
            uuid = item:GetAttribute("PET_UUID") or item:GetAttribute("UUID") or (item:FindFirstChild("PET_UUID") and item.PET_UUID.Value)
        end
        local sUuid = tostring(uuid or "")
        local stripped = sUuid:gsub("[{}]", "")

        if DataService and sUuid ~= "" then
            local ok, data = pcall(function() return DataService:GetData() end)
            if ok and data and data.PetsData and data.PetsData.PetInventory and data.PetsData.PetInventory.Data then
                local entry = data.PetsData.PetInventory.Data[sUuid] or data.PetsData.PetInventory.Data[stripped]
                if entry and entry.PetData and entry.PetData.IsFavorite ~= nil then
                    return entry.PetData.IsFavorite == true
                end
            end
        end

        if PetsServiceMod and PetsServiceMod.GetPlayerPetData and sUuid ~= "" then
            local ok, info = pcall(function() return PetsServiceMod:GetPlayerPetData(sUuid) end)
            if ok and info and info.PetData and info.PetData.IsFavorite ~= nil then
                return info.PetData.IsFavorite == true
            end
        end

        if item then
            local isFavAttr = item:GetAttribute("IsFavorite") or item:GetAttribute("Favorite") or item:GetAttribute("FAVORITE")
            if isFavAttr == true or isFavAttr == 1 or isFavAttr == "true" then return true end
            local favVal = item:FindFirstChild("IsFavorite") or item:FindFirstChild("Favorite")
            if favVal and (favVal.Value == true or favVal.Value == 1) then return true end
        end
        return false
    end

    GetAllPets = function()
        local pets = {}
        local seenUUIDs = {}
        local equippedMap = {}

        if DataService then
            local ok, data = pcall(function() return DataService:GetData() end)
            if ok and data and data.PetsData and data.PetsData.EquippedPets then
                for _, u in ipairs(data.PetsData.EquippedPets) do
                    local sU = tostring(u)
                    equippedMap[sU] = true
                    equippedMap[sU:gsub("[{}]", "")] = true
                end
            end
        end

        local toolLookup = {}
        local function registerTools(container)
            if not container then return end
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") and not item:FindFirstChild("Item_String") then
                    local u = item:GetAttribute("PET_UUID") or item:GetAttribute("UUID") or (item:FindFirstChild("PET_UUID") and item.PET_UUID.Value)
                    if u then
                        local sU = tostring(u)
                        toolLookup[sU] = item
                        toolLookup[sU:gsub("[{}]", "")] = item
                    end
                end
            end
        end
        if LocalPlayer then
            registerTools(LocalPlayer:FindFirstChild("Backpack"))
            registerTools(LocalPlayer.Character)
        end

        if DataService then
            local ok, data = pcall(function() return DataService:GetData() end)
            if ok and data and data.PetsData and data.PetsData.PetInventory and data.PetsData.PetInventory.Data then
                for uuid, entry in pairs(data.PetsData.PetInventory.Data) do
                    local petData = entry.PetData or {}
                    local rawType = entry.PetType or petData.Species or petData.Name or "Pet"
                    local cleanUUID = tostring(uuid)
                    local strippedUUID = cleanUUID:gsub("[{}]", "")

                    local rawMut = petData.MutationType or "Normal"
                    local mutation = getAutoMutationName(rawMut)
                    local level = tonumber(petData.Level or petData.Lvl or 1) or 1
                    local numWeight = 0
                    local weightStr = "?"

                    if PetUtilities and PetUtilities.CalculateWeight and petData.BaseWeight then
                        local calcW = PetUtilities:CalculateWeight(petData.BaseWeight, level) * 100
                        numWeight = math.round(calcW) / 100
                        weightStr = string.format("%.2f", numWeight)
                    elseif petData.BaseWeight then
                        numWeight = tonumber(petData.BaseWeight) or 0
                        weightStr = tostring(petData.BaseWeight)
                    end

                    local toolObj = toolLookup[cleanUUID] or toolLookup[strippedUUID]
                    local speciesName = rawType
                    if toolObj then
                        local cleanToolName = toolObj.Name:gsub("%s*%[.-%]", ""):gsub("^%s*(.-)%s*$", "%1")
                        if cleanToolName ~= "" and not cleanToolName:lower():find("tool") then
                            speciesName = cleanToolName
                        end
                    end

                    local isFav = (petData.IsFavorite == true) or IsPetFavorited(cleanUUID, toolObj)
                    local isInGarden = (equippedMap[cleanUUID] == true) or (equippedMap[strippedUUID] == true)

                    seenUUIDs[cleanUUID] = true
                    seenUUIDs[strippedUUID] = true

                    table.insert(pets, {
                        UUID = cleanUUID,
                        Name = speciesName,
                        Mutation = mutation,
                        RawMutation = rawMut,
                        Age = level,
                        Weight = weightStr,
                        NumericWeight = numWeight,
                        IsFavorite = isFav,
                        InGarden = isInGarden,
                        Tool = toolObj
                    })
                end
            end
        end

        local function scanFallbackTools(container)
            if not container then return end
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") and not item:FindFirstChild("Item_String") then
                    local u = item:GetAttribute("PET_UUID") or item:GetAttribute("UUID") or (item:FindFirstChild("PET_UUID") and item.PET_UUID.Value) or item.Name
                    local cleanUUID = tostring(u)
                    local strippedUUID = cleanUUID:gsub("[{}]", "")

                    if not seenUUIDs[cleanUUID] and not seenUUIDs[strippedUUID] then
                        seenUUIDs[cleanUUID] = true
                        seenUUIDs[strippedUUID] = true

                        local cleanSpecies = item.Name:gsub("%s*%[.-%]", ""):gsub("^%s*(.-)%s*$", "%1")
                        local weightStr = item.Name:match("%[([%d%.]+)%s*KG%]") or item.Name:match("([%d%.]+)%s*KG") or "?"
                        local age = tonumber(item.Name:match("%[Age%s*(%d+)%]") or item.Name:match("Age%s*(%d+)")) or 1
                        local rawMut = item:GetAttribute("Mutation") or (item.Name:match("%[(.-)%]") or "Normal")
                        local isFav = IsPetFavorited(cleanUUID, item)

                        table.insert(pets, {
                            UUID = cleanUUID,
                            Name = cleanSpecies,
                            Mutation = getAutoMutationName(rawMut),
                            RawMutation = rawMut,
                            Age = age,
                            Weight = weightStr,
                            NumericWeight = tonumber(weightStr) or 0,
                            IsFavorite = isFav,
                            InGarden = false,
                            Tool = item
                        })
                    end
                end
            end
        end
        if LocalPlayer then
            scanFallbackTools(LocalPlayer:FindFirstChild("Backpack"))
            scanFallbackTools(LocalPlayer.Character)
        end

        return pets
    end

    -- =====================================================================
    -- 7. DAFTAR PET SCROLL (TIM PET)
    -- =====================================================================
    local PetListScroll = Instance.new("ScrollingFrame", MutasiWrapper)
    PetListScroll.Size = UDim2.new(1, 0, 0, 145)
    PetListScroll.BackgroundColor3 = Color3.fromRGB(9, 12, 22)
    PetListScroll.ScrollBarThickness = 3
    PetListScroll.ScrollBarImageColor3 = C.PURPLE
    PetListScroll.LayoutOrder = 6
    PetListScroll.Visible = (State.MutasiActiveCategory ~= "Config")
    Instance.new("UICorner", PetListScroll).CornerRadius = UDim.new(0, 8)
    local plsStroke = Instance.new("UIStroke", PetListScroll)
    plsStroke.Color = Color3.fromRGB(30, 36, 60)

    local PlsLayout = Instance.new("UIListLayout", PetListScroll)
    PlsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PlsLayout.Padding = UDim.new(0, 6)
    local PlsPadding = Instance.new("UIPadding", PetListScroll)
    PlsPadding.PaddingTop = UDim.new(0, 8)
    PlsPadding.PaddingBottom = UDim.new(0, 8)
    PlsPadding.PaddingLeft = UDim.new(0, 8)
    PlsPadding.PaddingRight = UDim.new(0, 8)

    -- =====================================================================
    -- 8. WADAH KHUSUS TAB CONFIG (MURNI WEBHOOK + CLEAN MUTASI)
    -- =====================================================================
    local ConfigContainer = Instance.new("ScrollingFrame", MutasiWrapper)
    ConfigContainer.Size = UDim2.new(1, 0, 0, 245)
    ConfigContainer.BackgroundColor3 = Color3.fromRGB(9, 12, 22)
    ConfigContainer.ScrollBarThickness = 3
    ConfigContainer.ScrollBarImageColor3 = C.PURPLE
    ConfigContainer.LayoutOrder = 6
    ConfigContainer.Visible = (State.MutasiActiveCategory == "Config")
    Instance.new("UICorner", ConfigContainer).CornerRadius = UDim.new(0, 8)
    local cfgStroke = Instance.new("UIStroke", ConfigContainer)
    cfgStroke.Color = Color3.fromRGB(45, 52, 85)

    local CfgLayout = Instance.new("UIListLayout", ConfigContainer)
    CfgLayout.SortOrder = Enum.SortOrder.LayoutOrder
    CfgLayout.Padding = UDim.new(0, 8)
    local CfgPadding = Instance.new("UIPadding", ConfigContainer)
    CfgPadding.PaddingTop = UDim.new(0, 10)
    CfgPadding.PaddingBottom = UDim.new(0, 10)
    CfgPadding.PaddingLeft = UDim.new(0, 10)
    CfgPadding.PaddingRight = UDim.new(0, 10)

    -- Header Banner Config
    local CfgHeaderBanner = Instance.new("Frame", ConfigContainer)
    CfgHeaderBanner.Size = UDim2.new(1, 0, 0, 26)
    CfgHeaderBanner.BackgroundColor3 = Color3.fromRGB(16, 20, 38)
    Instance.new("UICorner", CfgHeaderBanner).CornerRadius = UDim.new(0, 6)

    local CfgHeaderTitle = Instance.new("TextLabel", CfgHeaderBanner)
    CfgHeaderTitle.Position = UDim2.new(0, 10, 0, 0)
    CfgHeaderTitle.Size = UDim2.new(1, -20, 1, 0)
    CfgHeaderTitle.BackgroundTransparency = 1
    CfgHeaderTitle.Text = "⚙️ PENGATURAN DISCORD WEBHOOK & CLEAN PET SHARD"
    CfgHeaderTitle.TextColor3 = C.PURPLE_L
    CfgHeaderTitle.Font = Enum.Font.GothamBold
    CfgHeaderTitle.TextSize = 9.5
    CfgHeaderTitle.TextXAlignment = Enum.TextXAlignment.Left

    -- 1. Webhook URL Section
    local WhLabel = Instance.new("TextLabel", ConfigContainer)
    WhLabel.Size = UDim2.new(1, 0, 0, 18)
    WhLabel.BackgroundTransparency = 1
    WhLabel.Text = "🌐 Discord Webhook URL:"
    WhLabel.TextColor3 = C.CYAN
    WhLabel.Font = Enum.Font.GothamBold
    WhLabel.TextSize = 9.5
    WhLabel.TextXAlignment = Enum.TextXAlignment.Left

    local WhRow = Instance.new("Frame", ConfigContainer)
    WhRow.Size = UDim2.new(1, 0, 0, 34)
    WhRow.BackgroundColor3 = Color3.fromRGB(15, 18, 36)
    Instance.new("UICorner", WhRow).CornerRadius = UDim.new(0, 6)
    local wrStroke = Instance.new("UIStroke", WhRow)
    wrStroke.Color = Color3.fromRGB(42, 50, 80)

    local WhBox = Instance.new("TextBox", WhRow)
    WhBox.Position = UDim2.new(0, 10, 0, 0)
    WhBox.Size = UDim2.new(1, -85, 1, 0)
    WhBox.BackgroundTransparency = 1
    WhBox.PlaceholderText = "Paste Discord Webhook URL disini..."
    WhBox.PlaceholderColor3 = Color3.fromRGB(115, 128, 160)
    WhBox.Text = State.MutasiWebhookURL or ""
    WhBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    WhBox.Font = Enum.Font.GothamMedium
    WhBox.TextSize = 8.5
    WhBox.TextXAlignment = Enum.TextXAlignment.Left
    WhBox.ClearTextOnFocus = false

    WhBox:GetPropertyChangedSignal("Text"):Connect(function()
        local cleaned = tostring(WhBox.Text):gsub("%s+", "")
        State.MutasiWebhookURL = cleaned
        if getgenv then getgenv().WebhookUrl = cleaned end
    end)

    local TestWhBtn = Instance.new("TextButton", WhRow)
    TestWhBtn.Position = UDim2.new(1, -70, 0.5, -13)
    TestWhBtn.Size = UDim2.new(0, 62, 0, 26)
    TestWhBtn.BackgroundColor3 = Color3.fromRGB(48, 24, 80)
    TestWhBtn.Text = "TEST"
    TestWhBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    TestWhBtn.Font = Enum.Font.GothamBold
    TestWhBtn.TextSize = 9
    Instance.new("UICorner", TestWhBtn).CornerRadius = UDim.new(0, 5)

    TestWhBtn.MouseButton1Click:Connect(function()
        TestWhBtn.Text = "KIRIM..."
        TestWhBtn.BackgroundColor3 = Color3.fromRGB(90, 45, 130)
        updateStatusUI("Mengirim pesan tes ke Discord Webhook...", true)

        task.spawn(function()
            local payload = {
                username = "ZyloHub Mutasi Bot",
                avatar_url = "https://i.imgur.com/8Qf9GkF.png",
                embeds = {{
                    title = "🔔 Tes Koneksi Discord Webhook Berhasil!",
                    description = "ZyloHub Auto Mutasi telah terhubung aktif dengan Discord Anda dalam mode **Event-Based Realtime**.",
                    color = 9055202,
                    fields = {
                        { name = "👤 Akun Roblox", value = string.format("`%s` (@%s)", LocalPlayer.DisplayName, LocalPlayer.Name), inline = true },
                        { name = "⚡ Status", value = "`CONNECTED & ACTIVE`", inline = true }
                    },
                    footer = { text = "ZyloHub • Auto Mutasi System" },
                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                }}
            }

            local ok, res = SendDiscordWebhookPayload(payload)
            if ok then
                TestWhBtn.Text = "✓ OKE"
                TestWhBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 80)
                updateStatusUI("✓ Pesan tes Discord Webhook berhasil terkirim!", false)
            else
                TestWhBtn.Text = "GAGAL"
                TestWhBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
                updateStatusUI("Gagal kirim Webhook: " .. tostring(res), false)
            end

            task.wait(3)
            TestWhBtn.Text = "TEST"
            TestWhBtn.BackgroundColor3 = Color3.fromRGB(48, 24, 80)
        end)
    end)

    -- 2. TOGGLE NOTIFIKASI WEBHOOK ON/OFF
    local WhToggleRow = Instance.new("Frame", ConfigContainer)
    WhToggleRow.Size = UDim2.new(1, 0, 0, 38)
    WhToggleRow.BackgroundColor3 = Color3.fromRGB(15, 18, 36)
    Instance.new("UICorner", WhToggleRow).CornerRadius = UDim.new(0, 6)
    local wtrStroke = Instance.new("UIStroke", WhToggleRow)
    wtrStroke.Color = Color3.fromRGB(42, 50, 80)

    local WhToggleLabel = Instance.new("TextLabel", WhToggleRow)
    WhToggleLabel.Position = UDim2.new(0, 10, 0, 0)
    WhToggleLabel.Size = UDim2.new(0.72, 0, 1, 0)
    WhToggleLabel.BackgroundTransparency = 1
    WhToggleLabel.Text = "Kirim Notifikasi Kegiatan Mutasi ke Discord (Realtime)"
    WhToggleLabel.TextColor3 = C.TEXT_W
    WhToggleLabel.Font = Enum.Font.GothamMedium
    WhToggleLabel.TextSize = 8.5
    WhToggleLabel.TextXAlignment = Enum.TextXAlignment.Left

    local WhToggleBtn = Instance.new("TextButton", WhToggleRow)
    WhToggleBtn.Position = UDim2.new(1, -70, 0.5, -13)
    WhToggleBtn.Size = UDim2.new(0, 62, 0, 26)
    WhToggleBtn.BackgroundColor3 = State.MutasiWebhookEnabled and Color3.fromRGB(40, 150, 80) or Color3.fromRGB(30, 34, 52)
    WhToggleBtn.Text = State.MutasiWebhookEnabled and "ON" or "OFF"
    WhToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    WhToggleBtn.Font = Enum.Font.GothamBold
    WhToggleBtn.TextSize = 9
    Instance.new("UICorner", WhToggleBtn).CornerRadius = UDim.new(0, 5)

    WhToggleBtn.MouseButton1Click:Connect(function()
        State.MutasiWebhookEnabled = not State.MutasiWebhookEnabled
        WhToggleBtn.Text = State.MutasiWebhookEnabled and "ON" or "OFF"
        WhToggleBtn.BackgroundColor3 = State.MutasiWebhookEnabled and Color3.fromRGB(40, 150, 80) or Color3.fromRGB(30, 34, 52)
        updateStatusUI("Notifikasi Webhook Discord: " .. (State.MutasiWebhookEnabled and "AKTIF" or "NONAKTIF"), false)
    end)

    -- 3. TOGGLE AUTO CLEAN SHARD ON/OFF
    local CleanRow = Instance.new("Frame", ConfigContainer)
    CleanRow.Size = UDim2.new(1, 0, 0, 38)
    CleanRow.BackgroundColor3 = Color3.fromRGB(15, 18, 36)
    Instance.new("UICorner", CleanRow).CornerRadius = UDim.new(0, 6)
    local clStroke = Instance.new("UIStroke", CleanRow)
    clStroke.Color = Color3.fromRGB(42, 50, 80)

    local CleanLabel = Instance.new("TextLabel", CleanRow)
    CleanLabel.Position = UDim2.new(0, 10, 0, 0)
    CleanLabel.Size = UDim2.new(0.72, 0, 1, 0)
    CleanLabel.BackgroundTransparency = 1
    CleanLabel.Text = "Auto Clean Shard jika Target Mutasi Belum Tercapai"
    CleanLabel.TextColor3 = C.TEXT_W
    CleanLabel.Font = Enum.Font.GothamMedium
    CleanLabel.TextSize = 8.5
    CleanLabel.TextXAlignment = Enum.TextXAlignment.Left

    local CleanToggleBtn = Instance.new("TextButton", CleanRow)
    CleanToggleBtn.Position = UDim2.new(1, -70, 0.5, -13)
    CleanToggleBtn.Size = UDim2.new(0, 62, 0, 26)
    CleanToggleBtn.BackgroundColor3 = State.AutoCleanIfNotTarget and Color3.fromRGB(40, 150, 80) or Color3.fromRGB(30, 34, 52)
    CleanToggleBtn.Text = State.AutoCleanIfNotTarget and "ON" or "OFF"
    CleanToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CleanToggleBtn.Font = Enum.Font.GothamBold
    CleanToggleBtn.TextSize = 9
    Instance.new("UICorner", CleanToggleBtn).CornerRadius = UDim.new(0, 5)

    CleanToggleBtn.MouseButton1Click:Connect(function()
        State.AutoCleanIfNotTarget = not State.AutoCleanIfNotTarget
        CleanToggleBtn.Text = State.AutoCleanIfNotTarget and "ON" or "OFF"
        CleanToggleBtn.BackgroundColor3 = State.AutoCleanIfNotTarget and Color3.fromRGB(40, 150, 80) or Color3.fromRGB(30, 34, 52)
        updateStatusUI("Auto Clean Shard: " .. (State.AutoCleanIfNotTarget and "AKTIF" or "NONAKTIF"), false)
    end)

    -- Info Card
    local InfoCard = Instance.new("Frame", ConfigContainer)
    InfoCard.Size = UDim2.new(1, 0, 0, 50)
    InfoCard.BackgroundColor3 = Color3.fromRGB(12, 15, 28)
    Instance.new("UICorner", InfoCard).CornerRadius = UDim.new(0, 6)
    local icStroke = Instance.new("UIStroke", InfoCard)
    icStroke.Color = Color3.fromRGB(30, 38, 62)

    local InfoText = Instance.new("TextLabel", InfoCard)
    InfoText.Position = UDim2.new(0, 10, 0, 6)
    InfoText.Size = UDim2.new(1, -20, 1, -12)
    InfoText.BackgroundTransparency = 1
    InfoText.Text = "💡 Event Realtime Webhook: Saat tombol Webhook ON, setiap ada pengambilan suplai GBXP, kenaikan tahap umur (XP/Elephant/100 Age), pet masuk mesin, mutasi sukses, atau pencucian shard akan langsung terkirim ke Discord."
    InfoText.TextColor3 = C.TEXT_M
    InfoText.Font = Enum.Font.GothamMedium
    InfoText.TextSize = 8
    InfoText.TextWrapped = true
    InfoText.TextXAlignment = Enum.TextXAlignment.Left
    InfoText.TextYAlignment = Enum.TextYAlignment.Top

    ConfigContainer.CanvasSize = UDim2.new(0, 0, 0, 230)

    -- =====================================================================
    -- 9. REFRESH DAFTAR PET (TIM PET)
    -- =====================================================================
    refreshPetList = function()
        local activeCat = State.MutasiActiveCategory or "Elephant"
        if activeCat == "Config" then return end

        local isGBXP = (activeCat == "GBXP")
        if isGBXP then
            ListTitle.Text = string.format("Gudang Suplai GBXP (Non-Fav, Age %d-%d)", State.MutasiTeamThresholds.GBXP.EquipAge or 0, State.MutasiTeamThresholds.GBXP.UnequipAge or 100)
        else
            ListTitle.Text = "Select Pet " .. activeCat .. " Team (Favorite List)"
        end

        for _, c in ipairs(PetListScroll:GetChildren()) do
            if c:IsA("TextButton") or c:IsA("TextLabel") or c:IsA("Frame") then
                c:Destroy()
            end
        end

        if updateTeamBadgesUI then updateTeamBadgesUI() end

        local allPets = GetAllPets()
        local filtered = {}
        local minGBAge = State.MutasiTeamThresholds.GBXP.EquipAge or 0
        local maxGBAge = State.MutasiTeamThresholds.GBXP.UnequipAge or 500

        for _, p in ipairs(allPets) do
            local matchesRule = false
            if isGBXP then
                if not p.IsFavorite then
                    if p.Age >= minGBAge and p.Age <= maxGBAge then
                        matchesRule = true
                    end
                end
            else
                matchesRule = (p.IsFavorite == true)
            end

            if matchesRule then
                local matchesSearch = true
                if State.MutasiSearchQuery and State.MutasiSearchQuery ~= "" then
                    local q = State.MutasiSearchQuery
                    local nLow = p.Name:lower()
                    local mLow = p.Mutation:lower()
                    local aStr = tostring(p.Age)
                    local wStr = tostring(p.Weight):lower()
                    if not (nLow:find(q, 1, true) or mLow:find(q, 1, true) or aStr:find(q, 1, true) or wStr:find(q, 1, true)) then
                        matchesSearch = false
                    end
                end

                if matchesSearch then
                    table.insert(filtered, p)
                end
            end
        end

        local teamMap = State.MutasiSelectedTeams[activeCat] or {}

        table.sort(filtered, function(a, b)
            local aSel = (teamMap[a.UUID] == true) or (teamMap[tostring(a.UUID):gsub("[{}]", "")] == true)
            local bSel = (teamMap[b.UUID] == true) or (teamMap[tostring(b.UUID):gsub("[{}]", "")] == true)
            if isGBXP and State.GBXPSelectMode == "auto" then
                aSel = true
                bSel = true
            end
            if aSel ~= bSel then return aSel == true end
            if a.Age ~= b.Age then return a.Age > b.Age end
            return a.Name < b.Name
        end)

        local count = 0
        for idx, pet in ipairs(filtered) do
            count = count + 1
            local cleanUUID = pet.UUID
            local isSelected = (teamMap[cleanUUID] == true) or (teamMap[tostring(cleanUUID):gsub("[{}]", "")] == true)
            local isAutoMode = (isGBXP and State.GBXPSelectMode == "auto")

            local itemBtn = Instance.new("TextButton", PetListScroll)
            itemBtn.Size = UDim2.new(1, 0, 0, 28)
            itemBtn.LayoutOrder = (isSelected or isAutoMode) and idx or (1000 + idx)
            Instance.new("UICorner", itemBtn).CornerRadius = UDim.new(0, 6)
            local iStroke = Instance.new("UIStroke", itemBtn)

            if isAutoMode then
                itemBtn.BackgroundColor3 = Color3.fromRGB(45, 24, 76)
                itemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                itemBtn.Font = Enum.Font.GothamBold
                itemBtn.TextSize = 8.5
                iStroke.Color = Color3.fromRGB(150, 75, 235)
                iStroke.Thickness = 1.2
                itemBtn.Text = string.format("[SUPLAI AUTO] [%s] %s | Age %s | %s KG", pet.Mutation, pet.Name, tostring(pet.Age), tostring(pet.Weight))
            elseif isSelected then
                itemBtn.BackgroundColor3 = Color3.fromRGB(56, 22, 98)
                itemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                itemBtn.Font = Enum.Font.GothamBold
                itemBtn.TextSize = 8.5
                iStroke.Color = Color3.fromRGB(168, 85, 247)
                iStroke.Thickness = 1.5

                local favTag = pet.IsFavorite and "⭐" or "🧪"
                itemBtn.Text = string.format("[✓ TERPILIH] %s [%s] %s | Age %s | %s KG", favTag, pet.Mutation, pet.Name, tostring(pet.Age), tostring(pet.Weight))
            else
                itemBtn.BackgroundColor3 = Color3.fromRGB(13, 17, 32)
                itemBtn.TextColor3 = Color3.fromRGB(210, 218, 240)
                itemBtn.Font = Enum.Font.GothamMedium
                itemBtn.TextSize = 8.5
                iStroke.Color = Color3.fromRGB(34, 40, 64)
                iStroke.Thickness = 1

                local favTag = pet.IsFavorite and "⭐ " or ""
                itemBtn.Text = string.format("%s[%s] %s | Age %s | %s KG", favTag, pet.Mutation, pet.Name, tostring(pet.Age), tostring(pet.Weight))
            end

            itemBtn.MouseButton1Click:Connect(function()
                if isGBXP and State.GBXPSelectMode == "auto" then
                    updateStatusUI("[GBXP Auto]: Gudang suplai otomatis memilih pet non-fav umur " .. minGBAge .. "-" .. maxGBAge, false)
                    return
                end

                local newSel = not isSelected
                teamMap[cleanUUID] = newSel
                teamMap[tostring(cleanUUID):gsub("[{}]", "")] = newSel
                State.MutasiSelectedTeams[activeCat] = teamMap

                if updateTeamBadgesUI then updateTeamBadgesUI() end
                refreshPetList()
            end)
        end

        if count == 0 then
            local empty = Instance.new("TextLabel", PetListScroll)
            empty.Size = UDim2.new(1, 0, 1, 0)
            empty.BackgroundTransparency = 1
            if isGBXP then
                empty.Text = string.format("Tidak ada pet Non-Fav di gudang dengan rentang umur %d - %d.", minGBAge, maxGBAge)
            else
                empty.Text = "Belum ada pet FAVORITE di kategori ini. Beri bintang pada pet di game terlebih dahulu!"
            end
            empty.TextColor3 = C.TEXT_M
            empty.Font = Enum.Font.GothamMedium
            empty.TextSize = 8.5
            empty.TextWrapped = true
            PetListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        else
            PetListScroll.CanvasSize = UDim2.new(0, 0, 0, count * 32 + 12)
        end
    end

    -- =====================================================================
    -- 10. TOMBOL AKSI BAWAH (START, STOP, MODE)
    -- =====================================================================
    local ActionRow = Instance.new("Frame", MutasiWrapper)
    ActionRow.Size = UDim2.new(1, 0, 0, 32)
    ActionRow.BackgroundTransparency = 1
    ActionRow.LayoutOrder = 7
    ActionRow.Visible = (State.MutasiActiveCategory ~= "Config")

    local ActLayout = Instance.new("UIListLayout", ActionRow)
    ActLayout.FillDirection = Enum.FillDirection.Horizontal
    ActLayout.Padding = UDim.new(0, 8)
    ActLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    ActLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local StartBtn = Instance.new("TextButton", ActionRow)
    StartBtn.Size = UDim2.new(0.42, -5, 0, 30)
    StartBtn.BackgroundColor3 = Color3.fromRGB(15, 18, 36)
    StartBtn.Text = "⚡ START"
    StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    StartBtn.Font = Enum.Font.GothamBold
    StartBtn.TextSize = 9.5
    Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 15)
    local startStroke = Instance.new("UIStroke", StartBtn)
    startStroke.Color = C.PURPLE
    startStroke.Thickness = 1.5

    updateActionButton = function()
        if not State.MutasiRunning then
            StartBtn.BackgroundColor3 = Color3.fromRGB(15, 18, 36)
            StartBtn.Text = "⚡ START"
        end
    end

    local StopBtn = Instance.new("TextButton", ActionRow)
    StopBtn.Size = UDim2.new(0.34, -5, 0, 30)
    StopBtn.BackgroundColor3 = Color3.fromRGB(15, 18, 36)
    StopBtn.Text = "STOP"
    StopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    StopBtn.Font = Enum.Font.GothamBold
    StopBtn.TextSize = 9.5
    Instance.new("UICorner", StopBtn).CornerRadius = UDim.new(0, 15)
    local stopStroke = Instance.new("UIStroke", StopBtn)
    stopStroke.Color = Color3.fromRGB(50, 58, 88)
    stopStroke.Thickness = 1.5

    local ModeBtn = Instance.new("TextButton", ActionRow)
    ModeBtn.Size = UDim2.new(0.24, -5, 0, 30)
    ModeBtn.BackgroundColor3 = Color3.fromRGB(15, 18, 36)
    ModeBtn.Text = State.MutasiMode .. " ▾"
    ModeBtn.TextColor3 = C.CYAN
    ModeBtn.Font = Enum.Font.GothamBold
    ModeBtn.TextSize = 9
    Instance.new("UICorner", ModeBtn).CornerRadius = UDim.new(0, 15)
    local modeStroke = Instance.new("UIStroke", ModeBtn)
    modeStroke.Color = Color3.fromRGB(50, 58, 88)
    modeStroke.Thickness = 1.5

    -- =====================================================================
    -- 11. GANTI KATEGORI
    -- =====================================================================
    SwitchCategory = function(catName)
        State.MutasiActiveCategory = catName
        local isGB = (catName == "GBXP")
        local isMach = (catName == "Machine")
        local isNight = (catName == "Nightmare")
        local isConfig = (catName == "Config")

        for cName, data in pairs(CategoryButtons) do
            local isActive = (cName == catName)
            data.btn.BackgroundColor3 = isActive and Color3.fromRGB(48, 24, 80) or Color3.fromRGB(15, 18, 34)
            data.btn.TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or C.TEXT_M
            data.stroke.Color = isActive and C.PURPLE or Color3.fromRGB(38, 45, 70)
            data.stroke.Thickness = isActive and 1.5 or 1
        end

        ThreshHeader.Visible = not isConfig
        ThreshBody.Visible = not isConfig and isThreshOpen
        PetListHeader.Visible = not isConfig
        SearchBarRow.Visible = not isConfig
        PetListScroll.Visible = not isConfig
        ActionRow.Visible = not isConfig

        ConfigContainer.Visible = isConfig

        RowGBXPMax.Visible = isGB
        RowGBXPMode.Visible = isGB
        RowTargetMut.Visible = (isMach or isNight)

        if isMach or isNight then
            TargetMutLabel.Text = "Target Mutasi (" .. catName .. ")"
            TargetMutBtn.Text = (isMach and State.MachineTargetMutation or State.NightmareTargetMutation) .. " ▾"
        end

        local h = 88
        if isGB then h = 148
        elseif isMach or isNight then h = 118 end
        ThreshBody.Size = UDim2.new(1, 0, 0, h)

        if not isConfig and State.MutasiTeamThresholds[catName] then
            State.MutasiEquipAge = State.MutasiTeamThresholds[catName].EquipAge
            State.MutasiUnequipAge = State.MutasiTeamThresholds[catName].UnequipAge
            EqBox.Text = tostring(State.MutasiEquipAge)
            UneqBox.Text = tostring(State.MutasiUnequipAge)
            EqLabel.Text = "Equip Age (" .. catName .. ")"
            UneqLabel.Text = "Unequip Age (" .. catName .. ")"
        end

        if updateThresholdTitle then updateThresholdTitle() end
        if updateTeamBadgesUI then updateTeamBadgesUI() end
        if updateActionButton then updateActionButton() end
        if refreshPetList and not isConfig then refreshPetList() end
    end

    task.defer(function()
        if updateTeamBadgesUI then updateTeamBadgesUI() end
        refreshPetList()
    end)

    -- =====================================================================
    -- 12. STATUS BAR
    -- =====================================================================
    local StatusBar = Instance.new("Frame", MutasiWrapper)
    StatusBar.Size = UDim2.new(1, 0, 0, 24)
    StatusBar.BackgroundColor3 = Color3.fromRGB(11, 14, 28)
    StatusBar.LayoutOrder = 8
    Instance.new("UICorner", StatusBar).CornerRadius = UDim.new(0, 6)
    local sbStroke = Instance.new("UIStroke", StatusBar)
    sbStroke.Color = Color3.fromRGB(38, 46, 75)

    local StatusDot = Instance.new("TextLabel", StatusBar)
    StatusDot.Position = UDim2.new(0, 8, 0, 0)
    StatusDot.Size = UDim2.new(0, 14, 1, 0)
    StatusDot.BackgroundTransparency = 1
    StatusDot.Text = "●"
    StatusDot.TextColor3 = Color3.fromRGB(140, 155, 190)
    StatusDot.Font = Enum.Font.GothamBold
    StatusDot.TextSize = 10

    local StatusLabel = Instance.new("TextLabel", StatusBar)
    StatusLabel.Position = UDim2.new(0, 24, 0, 0)
    StatusLabel.Size = UDim2.new(1, -30, 1, 0)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "[STATUS]: " .. State.MutasiStatusText
    StatusLabel.TextColor3 = C.TEXT_W
    StatusLabel.Font = Enum.Font.GothamMedium
    StatusLabel.TextSize = 8.5
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.TextTruncate = Enum.TextTruncate.AtEnd

    updateStatusUI = function(text, isRunning)
        State.MutasiStatusText = text or State.MutasiStatusText
        StatusLabel.Text = "[STATUS]: " .. State.MutasiStatusText
        if isRunning then
            StatusDot.TextColor3 = Color3.fromRGB(0, 235, 140)
            sbStroke.Color = C.PURPLE
        else
            StatusDot.TextColor3 = Color3.fromRGB(140, 155, 190)
            sbStroke.Color = Color3.fromRGB(38, 46, 75)
        end
    end

    -- =====================================================================
    -- 13. MODAL POPUP SELECTOR (MODE A - F)
    -- =====================================================================
    local ModePopup = Instance.new("Frame", ParentContainer)
    ModePopup.Size = UDim2.new(1, 0, 0, 235)
    ModePopup.Position = UDim2.new(0, 0, 1, -268)
    ModePopup.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
    ModePopup.ZIndex = 40
    ModePopup.Visible = false
    Instance.new("UICorner", ModePopup).CornerRadius = UDim.new(0, 8)
    local mpStroke = Instance.new("UIStroke", ModePopup)
    mpStroke.Color = C.PURPLE
    mpStroke.Thickness = 1.5

    local MpHeader = Instance.new("Frame", ModePopup)
    MpHeader.Size = UDim2.new(1, 0, 0, 28)
    MpHeader.BackgroundColor3 = Color3.fromRGB(16, 20, 38)
    MpHeader.ZIndex = 41
    Instance.new("UICorner", MpHeader).CornerRadius = UDim.new(0, 8)

    local MpTitle = Instance.new("TextLabel", MpHeader)
    MpTitle.Position = UDim2.new(0, 10, 0, 0)
    MpTitle.Size = UDim2.new(1, -40, 1, 0)
    MpTitle.BackgroundTransparency = 1
    MpTitle.Text = "PILIH MODE PIPELINE MUTASI"
    MpTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    MpTitle.Font = Enum.Font.GothamBold
    MpTitle.TextSize = 9.5
    MpTitle.TextXAlignment = Enum.TextXAlignment.Left
    MpTitle.ZIndex = 42

    local MpClose = Instance.new("TextButton", MpHeader)
    MpClose.Position = UDim2.new(1, -26, 0.5, -10)
    MpClose.Size = UDim2.new(0, 20, 0, 20)
    MpClose.BackgroundColor3 = Color3.fromRGB(28, 20, 36)
    MpClose.Text = "✕"
    MpClose.TextColor3 = Color3.fromRGB(220, 180, 255)
    MpClose.Font = Enum.Font.GothamBold
    MpClose.TextSize = 10
    MpClose.ZIndex = 42
    Instance.new("UICorner", MpClose).CornerRadius = UDim.new(0, 10)

    local MpScroll = Instance.new("ScrollingFrame", ModePopup)
    MpScroll.Position = UDim2.new(0, 6, 0, 32)
    MpScroll.Size = UDim2.new(1, -12, 1, -38)
    MpScroll.BackgroundTransparency = 1
    MpScroll.ScrollBarThickness = 3
    MpScroll.ScrollBarImageColor3 = C.PURPLE
    MpScroll.ZIndex = 41
    MpScroll.CanvasSize = UDim2.new(0, 0, 0, 290)

    local MpList = Instance.new("UIListLayout", MpScroll)
    MpList.SortOrder = Enum.SortOrder.LayoutOrder
    MpList.Padding = UDim.new(0, 5)

    local PipelineModes = {
        { id = "Mode: A", letter = "MODE A", route = "GBXP > XP > 100 AGE > INVENTORY", stages = { "XP", "100 Age" }, order = 1 },
        { id = "Mode: B", letter = "MODE B", route = "GBXP > XP > NIGHTMARE > INVENTORY", stages = { "XP", "Nightmare" }, order = 2 },
        { id = "Mode: C", letter = "MODE C", route = "GBXP > XP > MACHINE > INVENTORY", stages = { "XP", "Machine" }, order = 3 },
        { id = "Mode: D", letter = "MODE D", route = "GBXP > XP > ELEPHANT > 100 AGE > INVENTORY", stages = { "XP", "Elephant", "100 Age" }, order = 4 },
        { id = "Mode: E", letter = "MODE E", route = "GBXP > XP > ELEPHANT > NIGHTMARE > 100 AGE > INVENTORY", stages = { "XP", "Elephant", "Nightmare", "100 Age" }, order = 5 },
        { id = "Mode: F", letter = "MODE F", route = "GBXP > XP > ELEPHANT > MACHINE > 100 AGE > INVENTORY", stages = { "XP", "Elephant", "Machine", "100 Age" }, order = 6 }
    }

    local ModeItemElements = {}
    local function updateModeSelectionUI()
        ModeBtn.Text = State.MutasiMode .. (ModePopup.Visible and " ▴" or " ▾")
        for mId, elem in pairs(ModeItemElements) do
            local isSelected = (State.MutasiMode == mId)
            elem.btn.BackgroundColor3 = isSelected and Color3.fromRGB(48, 24, 80) or Color3.fromRGB(15, 18, 34)
            elem.stroke.Color = isSelected and C.PURPLE or Color3.fromRGB(38, 45, 70)
            elem.stroke.Thickness = isSelected and 1.5 or 1
            elem.title.TextColor3 = isSelected and C.PURPLE_L or C.TEXT_W
            elem.check.Visible = isSelected
        end
    end

    for _, m in ipairs(PipelineModes) do
        local mBtn = Instance.new("TextButton", MpScroll)
        mBtn.Size = UDim2.new(1, -4, 0, 42)
        mBtn.BackgroundColor3 = (State.MutasiMode == m.id) and Color3.fromRGB(48, 24, 80) or Color3.fromRGB(15, 18, 34)
        mBtn.Text = ""
        mBtn.AutoButtonColor = false
        mBtn.LayoutOrder = m.order
        mBtn.ZIndex = 42
        Instance.new("UICorner", mBtn).CornerRadius = UDim.new(0, 6)
        local mStroke = Instance.new("UIStroke", mBtn)
        mStroke.Color = (State.MutasiMode == m.id) and C.PURPLE or Color3.fromRGB(38, 45, 70)

        local mLblTitle = Instance.new("TextLabel", mBtn)
        mLblTitle.Position = UDim2.new(0, 8, 0, 3)
        mLblTitle.Size = UDim2.new(1, -40, 0, 13)
        mLblTitle.BackgroundTransparency = 1
        mLblTitle.Text = m.letter .. ": (" .. m.route .. ")"
        mLblTitle.TextColor3 = (State.MutasiMode == m.id) and C.PURPLE_L or C.TEXT_W
        mLblTitle.Font = Enum.Font.GothamBold
        mLblTitle.TextSize = 8.5
        mLblTitle.TextXAlignment = Enum.TextXAlignment.Left
        mLblTitle.ZIndex = 43

        local mLblDesc = Instance.new("TextLabel", mBtn)
        mLblDesc.Position = UDim2.new(0, 8, 0, 18)
        mLblDesc.Size = UDim2.new(1, -40, 0, 20)
        mLblDesc.BackgroundTransparency = 1
        mLblDesc.Text = "Jalur estafet otomatis rombongan pet"
        mLblDesc.TextColor3 = C.TEXT_M
        mLblDesc.Font = Enum.Font.GothamMedium
        mLblDesc.TextSize = 8
        mLblDesc.TextXAlignment = Enum.TextXAlignment.Left
        mLblDesc.ZIndex = 43

        local mCheck = Instance.new("TextLabel", mBtn)
        mCheck.Position = UDim2.new(1, -24, 0.5, -8)
        mCheck.Size = UDim2.new(0, 16, 0, 16)
        mCheck.BackgroundTransparency = 1
        mCheck.Text = "✓"
        mCheck.TextColor3 = C.CYAN
        mCheck.Font = Enum.Font.GothamBold
        mCheck.TextSize = 11
        mCheck.Visible = (State.MutasiMode == m.id)
        mCheck.ZIndex = 43

        ModeItemElements[m.id] = { btn = mBtn, stroke = mStroke, title = mLblTitle, check = mCheck }

        mBtn.MouseButton1Click:Connect(function()
            State.MutasiMode = m.id
            ModePopup.Visible = false
            updateModeSelectionUI()
        end)
    end

    ModeBtn.MouseButton1Click:Connect(function()
        ModePopup.Visible = not ModePopup.Visible
        updateModeSelectionUI()
    end)
    MpClose.MouseButton1Click:Connect(function()
        ModePopup.Visible = false
        updateModeSelectionUI()
    end)

    -- =====================================================================
    -- 14. GAME ACTIONS & MESIN MUTASI
    -- =====================================================================
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

    UnequipPetByUUID = function(uuid)
        if not uuid then return end
        local sUuid = tostring(uuid)
        local stripped = sUuid:gsub("[{}]", "")

        local farm = GetFarm()
        local petArea = farm and farm:FindFirstChild("PetArea")
        if petArea then
            for _, obj in ipairs(petArea:GetChildren()) do
                local objUUID = obj:GetAttribute("UUID") or obj:GetAttribute("PET_UUID")
                if objUUID and (tostring(objUUID) == sUuid or tostring(objUUID):gsub("[{}]", "") == stripped) then
                    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then
                        prompt.HoldDuration = 0
                        prompt.RequiresLineOfSight = false
                        pcall(function() fireproximityprompt(prompt) end)
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

    EquipPetByUUID = function(uuid, targetCF)
        if not uuid then return end
        local petArea = GetFarmPetArea()
        local targetPos = targetCF or (petArea and petArea.CFrame + Vector3.new(0, 2, 0)) or (LocalPlayer.Character and LocalPlayer.Character:GetPivot()) or CFrame.new(0, 5, 0)

        if PetsServiceMod and PetsServiceMod.EquipPet then
            pcall(function() PetsServiceMod:EquipPet(uuid, targetPos) end)
            pcall(function() PetsServiceMod:EquipPet(tostring(uuid):gsub("[{}]", ""), targetPos) end)
        end
        if PetsServiceRemote then
            pcall(function() PetsServiceRemote:FireServer("EquipPet", uuid, targetPos) end)
            pcall(function() PetsServiceRemote:FireServer("EquipPet", tostring(uuid):gsub("[{}]", ""), targetPos) end)
        end
    end

    RecallAllPetsFromFarm = function()
        local farm = GetFarm()
        local petArea = farm and farm:FindFirstChild("PetArea")
        if petArea then
            for _, obj in ipairs(petArea:GetChildren()) do
                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    prompt.HoldDuration = 0
                    prompt.RequiresLineOfSight = false
                    pcall(function() fireproximityprompt(prompt) end)
                end
                local objUUID = obj:GetAttribute("UUID") or obj:GetAttribute("PET_UUID")
                if objUUID then UnequipPetByUUID(objUUID) end
            end
        end

        local allPets = GetAllPets()
        for _, p in ipairs(allPets) do
            if p.InGarden then UnequipPetByUUID(p.UUID) end
        end
    end

    EquipSupportPets = function(teamName)
        local teamMap = State.MutasiSelectedTeams[teamName] or {}
        local allPets = GetAllPets()
        local petLookup = {}
        for _, p in ipairs(allPets) do
            petLookup[p.UUID] = p
            petLookup[tostring(p.UUID):gsub("[{}]", "")] = p
        end

        for u, isSel in pairs(teamMap) do
            if isSel == true then
                local p = petLookup[u] or petLookup[tostring(u):gsub("[{}]", "")]
                if p and not p.InGarden then
                    EquipPetByUUID(p.UUID)
                    task.wait(0.15)
                end
            end
        end
    end

    UnequipSupportPets = function(teamName)
        local teamMap = State.MutasiSelectedTeams[teamName] or {}
        for u, isSel in pairs(teamMap) do
            if isSel == true then
                UnequipPetByUUID(u)
                task.wait(0.1)
            end
        end
    end

    GetMutationMachineInstance = function()
        if CollectionService then
            local tagged = CollectionService:GetTagged("PetMutationMachine")
            if tagged and #tagged > 0 then return tagged[1] end
        end
        local npcs = workspace:FindFirstChild("NPCS")
        local mach = npcs and npcs:FindFirstChild("PetMutationMachine")
        if mach then return mach end
        return workspace:FindFirstChild("PetMutationMachine", true)
    end

    local function AutoClickMachineConfirmButton()
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not pGui then return false end

        for _, gui in ipairs(pGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Enabled then
                for _, desc in ipairs(gui:GetDescendants()) do
                    if desc:IsA("TextButton") or desc:IsA("ImageButton") then
                        local btnText = (desc:IsA("TextButton") and desc.Text) or desc.Name
                        if tostring(btnText):lower():find("confirm") or tostring(desc.Name):lower():find("confirm") then
                            pcall(function()
                                if desc.Visible then
                                    if desc.MouseButton1Click then
                                        for _, con in pairs(getconnections(desc.MouseButton1Click)) do con:Fire() end
                                    end
                                    if desc.Activated then
                                        for _, con in pairs(getconnections(desc.Activated)) do con:Fire() end
                                    end
                                end
                            end)
                            return true
                        end
                    end
                end
            end
        end
        return false
    end

    local function IsMachinePetReady()
        if DataService then
            local ok, data = pcall(function() return DataService:GetData() end)
            if ok and data then
                if data.PetMutationMachineData and data.PetMutationMachineData.PetReady ~= nil then
                    return data.PetMutationMachineData.PetReady == true
                end
                if data.PetReady ~= nil then return data.PetReady == true end
            end
        end

        local machine = GetMutationMachineInstance()
        if machine then
            for _, desc in ipairs(machine:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Visible then
                    local txt = desc.Text:lower()
                    if txt:find("ready") or txt:find("claim") or txt:find("selesai") then return true end
                end
                if desc:IsA("ProximityPrompt") and desc.Enabled then
                    local act = desc.ActionText:lower()
                    if act:find("claim") or act:find("take") or act:find("ambil") or act:find("collect") then return true end
                end
            end
        end
        return false
    end

    -- =====================================================================
    -- 15. AUTOMATION RUNNER ENGINE
    -- =====================================================================
    local runnerThread = nil

    local function StopAutoPipeline()
        State.MutasiRunning = false
        if runnerThread then
            task.cancel(runnerThread)
            runnerThread = nil
        end
        StartBtn.BackgroundColor3 = Color3.fromRGB(
