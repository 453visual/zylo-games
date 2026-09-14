-- =========================================================================
--  ZYLOHUB - PET LEVELING & UPGRADE MODULE (OFFICIAL EXTENSION)
--  Repository: zylo-games/PetLevelingModule.lua
--  Theme: Deep Obsidian Black (#070912) & Cosmic Purple (#8A2BE2)
--  STATUS: DRAFT / PENDING LEVELING ENGINE PROJECT
-- =========================================================================

return function(PagePets, State, ZyloLib, Main)
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

    local C = ZyloLib.Colors

    -- Inisialisasi State Khusus Leveling
    State.AutoLevelUp = State.AutoLevelUp or false
    State.TargetLevel = State.TargetLevel or 50
    State.LevelSelectedPetsOnly = (State.LevelSelectedPetsOnly ~= nil) and State.LevelSelectedPetsOnly or true

    -- Accordion UI Pet Leveling di Tab Pets
    local accLevel, bodyLevel = ZyloLib:CreateAccordion(PagePets, "Pet Leveling & Training", false, 140)

    -- Row 1: Auto Level Toggle
    local rowAutoLvl = Instance.new("Frame", bodyLevel)
    rowAutoLvl.Size = UDim2.new(1, -24, 0, 30)
    rowAutoLvl.Position = UDim2.new(0, 12, 0, 6)
    rowAutoLvl.BackgroundColor3 = C.CARD_2
    Instance.new("UICorner", rowAutoLvl).CornerRadius = UDim.new(0, 6)

    local alLbl = Instance.new("TextLabel", rowAutoLvl)
    alLbl.Position = UDim2.new(0, 10, 0, 0)
    alLbl.Size = UDim2.new(1, -55, 1, 0)
    alLbl.BackgroundTransparency = 1
    alLbl.Text = "Auto Level Up / Training Pet"
    alLbl.TextColor3 = C.TEXT_W
    alLbl.Font = Enum.Font.GothamMedium
    alLbl.TextSize = 9
    alLbl.TextXAlignment = Enum.TextXAlignment.Left

    local alSw = ZyloLib:CreatePillSwitch(rowAutoLvl, State.AutoLevelUp, function(v)
        State.AutoLevelUp = v
    end)
    alSw.Position = UDim2.new(1, -40, 0.5, -10)

    -- Row 2: Target Level Input
    local rowTarget = Instance.new("Frame", bodyLevel)
    rowTarget.Size = UDim2.new(1, -24, 0, 30)
    rowTarget.Position = UDim2.new(0, 12, 0, 42)
    rowTarget.BackgroundColor3 = C.CARD_2
    Instance.new("UICorner", rowTarget).CornerRadius = UDim.new(0, 6)

    local tgLbl = Instance.new("TextLabel", rowTarget)
    tgLbl.Position = UDim2.new(0, 10, 0, 0)
    tgLbl.Size = UDim2.new(0.65, 0, 1, 0)
    tgLbl.BackgroundTransparency = 1
    tgLbl.Text = "Target Level Maksimal"
    tgLbl.TextColor3 = C.TEXT_M
    tgLbl.Font = Enum.Font.GothamMedium
    tgLbl.TextSize = 9
    tgLbl.TextXAlignment = Enum.TextXAlignment.Left

    local tgBox = Instance.new("TextBox", rowTarget)
    tgBox.Position = UDim2.new(1, -65, 0.5, -11)
    tgBox.Size = UDim2.new(0, 55, 0, 22)
    tgBox.BackgroundColor3 = Color3.fromRGB(14, 18, 36)
    tgBox.Text = tostring(State.TargetLevel)
    tgBox.TextColor3 = C.TEXT_W
    tgBox.Font = Enum.Font.GothamBold
    tgBox.TextSize = 9.5
    Instance.new("UICorner", tgBox).CornerRadius = UDim.new(0, 5)
    local tgStroke = Instance.new("UIStroke", tgBox)
    tgStroke.Color = C.STROKE

    tgBox:GetPropertyChangedSignal("Text"):Connect(function()
        local val = tonumber(tgBox.Text)
        if val then State.TargetLevel = val end
    end)

    -- Status Informasi
    local infoLbl = Instance.new("TextLabel", bodyLevel)
    infoLbl.Position = UDim2.new(0, 12, 0, 80)
    infoLbl.Size = UDim2.new(1, -24, 0, 45)
    infoLbl.BackgroundTransparency = 1
    infoLbl.Text = "ℹ️ Modul Leveling siap dikembangkan. Fitur utama & auto hatch saat ini tetap berjalan normal tanpa gangguan."
    infoLbl.TextColor3 = Color3.fromRGB(130, 160, 220)
    infoLbl.Font = Enum.Font.GothamMedium
    infoLbl.TextSize = 8.5
    infoLbl.TextWrapped = true
    infoLbl.TextXAlignment = Enum.TextXAlignment.Left

    -- Leveling Worker Loop (Siap diisi logika training saat kita masuk fase leveling)
    task.spawn(function()
        while true do
            if State.AutoLevelUp then
                -- Placeholder siap pakai untuk logic remote XP / Training
            end
            task.wait(1)
        end
    end)

    return {
        State = State
    }
end
