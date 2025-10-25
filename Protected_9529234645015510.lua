local Compkiller = loadstring(game:HttpGet("https://raw.githubusercontent.com/4lpaca-pin/CompKiller/refs/heads/main/src/source.luau"))();

local player = game:GetService("Players").LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local TweenService = game:GetService("TweenService")
local vim = game:GetService("VirtualInputManager")

-- Toggle Button GUI
local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "ToggleGui"
ToggleGui.Parent = playerGui
ToggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ToggleGui.ResetOnSpawn = false

local Toggle = Instance.new("TextButton")
Toggle.Name = "Toggle"
Toggle.Parent = ToggleGui
Toggle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Toggle.TextColor3 = Color3.fromRGB(30, 30, 30)
Toggle.Position = UDim2.new(0.02, 0, 0.45, 0)
Toggle.Size = UDim2.new(0, 100, 0, 40)
Toggle.Text = "Close GUI"
Toggle.Font = Enum.Font.GothamMedium
Toggle.TextSize = 16
Toggle.AutoButtonColor = false
Toggle.Draggable = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = Toggle

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(220, 220, 220)
UIStroke.Thickness = 1.4
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Parent = Toggle

local isOpen = true

local function hover(on)
    local targetColor = on and Color3.fromRGB(245, 245, 245) or Color3.fromRGB(255, 255, 255)
    TweenService:Create(Toggle, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {BackgroundColor3 = targetColor}):Play()
end

Toggle.MouseEnter:Connect(function() hover(true) end)
Toggle.MouseLeave:Connect(function() hover(false) end)

Toggle.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    Toggle.Text = isOpen and "Close GUI" or "Open GUI"
    vim:SendKeyEvent(true, Enum.KeyCode.LeftAlt, false, game)
    task.wait(0.05)
    vim:SendKeyEvent(false, Enum.KeyCode.LeftAlt, false, game)
end)

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ==================== FOV CIRCLE ====================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Thickness = 2
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Transparency = 1
FOVCircle.NumSides = 64
FOVCircle.Radius = 150
FOVCircle.Filled = false

-- Update FOV Circle Position
RunService.RenderStepped:Connect(function()
    if FOVCircle then
        local viewport = Camera.ViewportSize
        FOVCircle.Position = Vector2.new(viewport.X / 2, (viewport.Y / 2) - 120)
        FOVCircle.Radius = getgenv().silentaimfov or 150
        FOVCircle.Visible = getgenv().silentaim and getgenv().showfov
    end
end)

-- Silent Aim Variables
getgenv().silentaim = false
getgenv().silentaimfov = 150
getgenv().maxdistance = 400
getgenv().selectpart = "Head"
getgenv().prediction = 0.135
getgenv().localPlayerName = LocalPlayer.Name
getgenv().showfov = true
getgenv().remotecooldown = 0.1 

-- Cooldown System
local lastRemoteTime = 0
local canFireRemote = true

local function CheckCooldown()
    local currentTime = tick()
    if (currentTime - lastRemoteTime) >= getgenv().remotecooldown then
        canFireRemote = true
        return true
    end
    return false
end

-- FOV Check
local function IsInFOV(targetPosition)
    local viewport = Camera.ViewportSize
    local screenCenter = Vector2.new(viewport.X / 2, viewport.Y / 2)
    
    local targetScreen, onScreen = Camera:WorldToViewportPoint(targetPosition)
    if not onScreen then return false end
    
    local distance = (Vector2.new(targetScreen.X, targetScreen.Y) - screenCenter).Magnitude
    
    return distance <= getgenv().silentaimfov
end

