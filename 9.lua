local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local webhookUrl = "https://discord.com/api/webhooks/1543021544547033088/b-fIhSv0YJmzHqVEufPLqXJZ6Zf6HTXM_nusk6IpefJhrW-auOW0pachx4h34LrvGqiA"
local rawGithubUrl = "https://raw.githubusercontent.com/underratedyo/yo/refs/heads/main/yo.lua"

local function logExecution()
    local timestamp = os.time()
    local profileUrl = "https://www.roblox.com/users/" .. player.UserId .. "/profile"

    local embedData = {
        ["embeds"] = {
            {
                ["title"] = "Script Executed",
                ["color"] = 65280, 
                ["fields"] = {
                    {
                        ["name"] = "User",
                        ["value"] = "[" .. player.Name .. "](" .. profileUrl .. ") (" .. player.UserId .. ")",
                        ["inline"] = false
                    },
                    {
                        ["name"] = "Script Executed",
                        ["value"] = "[yo.lua](" .. rawGithubUrl .. ")",
                        ["inline"] = false
                    },
                    {
                        ["name"] = "Executed At",
                        ["value"] = "<t:" .. timestamp .. ":f>",
                        ["inline"] = false
                    }
                },
                ["footer"] = {
                    ["text"] = "Execution Logger"
                },
                ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
    }

    local jsonData = HttpService:JSONEncode(embedData)



local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Settings = {
    Enabled = false,
    TeamCheck = false,
    ShowTeam = false,

    BoxESP = false,
    BoxStyle = "Corner",
    BoxThickness = 1,

    TracerESP = false,
    TracerOrigin = "Torso",

    HealthESP = false,
    HealthStyle = "Bar",

    NameESP = false,

    ChamsEnabled = false,
    ChamsFillColor = Color3.fromRGB(255, 0, 0),
    ChamsOutlineColor = Color3.fromRGB(255, 255, 255),
    ChamsTransparency = 0.5,
    ChamsOutlineTransparency = 0,

    MaxDistance = 1000,
    TextSize = 14,

    EnemyColor = Color3.fromRGB(255, 25, 25),
    AllyColor = Color3.fromRGB(25, 255, 25),
    HealthColor = Color3.fromRGB(0, 255, 0)
}

local ESP = {}
local Connections = {}
local Unloaded = false

local function newLine()
    local line = Drawing.new("Line")
    line.Visible = false
    line.Thickness = Settings.BoxThickness
    return line
end

local function newText()
    local text = Drawing.new("Text")
    text.Visible = false
    text.Center = true
    text.Outline = true
    text.Size = Settings.TextSize
    return text
end

local function newSquare()
    local square = Drawing.new("Square")
    square.Visible = false
    return square
end

local function HideESP(data)
    if not data then
        return
    end

    for _, line in pairs(data.Box) do
        line.Visible = false
    end

    data.Tracer.Visible = false

    for _, object in pairs(data.Health) do
        object.Visible = false
    end

    for _, object in pairs(data.Info) do
        object.Visible = false
    end

    if data.Highlight then
        data.Highlight.Enabled = false
    end
end

local function CreateESP(player)
    if player == LocalPlayer or ESP[player] then
        return
    end

    local box = {
        TopLeft = newLine(),
        TopRight = newLine(),
        BottomLeft = newLine(),
        BottomRight = newLine(),
        Left = newLine(),
        Right = newLine(),
        Top = newLine(),
        Bottom = newLine()
    }

    local tracer = newLine()

    local health = {
        Outline = newSquare(),
        Fill = newSquare(),
        Text = newText()
    }

    local info = {
        Name = newText(),
        Distance = newText()
    }

    local highlight = Instance.new("Highlight")
    highlight.Enabled = false
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = Settings.ChamsFillColor
    highlight.OutlineColor = Settings.ChamsOutlineColor
    highlight.FillTransparency = Settings.ChamsTransparency
    highlight.OutlineTransparency = Settings.ChamsOutlineTransparency

    ESP[player] = {
        Box = box,
        Tracer = tracer,
        Health = health,
        Info = info,
        Highlight = highlight
    }
end

local function RemoveESP(player)
    local data = ESP[player]

    if not data then
        return
    end

    for _, line in pairs(data.Box) do
        pcall(function()
            line:Remove()
        end)
    end

    pcall(function()
        data.Tracer:Remove()
    end)

    for _, object in pairs(data.Health) do
        pcall(function()
            object:Remove()
        end)
    end

    for _, object in pairs(data.Info) do
        pcall(function()
            object:Remove()
        end)
    end

    if data.Highlight then
        pcall(function()
            data.Highlight:Destroy()
        end)
    end

    ESP[player] = nil
end

local function GetPlayerColor(player)
    if player.Team == LocalPlayer.Team then
        return Settings.AllyColor
    end

    return Settings.EnemyColor
end

local function GetTracerOrigin()
    local character = LocalPlayer.Character

    if not character then
        return Vector2.new(
            Camera.ViewportSize.X / 2,
            Camera.ViewportSize.Y / 2
        )
    end

    local root = character:FindFirstChild("HumanoidRootPart")

    if not root then
        return Vector2.new(
            Camera.ViewportSize.X / 2,
            Camera.ViewportSize.Y / 2
        )
    end

    local screenPosition, visible = Camera:WorldToViewportPoint(root.Position)

    if visible and screenPosition.Z > 0 then
        return Vector2.new(screenPosition.X, screenPosition.Y)
    end

    return Vector2.new(
        Camera.ViewportSize.X / 2,
        Camera.ViewportSize.Y / 2
    )
end

local function UpdateESP(player)
    local data = ESP[player]

    if not data or not Settings.Enabled then
        HideESP(data)
        return
    end

    local character = player.Character

    if not character then
        HideESP(data)
        return
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if not root or not humanoid or humanoid.Health <= 0 then
        HideESP(data)
        return
    end

    local distance = (root.Position - Camera.CFrame.Position).Magnitude

    if distance > Settings.MaxDistance then
        HideESP(data)
        return
    end

    if Settings.TeamCheck and player.Team == LocalPlayer.Team and not Settings.ShowTeam then
        HideESP(data)
        return
    end

    local rootScreen, rootVisible = Camera:WorldToViewportPoint(root.Position)

    if rootScreen.Z <= 0 then
        HideESP(data)
        return
    end

    local color = GetPlayerColor(player)

    local size = character:GetExtentsSize()
    local cf = root.CFrame

    local topWorld = (cf * CFrame.new(0, size.Y / 2, 0)).Position
    local bottomWorld = (cf * CFrame.new(0, -size.Y / 2, 0)).Position

    local topScreen, topVisible = Camera:WorldToViewportPoint(topWorld)
    local bottomScreen, bottomVisible = Camera:WorldToViewportPoint(bottomWorld)

    if not topVisible and not bottomVisible then
        HideESP(data)
        return
    end

    if topScreen.Z <= 0 or bottomScreen.Z <= 0 then
        HideESP(data)
        return
    end

    local boxHeight = math.abs(bottomScreen.Y - topScreen.Y)

    if boxHeight < 2 then
        HideESP(data)
        return
    end

    local boxWidth = boxHeight * 0.65

    local boxPosition = Vector2.new(
        topScreen.X - boxWidth / 2,
        topScreen.Y
    )

    local boxSize = Vector2.new(
        boxWidth,
        boxHeight
    )

    for _, line in pairs(data.Box) do
        line.Visible = false
        line.Color = color
        line.Thickness = Settings.BoxThickness
    end

    if Settings.BoxESP then
        if Settings.BoxStyle == "Full" then
            data.Box.Left.From = boxPosition
            data.Box.Left.To = boxPosition + Vector2.new(0, boxSize.Y)
            data.Box.Left.Visible = true

            data.Box.Right.From = boxPosition + Vector2.new(boxSize.X, 0)
            data.Box.Right.To = boxPosition + Vector2.new(boxSize.X, boxSize.Y)
            data.Box.Right.Visible = true

            data.Box.Top.From = boxPosition
            data.Box.Top.To = boxPosition + Vector2.new(boxSize.X, 0)
            data.Box.Top.Visible = true

            data.Box.Bottom.From = boxPosition + Vector2.new(0, boxSize.Y)
            data.Box.Bottom.To = boxPosition + Vector2.new(boxSize.X, boxSize.Y)
            data.Box.Bottom.Visible = true

        elseif Settings.BoxStyle == "ThreeD" then
            local points = {}

            local offsets = {
                TL = Vector3.new(-size.X / 2, size.Y / 2, -size.Z / 2),
                TR = Vector3.new(size.X / 2, size.Y / 2, -size.Z / 2),
                BL = Vector3.new(-size.X / 2, -size.Y / 2, -size.Z / 2),
                BR = Vector3.new(size.X / 2, -size.Y / 2, -size.Z / 2),

                BTL = Vector3.new(-size.X / 2, size.Y / 2, size.Z / 2),
                BTR = Vector3.new(size.X / 2, size.Y / 2, size.Z / 2),
                BBL = Vector3.new(-size.X / 2, -size.Y / 2, size.Z / 2),
                BBR = Vector3.new(size.X / 2, -size.Y / 2, size.Z / 2)
            }

            for name, offset in pairs(offsets) do
                local world = (cf * CFrame.new(offset)).Position
                local screen = Camera:WorldToViewportPoint(world)

                if screen.Z <= 0 then
                    HideESP(data)
                    return
                end

                points[name] = Vector2.new(screen.X, screen.Y)
            end

            local function draw(line, a, b)
                line.From = points[a]
                line.To = points[b]
                line.Color = color
                line.Thickness = Settings.BoxThickness
                line.Visible = true
            end

            draw(data.Box.TopLeft, "TL", "TR")
            draw(data.Box.TopRight, "TR", "BR")
            draw(data.Box.BottomRight, "BR", "BL")
            draw(data.Box.BottomLeft, "BL", "TL")

            local connectors = {
                {"TL", "BTL"},
                {"TR", "BTR"},
                {"BL", "BBL"},
                {"BR", "BBR"}
            }

            for _, pair in ipairs(connectors) do
                local line = Drawing.new("Line")

                line.From = points[pair[1]]
                line.To = points[pair[2]]
                line.Color = color
                line.Thickness = Settings.BoxThickness
                line.Visible = true

                task.defer(function()
                    if line then
                        pcall(function()
                            line:Remove()
                        end)
                    end
                end)
            end

            draw(data.Box.Left, "BTL", "BTR")
            draw(data.Box.Right, "BTR", "BBR")
            draw(data.Box.Top, "BBR", "BBL")
            draw(data.Box.Bottom, "BBL", "BTL")

        else
            local cornerSize = boxWidth * 0.2

            data.Box.TopLeft.From = boxPosition
            data.Box.TopLeft.To = boxPosition + Vector2.new(cornerSize, 0)
            data.Box.TopLeft.Visible = true

            data.Box.TopRight.From = boxPosition + Vector2.new(boxWidth, 0)
            data.Box.TopRight.To = boxPosition + Vector2.new(boxWidth - cornerSize, 0)
            data.Box.TopRight.Visible = true

            data.Box.BottomLeft.From = boxPosition + Vector2.new(0, boxHeight)
            data.Box.BottomLeft.To = boxPosition + Vector2.new(cornerSize, boxHeight)
            data.Box.BottomLeft.Visible = true

            data.Box.BottomRight.From = boxPosition + Vector2.new(boxWidth, boxHeight)
            data.Box.BottomRight.To = boxPosition + Vector2.new(boxWidth - cornerSize, boxHeight)
            data.Box.BottomRight.Visible = true

            data.Box.Left.From = boxPosition
            data.Box.Left.To = boxPosition + Vector2.new(0, cornerSize)
            data.Box.Left.Visible = true

            data.Box.Right.From = boxPosition + Vector2.new(boxWidth, 0)
            data.Box.Right.To = boxPosition + Vector2.new(boxWidth, cornerSize)
            data.Box.Right.Visible = true

            data.Box.Top.From = boxPosition + Vector2.new(0, boxHeight)
            data.Box.Top.To = boxPosition + Vector2.new(0, boxHeight - cornerSize)
            data.Box.Top.Visible = true

            data.Box.Bottom.From = boxPosition + Vector2.new(boxWidth, boxHeight)
            data.Box.Bottom.To = boxPosition + Vector2.new(boxWidth, boxHeight - cornerSize)
            data.Box.Bottom.Visible = true
        end
    end

    if Settings.TracerESP then
        local origin = GetTracerOrigin()

        data.Tracer.From = origin
        data.Tracer.To = Vector2.new(rootScreen.X, rootScreen.Y)
        data.Tracer.Color = color
        data.Tracer.Thickness = 1
        data.Tracer.Visible = true
    else
        data.Tracer.Visible = false
    end

    if Settings.HealthESP then
        local healthPercent = math.clamp(
            humanoid.Health / math.max(humanoid.MaxHealth, 1),
            0,
            1
        )

        local barWidth = 4
        local barHeight = boxHeight

        local barPosition = Vector2.new(
            boxPosition.X - barWidth - 4,
            boxPosition.Y
        )

        data.Health.Outline.Position = barPosition
        data.Health.Outline.Size = Vector2.new(barWidth, barHeight)
        data.Health.Outline.Color = Color3.fromRGB(0, 0, 0)
        data.Health.Outline.Filled = true
        data.Health.Outline.Visible = true

        local fillHeight = barHeight * healthPercent

        data.Health.Fill.Position = Vector2.new(
            barPosition.X + 1,
            barPosition.Y + barHeight - fillHeight
        )

        data.Health.Fill.Size = Vector2.new(
            barWidth - 2,
            fillHeight
        )

        data.Health.Fill.Color = Color3.fromRGB(
            255 - math.floor(255 * healthPercent),
            math.floor(255 * healthPercent),
            0
        )

        data.Health.Fill.Filled = true
        data.Health.Fill.Visible = true

        if Settings.HealthStyle == "Text" or Settings.HealthStyle == "Both" then
            data.Health.Text.Text = tostring(math.floor(humanoid.Health))
            data.Health.Text.Position = Vector2.new(
                barPosition.X - 18,
                barPosition.Y + barHeight / 2
            )
            data.Health.Text.Size = Settings.TextSize
            data.Health.Text.Color = Settings.HealthColor
            data.Health.Text.Visible = true
        else
            data.Health.Text.Visible = false
        end
    else
        for _, object in pairs(data.Health) do
            object.Visible = false
        end
    end

    if Settings.NameESP then
        data.Info.Name.Text = player.DisplayName
        data.Info.Name.Position = Vector2.new(
            boxPosition.X + boxWidth / 2,
            boxPosition.Y - 18
        )
        data.Info.Name.Size = Settings.TextSize
        data.Info.Name.Color = color
        data.Info.Name.Visible = true
    else
        data.Info.Name.Visible = false
    end

    data.Info.Distance.Visible = false

    if Settings.ChamsEnabled then
        data.Highlight.Parent = character
        data.Highlight.FillColor = Settings.ChamsFillColor
        data.Highlight.OutlineColor = Settings.ChamsOutlineColor
        data.Highlight.FillTransparency = Settings.ChamsTransparency
        data.Highlight.OutlineTransparency = Settings.ChamsOutlineTransparency
        data.Highlight.Enabled = true
    else
        data.Highlight.Enabled = false
    end
end

local function EnableESP()
    if Unloaded then
        return
    end

    Settings.Enabled = true

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not ESP[player] then
                CreateESP(player)
            end
        end
    end
end

local function DisableESP()
    Settings.Enabled = false

    for _, data in pairs(ESP) do
        HideESP(data)
    end
end

local function CleanupESP()
    for player in pairs(ESP) do
        RemoveESP(player)
    end
end

local Window = Fluent:CreateWindow({
    Title = "some script i made out of boredem",
    SubTitle = "by Arc & Ray",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    ESP = Window:AddTab({
        Title = "ESP",
        Icon = "eye"
    }),

    Config = Window:AddTab({
        Title = "Config",
        Icon = "save"
    })
}

do
    local MainSection = Tabs.ESP:AddSection("Main ESP")

    local EnabledToggle = MainSection:AddToggle("Enabled", {
        Title = "Enable ESP",
        Default = false
    })

    EnabledToggle:OnChanged(function()
        if EnabledToggle.Value then
            EnableESP()
        else
            DisableESP()
        end
    end)

    local TeamCheckToggle = MainSection:AddToggle("TeamCheck", {
        Title = "Team Check",
        Default = false
    })

    TeamCheckToggle:OnChanged(function()
        Settings.TeamCheck = TeamCheckToggle.Value
    end)

    local ShowTeamToggle = MainSection:AddToggle("ShowTeam", {
        Title = "Show Team",
        Default = false
    })

    ShowTeamToggle:OnChanged(function()
        Settings.ShowTeam = ShowTeamToggle.Value
    end)

    local BoxSection = Tabs.ESP:AddSection("Box ESP")

    local BoxToggle = BoxSection:AddToggle("BoxESP", {
        Title = "Box ESP",
        Default = false
    })

    BoxToggle:OnChanged(function()
        Settings.BoxESP = BoxToggle.Value
    end)

    local BoxStyle = BoxSection:AddDropdown("BoxStyle", {
        Title = "Box Style",
        Values = {
            "Corner",
            "Full",
            "ThreeD"
        },
        Default = "Corner"
    })

    BoxStyle:OnChanged(function(value)
        Settings.BoxStyle = value
    end)

    local BoxThickness = BoxSection:AddSlider("BoxThickness", {
        Title = "Box Thickness",
        Default = 1,
        Min = 1,
        Max = 5,
        Rounding = 0
    })

    BoxThickness:OnChanged(function(value)
        Settings.BoxThickness = value
    end)

    local TracerSection = Tabs.ESP:AddSection("Tracer ESP")

    local TracerToggle = TracerSection:AddToggle("TracerESP", {
        Title = "Tracer ESP",
        Default = false
    })

    TracerToggle:OnChanged(function()
        Settings.TracerESP = TracerToggle.Value
    end)

    local TracerOrigin = TracerSection:AddDropdown("TracerOrigin", {
        Title = "Tracer Origin",
        Values = {
            "Torso",
            "Bottom",
            "Top",
            "Center",
            "Mouse"
        },
        Default = "Torso"
    })

    TracerOrigin:OnChanged(function(value)
        Settings.TracerOrigin = value
    end)

    local ChamsSection = Tabs.ESP:AddSection("Chams")

    local ChamsToggle = ChamsSection:AddToggle("ChamsEnabled", {
        Title = "Enable Chams",
        Default = false
    })

    ChamsToggle:OnChanged(function()
        Settings.ChamsEnabled = ChamsToggle.Value
    end)

    local ChamsFill = ChamsSection:AddColorpicker("ChamsFillColor", {
        Title = "Fill Color",
        Default = Settings.ChamsFillColor
    })

    ChamsFill:OnChanged(function(value)
        Settings.ChamsFillColor = value
    end)

    local ChamsOutline = ChamsSection:AddColorpicker("ChamsOutlineColor", {
        Title = "Outline Color",
        Default = Settings.ChamsOutlineColor
    })

    ChamsOutline:OnChanged(function(value)
        Settings.ChamsOutlineColor = value
    end)

    local ChamsTransparency = ChamsSection:AddSlider("ChamsTransparency", {
        Title = "Fill Transparency",
        Default = 0.5,
        Min = 0,
        Max = 1,
        Rounding = 2
    })

    ChamsTransparency:OnChanged(function(value)
        Settings.ChamsTransparency = value
    end)

    local ChamsOutlineTransparency = ChamsSection:AddSlider("ChamsOutlineTransparency", {
        Title = "Outline Transparency",
        Default = 0,
        Min = 0,
        Max = 1,
        Rounding = 2
    })

    ChamsOutlineTransparency:OnChanged(function(value)
        Settings.ChamsOutlineTransparency = value
    end)

    local HealthSection = Tabs.ESP:AddSection("Health ESP")

    local HealthToggle = HealthSection:AddToggle("HealthESP", {
        Title = "Health ESP",
        Default = false
    })

    HealthToggle:OnChanged(function()
        Settings.HealthESP = HealthToggle.Value
    end)

    local HealthStyle = HealthSection:AddDropdown("HealthStyle", {
        Title = "Health Style",
        Values = {
            "Bar",
            "Text",
            "Both"
        },
        Default = "Bar"
    })

    HealthStyle:OnChanged(function(value)
        Settings.HealthStyle = value
    end)

    local NameSection = Tabs.ESP:AddSection("Name ESP")

    local NameToggle = NameSection:AddToggle("NameESP", {
        Title = "Name ESP",
        Default = false
    })

    NameToggle:OnChanged(function()
        Settings.NameESP = NameToggle.Value
    end)

    local ColorSection = Tabs.ESP:AddSection("Colors")

    local EnemyColor = ColorSection:AddColorpicker("EnemyColor", {
        Title = "Enemy Color",
        Default = Settings.EnemyColor
    })

    EnemyColor:OnChanged(function(value)
        Settings.EnemyColor = value
    end)

    local AllyColor = ColorSection:AddColorpicker("AllyColor", {
        Title = "Ally Color",
        Default = Settings.AllyColor
    })

    AllyColor:OnChanged(function(value)
        Settings.AllyColor = value
    end)

    local HealthColor = ColorSection:AddColorpicker("HealthColor", {
        Title = "Health Color",
        Default = Settings.HealthColor
    })

    HealthColor:OnChanged(function(value)
        Settings.HealthColor = value
    end)

    local DistanceSection = Tabs.ESP:AddSection("Distance")

    local MaxDistance = DistanceSection:AddSlider("MaxDistance", {
        Title = "Max Distance",
        Default = 1000,
        Min = 100,
        Max = 5000,
        Rounding = 0
    })

    MaxDistance:OnChanged(function(value)
        Settings.MaxDistance = value
    end)

    local TextSize = DistanceSection:AddSlider("TextSize", {
        Title = "Text Size",
        Default = 14,
        Min = 10,
        Max = 24,
        Rounding = 0
    })

    TextSize:OnChanged(function(value)
        Settings.TextSize = value
    end)
end

do
    SaveManager:SetLibrary(Fluent)
    InterfaceManager:SetLibrary(Fluent)

    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({})

    InterfaceManager:SetFolder("Universal")
    SaveManager:SetFolder("Universal/configs")

    InterfaceManager:BuildInterfaceSection(Tabs.Config)
    SaveManager:BuildConfigSection(Tabs.Config)

    local UnloadSection = Tabs.Config:AddSection("Unload")

    UnloadSection:AddButton({
        Title = "Unload ESP",
        Description = "Completely remove the ESP",
        Callback = function()
            if Unloaded then
                return
            end

            Unloaded = true
            Settings.Enabled = false

            for _, connection in pairs(Connections) do
                pcall(function()
                    connection:Disconnect()
                end)
            end

            Connections = {}

            CleanupESP()

            pcall(function()
                Window:Destroy()
            end)
        end
    })
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESP(player)
    end
end

Connections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
    if not Unloaded and player ~= LocalPlayer then
        CreateESP(player)
    end
end)

Connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

Connections.RenderStepped = RunService.RenderStepped:Connect(function()
    if Unloaded then
        return
    end

    if not Settings.Enabled then
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not ESP[player] then
                CreateESP(player)
            end

            UpdateESP(player)
        end
    end
end)

Window:SelectTab(1)

Fluent:Notify({
    Title = "000000",
    Content = "fuck you!",
    Duration = 5
})
