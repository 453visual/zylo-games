-- =========================================================================
--  ZYLOHUB - AUTO MUTASI MODULE (OFFICIAL EXTENSION v3.7.5 - ULTIMATE ENGINE)
--  Repository: zylo-games/PetMutasiModule.lua
--  Theme: Deep Obsidian Black (#070912) & Cosmic Purple (#8A2BE2)
--  Sub-Tabs: Elephant > Machine > Nightmare > 100 Age > XP > GBXP > Config
--  Mode Pipeline: Modal Popup Selector (Mode A - F)
--  Specialized Features:
--    1. Team Status Row Interaktif (Elephant, Machine, Nightmare, 100 Age, XP, GBXP)
--       - Menampilkan JUMLAH PET YANG SUDAH DIPILIH di setiap tim secara real-time
--       - Tombol interaktif: Klik badge tim mana pun untuk langsung berpindah kategori
--       - Indikator visual aktif & bercahaya untuk tim yang memiliki pet terpilih
--    2. Dynamic Thresholds per Team (Equip Age & Unequip Age tersimpan per tim)
--    3. Elephant, Machine, Nightmare, 100 Age, XP: HANYA PET FAVORIT
--    4. GBXP: HANYA PET NON-FAVORIT (Feeder / Leveling Pet)
--    5. Pinned Selected Pets di Urutan Paling Atas dengan UI Pembeda Jelas
--    6. "Select Optional" Search Bar untuk Mencari Pet Cepat Tanpa Scroll Manual
--    7. Runner Engine Resmi Terintegrasi Remote Asli Game & Machine Teleport
-- =========================================================================

return function(ParentContainer, State, ZyloLib, Main)
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
    local C = ZyloLib.Colors

    -- =====================================================================
    -- DATASET KAMUS MUTASI RESMI GAME & REPOSITORI
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
    -- SERVICES & REMOTES RESMI DARI GAME MODULES
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
    -- STATE INISIALISASI
    -- =====================================================================
    State.MutasiActiveCategory = State.MutasiActiveCategory or "Elephant"
    State.MutasiMode = State.MutasiMode or "Mode: A"
    State.MutasiRunning = State.MutasiRunning or false
    State.MutasiSearchQuery = State.MutasiSearchQuery or ""
    State.CompletedPets = State.CompletedPets or {}
    State.MutasiStatusText = "IDLE - Siap Memulai Pipeline"

    -- Threshold Age per Tim (Dapat disesuaikan secara independen)
    State.MutasiTeamThresholds = State.MutasiTeamThresholds or {
        Elephant = { EquipAge = 20, UnequipAge = 0 },
        Machine = { EquipAge = 20, UnequipAge = 0 },
        Nightmare = { EquipAge = 20, UnequipAge = 0 },
        ["100 Age"] = { EquipAge = 100, UnequipAge = 0 },
        XP = { EquipAge = 20, UnequipAge = 0 },
        GBXP = { EquipAge = 20, UnequipAge = 0 },
        Config = { EquipAge = 20, UnequipAge = 0 }
    }

    State.MutasiEquipAge = State.MutasiTeamThresholds[State.MutasiActiveCategory] and State.MutasiTeamThresholds[State.MutasiActiveCategory].EquipAge or 20
    State.MutasiUnequipAge = State.MutasiTeamThresholds[State.MutasiActiveCategory] and State.MutasiTeamThresholds[State.MutasiActiveCategory].UnequipAge or 0

    -- Tabel Seleksi Pet per Tim Kategori
    State.MutasiSelectedTeams = State.MutasiSelectedTeams or {
        Elephant = {},
        Machine = {},
        Nightmare = {},
        ["100 Age"] = {},
        XP = {},
        GBXP = {}
    }
    for _, cat in ipairs({"Elephant", "Machine", "Nightmare", "100 Age", "XP", "GBXP"}) do
        State.MutasiSelectedTeams[cat] = State.MutasiSelectedTeams[cat] or {}
    end

    -- Hitung jumlah pet yang sudah dipilih di dalam tim
    local function GetTeamSelectedCount(catName)
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
    MutasiWrapper.Size = UDim2.new(1, 0, 0, 480)
    MutasiWrapper.BackgroundTransparency = 1

    local MutasiLayout = Instance.new("UIListLayout", MutasiWrapper)
    MutasiLayout.SortOrder = Enum.SortOrder.LayoutOrder
    MutasiLayout.Padding = UDim.new(0, 6)

    -- Forward declarations
    local SwitchCategory
    local updateThresholdTitle
    local updateActionButton
    local refreshPetList
    local updateTeamBadgesUI
    local updateStatusUI

    -- =====================================================================
    -- 1. SUB-NAVIGASI KATEGORI (FULL WIDTH PILLS ROW)
    -- =====================================================================
    local NavRow = Instance.new("Frame", MutasiWrapper)
    NavRow.Size = UDim2.new(1, 0, 0, 28)
    NavRow.BackgroundTransparency = 1
    NavRow.BorderSizePixel = 0
    NavRow.ClipsDescendants = false
    NavRow.LayoutOrder = 1

    local PillsContainer = Instance.new("Frame", NavRow)
    PillsContainer.Size = UDim2.new(1, -32, 1, 0)
    PillsContainer.Position = UDim2.new(0, 0, 0, 0)
    PillsContainer.BackgroundTransparency = 1
    PillsContainer.BorderSizePixel = 0
    PillsContainer.ClipsDescendants = false

    local NavList = Instance.new("UIListLayout", PillsContainer)
    NavList.FillDirection = Enum.FillDirection.Horizontal
    NavList.HorizontalAlignment = Enum.HorizontalAlignment.Left
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
    -- 2. DROPDOWN HEADER: ( [Category] Team ) Threshold Age & Kg
    -- =====================================================================
    local ThreshHeader = Instance.new("TextButton", MutasiWrapper)
    ThreshHeader.Size = UDim2.new(1, 0, 0, 28)
    ThreshHeader.BackgroundColor3 = Color3.fromRGB(13, 16, 32)
    ThreshHeader.Text = ""
    ThreshHeader.LayoutOrder = 2
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
    -- 3. BODY COLLAPSIBLE: TIM BADGES (INTERAKTIF) + THRESHOLD INPUTS
    -- =====================================================================
    local ThreshBody = Instance.new("Frame", MutasiWrapper)
    ThreshBody.Size = UDim2.new(1, 0, 0, 88)
    ThreshBody.BackgroundTransparency = 1
    ThreshBody.LayoutOrder = 3

    local TbLayout = Instance.new("UIListLayout", ThreshBody)
    TbLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TbLayout.Padding = UDim.new(0, 5)

    local isThreshOpen = true
    ThreshHeader.MouseButton1Click:Connect(function()
        isThreshOpen = not isThreshOpen
        ThreshBody.Visible = isThreshOpen
        thArrow.Text = isThreshOpen and "▼" or "▶"
    end)

    -- Row 3A: TIM STATUS ROW DENGAN COUNTER PET TERPILIH & QUICK SWITCH (PERMINTAAN USER)
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
        bStroke.Thickness = 1

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

    -- Row 3B: Equip Age
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
            State.MutasiEquipAge = num
            if State.MutasiTeamThresholds[State.MutasiActiveCategory] then
                State.MutasiTeamThresholds[State.MutasiActiveCategory].EquipAge = num
            end
        end
    end)

    -- Row 3C: Unequip Age
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
            State.MutasiUnequipAge = num
            if State.MutasiTeamThresholds[State.MutasiActiveCategory] then
                State.MutasiTeamThresholds[State.MutasiActiveCategory].UnequipAge = num
            end
        end
    end)

    -- Update visual badges untuk tim yang dipilih (highlight aktif & selected count)
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
    -- 4. SECTION HEADER: Select Pet [Category] Team
    -- =====================================================================
    local PetListHeader = Instance.new("Frame", MutasiWrapper)
    PetListHeader.Size = UDim2.new(1, 0, 0, 20)
    PetListHeader.BackgroundTransparency = 1
    PetListHeader.LayoutOrder = 4

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
    -- 5. "SELECT OPTIONAL" QUICK SEARCH BAR
    -- =====================================================================
    local SearchBarRow = Instance.new("Frame", MutasiWrapper)
    SearchBarRow.Size = UDim2.new(1, 0, 0, 28)
    SearchBarRow.BackgroundColor3 = Color3.fromRGB(13, 16, 32)
    SearchBarRow.LayoutOrder = 5
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
    -- 6. SCANNER SISTEM: IS FAVORITED & GET ALL PETS
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

    local function GetAllPets()
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

        -- 1. Scan DataService Inventory
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

        -- 2. Fallback scan dari Backpack & Character Tools
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
    -- 7. FUNGSI GANTI KATEGORI (SWITCH CATEGORY)
    -- =====================================================================
    SwitchCategory = function(catName)
        State.MutasiActiveCategory = catName

        -- Update tombol pill sub-nav
        for cName, data in pairs(CategoryButtons) do
            local isActive = (cName == catName)
            data.btn.BackgroundColor3 = isActive and Color3.fromRGB(48, 24, 80) or Color3.fromRGB(15, 18, 34)
            data.btn.TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or C.TEXT_M
            data.stroke.Color = isActive and C.PURPLE or Color3.fromRGB(38, 45, 70)
            data.stroke.Thickness = isActive and 1.5 or 1
        end

        -- Update threshold values untuk tim ini
        if State.MutasiTeamThresholds[catName] then
            State.MutasiEquipAge = State.MutasiTeamThresholds[catName].EquipAge
            State.MutasiUnequipAge = State.MutasiTeamThresholds[catName].UnequipAge
        end
        EqBox.Text = tostring(State.MutasiEquipAge)
        UneqBox.Text = tostring(State.MutasiUnequipAge)
        EqLabel.Text = "Equip Age (" .. catName .. ")"
        UneqLabel.Text = "Unequip Age (" .. catName .. ")"

        if updateThresholdTitle then updateThresholdTitle() end
        if updateTeamBadgesUI then updateTeamBadgesUI() end
        if updateActionButton then updateActionButton() end
        if refreshPetList then refreshPetList() end
    end

    -- =====================================================================
    -- 8. DAFTAR PET DENGAN SORTING SELECTED DI ATAS & FILTER SPESIFIK
    --  - Elephant, Machine, Nightmare, 100 Age, XP: HANYA PET FAVORIT
    --  - GBXP: HANYA PET NON-FAVORIT
    --  - Selected Pets ditaruh paling atas dengan UI pembeda jelas
    -- =====================================================================
    local PetListScroll = Instance.new("ScrollingFrame", MutasiWrapper)
    PetListScroll.Size = UDim2.new(1, 0, 0, 145)
    PetListScroll.BackgroundColor3 = Color3.fromRGB(9, 12, 22)
    PetListScroll.ScrollBarThickness = 3
    PetListScroll.ScrollBarImageColor3 = C.PURPLE
    PetListScroll.LayoutOrder = 6
    Instance.new("UICorner", PetListScroll).CornerRadius = UDim.new(0, 8)
    local plsStroke = Instance.new("UIStroke", PetListScroll)
    plsStroke.Color = Color3.fromRGB(30, 36, 60)

    local PlsLayout = Instance.new("UIListLayout", PetListScroll)
    PlsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PlsLayout.Padding = UDim.new(0, 4)
    local PlsPadding = Instance.new("UIPadding", PetListScroll)
    PlsPadding.PaddingTop = UDim.new(0, 6)
    PlsPadding.PaddingBottom = UDim.new(0, 6)
    PlsPadding.PaddingLeft = UDim.new(0, 6)
    PlsPadding.PaddingRight = UDim.new(0, 6)

    refreshPetList = function()
        local activeCat = State.MutasiActiveCategory or "Elephant"
        local isGBXP = (activeCat == "GBXP")

        -- Update judul section header
        if isGBXP then
            ListTitle.Text = "Select Pet GBXP Team (Non-Favorite / Feeder List)"
        elseif activeCat == "Config" then
            ListTitle.Text = "Configuration & Delays"
        else
            ListTitle.Text = "Select Pet " .. activeCat .. " Team (Favorite List)"
        end

        for _, c in ipairs(PetListScroll:GetChildren()) do
            if c:IsA("TextButton") or c:IsA("TextLabel") or c:IsA("Frame") then
                c:Destroy()
            end
        end

        -- Update status counter pada tim badges di row atas
        if updateTeamBadgesUI then updateTeamBadgesUI() end

        if activeCat == "Config" then
            local cfgInfo = Instance.new("TextLabel", PetListScroll)
            cfgInfo.Size = UDim2.new(1, 0, 1, 0)
            cfgInfo.BackgroundTransparency = 1
            cfgInfo.Text = "Pengaturan Otomasi: Gunakan input Equip Age & Unequip Age di atas.\nTekan tab kategori tim untuk memilih daftar pet."
            cfgInfo.TextColor3 = C.TEXT_M
            cfgInfo.Font = Enum.Font.GothamMedium
            cfgInfo.TextSize = 9
            PetListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            return
        end

        local allPets = GetAllPets()

        -- Filter list sesuai tab yang aktif:
        -- Elephant, Nightmare, Machine, 100 Age, XP -> HANYA PET FAVORIT
        -- GBXP -> HANYA PET NON-FAVORIT
        local filtered = {}
        for _, p in ipairs(allPets) do
            local matchesFavoriteRule = false
            if isGBXP then
                matchesFavoriteRule = (p.IsFavorite == false)
            else
                matchesFavoriteRule = (p.IsFavorite == true)
            end

            if matchesFavoriteRule then
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

        -- SORTING: Pet yang SUDAH DIPILIH ditempatkan di PALING ATAS!
        table.sort(filtered, function(a, b)
            local aSel = (teamMap[a.UUID] == true) or (teamMap[tostring(a.UUID):gsub("[{}]", "")] == true)
            local bSel = (teamMap[b.UUID] == true) or (teamMap[tostring(b.UUID):gsub("[{}]", "")] == true)
            if aSel ~= bSel then
                return aSel == true
            end
            if a.Age ~= b.Age then
                return a.Age > b.Age
            end
            return a.Name < b.Name
        end)

        local count = 0
        for idx, pet in ipairs(filtered) do
            count = count + 1
            local cleanUUID = pet.UUID
            local isSelected = (teamMap[cleanUUID] == true) or (teamMap[tostring(cleanUUID):gsub("[{}]", "")] == true)

            local itemBtn = Instance.new("TextButton", PetListScroll)
            itemBtn.Size = UDim2.new(1, 0, 0, 28)
            itemBtn.LayoutOrder = isSelected and idx or (1000 + idx)
            Instance.new("UICorner", itemBtn).CornerRadius = UDim.new(0, 6)

            local iStroke = Instance.new("UIStroke", itemBtn)

            if isSelected then
                itemBtn.BackgroundColor3 = Color3.fromRGB(56, 22, 98) -- Cosmic Glowing Purple
                itemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                itemBtn.Font = Enum.Font.GothamBold
                itemBtn.TextSize = 8.5
                iStroke.Color = Color3.fromRGB(168, 85, 247)
                iStroke.Thickness = 1.5

                local favTag = pet.IsFavorite and "⭐" or "🧪"
                itemBtn.Text = string.format("[✓ TERPILIH] %s [%s] %s | Age %s | %s KG", favTag, pet.Mutation, pet.Name, tostring(pet.Age), tostring(pet.Weight))
            else
                itemBtn.BackgroundColor3 = Color3.fromRGB(13, 17, 32) -- Dark Obsidian Normal
                itemBtn.TextColor3 = Color3.fromRGB(210, 218, 240)
                itemBtn.Font = Enum.Font.GothamMedium
                itemBtn.TextSize = 8.5
                iStroke.Color = Color3.fromRGB(34, 40, 64)
                iStroke.Thickness = 1

                local favTag = pet.IsFavorite and "⭐ " or ""
                itemBtn.Text = string.format("%s[%s] %s | Age %s | %s KG", favTag, pet.Mutation, pet.Name, tostring(pet.Age), tostring(pet.Weight))
            end

            itemBtn.MouseButton1Click:Connect(function()
                local newSel = not isSelected
                teamMap[cleanUUID] = newSel
                teamMap[tostring(cleanUUID):gsub("[{}]", "")] = newSel
                State.MutasiSelectedTeams[activeCat] = teamMap

                -- Update counter pada badge tim di atas secara langsung
                if updateTeamBadgesUI then updateTeamBadgesUI() end
                refreshPetList()
            end)
        end

        if count == 0 then
            local empty = Instance.new("TextLabel", PetListScroll)
            empty.Size = UDim2.new(1, 0, 1, 0)
            empty.BackgroundTransparency = 1
            if isGBXP then
                empty.Text = "Tidak ada pet Non-Favorite yang cocok dengan pencarian."
            else
                empty.Text = "Belum ada pet FAVORITE di kategori ini. Silakan beri bintang/favorit pada pet di inventory game terlebih dahulu!"
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

    task.defer(function()
        if updateTeamBadgesUI then updateTeamBadgesUI() end
        refreshPetList()
    end)

    -- =====================================================================
    -- 9. BOTTOM ACTION BUTTONS: [ ⚡ START ] [ STOP ] [ Mode: A ▾ ]
    -- =====================================================================
    local ActionRow = Instance.new("Frame", MutasiWrapper)
    ActionRow.Size = UDim2.new(1, 0, 0, 32)
    ActionRow.BackgroundTransparency = 1
    ActionRow.LayoutOrder = 7

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
    -- 10. STATUS BAR & ACTIVITY MONITOR
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
    -- 11. MODAL POPUP: MODE PIPELINE SELECTOR
    -- =====================================================================
    local ModePopup = Instance.new("Frame", ParentContainer)
    ModePopup.Size = UDim2.new(1, 0, 0, 235)
    ModePopup.Position = UDim2.new(0, 0, 1, -268)
    ModePopup.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
    ModePopup.BorderSizePixel = 0
    ModePopup.ZIndex = 40
    ModePopup.Visible = false
    Instance.new("UICorner", ModePopup).CornerRadius = UDim.new(0, 8)
    local mpStroke = Instance.new("UIStroke", ModePopup)
    mpStroke.Color = C.PURPLE
    mpStroke.Thickness = 1.5

    local MpHeader = Instance.new("Frame", ModePopup)
    MpHeader.Size = UDim2.new(1, 0, 0, 28)
    MpHeader.BackgroundColor3 = Color3.fromRGB(16, 20, 38)
    MpHeader.BorderSizePixel = 0
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
    MpScroll.BorderSizePixel = 0
    MpScroll.ScrollBarThickness = 3
    MpScroll.ScrollBarImageColor3 = C.PURPLE
    MpScroll.ZIndex = 41
    MpScroll.CanvasSize = UDim2.new(0, 0, 0, 290)

    local MpList = Instance.new("UIListLayout", MpScroll)
    MpList.SortOrder = Enum.SortOrder.LayoutOrder
    MpList.Padding = UDim.new(0, 5)

    local PipelineModes = {
        {
            id = "Mode: A",
            letter = "MODE A",
            route = "GBXP > XP > 100 AGE > INVENTORY FAVORIT",
            desc = "Khusus nge-push pet agar cepat menyentuh Age 100–500.",
            order = 1
        },
        {
            id = "Mode: B",
            letter = "MODE B",
            route = "GBXP > XP > NIGHTMARE > INVENTORY FAVORIT",
            desc = "Khusus pet yang hanya diincar mutasinya secara cepat via skill pet.",
            order = 2
        },
        {
            id = "Mode: C",
            letter = "MODE C",
            route = "GBXP > XP > MACHINE > INVENTORY FAVORIT",
            desc = "Khusus pet yang hanya diincar mutasinya secara cepat via mesin mutasi.",
            order = 3
        },
        {
            id = "Mode: D",
            letter = "MODE D",
            route = "GBXP > XP > ELEPHANT > 100 AGE > INVENTORY FAVORIT",
            desc = "Membangun pet (Base max + Age tinggi).",
            order = 4
        },
        {
            id = "Mode: E",
            letter = "MODE E",
            route = "GBXP > XP > ELEPHANT > NIGHTMARE > 100 AGE > INVENTORY FAVORIT",
            desc = "Membangun pet sempurna dari nol (Base max + Mutasi Skill + Age tinggi).",
            order = 5
        },
        {
            id = "Mode: F",
            letter = "MODE F",
            route = "GBXP > XP > ELEPHANT > MACHINE > 100 AGE > INVENTORY FAVORIT",
            desc = "Membangun pet sempurna dari nol (Base max + Mutasi Mesin + Age tinggi).",
            order = 6
        }
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
        mStroke.Thickness = (State.MutasiMode == m.id) and 1.5 or 1

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
        mLblDesc.Text = m.desc
        mLblDesc.TextColor3 = C.TEXT_M
        mLblDesc.Font = Enum.Font.GothamMedium
        mLblDesc.TextSize = 8
        mLblDesc.TextWrapped = true
        mLblDesc.TextXAlignment = Enum.TextXAlignment.Left
        mLblDesc.TextYAlignment = Enum.TextYAlignment.Top
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

        ModeItemElements[m.id] = {
            btn = mBtn,
            stroke = mStroke,
            title = mLblTitle,
            check = mCheck
        }

        mBtn.MouseButton1Click:Connect(function()
            State.MutasiMode = m.id
            ModePopup.Visible = false
            updateModeSelectionUI()
            print("[ZyloHub] Mode dipilih: " .. m.letter)
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
    -- 12. FUNGSI GAME: FARM, INVENTORY & EQUIP / UNEQUIP
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

    local function UnequipPetByUUID(uuid)
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

    local function EquipPetByUUID(uuid, targetCF)
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

    local function SafeInteractWithMutationMachine(petUUID)
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
        local originalCFrame = character:GetPivot()

        local machine = workspace:FindFirstChild("NPCS") and workspace.NPCS:FindFirstChild("PetMutationMachine")
        if not machine then
            machine = workspace:FindFirstChild("PetMutationMachine", true)
        end
        if not machine then return false end

        local promptPart = machine:FindFirstChild("ProxPromptPart", true) or machine:FindFirstChild("Model", true) or machine.PrimaryPart
        local prompt = machine:FindFirstChildWhichIsA("ProximityPrompt", true)

        local targetCFrame = (promptPart and promptPart.CFrame + Vector3.new(0, 2, 3)) or machine:GetPivot() + Vector3.new(0, 2, 3)

        updateStatusUI("Teleport ke Mesin Mutasi...", true)
        character:PivotTo(targetCFrame)
        task.wait(0.4)

        if prompt then
            prompt.HoldDuration = 0
            prompt.RequiresLineOfSight = false
            pcall(function() fireproximityprompt(prompt) end)
            task.wait(0.3)
        end

        if PetMutationMachineRemote and petUUID then
            pcall(function()
                PetMutationMachineRemote:FireServer("SubmitPet", petUUID)
                PetMutationMachineRemote:FireServer(petUUID)
            end)
        end

        task.wait(0.5)
        updateStatusUI("Kembali ke Kebun...", true)
        character:PivotTo(originalCFrame)
        task.wait(0.3)
        return true
    end

    -- =====================================================================
    -- 13. AUTOMATION RUNNER ENGINE
    -- =====================================================================
    local runnerThread = nil

    local function StopAutoPipeline()
        State.MutasiRunning = false
        if runnerThread then
            task.cancel(runnerThread)
            runnerThread = nil
        end
        StartBtn.BackgroundColor3 = Color3.fromRGB(15, 18, 36)
        StartBtn.Text = "⚡ START"
        updateStatusUI("STOPPED - Pipeline dihentikan.", false)
    end

    -- Equip seluruh pet yang DIPILIH oleh user di tim tertentu
    local function EquipTeamPets(teamName)
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

    local function RunAutoPipeline()
        if runnerThread then task.cancel(runnerThread) end
        runnerThread = task.spawn(function()
            local activeMode = State.MutasiMode or "Mode: A"
            updateStatusUI("Memulai " .. activeMode .. "...", true)
            task.wait(0.5)

            while State.MutasiRunning do
                local allPets = GetAllPets()
                local petLookup = {}
                for _, p in ipairs(allPets) do
                    petLookup[p.UUID] = p
                    petLookup[tostring(p.UUID):gsub("[{}]", "")] = p
                end

                -- Ambil pet target:
                -- Prioritas 1: Pet yang DIPILIH user di tab GBXP
                -- Prioritas 2: Pet non-favorit yang belum selesai
                local targetPet = nil
                local gbxpSelected = State.MutasiSelectedTeams["GBXP"] or {}
                for u, isSel in pairs(gbxpSelected) do
                    if isSel == true and not State.CompletedPets[u] then
                        local p = petLookup[u] or petLookup[tostring(u):gsub("[{}]", "")]
                        if p then
                            targetPet = p
                            break
                        end
                    end
                end

                -- Fallback: Jika tidak ada centang di GBXP, proses pet non-favorit otomatis
                if not targetPet then
                    for _, p in ipairs(allPets) do
                        if not p.IsFavorite and not State.CompletedPets[p.UUID] then
                            local threshold = math.max(tonumber(State.MutasiTeamThresholds["GBXP"] and State.MutasiTeamThresholds["GBXP"].EquipAge) or 20, 100)
                            if activeMode == "Mode: A" and p.Age < threshold then
                                targetPet = p
                                break
                            elseif activeMode == "Mode: B" and p.RawMutation ~= "A" and p.Mutation ~= "Nightmare" then
                                targetPet = p
                                break
                            elseif activeMode == "Mode: C" and p.Mutation == "Normal" then
                                targetPet = p
                                break
                            elseif (activeMode == "Mode: D" or activeMode == "Mode: E" or activeMode == "Mode: F") and p.Age < 100 then
                                targetPet = p
                                break
                            end
                        end
                    end
                end

                if not targetPet then
                    updateStatusUI("Semua pet target selesai atau tidak ada pet non-favorit tersisa.", false)
                    task.wait(3)
                    if not State.MutasiRunning then break end
                else
                    local pName = targetPet.Name or "Pet"
                    local pAge = targetPet.Age or 1
                    local pUuid = targetPet.UUID

                    -- Pasang Pet Team yang Sudah Dipilih oleh User
                    if activeMode == "Mode: A" or activeMode == "Mode: B" or activeMode == "Mode: C" then
                        EquipTeamPets("XP")
                    elseif activeMode == "Mode: D" or activeMode == "Mode: E" or activeMode == "Mode: F" then
                        EquipTeamPets("Elephant")
                        task.wait(0.2)
                        EquipTeamPets("XP")
                    end

                    -- Eksekusi Sesuai Mode Pipeline
                    if activeMode == "Mode: A" then
                        local threshold = math.max(tonumber(State.MutasiTeamThresholds["100 Age"] and State.MutasiTeamThresholds["100 Age"].EquipAge) or 100, 100)
                        updateStatusUI(string.format("[Mode A]: Push Age %s (%d/%d)...", pName, pAge, threshold), true)
                        EquipPetByUUID(pUuid)
                        task.wait(2.5)

                        local refreshed = GetAllPets()
                        for _, rp in ipairs(refreshed) do
                            if rp.UUID == pUuid or tostring(rp.UUID):gsub("[{}]", "") == tostring(pUuid):gsub("[{}]", "") then
                                if rp.Age >= threshold then
                                    updateStatusUI(string.format("[Mode A]: %s Mencapai Age %d! Selesai.", pName, rp.Age), true)
                                    UnequipPetByUUID(pUuid)
                                    State.CompletedPets[pUuid] = true
                                    task.wait(1)
                                end
                                break
                            end
                        end

                    elseif activeMode == "Mode: B" then
                        updateStatusUI(string.format("[Mode B]: Mutasi Nightmare %s (Mut: %s)...", pName, targetPet.Mutation), true)
                        EquipPetByUUID(pUuid)
                        task.wait(2.5)

                        local refreshed = GetAllPets()
                        for _, rp in ipairs(refreshed) do
                            if rp.UUID == pUuid or tostring(rp.UUID):gsub("[{}]", "") == tostring(pUuid):gsub("[{}]", "") then
                                if rp.RawMutation == "A" or rp.Mutation == "Nightmare" then
                                    updateStatusUI(string.format("[Mode B]: SUKSES! %s telah menjadi Nightmare!", pName), true)
                                    UnequipPetByUUID(pUuid)
                                    State.CompletedPets[pUuid] = true
                                    task.wait(1)
                                end
                                break
                            end
                        end

                    elseif activeMode == "Mode: C" then
                        updateStatusUI(string.format("[Mode C]: Memasukkan %s ke Mesin Mutasi...", pName), true)
                        SafeInteractWithMutationMachine(pUuid)
                        task.wait(3)
                        updateStatusUI(string.format("[Mode C]: Menunggu proses mesin untuk %s...", pName), true)
                        task.wait(4)
                        SafeInteractWithMutationMachine(pUuid)
                        UnequipPetByUUID(pUuid)
                        State.CompletedPets[pUuid] = true
                        task.wait(1)

                    elseif activeMode == "Mode: D" then
                        updateStatusUI(string.format("[Mode D]: Push Elephant Base + Age 100 (%s)...", pName), true)
                        EquipPetByUUID(pUuid)
                        task.wait(2.5)

                        local refreshed = GetAllPets()
                        for _, rp in ipairs(refreshed) do
                            if rp.UUID == pUuid or tostring(rp.UUID):gsub("[{}]", "") == tostring(pUuid):gsub("[{}]", "") then
                                if rp.Age >= 100 then
                                    updateStatusUI(string.format("[Mode D]: %s Selesai Base + Age 100!", pName), true)
                                    UnequipPetByUUID(pUuid)
                                    State.CompletedPets[pUuid] = true
                                    task.wait(1)
                                end
                                break
                            end
                        end

                    elseif activeMode == "Mode: E" then
                        updateStatusUI(string.format("[Mode E]: Elephant > Nightmare > Age 100 (%s)...", pName), true)
                        EquipPetByUUID(pUuid)
                        task.wait(2.5)

                        local refreshed = GetAllPets()
                        for _, rp in ipairs(refreshed) do
                            if rp.UUID == pUuid or tostring(rp.UUID):gsub("[{}]", "") == tostring(pUuid):gsub("[{}]", "") then
                                if rp.Age >= 100 and (rp.RawMutation == "A" or rp.Mutation == "Nightmare") then
                                    updateStatusUI(string.format("[Mode E]: Sempurna! %s Nightmare + Age 100!", pName), true)
                                    UnequipPetByUUID(pUuid)
                                    State.CompletedPets[pUuid] = true
                                    task.wait(1)
                                end
                                break
                            end
                        end

                    elseif activeMode == "Mode: F" then
                        updateStatusUI(string.format("[Mode F]: Elephant > Mesin > Age 100 (%s)...", pName), true)
                        SafeInteractWithMutationMachine(pUuid)
                        task.wait(3)
                        EquipPetByUUID(pUuid)
                        task.wait(2.5)

                        local refreshed = GetAllPets()
                        for _, rp in ipairs(refreshed) do
                            if rp.UUID == pUuid or tostring(rp.UUID):gsub("[{}]", "") == tostring(pUuid):gsub("[{}]", "") then
                                if rp.Age >= 100 and rp.Mutation ~= "Normal" then
                                    updateStatusUI(string.format("[Mode F]: Sempurna! %s Mutasi Mesin + Age 100!", pName), true)
                                    UnequipPetByUUID(pUuid)
                                    State.CompletedPets[pUuid] = true
                                    task.wait(1)
                                end
                                break
                            end
                        end
                    end
                end

                if updateTeamBadgesUI then updateTeamBadgesUI() end
                refreshPetList()
                task.wait(1.5)
            end

            updateStatusUI("Pipeline Selesai / Berhenti.", false)
        end)
    end

    StartBtn.MouseButton1Click:Connect(function()
        if State.MutasiRunning then return end
        State.MutasiRunning = true
        StartBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 80)
        StartBtn.Text = "RUNNING (" .. State.MutasiMode .. ")"
        RunAutoPipeline()
    end)

    StopBtn.MouseButton1Click:Connect(function()
        StopAutoPipeline()
    end)

    return {
        Refresh = refreshPetList,
        Wrapper = MutasiWrapper
    }
end