-- Get Closest Player in FOV
local function GetClosestPlayerPart()
    local closestDist = math.huge
    local targetPart = nil
    
    local myCharacter = LocalPlayer.Character
    if not myCharacter or not myCharacter:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local myName = LocalPlayer.Name
    local myPos = myCharacter.HumanoidRootPart.Position
    local viewport = Camera.ViewportSize
    local screenCenter = Vector2.new(viewport.X / 2, viewport.Y / 2)
    
    -- Search all players
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer ~= LocalPlayer and targetPlayer.Character then
            local targetChar = targetPlayer.Character
            local hrp = targetChar:FindFirstChild("HumanoidRootPart")
            local humanoid = targetChar:FindFirstChild("Humanoid")
            local part = targetChar:FindFirstChild(getgenv().selectpart)
            
            if hrp and humanoid and humanoid.Health > 0 and part then
                local distance = (hrp.Position - myPos).Magnitude
                
                if distance <= getgenv().maxdistance then
                    if IsInFOV(part.Position) then
                        local targetScreen = Camera:WorldToViewportPoint(part.Position)
                        local screenDist = (Vector2.new(targetScreen.X, targetScreen.Y) - screenCenter).Magnitude
                        
                        if screenDist < closestDist then
                            closestDist = screenDist
                            targetPart = part
                        end
                    end
                end
            end
        end
    end
    
    -- Backup: Tagged Characters
    if not targetPart then
        local taggedChars = CollectionService:GetTagged("Character")
        for _, targetChar in pairs(taggedChars) do
            if targetChar.Name ~= myName then
                local hrp = targetChar:FindFirstChild("HumanoidRootPart")
                local humanoid = targetChar:FindFirstChild("Humanoid")
                local part = targetChar:FindFirstChild(getgenv().selectpart)
                
                if hrp and humanoid and humanoid.Health > 0 and part then
                    local distance = (hrp.Position - myPos).Magnitude
                    
                    if distance <= getgenv().maxdistance then
                        if IsInFOV(part.Position) then
                            local targetScreen = Camera:WorldToViewportPoint(part.Position)
                            local screenDist = (Vector2.new(targetScreen.X, targetScreen.Y) - screenCenter).Magnitude
                            
                            if screenDist < closestDist then
                                closestDist = screenDist
                                targetPart = part
                            end
                        end
                    end
                end
            end
        end
    end
    
    return targetPart
end

local function GetCurrentWeapon()
    local character = LocalPlayer.Character
    if not character then return nil end
    local revolver = character:FindFirstChild("Revolver")
    if revolver and revolver:IsA("Tool") then
        local handle = revolver:FindFirstChild("Handle")
        if handle then
            return revolver
        end
    end
    
    return nil
end

-- ==================== REMOTE FIRING WITH COOLDOWN ====================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if getgenv().silentaim and CheckCooldown() then
            task.spawn(function()
                pcall(function()
                    local targetPart = GetClosestPlayerPart()
                    
                    if targetPart then
                        local targetHumanoid = targetPart.Parent:FindFirstChild("Humanoid")
                        local currentWeapon = GetCurrentWeapon()
                        
                        if targetHumanoid and currentWeapon then
                            local weaponHandle = currentWeapon:FindFirstChild("Handle")
                            
                            if weaponHandle then
                                workspace.Terrain["."]:FireServer(
                                    targetHumanoid,
                                    "Hit",
                                    weaponHandle,
                                    2,
                                    currentWeapon.Name
                                )

                                lastRemoteTime = tick()
                                canFireRemote = false
                                
                                print("💥 Remote Fired to: " .. targetPart.Parent.Name)
                            end
                        end
                    end
                end)
            end)
        end
    end
end)


task.spawn(function()
    local success, ATK = pcall(function()
        return game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("MobileSupport", 10):WaitForChild("ATK", 5):WaitForChild("TextButton", 5)
    end)
    
    if success and ATK then
        print("✅ Mobile ATK Button Found!")
        ATK.MouseButton1Click:Connect(function()
            if getgenv().silentaim and CheckCooldown() then
                task.spawn(function()
                    pcall(function()
                        local targetPart = GetClosestPlayerPart()
                        
                        if targetPart then
                            local targetHumanoid = targetPart.Parent:FindFirstChild("Humanoid")
                            local currentWeapon = GetCurrentWeapon()
                            
                            if targetHumanoid and currentWeapon then
                                local weaponHandle = currentWeapon:FindFirstChild("Handle")
                                
                                if weaponHandle then
                                    workspace.Terrain["."]:FireServer(
                                        targetHumanoid,
                                        "Hit",
                                        weaponHandle,
                                        2,
                                        currentWeapon.Name
                                    )

                                    lastRemoteTime = tick()
                                    canFireRemote = false
                                    
                                    print("📱💥 Mobile Remote Fired to: " .. targetPart.Parent.Name)
                                end
                            end
                        end
                    end)
                end)
            end
        end)
    else
        warn("❌ Mobile ATK Button not found!")
    end
end)

-- Notification
local Notifier = Compkiller.newNotify();

-- Config Manager
local ConfigManager = Compkiller:ConfigManager({
    Directory = "Compkiller-UI",
    Config = "Undetectable-Silent-Aim"
});

Compkiller:Loader("rbxassetid://71610633224812", 2.5).yield();

-- Creating Window
local Window = Compkiller.new({
    Name = "Undetectable Silent Aim",
    Keybind = "LeftAlt",
    Logo = "rbxassetid://71610633224812",
    Scale = Compkiller.Scale.Window,
    TextSize = 15,
});

-- Welcome Notification
Notifier.new({
    Title = "Undetectable Silent Aim",
    Content = "Dynamic Target + FOV Circle!",
    Duration = 5,
    Icon = "rbxassetid://71610633224812"
});

