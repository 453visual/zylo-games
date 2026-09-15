-- =========================================================================
--  ZYLOHUB - AUTO MUTASI MODULE (OFFICIAL EXTENSION)
--  Repository: zylo-games/PetMutasiModule.lua
--  Theme: Deep Obsidian Black (#070912) & Cosmic Purple (#8A2BE2)
--  No Yellow Color - Pure ZyloHub Clean Aesthetics
-- =========================================================================

return function(ParentContainer, State, ZyloLib, Main)
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
    local C = ZyloLib.Colors

    -- Inisialisasi State Mutasi
    State.MutasiActiveCategory = State.MutasiActiveCategory or "Nightmare"
    State.MutasiEquipAge = State.MutasiEquipAge or 20
    State.MutasiUnequipAge = State.MutasiUnequipAge or 0
    State.MutasiMode = State.MutasiMode or "Mode: A"
    State.MutasiRunning = State.MutasiRunning or false
    State.MutasiSelectedPets = State.MutasiSelectedPets or {}
    State.MutasiSearchQuery = State.MutasiSearchQuery or ""

    -- Container Utama di dalam Accordion Auto Mutasi
    local MutasiWrapper = Instance.new("Frame", ParentContainer)
    MutasiWrapper.Size = UDim2.new(1, 0, 0, 480)
    MutasiWrapper.BackgroundTransparency = 1

    local MutasiLayout = Instance.new("UIListLayout", MutasiWrapper)
    MutasiLayout.SortOrder = Enum.SortOrder.LayoutOrder
    MutasiLayout.Padding = UDim.new(0, 6)

    -- =====================================================================
    -- 1. SUB-NAVIGASI KATEGORI (Nightmare | 100 Age | XP | GBXP | Config)
    -- =====================================================================
    local NavRow = Instance.new("ScrollingFrame", MutasiWrapper)
    NavRow.Size = UDim2.new(1, 0, 0, 30)
    NavRow.BackgroundTransparency = 1
    NavRow.ScrollBarThickness = 0
    NavRow.CanvasSize = UDim2.new(0, 380, 0, 0)
    NavRow.LayoutOrder = 1

    local NavList = Instance.new("UIListLayout", NavRow)
    NavList.FillDirection = Enum.FillDirection.Horizontal
    NavList.Padding = UDim.new(0, 6)

    local Categories = {
        { id = "Nightmare", name = "🌙 Nightmare" },
        { id = "100 Age",   name = "💯 100 Age" },
        { id = "XP",        name = "🧊 XP" },
        { id = "GBXP",      name = "🧪 GBXP" },
        { id = "Config",    name = "⚙️ Config" }
    }

    local CategoryButtons = {}
    local refreshPetList -- forward declaration

    for _, cat in ipairs(Categories) do
        local btn = Instance.new("TextButton", NavRow)
        btn.Size = UDim2.new(0, 70, 0, 26)
        btn.BackgroundColor3 = (State.MutasiActiveCategory == cat.id) and C.PURPLE or C.CARD_2
        btn.Text = cat.name
        btn.TextColor3 = (State.MutasiActiveCategory == cat.id) and Color3.fromRGB(255, 255, 255) or C.TEXT_M
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 8.5
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        local stroke = Instance.new("UIStroke", btn)
        stroke.Color = (State.MutasiActiveCategory == cat.id) and C.PURPLE_L or Color3.fromRGB(45, 52, 80)

        CategoryButtons[cat.id] = { btn = btn, stroke = stroke }

        btn.MouseButton1Click:Connect(function()
            State.MutasiActiveCategory = cat.id
            for id, data in pairs(CategoryButtons) do
                local isActive = (id == cat.id)
                data.btn.BackgroundColor3 = isActive and C.PURPLE or C.CARD_2
                data.btn.TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or C.TEXT_M
                data.stroke.Color = isActive and C.PURPLE_L or Color3.fromRGB(45, 52, 80)
            end
            if refreshPetList then refreshPetList() end
        end)
    end

    -- =====================================================================
    -- 2. STATUS BADGES / CHIPS (Ringkasan Total Pet Terdeteksi)
    -- =====================================================================
    local BadgeRow = Instance.new("Frame", MutasiWrapper)
    BadgeRow.Size = UDim2.new(1, 0, 0, 24)
    BadgeRow.BackgroundTransparency = 1
    BadgeRow.LayoutOrder = 2

    local BadgeLayout = Instance.new("UIListLayout", BadgeRow)
    BadgeLayout.FillDirection = Enum.FillDirection.Horizontal
    BadgeLayout.Padding = UDim.new(0, 5)

    local function CreateBadge(parent, icon, title, initialVal, accentColor)
        local bg = Instance.new("Frame", parent)
        bg.Size = UDim2.new(0.24, -4, 1, 0)
        bg.BackgroundColor3 = Color3.fromRGB(12, 16, 32)
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 5)
        local strk = Instance.new("UIStroke", bg)
        strk.Color = Color3.fromRGB(35, 42, 68)

        local lbl = Instance.new("TextLabel", bg)
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = icon .. " " .. title .. " (" .. tostring(initialVal) .. ")"
        lbl.TextColor3 = accentColor or C.TEXT_M
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 8
        return lbl
    end

    local badgeNM   = CreateBadge(BadgeRow, "🌙", "NM", 0, C.PURPLE_L)
    local badge100  = CreateBadge(BadgeRow, "💯", "100", 0, C.CYAN)
    local badgeXP   = CreateBadge(BadgeRow, "🧊", "XP", 0, Color3.fromRGB(130, 200, 255))
    local badgeGBXP = CreateBadge(BadgeRow, "🧪", "GBXP", 0, Color3.fromRGB(180, 140, 255))

    -- =====================================================================
    -- 3. COLLAPSIBLE THRESHOLD AGE & SETTINGS (BISA DI-HIDE / TAMPILKAN)
    -- =====================================================================
    local ThreshHeader = Instance.new("TextButton", MutasiWrapper)
    ThreshHeader.Size = UDim2.new(1, 0, 0, 32)
    ThreshHeader.BackgroundColor3 = Color3.fromRGB(14, 18, 36)
    ThreshHeader.Text = ""
    ThreshHeader.LayoutOrder = 3
    Instance.new("UICorner", ThreshHeader).CornerRadius = UDim.new(0, 6)
    local thStroke = Instance.new("UIStroke", ThreshHeader)
    thStroke.Color = Color3.fromRGB(45, 55, 85)

    local thTitle = Instance.new("TextLabel", ThreshHeader)
    thTitle.Position = UDim2.new(0, 10, 0, 0)
    thTitle.Size = UDim2.new(0.8, 0, 1, 0)
    thTitle.BackgroundTransparency = 1
    thTitle.Text = "( " .. State.MutasiActiveCategory .. " Team ) Threshold Age & Settings"
    thTitle.TextColor3 = C.TEXT_W
    thTitle.Font = Enum.Font.GothamBold
    thTitle.TextSize = 9
    thTitle.TextXAlignment = Enum.TextXAlignment.Left

    local thArrow = Instance.new("TextLabel", ThreshHeader)
    thArrow.Position = UDim2.new(1, -26, 0, 0)
    thArrow.Size = UDim2.new(0, 20, 1, 0)
    thArrow.BackgroundTransparency = 1
    thArrow.Text = "▼"
    thArrow.TextColor3 = C.PURPLE_L
    thArrow.Font = Enum.Font.GothamBold
    thArrow.TextSize = 9

    -- Body Threshold yang bisa di Hide / Tampilkan
    local ThreshBody = Instance.new("Frame", MutasiWrapper)
    ThreshBody.Size = UDim2.new(1, 0, 0, 78)
    ThreshBody.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
    ThreshBody.LayoutOrder = 4
    ThreshBody.Visible = true
    Instance.new("UICorner", ThreshBody).CornerRadius = UDim.new(0, 6)
    local tbStroke = Instance.new("UIStroke", ThreshBody)
    tbStroke.Color = Color3.fromRGB(35, 42, 65)

    -- Toggle Hide/Show Interaksi
    local isThreshOpen = true
    ThreshHeader.MouseButton1Click:Connect(function()
        isThreshOpen = not isThreshOpen
        ThreshBody.Visible = isThreshOpen
        thArrow.Text = isThreshOpen and "▼" or "▶"
    end)

    -- Row 1: Equip Age
    local RowEq = Instance.new("Frame", ThreshBody)
    RowEq.Position = UDim2.new(0, 10, 0, 8)
    RowEq.Size = UDim2.new(1, -20, 0, 28)
    RowEq.BackgroundTransparency = 1

    local EqLabel = Instance.new("TextLabel", RowEq)
    EqLabel.Size = UDim2.new(0.6, 0, 1, 0)
    EqLabel.BackgroundTransparency = 1
    EqLabel.Text = "Equip Age"
    EqLabel.TextColor3 = C.TEXT
    EqLabel.Font = Enum.Font.GothamMedium
    EqLabel.TextSize = 9
    EqLabel.TextXAlignment = Enum.TextXAlignment.Left

    local EqBox = Instance.new("TextBox", RowEq)
    EqBox.Position = UDim2.new(1, -80, 0.5, -12)
    EqBox.Size = UDim2.new(0, 80, 0, 24)
    EqBox.BackgroundColor3 = Color3.fromRGB(18, 22, 42)
    EqBox.Text = tostring(State.MutasiEquipAge)
    EqBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    EqBox.Font = Enum.Font.GothamBold
    EqBox.TextSize = 9
    Instance.new("UICorner", EqBox).CornerRadius = UDim.new(0, 5)
    local eqStroke = Instance.new("UIStroke", EqBox)
    eqStroke.Color = Color3.fromRGB(50, 60, 90)

    EqBox:GetPropertyChangedSignal("Text"):Connect(function()
        local num = tonumber(EqBox.Text)
        if num then State.MutasiEquipAge = num end
    end)

    -- Row 2: Unequip Age
    local RowUneq = Instance.new("Frame", ThreshBody)
    RowUneq.Position = UDim2.new(0, 10, 0, 42)
    RowUneq.Size = UDim2.new(1, -20, 0, 28)
    RowUneq.BackgroundTransparency = 1

    local UneqLabel = Instance.new("TextLabel", RowUneq)
    UneqLabel.Size = UDim2.new(0.6, 0, 1, 0)
    UneqLabel.BackgroundTransparency = 1
    UneqLabel.Text = "Unequip Age"
    UneqLabel.TextColor3 = C.TEXT
    UneqLabel.Font = Enum.Font.GothamMedium
    UneqLabel.TextSize = 9
    UneqLabel.TextXAlignment = Enum.TextXAlignment.Left

    local UneqBox = Instance.new("TextBox", RowUneq)
    UneqBox.Position = UDim2.new(1, -80, 0.5, -12)
    UneqBox.Size = UDim2.new(0, 80, 0, 24)
    UneqBox.BackgroundColor3 = Color3.fromRGB(18, 22, 42)
    UneqBox.Text = tostring(State.MutasiUnequipAge)
    UneqBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    UneqBox.Font = Enum.Font.GothamBold
    UneqBox.TextSize = 9
    Instance.new("UICorner", UneqBox).CornerRadius = UDim.new(0, 5)
    local unStroke = Instance.new("UIStroke", UneqBox)
    unStroke.Color = Color3.fromRGB(50, 60, 90)

    UneqBox:GetPropertyChangedSignal("Text"):Connect(function()
        local num = tonumber(UneqBox.Text)
        if num then State.MutasiUnequipAge = num end
    end)

    -- =====================================================================
    -- 4. DAFTAR PET / PET SELECTOR (THEME ZYLOHUB - DEEP OBSIDIAN & PURPLE)
    -- =====================================================================
    local PetListHeader = Instance.new("Frame", MutasiWrapper)
    PetListHeader.Size = UDim2.new(1, 0, 0, 26)
    PetListHeader.BackgroundTransparency = 1
    PetListHeader.LayoutOrder = 5

    local ListTitle = Instance.new("TextLabel", PetListHeader)
    ListTitle.Position = UDim2.new(0, 4, 0, 0)
    ListTitle.Size = UDim2.new(0.6, 0, 1, 0)
    ListTitle.BackgroundTransparency = 1
    ListTitle.Text = "Select Pet Mutasi Team (Favorite / Backpack)"
    ListTitle.TextColor3 = C.TEXT_M
    ListTitle.Font = Enum.Font.GothamMedium
    ListTitle.TextSize = 8.5
    ListTitle.TextXAlignment = Enum.TextXAlignment.Left

    local SearchPetBox = Instance.new("TextBox", PetListHeader)
    SearchPetBox.Position = UDim2.new(1, -120, 0, 0)
    SearchPetBox.Size = UDim2.new(0, 120, 1, 0)
    SearchPetBox.BackgroundColor3 = Color3.fromRGB(14, 18, 36)
    SearchPetBox.PlaceholderText = "🔍 Search pet..."
    SearchPetBox.PlaceholderColor3 = C.TEXT_M
    SearchPetBox.Text = ""
    SearchPetBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    SearchPetBox.Font = Enum.Font.GothamMedium
    SearchPetBox.TextSize = 8.5
    Instance.new("UICorner", SearchPetBox).CornerRadius = UDim.new(0, 5)
    local spbStroke = Instance.new("UIStroke", SearchPetBox)
    spbStroke.Color = Color3.fromRGB(45, 52, 78)

    local PetListScroll = Instance.new("ScrollingFrame", MutasiWrapper)
    PetListScroll.Size = UDim2.new(1, 0, 0, 175)
    PetListScroll.BackgroundColor3 = Color3.fromRGB(8, 11, 22)
    PetListScroll.ScrollBarThickness = 3
    PetListScroll.ScrollBarImageColor3 = C.PURPLE
    PetListScroll.LayoutOrder = 6
    Instance.new("UICorner", PetListScroll).CornerRadius = UDim.new(0, 8)
    local plsStroke = Instance.new("UIStroke", PetListScroll)
    plsStroke.Color = Color3.fromRGB(25, 32, 54)

    local PlsLayout = Instance.new("UIListLayout", PetListScroll)
    PlsLayout.Padding = UDim.new(0, 4)
    local PlsPadding = Instance.new("UIPadding", PetListScroll)
    PlsPadding.PaddingTop = UDim.new(0, 6)
    PlsPadding.PaddingBottom = UDim.new(0, 6)
    PlsPadding.PaddingLeft = UDim.new(0, 6)
    PlsPadding.PaddingRight = UDim.new(0, 6)

    -- Fungsi membaca pet dari Backpack
    local function GetBackpackPets()
        local pets = {}
        local bp = LocalPlayer:FindFirstChild("Backpack")
        local char = LocalPlayer.Character
        local function scan(container)
            if not container then return end
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") and (tool:FindFirstChild("PetData") or tool.Name:lower():find("pet") or tool:GetAttribute("Pet")) then
                    local pName = tool.Name:gsub("%[.-%]", ""):gsub("^%s*(.-)%s*$", "%1")
                    local mutation = tool:GetAttribute("Mutation") or (tool.Name:match("%[(.-)%]") or "Normal")
                    local age = tool:GetAttribute("Age") or tonumber(tool.Name:match("Age%s*(%d+)")) or 1
                    local weight = tool:GetAttribute("Weight") or tonumber(tool.Name:match("(%d+%.?%d*)%s*KG")) or 5.0
                    local uuid = tool:GetAttribute("UUID") or tool.Name

                    table.insert(pets, {
                        UUID = uuid,
                        Name = pName,
                        Mutation = mutation,
                        Age = age,
                        Weight = weight,
                        Tool = tool
                    })
                end
            end
        end
        scan(bp)
        scan(char)
        return pets
    end

    refreshPetList = function()
        for _, c in ipairs(PetListScroll:GetChildren()) do
            if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
        end

        local pets = GetBackpackPets()
        local q = State.MutasiSearchQuery:lower()
        local count = 0

        -- Update badges counter
        local cNM, c100, cXP, cGBXP = 0, 0, 0, 0
        for _, p in ipairs(pets) do
            local mLow = p.Mutation:lower()
            if mLow:find("nightmare") or mLow:find("mutasi") then cNM = cNM + 1 end
            if p.Age >= 100 then c100 = c100 + 1 end
            if mLow:find("xp") and not mLow:find("gbxp") then cXP = cXP + 1 end
            if mLow:find("gbxp") then cGBXP = cGBXP + 1 end
        end
        badgeNM.Text = "🌙 NM (" .. cNM .. ")"
        badge100.Text = "💯 100 (" .. c100 .. ")"
        badgeXP.Text = "🧊 XP (" .. cXP .. ")"
        badgeGBXP.Text = "🧪 GBXP (" .. cGBXP .. ")"

        for _, pet in ipairs(pets) do
            local fullName = string.format("[%s] %s | Age %s | %.2f KG", pet.Mutation, pet.Name, tostring(pet.Age), pet.Weight)
            if q == "" or fullName:lower():find(q) then
                count = count + 1
                local isSelected = State.MutasiSelectedPets[pet.UUID] or false

                local itemBtn = Instance.new("TextButton", PetListScroll)
                itemBtn.Size = UDim2.new(1, 0, 0, 30)
                -- PENGGANTI WARNA KUNING: Menggunakan Dark Obsidian Purple Theme ZyloHub
                itemBtn.BackgroundColor3 = isSelected and Color3.fromRGB(48, 24, 78) or Color3.fromRGB(15, 19, 36)
                itemBtn.Text = ""
                Instance.new("UICorner", itemBtn).CornerRadius = UDim.new(0, 6)
                local iStroke = Instance.new("UIStroke", itemBtn)
                iStroke.Color = isSelected and C.PURPLE or Color3.fromRGB(35, 42, 65)
                iStroke.Thickness = isSelected and 1.5 or 1

                -- Tag Mutasi
                local tagLbl = Instance.new("TextLabel", itemBtn)
                tagLbl.Position = UDim2.new(0, 8, 0, 0)
                tagLbl.Size = UDim2.new(0.25, 0, 1, 0)
                tagLbl.BackgroundTransparency = 1
                tagLbl.Text = "[" .. pet.Mutation .. "]"
                tagLbl.TextColor3 = isSelected and Color3.fromRGB(220, 180, 255) or C.PURPLE_L
                tagLbl.Font = Enum.Font.GothamBold
                tagLbl.TextSize = 8.5
                tagLbl.TextXAlignment = Enum.TextXAlignment.Left

                -- Nama Pet
                local nameLbl = Instance.new("TextLabel", itemBtn)
                nameLbl.Position = UDim2.new(0.26, 5, 0, 0)
                nameLbl.Size = UDim2.new(0.42, -5, 1, 0)
                nameLbl.BackgroundTransparency = 1
                nameLbl.Text = pet.Name
                nameLbl.TextColor3 = C.TEXT_W
                nameLbl.Font = Enum.Font.GothamBold
                nameLbl.TextSize = 8.5
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

                -- Info Age & KG
                local infoLbl = Instance.new("TextLabel", itemBtn)
                infoLbl.Position = UDim2.new(0.68, 0, 0, 0)
                infoLbl.Size = UDim2.new(0.24, 0, 1, 0)
                infoLbl.BackgroundTransparency = 1
                infoLbl.Text = string.format("Age %s | %.1fKG", tostring(pet.Age), pet.Weight)
                infoLbl.TextColor3 = isSelected and C.CYAN or C.TEXT_M
                infoLbl.Font = Enum.Font.Gotham
                infoLbl.TextSize = 8
                infoLbl.TextXAlignment = Enum.TextXAlignment.Right

                -- Checkmark Indicator
                local checkLbl = Instance.new("TextLabel", itemBtn)
                checkLbl.Position = UDim2.new(1, -22, 0, 0)
                checkLbl.Size = UDim2.new(0, 18, 1, 0)
                checkLbl.BackgroundTransparency = 1
                checkLbl.Text = isSelected and "✓" or "○"
                checkLbl.TextColor3 = isSelected and C.PURPLE_L or C.TEXT_M
                checkLbl.Font = Enum.Font.GothamBold
                checkLbl.TextSize = 10

                itemBtn.MouseButton1Click:Connect(function()
                    State.MutasiSelectedPets[pet.UUID] = not State.MutasiSelectedPets[pet.UUID]
                    refreshPetList()
                end)
            end
        end

        if count == 0 then
            local empty = Instance.new("TextLabel", PetListScroll)
            empty.Size = UDim2.new(1, 0, 1, 0)
            empty.BackgroundTransparency = 1
            empty.Text = (q ~= "") and "Tidak ada pet yang cocok dengan '" .. q .. "'" or "Belum ada pet terdeteksi di Backpack."
            empty.TextColor3 = C.TEXT_M
            empty.Font = Enum.Font.GothamMedium
            empty.TextSize = 8.5
            PetListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        else
            PetListScroll.CanvasSize = UDim2.new(0, 0, 0, count * 34 + 12)
        end
    end

    SearchPetBox:GetPropertyChangedSignal("Text"):Connect(function()
        State.MutasiSearchQuery = SearchPetBox.Text
        refreshPetList()
    end)

    task.defer(refreshPetList)

    -- =====================================================================
    -- 5. ACTION BUTTONS (START, STOP, MODE SELECTOR)
    -- =====================================================================
    local ActionRow = Instance.new("Frame", MutasiWrapper)
    ActionRow.Size = UDim2.new(1, 0, 0, 32)
    ActionRow.BackgroundTransparency = 1
    ActionRow.LayoutOrder = 7

    -- Tombol Start
    local StartBtn = Instance.new("TextButton", ActionRow)
    StartBtn.Position = UDim2.new(0, 0, 0, 0)
    StartBtn.Size = UDim2.new(0.42, 0, 1, 0)
    StartBtn.BackgroundColor3 = C.PURPLE
    StartBtn.Text = "⚡ START NM+LVL"
    StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    StartBtn.Font = Enum.Font.GothamBold
    StartBtn.TextSize = 9.5
    Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 6)

    -- Tombol Stop
    local StopBtn = Instance.new("TextButton", ActionRow)
    StopBtn.Position = UDim2.new(0.44, 0, 0, 0)
    StopBtn.Size = UDim2.new(0.32, 0, 1, 0)
    StopBtn.BackgroundColor3 = Color3.fromRGB(28, 20, 34)
    StopBtn.Text = "⏹ STOP NM+LVL"
    StopBtn.TextColor3 = Color3.fromRGB(255, 120, 140)
    StopBtn.Font = Enum.Font.GothamBold
    StopBtn.TextSize = 9
    Instance.new("UICorner", StopBtn).CornerRadius = UDim.new(0, 6)
    local stStroke = Instance.new("UIStroke", StopBtn)
    stStroke.Color = Color3.fromRGB(60, 30, 45)

    -- Tombol Mode: A / Mode: B
    local ModeBtn = Instance.new("TextButton", ActionRow)
    ModeBtn.Position = UDim2.new(0.78, 0, 0, 0)
    ModeBtn.Size = UDim2.new(0.22, 0, 1, 0)
    ModeBtn.BackgroundColor3 = Color3.fromRGB(18, 22, 42)
    ModeBtn.Text = State.MutasiMode
    ModeBtn.TextColor3 = C.CYAN
    ModeBtn.Font = Enum.Font.GothamBold
    ModeBtn.TextSize = 9
    Instance.new("UICorner", ModeBtn).CornerRadius = UDim.new(0, 6)
    local mbStroke = Instance.new("UIStroke", ModeBtn)
    mbStroke.Color = Color3.fromRGB(45, 55, 85)

    ModeBtn.MouseButton1Click:Connect(function()
        if State.MutasiMode == "Mode: A" then
            State.MutasiMode = "Mode: B"
        else
            State.MutasiMode = "Mode: A"
        end
        ModeBtn.Text = State.MutasiMode
    end)

    StartBtn.MouseButton1Click:Connect(function()
        State.MutasiRunning = true
        StartBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
        StartBtn.Text = "ACTIVE (RUNNING...)"
        ZyloLib:Notify("Auto Mutasi", "Memulai proses mutasi (" .. State.MutasiMode .. ")", 2.5)
    end)

    StopBtn.MouseButton1Click:Connect(function()
        State.MutasiRunning = false
        StartBtn.BackgroundColor3 = C.PURPLE
        StartBtn.Text = "⚡ START NM+LVL"
        ZyloLib:Notify("Auto Mutasi", "Proses mutasi dihentikan.", 2)
    end)

    return {
        Refresh = refreshPetList,
        Wrapper = MutasiWrapper
    }
end
