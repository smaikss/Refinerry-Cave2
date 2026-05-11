local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

local targetTreePos = nil
local autoTreeTeleport = false
local clickTeleportPlayer = true
local freecamActive = false
local freecamPart = nil
local currentLanguage = "EN" 

-- ==================== СПИСОК КООРДИНАТ (Empty) ====================
local savedTeleports = {}

-- ==================== МОВНІ ПАКЕТИ ====================
local lang = {
    EN = {
        title = "💎 Refinery Caves 2 Helper",
        farm = "Farm",
        teleport = "Teleport",
        settings = "Settings",
        tp_tree = "🟢 Tree TP [G]: ON",
        tp_tree_off = "🔴 Tree TP [G]: OFF",
        save_sell = "🎯 Save Sell Point",
        add_pos = "➕ Save Current Position",
        tp_f = "🟢 Click TP (F): ON",
        tp_f_off = "🔴 Click TP (F): OFF",
        freecam = "🎥 Freecam: ON",
        freecam_off = "🎥 Freecam: OFF",
        lang_btn = "🌐 Language: English"
    },
    RU = {
        title = "💎 Refinery Caves 2 Helper",
        farm = "Фарм",
        teleport = "Телепорт",
        settings = "Настройки",
        tp_tree = "🟢 ТП Дерева [G]: ВКЛ",
        tp_tree_off = "🔴 ТП Дерева [G]: ВЫКЛ",
        save_sell = "🎯 Сохранить точку продажи",
        add_pos = "➕ Сохранить текущее место",
        tp_f = "🟢 ТП на клик (F): ВКЛ",
        tp_f_off = "🔴 ТП на клик (F): ВЫКЛ",
        freecam = "🎥 Фрикамера: ВКЛ",
        freecam_off = "🎥 Фрикамера: ВЫКЛ",
        lang_btn = "🌐 Язык: Русский"
    }
}

-- ==================== GUI SETUP ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RC2_Ultimate_Helper"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 460, 0, 550)
Frame.Position = UDim2.new(0.5, -230, 0.5, -275)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

-- Додамо закруглення кутів для меню
local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 10)
FrameCorner.Parent = Frame

-- КНОПКА ЗАКРИТТЯ (Яскраво-червона)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseButton"
CloseBtn.Size = UDim2.new(0, 35, 0, 35)
CloseBtn.Position = UDim2.new(1, -40, 0, 7) -- Чітка позиція вгорі справа
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Чистий червоний
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.TextSize = 22
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.ZIndex = 10 -- Поверх усього
CloseBtn.Parent = Frame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 5)
CloseCorner.Parent = CloseBtn

-- Обводка для кнопки, щоб її було видно
local CloseStroke = Instance.new("UIStroke")
CloseStroke.Thickness = 2
CloseStroke.Color = Color3.new(1, 1, 1)
CloseStroke.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Перетягування (Drag)
local dragging, dragStart, startPos
Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = Frame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 0, 50) -- Залишаємо місце для кнопки
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = lang[currentLanguage].title
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextScaled = true
Title.Font = Enum.Font.SourceSansBold
Title.Parent = Frame

local CoordLabel = Instance.new("TextLabel")
CoordLabel.Size = UDim2.new(1, -20, 0, 30)
CoordLabel.Position = UDim2.new(0, 10, 0, 55)
CoordLabel.BackgroundTransparency = 1
CoordLabel.Text = "X: 0 | Y: 0 | Z: 0"
CoordLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
CoordLabel.TextSize = 18
CoordLabel.Parent = Frame

local TabButtons = Instance.new("Frame")
TabButtons.Size = UDim2.new(1, 0, 0, 40)
TabButtons.Position = UDim2.new(0, 0, 0, 90)
TabButtons.BackgroundTransparency = 1
TabButtons.Parent = Frame

local Scrolling = Instance.new("ScrollingFrame")
Scrolling.Size = UDim2.new(1, -20, 1, -150); Scrolling.Position = UDim2.new(0, 10, 0, 140)
Scrolling.BackgroundTransparency = 1; Scrolling.ScrollBarThickness = 6; Scrolling.Parent = Frame
local UIList = Instance.new("UIListLayout"); UIList.Padding = UDim.new(0, 8); UIList.Parent = Scrolling

local function ClearScroll()
    for _, v in pairs(Scrolling:GetChildren()) do if v:IsA("GuiObject") and v.Name ~= "UIListLayout" then v:Destroy() end end
end

-- ==================== FREECAM LOGIC ====================
local function ToggleFreecam()
    freecamActive = not freecamActive
    if freecamActive then
        local camPos = Camera.CFrame
        freecamPart = Instance.new("Part")
        freecamPart.Size = Vector3.new(1, 1, 1)
        freecamPart.Transparency = 1
        freecamPart.CanCollide = false
        freecamPart.Anchored = true
        freecamPart.CFrame = camPos
        freecamPart.Parent = Workspace
        Camera.CameraSubject = freecamPart
    else
        if freecamPart then freecamPart:Destroy() freecamPart = nil end
        if LocalPlayer.Character then
            Camera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
        end
    end