-- Watermark
local Watermark = Window:Watermark();

Watermark:AddText({
    Icon = "user",
    Text = LocalPlayer.Name,
});

Watermark:AddText({
    Icon = "clock",
    Text = Compkiller:GetDate(),
});

local Time = Watermark:AddText({
    Icon = "timer",
    Text = "TIME",
});

task.spawn(function()
    while true do task.wait()
        Time:SetText(Compkiller:GetTimeNow());
    end
end)

Watermark:AddText({
    Icon = "server",
    Text = Compkiller.Version,
});

-- ==================== MAIN CATEGORY ====================
Window:DrawCategory({
    Name = "Combat"
});

-- ==================== SILENT AIM TAB ====================
local SilentAimTab = Window:DrawTab({
    Name = "Silent Aim",
    Icon = "crosshair",
    EnableScrolling = true
});

local SilentAimSection = SilentAimTab:DrawSection({
    Name = "Silent Aim Settings",
    Position = 'left'
});

-- Silent Aim Statistics
local hitCount = 0
local shotCount = 0

-- Mouse Hook for Silent Aim
local mt = getrawmetatable(game)
local real_index = mt.__index
setreadonly(mt, false)

mt.__index = newcclosure(function(self, key)
    if not checkcaller() and getgenv().silentaim then
        local success, isMouse = pcall(function()
            return self:IsA("Mouse") and (key == "Hit" or key == "Target" or key == "X" or key == "Y")
        end)
        
        if success and isMouse then
            local targetPart = GetClosestPlayerPart()
            
            if targetPart then
                local hrp = targetPart.Parent:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local velocity = hrp.AssemblyLinearVelocity
                    local predictedPos = targetPart.Position + (velocity * getgenv().prediction)
                    
                    if key == "Hit" then
                        return CFrame.new(predictedPos)
                    elseif key == "Target" then
                        return targetPart
                    elseif key == "X" then
                        local screen = Camera:WorldToViewportPoint(predictedPos)
                        return screen.X
                    elseif key == "Y" then
                        local screen = Camera:WorldToViewportPoint(predictedPos)
                        return screen.Y
                    end
                end
            end
        end
    end
    
    return real_index(self, key)
end)

setreadonly(mt, true)

-- Silent Aim Info Display
local SilentAimInfoParagraph = SilentAimSection:AddParagraph({
    Title = "Silent Aim Stats",
    Content = "Status: Inactive\nTarget: None\nCooldown: Ready"
})

task.spawn(function()
    while task.wait(0.1) do
        local statusText = getgenv().silentaim and "🟢 ACTIVE" or "🔴 Inactive"
        
        local targetPart = GetClosestPlayerPart()
        local targetText = targetPart and "🎯 " .. targetPart.Parent.Name or "None"
        
        local cooldownText = canFireRemote and "✅ Ready" or "⏳ Cooling..."
        
        pcall(function()
            SilentAimInfoParagraph:SetContent(
                "Status: " .. statusText .. 
                "\nTarget: " .. targetText ..
                "\nCooldown: " .. cooldownText
            )
        end)
    end
end)

-- UI Controls
SilentAimSection:AddToggle({
    Name = "Enable Silent Aim",
    Flag = "SilentAim_Enable",
    Default = false,
    Callback = function(Value)
        getgenv().silentaim = Value
        if Value then
            Notifier.new({
                Title = "Silent Aim",
                Content = "Dynamic Mode Active!",
                Duration = 3,
                Icon = "rbxassetid://71610633224812"
            })
        end
    end,
})

SilentAimSection:AddToggle({
    Name = "Show FOV Circle",
    Flag = "ShowFOV",
    Default = true,
    Callback = function(Value)
        getgenv().showfov = Value
        FOVCircle.Visible = Value and getgenv().silentaim
    end,
})

