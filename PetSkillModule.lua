-- =========================================================================
--  ZYLOHUB - PET SKILL MODULE (PNP & PET BOOST)
--  Theme: Deep Obsidian Black (#070912) & Cosmic Purple (#8A2BE2)
--  Sub-fitur di dalam Config: "Pet Skill" (sebelumnya Swap Skill Config)
-- =========================================================================

local PetSkillModule = {}

function PetSkillModule.Init(ParentContainer, State, ZyloLib, MainScreen)
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

    -- Wrapper Frame Utama
    local SkillContainer = Instance.new("Frame")
    SkillContainer.Name = "PetSkillContainer"
    SkillContainer.Size = UDim2.new(1, 0, 0, 0)
    SkillContainer.AutomaticSize = Enum.AutomaticSize.Y
    SkillContainer.BackgroundTransparency = 1
    SkillContainer.Parent = ParentContainer

    local ListLayout = Instance.new("UIListLayout", SkillContainer)
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Padding = UDim.new(0, 10)

    -- =====================================================================
    -- [CARD 1: FITUR PNP (PICK AND PLACE)]
    -- =====================================================================
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

    -- Header PNP
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
    end)
    pnpToggle.Position = UDim2.new(1, -38, 0.5, -9)

    -- Deskripsi Singkat PNP
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

    -- Row 1: Select Pet PNP
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
    btnPetPNP.Text = State.PNP.SelectedPet .. "  v"
    btnPetPNP.TextColor3 = Color3.fromRGB(195, 205, 235)
    btnPetPNP.Font = Enum.Font.GothamBold
    btnPetPNP.TextSize = 8.5
    Instance.new("UICorner", btnPetPNP).CornerRadius = UDim.new(0, 5)
    local bStroke1 = Instance.new("UIStroke", btnPetPNP)
    bStroke1.Color = Color3.fromRGB(45, 55, 85)

    -- Row 2: Delay Detik PNP
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
    boxDelayPNP.Text = tostring(State.PNP.DelaySeconds)
    boxDelayPNP.TextColor3 = C.CYAN
    boxDelayPNP.Font = Enum.Font.GothamBold
    boxDelayPNP.TextSize = 9.5
    Instance.new("UICorner", boxDelayPNP).CornerRadius = UDim.new(0, 5)
    local bStroke2 = Instance.new("UIStroke", boxDelayPNP)
    bStroke2.Color = Color3.fromRGB(45, 55, 85)

    boxDelayPNP:GetPropertyChangedSignal("Text"):Connect(function()
        local val = tonumber(boxDelayPNP.Text)
        if val and val >= 0 then
            State.PNP.DelaySeconds = val
        end
    end)

    -- =====================================================================
    -- [CARD 2: FITUR PET BOOST & TOYS]
    -- =====================================================================
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

    -- Header Pet Boost
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
    end)
    boostToggle.Position = UDim2.new(1, -38, 0.5, -9)

    -- Deskripsi Singkat Pet Boost
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

    -- Row 1: Target Pet
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
    btnPetBoost.Text = State.PetBoost.SelectedPet .. "  v"
    btnPetBoost.TextColor3 = Color3.fromRGB(195, 205, 235)
    btnPetBoost.Font = Enum.Font.GothamBold
    btnPetBoost.TextSize = 8.5
    Instance.new("UICorner", btnPetBoost).CornerRadius = UDim.new(0, 5)
    local bStroke3 = Instance.new("UIStroke", btnPetBoost)
    bStroke3.Color = Color3.fromRGB(45, 55, 85)

    -- Row 2: Select Boost / Toy
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
    btnItemBoost.Text = State.PetBoost.SelectedBoostItem .. "  v"
    btnItemBoost.TextColor3 = Color3.fromRGB(195, 205, 235)
    btnItemBoost.Font = Enum.Font.GothamBold
    btnItemBoost.TextSize = 8.5
    Instance.new("UICorner", btnItemBoost).CornerRadius = UDim.new(0, 5)
    local bStroke4 = Instance.new("UIStroke", btnItemBoost)
    bStroke4.Color = Color3.fromRGB(45, 55, 85)

    return {
        Container = SkillContainer,
        UpdatePetList = function(pets)
            -- Nanti diisi handler dropdown saat daftar pet siap
        end
    }
end

return PetSkillModule
