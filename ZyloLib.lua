-- =========================================================================
--  ZYLOHUB UI FRAMEWORK (v3.5 - OFFICIAL LIBRARY ENGINE)
--  Theme: Deep Obsidian Black (#070912) & Cosmic Purple (#8A2BE2)
--  Mobile-Optimized & 0 Register Overflow Guaranteed
-- =========================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local ZyloLib = {}
ZyloLib.__index = ZyloLib

local C_BG       = Color3.fromRGB(7, 9, 18)
local C_TOPBAR   = Color3.fromRGB(11, 14, 28)
local C_CARD     = Color3.fromRGB(12, 16, 32)
local C_CARD_2   = Color3.fromRGB(16, 21, 42)
local C_PURPLE   = Color3.fromRGB(138, 43, 226)
local C_PURPLE_L = Color3.fromRGB(175, 82, 255)
local C_CYAN     = Color3.fromRGB(0, 240, 255)
local C_STROKE   = Color3.fromRGB(30, 36, 68)
local C_TEXT_W   = Color3.fromRGB(245, 247, 255)
local C_TEXT_M   = Color3.fromRGB(145, 155, 185)

local function getSafeMount()
    local success, pgui = pcall(function()
        return LocalPlayer:WaitForChild("PlayerGui", 5)
    end)
    if success and pgui then return pgui end
    return CoreGui
end

function ZyloLib:CreateWindow(config)
    local Window = {}
    Window.Tabs = {}
    Window.TabButtons = {}
    Window.CurrentTab = nil

    local GUI_NAME = "ZyloHub_Official_UI"
    pcall(function()
        local old = getSafeMount():FindFirstChild(GUI_NAME)
        if old then old:Destroy() end
    end)

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = GUI_NAME
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 999999
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = getSafeMount()
    Window.ScreenGui = ScreenGui

    -- Main Window
    local Main = Instance.new("Frame", ScreenGui)
    Main.Name = "MainWindow"
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.Size = UDim2.new(0, 620, 0, 400)
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.BackgroundColor3 = C_BG
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Main.Active = true
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)
    local mbStroke = Instance.new("UIStroke", Main)
    mbStroke.Color = Color3.fromRGB(50, 40, 95)
    mbStroke.Thickness = 1.5
    Window.Main = Main

    -- Mobile Scaler
    local uis = Instance.new("UIScale", Main)
    local function autoScale()
        pcall(function()
            local cam = workspace.CurrentCamera
            if cam and cam.ViewportSize.Y > 0 then
                local sy = math.min(1, (cam.ViewportSize.Y - 20) / 415)
                local sx = math.min(1, (cam.ViewportSize.X - 20) / 635)
                uis.Scale = math.clamp(math.min(sx, sy), 0.55, 1)
            end
        end)
    end
    autoScale()
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(autoScale)
    end

    -- Floating Button Z
    local FloatBtn = Instance.new("TextButton", ScreenGui)
    FloatBtn.Size = UDim2.new(0, 46, 0, 46)
    FloatBtn.Position = UDim2.new(0, 18, 0.18, 0)
    FloatBtn.BackgroundColor3 = Color3.fromRGB(18, 14, 38)
    FloatBtn.Text = "Z"
    FloatBtn.TextColor3 = Color3.fromRGB(220, 130, 255)
    FloatBtn.Font = Enum.Font.FredokaOne
    FloatBtn.TextSize = 24
    FloatBtn.Active = true
    FloatBtn.Draggable = true
    FloatBtn.ZIndex = 1500000
    Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(0, 14)
    local fbStroke = Instance.new("UIStroke", FloatBtn)
    fbStroke.Color = C_PURPLE
    fbStroke.Thickness = 2.2

    local function toggleUI() Main.Visible = not Main.Visible end
    FloatBtn.MouseButton1Click:Connect(toggleUI)

    -- Topbar
    local Topbar = Instance.new("Frame", Main)
    Topbar.Size = UDim2.new(1, 0, 0, 46)
    Topbar.BackgroundColor3 = C_TOPBAR
    Topbar.BorderSizePixel = 0

    local LogoBadge = Instance.new("Frame", Topbar)
    LogoBadge.Size = UDim2.new(0, 30, 0, 30)
    LogoBadge.Position = UDim2.new(0, 12, 0.5, -15)
    LogoBadge.BackgroundColor3 = Color3.fromRGB(24, 18, 48)
    Instance.new("UICorner", LogoBadge).CornerRadius = UDim.new(0, 8)
    local lbStroke = Instance.new("UIStroke", LogoBadge)
    lbStroke.Color = C_PURPLE
    lbStroke.Thickness = 1.5

    local LogoText = Instance.new("TextLabel", LogoBadge)
    LogoText.Size = UDim2.new(1, 0, 1, 0)
    LogoText.BackgroundTransparency = 1
    LogoText.Text = "Z"
    LogoText.TextColor3 = Color3.fromRGB(220, 130, 255)
    LogoText.Font = Enum.Font.FredokaOne
    LogoText.TextSize = 18

    local BrandTitle = Instance.new("TextLabel", Topbar)
    BrandTitle.Position = UDim2.new(0, 48, 0, 7)
    BrandTitle.Size = UDim2.new(0, 130, 0, 16)
    BrandTitle.BackgroundTransparency = 1
    BrandTitle.Text = config.Title or "ZYLOHUB"
    BrandTitle.TextColor3 = C_TEXT_W
    BrandTitle.Font = Enum.Font.GothamBold
    BrandTitle.TextSize = 14
    BrandTitle.TextXAlignment = Enum.TextXAlignment.Left

    local BrandSub = Instance.new("TextLabel", Topbar)
    BrandSub.Position = UDim2.new(0, 48, 0, 24)
    BrandSub.Size = UDim2.new(0, 180, 0, 14)
    BrandSub.BackgroundTransparency = 1
    BrandSub.Text = config.SubTitle or "Auto • Farm • Pets • More"
    BrandSub.TextColor3 = C_PURPLE_L
    BrandSub.Font = Enum.Font.GothamMedium
    BrandSub.TextSize = 9
    BrandSub.TextXAlignment = Enum.TextXAlignment.Left

    local VersionPill = Instance.new("Frame", Topbar)
    VersionPill.Size = UDim2.new(0, 42, 0, 22)
    VersionPill.Position = UDim2.new(1, -210, 0.5, -11)
    VersionPill.BackgroundColor3 = Color3.fromRGB(18, 20, 38)
    Instance.new("UICorner", VersionPill).CornerRadius = UDim.new(0, 11)
    Instance.new("UIStroke", VersionPill).Color = Color3.fromRGB(70, 50, 120)

    local VText = Instance.new("TextLabel", VersionPill)
    VText.Size = UDim2.new(1, 0, 1, 0)
    VText.BackgroundTransparency = 1
    VText.Text = config.Version or "v3.5"
    VText.TextColor3 = Color3.fromRGB(195, 175, 255)
    VText.Font = Enum.Font.GothamBold
    VText.TextSize = 9

    local DetectPill = Instance.new("Frame", Topbar)
    DetectPill.Size = UDim2.new(0, 115, 0, 24)
    DetectPill.Position = UDim2.new(1, -162, 0.5, -12)
    DetectPill.BackgroundColor3 = Color3.fromRGB(14, 25, 36)
    Instance.new("UICorner", DetectPill).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", DetectPill).Color = Color3.fromRGB(0, 160, 140)

    local Dot = Instance.new("Frame", DetectPill)
    Dot.Size = UDim2.new(0, 6, 0, 6)
    Dot.Position = UDim2.new(0, 8, 0.5, -3)
    Dot.BackgroundColor3 = Color3.fromRGB(0, 255, 170)
    Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

    local DText = Instance.new("TextLabel", DetectPill)
    DText.Position = UDim2.new(0, 20, 0, 0)
    DText.Size = UDim2.new(1, -22, 1, 0)
    DText.BackgroundTransparency = 1
    DText.Text = "Game Detected"
    DText.TextColor3 = Color3.fromRGB(0, 255, 190)
    DText.Font = Enum.Font.GothamBold
    DText.TextSize = 9
    DText.TextXAlignment = Enum.TextXAlignment.Left

    local CloseBtn = Instance.new("TextButton", Topbar)
    CloseBtn.Size = UDim2.new(0, 24, 0, 24)
    CloseBtn.Position = UDim2.new(1, -24, 0.5, -12)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = C_TEXT_M
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 12
    CloseBtn.MouseButton1Click:Connect(toggleUI)

    -- Sidebar
    local Sidebar = Instance.new("Frame", Main)
    Sidebar.Size = UDim2.new(0, 130, 1, -46)
    Sidebar.Position = UDim2.new(0, 0, 0, 46)
    Sidebar.BackgroundColor3 = Color3.fromRGB(9, 12, 24)
    Sidebar.BorderSizePixel = 0

    local SideScroll = Instance.new("ScrollingFrame", Sidebar)
    SideScroll.Size = UDim2.new(1, 0, 1, -85)
    SideScroll.BackgroundTransparency = 1
    SideScroll.ScrollBarThickness = 0
    SideScroll.CanvasSize = UDim2.new(0, 0, 0, 330)

    local SideLayout = Instance.new("UIListLayout", SideScroll)
    SideLayout.Padding = UDim.new(0, 3)
    local SidePad = Instance.new("UIPadding", SideScroll)
    SidePad.PaddingTop = UDim.new(0, 6)
    SidePad.PaddingLeft = UDim.new(0, 6)
    SidePad.PaddingRight = UDim.new(0, 6)
    Window.SideScroll = SideScroll

    -- Brand Card
    local BrandCard = Instance.new("Frame", Sidebar)
    BrandCard.Size = UDim2.new(1, -12, 0, 75)
    BrandCard.Position = UDim2.new(0, 6, 1, -80)
    BrandCard.BackgroundColor3 = Color3.fromRGB(14, 18, 36)
    Instance.new("UICorner", BrandCard).CornerRadius = UDim.new(0, 10)
    local bcStroke = Instance.new("UIStroke", BrandCard)
    bcStroke.Color = Color3.fromRGB(80, 45, 140)

    local BcTitle = Instance.new("TextLabel", BrandCard)
    BcTitle.Position = UDim2.new(0, 10, 0, 12)
    BcTitle.Size = UDim2.new(1, -16, 0, 14)
    BcTitle.BackgroundTransparency = 1
    BcTitle.Text = "⚡ ZYLOHUB"
    BcTitle.TextColor3 = C_TEXT_W
    BcTitle.Font = Enum.Font.GothamBold
    BcTitle.TextSize = 11
    BcTitle.TextXAlignment = Enum.TextXAlignment.Left

    local BcDesc = Instance.new("TextLabel", BrandCard)
    BcDesc.Position = UDim2.new(0, 10, 0, 28)
    BcDesc.Size = UDim2.new(1, -16, 0, 24)
    BcDesc.BackgroundTransparency = 1
    BcDesc.Text = "Better Scripts\nBetter Experience"
    BcDesc.TextColor3 = C_TEXT_M
    BcDesc.Font = Enum.Font.GothamMedium
    BcDesc.TextSize = 8
    BcDesc.TextXAlignment = Enum.TextXAlignment.Left

    -- Content Container
    local Content = Instance.new("Frame", Main)
    Content.Size = UDim2.new(1, -140, 1, -52)
    Content.Position = UDim2.new(0, 135, 0, 50)
    Content.BackgroundTransparency = 1
    Window.Content = Content

    -- Dragging Logic
    local dragging, dragStart, startPos
    Topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
        end
    end)
    Topbar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    function Window:CreateTab(name, icon, order, canvasHeight)
        local Tab = {}
        local sf = Instance.new("ScrollingFrame", Content)
        sf.Name = name .. "Page"
        sf.Size = UDim2.new(1, 0, 1, 0)
        sf.BackgroundTransparency = 1
        sf.BorderSizePixel = 0
        sf.ScrollBarThickness = 2
        sf.ScrollBarImageColor3 = C_PURPLE
        sf.CanvasSize = UDim2.new(0, 0, 0, canvasHeight or 500)
        sf.Visible = false

        local list = Instance.new("UIListLayout", sf)
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Padding = UDim.new(0, 8)
        local pad = Instance.new("UIPadding", sf)
        pad.PaddingRight = UDim.new(0, 8)
        pad.PaddingBottom = UDim.new(0, 8)
        Tab.Page = sf

        local btn = Instance.new("TextButton", SideScroll)
        btn.Size = UDim2.new(1, 0, 0, 28)
        btn.BackgroundColor3 = Color3.fromRGB(18, 22, 42)
        btn.BackgroundTransparency = 1
        btn.Text = "   " .. icon .. "   " .. name
        btn.TextColor3 = C_TEXT_M
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 10
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.LayoutOrder = order or 1
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        btn.MouseButton1Click:Connect(function()
            Window:SelectTab(name)
        end)

        Window.Tabs[name] = Tab
        Window.TabButtons[name] = btn
        return Tab
    end

    function Window:SelectTab(name)
        for tName, btn in pairs(Window.TabButtons) do
            btn.BackgroundTransparency = 1
            btn.TextColor3 = C_TEXT_M
            if Window.Tabs[tName] then Window.Tabs[tName].Page.Visible = false end
        end
        local targetBtn = Window.TabButtons[name]
        local targetTab = Window.Tabs[name]
        if targetBtn and targetTab then
            targetBtn.BackgroundTransparency = 0
            targetBtn.BackgroundColor3 = C_PURPLE
            targetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            targetTab.Page.Visible = true
            Window.CurrentTab = name
        end
    end

    return Window
end

-- Helper Pill Switch Reusable
function ZyloLib:CreatePillSwitch(parent, defaultState, callback)
    local switch = Instance.new("TextButton", parent)
    switch.Size = UDim2.new(0, 36, 0, 20)
    switch.BackgroundColor3 = defaultState and C_PURPLE or Color3.fromRGB(26, 28, 44)
    switch.Text = ""
    Instance.new("UICorner", switch).CornerRadius = UDim.new(1, 0)
    local swStroke = Instance.new("UIStroke", switch)
    swStroke.Color = Color3.fromRGB(45, 50, 75)

    local knob = Instance.new("Frame", switch)
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = defaultState and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local active = defaultState
    switch.MouseButton1Click:Connect(function()
        active = not active
        local targetPos = active and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        local targetColor = active and C_PURPLE or Color3.fromRGB(26, 28, 44)
        TweenService:Create(knob, TweenInfo.new(0.16, Enum.EasingStyle.Quad), { Position = targetPos }):Play()
        TweenService:Create(switch, TweenInfo.new(0.16, Enum.EasingStyle.Quad), { BackgroundColor3 = targetColor }):Play()
        callback(active)
    end)
    return switch
end

return ZyloLib