SilentAimSection:AddDropdown({
    Name = "Target Part",
    Default = "Head",
    Flag = "SilentAim_Part",
    Values = {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart"},
    Callback = function(Value)
        getgenv().selectpart = Value
    end
})

SilentAimSection:AddSlider({
    Name = "FOV Size",
    Min = 50,
    Max = 300,
    Default = 150,
    Round = 0,
    Flag = "SilentAim_FOV",
    Callback = function(Value)
        getgenv().silentaimfov = Value
        FOVCircle.Radius = Value
    end
});

SilentAimSection:AddSlider({
    Name = "Max Distance",
    Min = 100,
    Max = 800,
    Default = 400,
    Round = 0,
    Flag = "SilentAim_Distance",
    Callback = function(Value)
        getgenv().maxdistance = Value
    end
});

SilentAimSection:AddSlider({
    Name = "Prediction",
    Min = 0.1,
    Max = 0.25,
    Default = 0.135,
    Round = 3,
    Flag = "Prediction_Amount",
    Callback = function(Value)
        getgenv().prediction = Value
    end
});

SilentAimSection:AddSlider({
    Name = "Remote Cooldown (ms)",
    Min = 50,
    Max = 500,
    Default = 100,
    Round = 0,
    Flag = "Remote_Cooldown",
    Callback = function(Value)
        getgenv().remotecooldown = Value / 1000
    end
});

local VisualSection = SilentAimTab:DrawSection({
    Name = "Visual Settings",
    Position = 'right'
});

VisualSection:AddColorPicker({
    Name = "FOV Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(Value)
        FOVCircle.Color = Value
    end,
});

VisualSection:AddSlider({
    Name = "FOV Transparency",
    Min = 0,
    Max = 1,
    Default = 1,
    Round = 2,
    Flag = "FOV_Transparency",
    Callback = function(Value)
        FOVCircle.Transparency = Value
    end
});

VisualSection:AddSlider({
    Name = "FOV Thickness",
    Min = 1,
    Max = 5,
    Default = 2,
    Round = 0,
    Flag = "FOV_Thickness",
    Callback = function(Value)
        FOVCircle.Thickness = Value
    end
});

-- ==================== SETTINGS TAB ====================
Window:DrawCategory({
    Name = "Settings"
});

local SettingTab = Window:DrawTab({
    Icon = "settings",
    Name = "UI Settings",
    Type = "Single",
    EnableScrolling = true
});

local ThemeTab = Window:DrawTab({
    Icon = "paintbrush",
    Name = "Themes",
    Type = "Single"
});

local Settings = SettingTab:DrawSection({
    Name = "UI Customization",
});

Settings:AddToggle({
    Name = "Always Show Frame",
    Default = false,
    Callback = function(v)
        Window.AlwayShowTab = v;
    end,
});

Settings:AddColorPicker({
    Name = "Highlight",
    Default = Compkiller.Colors.Highlight,
    Callback = function(v)
        Compkiller.Colors.Highlight = v;
        Compkiller:RefreshCurrentColor();
    end,
});

Settings:AddColorPicker({
    Name = "Toggle Color",
    Default = Compkiller.Colors.Toggle,
    Callback = function(v)
        Compkiller.Colors.Toggle = v;
        Compkiller:RefreshCurrentColor(v);
    end,
});

Settings:AddColorPicker({
    Name = "Drop Color",
    Default = Compkiller.Colors.DropColor,
    Callback = function(v)
        Compkiller.Colors.DropColor = v;
        Compkiller:RefreshCurrentColor(v);
    end,
});

Settings:AddButton({
    Name = "Get Theme",
    Callback = function()
        print(Compkiller:GetTheme())
        
        Notifier.new({
            Title = "Notification",
            Content = "Copied Theme Color to clipboard",
            Duration = 5,
            Icon = "rbxassetid://71610633224812"
        });
    end,
});

Settings:AddButton({
    Name = "Destroy UI",
    Callback = function()
        Notifier.new({
            Title = "Destroying UI",
            Content = "Goodbye!",
            Duration = 1,
            Icon = "rbxassetid://71610633224812"
        });
        
        task.wait(1)
        
        getgenv().silentaim = false
        
        -- Destroy FOV Circle
        if FOVCircle then
            FOVCircle:Remove()
        end
        
        pcall(function()
            if ToggleGui then 
                ToggleGui:Destroy() 
            end
        end)
        
        pcall(function()
            for _, gui in pairs(playerGui:GetChildren()) do
                if gui.Name:find("Compkiller") or gui.Name:find("Watermark") or gui.Name == "ToggleGui" then
                    gui:Destroy()
                end
            end
        end)
        
        task.wait(0.5)
        script:Destroy()
        
        print("UI Destroyed Successfully!")
    end,
});

ThemeTab:DrawSection({
    Name = "UI Themes"
}):AddDropdown({
    Name = "Select Theme",
    Default = "Default",
    Values = {
        "Default",
        "Dark Green",
        "Dark Blue",
        "Purple Rose",
        "Skeet"
    },
    Callback = function(v)
        Compkiller:SetTheme(v)
    end,
})

-- Creating Config Tab
local ConfigUI = Window:DrawConfig({
    Name = "Config",
    Icon = "folder",
    Config = ConfigManager
});

ConfigUI:Init();

print("✅ Undetectable Silent Aim Loaded!")
print("🎯 Dynamic Target System: ACTIVE")
print("⭕ FOV Circle: ENABLED")
print("⏱️ Cooldown System: READY")
print("🔐 Anti-Detection: ACTIVE")