end

-- ==================== MAIN LOOP ====================
RunService.RenderStepped:Connect(function()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        CoordLabel.Text = string.format("X: %.1f | Y: %.1f | Z: %.1f", root.Position.X, root.Position.Y, root.Position.Z)
    end

    if freecamActive and freecamPart then
        local speed = 2.5
        local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.E) then moveDir += Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveDir -= Vector3.new(0, 1, 0) end
        freecamPart.CFrame += moveDir * speed
    end
end)

-- ==================== INTERFACE FUNCTIONS ====================
local function ShowFarm()
    ClearScroll()
    local t = lang[currentLanguage]
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(1, 0, 0, 60); ToggleBtn.BackgroundColor3 = autoTreeTeleport and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
    ToggleBtn.Text = autoTreeTeleport and t.tp_tree or t.tp_tree_off
    ToggleBtn.TextColor3 = Color3.new(1, 1, 1); ToggleBtn.Parent = Scrolling
    ToggleBtn.MouseButton1Click:Connect(function() autoTreeTeleport = not autoTreeTeleport; ShowFarm() end)

    local SaveBtn = Instance.new("TextButton")
    SaveBtn.Size = UDim2.new(1, 0, 0, 50); SaveBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
    SaveBtn.Text = t.save_sell; SaveBtn.TextColor3 = Color3.new(1, 1, 1); SaveBtn.Parent = Scrolling
    SaveBtn.MouseButton1Click:Connect(function()
        if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then targetTreePos = LocalPlayer.Character.PrimaryPart.Position end
    end)
end

local function ShowTeleports()
    ClearScroll()
    local t = lang[currentLanguage]
    local AddBtn = Instance.new("TextButton")
    AddBtn.Size = UDim2.new(1, 0, 0, 50); AddBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
    AddBtn.Text = t.add_pos; AddBtn.TextColor3 = Color3.new(1, 1, 1); AddBtn.Parent = Scrolling
    AddBtn.MouseButton1Click:Connect(function()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then table.insert(savedTeleports, {Name = "Point " .. (#savedTeleports + 1), Position = hrp.Position}); ShowTeleports() end
    end)

    for _, loc in ipairs(savedTeleports) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 45); btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        btn.Text = "🚀 " .. loc.Name; btn.TextColor3 = Color3.new(1, 1, 1); btn.Parent = Scrolling
        btn.MouseButton1Click:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(loc.Position + Vector3.new(0, 5, 0))
            end
        end)
    end
end

local function ShowSettings()
    ClearScroll()
    local t = lang[currentLanguage]
    
    local LangBtn = Instance.new("TextButton")
    LangBtn.Size = UDim2.new(1, 0, 0, 50); LangBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 150)
    LangBtn.Text = t.lang_btn; LangBtn.TextColor3 = Color3.new(1, 1, 1); LangBtn.Parent = Scrolling
    LangBtn.MouseButton1Click:Connect(function()
        currentLanguage = (currentLanguage == "EN") and "RU" or "EN"
        Title.Text = lang[currentLanguage].title
        ShowSettings()
    end)

    local CamBtn = Instance.new("TextButton")
    CamBtn.Size = UDim2.new(1, 0, 0, 50); CamBtn.BackgroundColor3 = freecamActive and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
    CamBtn.Text = freecamActive and t.freecam or t.freecam_off
    CamBtn.TextColor3 = Color3.new(1, 1, 1); CamBtn.Parent = Scrolling
    CamBtn.MouseButton1Click:Connect(function() ToggleFreecam(); ShowSettings() end)

    local FBtn = Instance.new("TextButton")
    FBtn.Size = UDim2.new(1, 0, 0, 50); FBtn.BackgroundColor3 = clickTeleportPlayer and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
    FBtn.Text = clickTeleportPlayer and t.tp_f or t.tp_f_off
    FBtn.TextColor3 = Color3.new(1, 1, 1); FBtn.Parent = Scrolling
    FBtn.MouseButton1Click:Connect(function() clickTeleportPlayer = not clickTeleportPlayer; ShowSettings() end)
end

-- ==================== TABS SETUP ====================
local function CreateTabBtn(text, pos, func)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.33, -5, 1, 0); btn.Position = UDim2.new(pos, 0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); btn.Text = text; btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Parent = TabButtons; btn.MouseButton1Click:Connect(func)
    return btn
end

CreateTabBtn("Farm", 0, ShowFarm)
CreateTabBtn("Teleport", 0.33, ShowTeleports)
CreateTabBtn("Settings", 0.66, ShowSettings)

-- ==================== INPUT HANDLING ====================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F and clickTeleportPlayer then
        local mouse = LocalPlayer:GetMouse()
        if mouse.Hit and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
        end
    end
    if input.KeyCode == Enum.KeyCode.G and autoTreeTeleport and targetTreePos then
        local target = LocalPlayer:GetMouse().Target
        if target and not target.Anchored and not target:IsA("Terrain") then
            pcall(function()
                target.CFrame = CFrame.new(targetTreePos + Vector3.new(0, 5, 0))
            end)
        end
    end
end)

ShowFarm()
