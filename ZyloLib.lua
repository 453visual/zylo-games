-- =========================================================================
--  ZYLOHUB UI FRAMEWORK (v3.5 - OFFICIAL UI LIBRARY)
--  Theme: Deep Obsidian Black (#070912) & Cosmic Purple (#8A2BE2)
--  Presisi 100% Sesuai Desain Asli ZyloHub
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

ZyloLib.Colors = {
    BG = C_BG, TOPBAR = C_TOPBAR, CARD = C_CARD, CARD_2 = C_CARD_2,
    PURPLE = C_PURPLE, PURPLE_L = C_PURPLE_L, CYAN = C_CYAN,
    STROKE = C_STROKE, TEXT_W = C_TEXT_W, TEXT_M = C_TEXT_M
}

function ZyloLib:CreateWindow()
    local Window = {}
    Window.Tabs = {}
    Window.Buttons = {}

    -- Mount GUI
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ZyloHub_v3_5_PetEggService"
    ScreenGui.ResetOnSpawn = false

    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = CoreGui
    elseif gethui then
        ScreenGui.Parent = gethui()
    else
        local pgui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
        ScreenGui.Parent = pgui or CoreGui
    end
    Window.ScreenGui = ScreenGui

    -- Floating Button Z
    local FloatBtn = Instance.new("TextButton", ScreenGui)
    FloatBtn.Name = "ZyloFloatToggle"
    FloatBtn.Size = UDim2.new(0, 42, 0, 42)
    FloatBtn.Position = UDim2.new(0, 20, 0.5, -21)
    FloatBtn.BackgroundColor3 = Color3.fromRGB(18, 14, 38)
    FloatBtn.Text = "Z"
    FloatBtn.TextColor3 = Color3.fromRGB(220, 130, 255)
    FloatBtn.Font = Enum.Font.FredokaOne
    FloatBtn.TextSize = 22
    FloatBtn.AutoButtonColor = false
    FloatBtn.ZIndex = 1500000
    Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(0, 12)
    local FbStroke = Instance.new("UIStroke", FloatBtn)
    FbStroke.Color = C_PURPLE
    FbStroke.Thickness = 2

    local fbDragging, fbDragStart, fbStartPos
    FloatBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            fbDragging = true
            fbDragStart = input.Position
            fbStartPos = FloatBtn.Position
        end
    end)
    FloatBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            fbDragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if fbDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - fbDragStart
            FloatBtn.Position = UDim2.new(fbStartPos.X.Scale, fbStartPos.X.Offset + delta.X, fbStartPos.Y.Scale, fbStartPos.Y.Offset + delta.Y)
        end
    end)

    -- Main Frame
    local Main = Instance.new("Frame", ScreenGui)
    Main.Name = "MainWindow"
    Main.Size = UDim2.new(0, 620, 0, 400)
    Main.Position = UDim2.new(0.5, -310, 0.5, -200)
    Main.BackgroundColor3 = C_BG
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)
    local MainBorder = Instance.new("UIStroke", Main)
    MainBorder.Color = Color3.fromRGB(50, 40, 95)
    MainBorder.Thickness = 1.5
    Window.Main = Main

    local function toggleUI() Main.Visible = not Main.Visible end
    FloatBtn.MouseButton1Click:Connect(toggleUI)

    -- Topbar
    local Topbar = Instance.new("Frame", Main)
    Topbar.Size = UDim2.new(1, 0, 0, 46)
    Topbar.BackgroundColor3 = C_TOPBAR
    Topbar.BorderSizePixel = 0

    local TopBorder = Instance.new("Frame", Topbar)
    TopBorder.Size = UDim2.new(1, 0, 0, 1)
    TopBorder.Position = UDim2.new(0, 0, 1, -1)
    TopBorder.BackgroundColor3 = C_STROKE
    TopBorder.BorderSizePixel = 0

    local LogoBadge = Instance.new("Frame", Topbar)
    LogoBadge.Size = UDim2.new(0, 30, 0, 30)
    LogoBadge.Position = UDim2.new(0, 12, 0.5, -15)
    LogoBadge.BackgroundColor3 = Color3.fromRGB(24, 18, 48)
    Instance.new("UICorner", LogoBadge).CornerRadius = UDim.new(0, 8)
    local LbStroke = Instance.new("UIStroke", LogoBadge)
    LbStroke.Color = C_PURPLE
    LbStroke.Thickness = 1.5

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
    BrandTitle.Text = "ZYLOHUB"
    BrandTitle.TextColor3 = C_TEXT_W
    BrandTitle.Font = Enum.Font.GothamBold
    BrandTitle.TextSize = 14
    BrandTitle.TextXAlignment = Enum.TextXAlignment.Left

    local BrandSub = Instance.new("TextLabel", Topbar)
    BrandSub.Position = UDim2.new(0, 48, 0, 24)
    BrandSub.Size = UDim2.new(0, 180, 0, 14)
    BrandSub.BackgroundTransparency = 1
    BrandSub.Text = "Auto • Farm • Pets • More"
    BrandSub.TextColor3 = C_PURPLE_L
    BrandSub.Font = Enum.Font.GothamMedium
    BrandSub.TextSize = 9
    BrandSub.TextXAlignment = Enum.TextXAlignment.Left

    local VersionPill = Instance.new("Frame", Topbar)
    VersionPill.Size = UDim2.new(0, 42, 0, 22)
    VersionPill.Position = UDim2.new(1, -210, 0.5, -11)
    VersionPill.BackgroundColor3 = Color3.fromRGB(18, 20, 38)
    Instance.new("UICorner", VersionPill).CornerRadius = UDim.new(0, 11)
    local VpStroke = Instance.new("UIStroke", VersionPill)
    VpStroke.Color = Color3.fromRGB(70, 50, 120)
    local VText = Instance.new("TextLabel", VersionPill)
    VText.Size = UDim2.new(1, 0, 1, 0)
    VText.BackgroundTransparency = 1
    VText.Text = "v3.5"
    VText.TextColor3 = Color3.fromRGB(195, 175, 255)
    VText.Font = Enum.Font.GothamBold
    VText.TextSize = 9

    local DetectPill = Instance.new("Frame", Topbar)
    DetectPill.Size = UDim2.new(0, 115, 0, 24)
    DetectPill.Position = UDim2.new(1, -162, 0.5, -12)
    DetectPill.BackgroundColor3 = Color3.fromRGB(14, 25, 36)
    Instance.new("UICorner", DetectPill).CornerRadius = UDim.new(0, 12)
    local DpStroke = Instance.new("UIStroke", DetectPill)
    DpStroke.Color = Color3.fromRGB(0, 160, 140)

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

    local MinBtn = Instance.new("TextButton", Topbar)
    MinBtn.Size = UDim2.new(0, 24, 0, 24)
    MinBtn.Position = UDim2.new(1, -44, 0.5, -12)
    MinBtn.BackgroundTransparency = 1
    MinBtn.Text = "—"
    MinBtn.TextColor3 = C_TEXT_M
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextSize = 13
    MinBtn.MouseButton1Click:Connect(toggleUI)

    local CloseBtn = Instance.new("TextButton", Topbar)
    CloseBtn.Size = UDim2.new(0, 24, 0, 24)
    CloseBtn.Position = UDim2.new(1, -24, 0.5, -12)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = C_TEXT_M
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 12
    CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    -- Topbar Dragging
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

    -- Sidebar
    local Sidebar = Instance.new("Frame", Main)
    Sidebar.Size = UDim2.new(0, 130, 1, -46)
    Sidebar.Position = UDim2.new(0, 0, 0, 46)
    Sidebar.BackgroundColor3 = Color3.fromRGB(9, 12, 24)
    Sidebar.BorderSizePixel = 0

    local SideScroll = Instance.new("ScrollingFrame", Sidebar)
    SideScroll.Size = UDim2.new(1, 0, 1, -85)
    SideScroll.BackgroundTransparency = 1
    SideScroll.BorderSizePixel = 0
    SideScroll.ScrollBarThickness = 0
    SideScroll.CanvasSize = UDim2.new(0, 0, 0, 330)

    local SideLayout = Instance.new("UIListLayout", SideScroll)
    SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SideLayout.Padding = UDim.new(0, 3)

    local SidePad = Instance.new("UIPadding", SideScroll)
    SidePad.PaddingTop = UDim.new(0, 6)
    SidePad.PaddingLeft = UDim.new(0, 6)
    SidePad.PaddingRight = UDim.new(0, 6)

    local BrandCard = Instance.new("Frame", Sidebar)
    BrandCard.Size = UDim2.new(1, -12, 0, 75)
    BrandCard.Position = UDim2.new(0, 6, 1, -80)
    BrandCard.BackgroundColor3 = Color3.fromRGB(14, 18, 36)
    Instance.new("UICorner", BrandCard).CornerRadius = UDim.new(0, 10)
    local BcStroke = Instance.new("UIStroke", BrandCard)
    BcStroke.Color = Color3.fromRGB(80, 45, 140)

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

    -- Container Page
    local Content = Instance.new("Frame", Main)
    Content.Size = UDim2.new(1, -140, 1, -52)
    Content.Position = UDim2.new(0, 135, 0, 50)
    Content.BackgroundTransparency = 1
    Window.Content = Content

    function Window:CreateTab(name, icon, order, canvasHeight)
        local sf = Instance.new("ScrollingFrame", Content)
        sf.Name = name .. "Page"
        sf.Size = UDim2.new(1, 0, 1, 0)
        sf.BackgroundTransparency = 1
        sf.BorderSizePixel = 0
        sf.ScrollBarThickness = 2
        sf.ScrollBarImageColor3 = C_PURPLE
        sf.CanvasSize = UDim2.new(0, 0, 0, canvasHeight or 400)
        sf.Visible = false

        local list = Instance.new("UIListLayout", sf)
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Padding = UDim.new(0, 8)

        local pad = Instance.new("UIPadding", sf)
        pad.PaddingRight = UDim.new(0, 8)
        pad.PaddingBottom = UDim.new(0, 8)

        local btn = Instance.new("TextButton", SideScroll)
        btn.Size = UDim2.new(1, 0, 0, 28)
        btn.BackgroundColor3 = Color3.fromRGB(18, 22, 42)
        btn.BackgroundTransparency = 1
        btn.Text = "   " .. icon .. "   " .. name
        btn.TextColor3 = C_TEXT_M
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 10
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.LayoutOrder = order
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        btn.MouseButton1Click:Connect(function()
            Window:SelectTab(name)
        end)

        Window.Tabs[name] = sf
        Window.Buttons[name] = btn
        return sf
    end

    function Window:SelectTab(name)
        for tName, tBtn in pairs(Window.Buttons) do
            tBtn.BackgroundTransparency = 1
            tBtn.TextColor3 = C_TEXT_M
            if Window.Tabs[tName] then Window.Tabs[tName].Visible = false end
        end
        if Window.Buttons[name] and Window.Tabs[name] then
            Window.Buttons[name].BackgroundTransparency = 0
            Window.Buttons[name].BackgroundColor3 = C_PURPLE
            Window.Buttons[name].TextColor3 = Color3.fromRGB(255, 255, 255)
            Window.Tabs[name].Visible = true
        end
    end

    return Window
end

-- Pill Switch Reusable
function ZyloLib:CreatePillSwitch(parent, defaultState, callback)
    local switch = Instance.new("TextButton", parent)
    switch.Size = UDim2.new(0, 36, 0, 20)
    switch.BackgroundColor3 = defaultState and C_PURPLE or Color3.fromRGB(26, 28, 44)
    switch.Text = ""
    switch.AutoButtonColor = false
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

-- Accordion Reusable
function ZyloLib:CreateAccordion(parent, titleText, defaultOpen, expandedH)
    local accFrame = Instance.new("Frame", parent)
    accFrame.Size = UDim2.new(1, 0, 0, defaultOpen and expandedH or 38)
    accFrame.BackgroundColor3 = C_CARD
    accFrame.ClipsDescendants = true
    Instance.new("UICorner", accFrame).CornerRadius = UDim.new(0, 8)
    local aStroke = Instance.new("UIStroke", accFrame)
    aStroke.Color = C_STROKE

    local headBtn = Instance.new("TextButton", accFrame)
    headBtn.Size = UDim2.new(1, 0, 0, 38)
    headBtn.BackgroundTransparency = 1
    headBtn.Text = ""
    headBtn.AutoButtonColor = false

    local titleLbl = Instance.new("TextLabel", headBtn)
    titleLbl.Position = UDim2.new(0, 12, 0, 0)
    titleLbl.Size = UDim2.new(1, -45, 1, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = titleText
    titleLbl.TextColor3 = C_TEXT_W
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 11
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left

    local chevron = Instance.new("TextLabel", headBtn)
    chevron.Position = UDim2.new(1, -26, 0, 0)
    chevron.Size = UDim2.new(0, 20, 1, 0)
    chevron.BackgroundTransparency = 1
    chevron.Text = defaultOpen and "v" or ">"
    chevron.TextColor3 = defaultOpen and C_PURPLE_L or C_TEXT_M
    chevron.Font = Enum.Font.GothamBold
    chevron.TextSize = 11

    local divLine = Instance.new("Frame", accFrame)
    divLine.Position = UDim2.new(0, 0, 0, 37)
    divLine.Size = UDim2.new(1, 0, 0, 1.5)
    divLine.BackgroundColor3 = C_PURPLE_L
    divLine.BorderSizePixel = 0
    divLine.Visible = defaultOpen

    local body = Instance.new("Frame", accFrame)
    body.Position = UDim2.new(0, 0, 0, 39)
    body.Size = UDim2.new(1, 0, 0, expandedH - 39)
    body.BackgroundTransparency = 1

    local isOpen = defaultOpen
    local function setAccordion(open)
        isOpen = open
        chevron.Text = isOpen and "v" or ">"
        chevron.TextColor3 = isOpen and C_PURPLE_L or C_TEXT_M
        divLine.Visible = isOpen
        TweenService:Create(accFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
            Size = UDim2.new(1, 0, 0, isOpen and expandedH or 38)
        }):Play()
    end

    headBtn.MouseButton1Click:Connect(function() setAccordion(not isOpen) end)
    return accFrame, body, setAccordion
end

return ZyloLib
