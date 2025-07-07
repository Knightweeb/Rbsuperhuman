---

### 2. `autofarm-superhuman.lua`

```lua
if not game:IsLoaded() then game.Loaded:Wait() end
local plr = game.Players.LocalPlayer
local rs = game:GetService("ReplicatedStorage")
local ws = game:GetService("Workspace")
local ts = game:GetService("TweenService")

-- Performance boost
if getfpscap then setfpscap(30) end
for _, v in pairs(game:GetDescendants()) do
    if v:IsA("Texture") or v:IsA("Decal") then
        v.Transparency = 1
    end
end

local styles = {"Dark Step", "Electric", "Water Kung Fu", "Dragon Breath"}
local masteryGoal = 300
local currentStyleIndex = 1

local function getStyleTool(name)
    return plr.Backpack:FindFirstChild(name) or (plr.Character and plr.Character:FindFirstChild(name))
end

local function equipStyle(name)
    local tool = getStyleTool(name)
    if tool then
        tool.Parent = plr.Character
        plr.Character.Humanoid:EquipTool(tool)
        return true
    end
    return false
end

local function getStyleMastery(name)
    local tool = getStyleTool(name)
    if tool and tool:FindFirstChild("Level") then
        return tool.Level.Value
    end
    return 0
end

local function tpTo(pos)
    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = plr.Character.HumanoidRootPart
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear)
        local tween = ts:Create(hrp, tweenInfo, {CFrame = CFrame.new(pos.X, pos.Y + 5, pos.Z)})
        tween:Play()
        tween.Completed:Wait()
    end
end

local function buyStyle(name)
    local shop = ws:FindFirstChild("Shop")
    if not shop then return false end
    local styleButton = nil
    for _, btn in pairs(shop:GetChildren()) do
        if btn.Name == name then
            styleButton = btn
            break
        end
    end
    if not styleButton then
        warn("Style "..name.." not found in shop")
        return false
    end
    tpTo(styleButton.Position or Vector3.new(0, 100, 0))
    task.wait(1)
    pcall(function()
        rs.Remotes.ShopBuy:InvokeServer("Style", name)
    end)
    print("Bought style: "..name)
    task.wait(2)
    return true
end

local function getNearestMob()
    local enemies = ws.Enemies:GetChildren()
    local closest, dist = nil, math.huge
    for _, mob in ipairs(enemies) do
        if mob:FindFirstChild("HumanoidRootPart") and mob.Humanoid.Health > 0 then
            local d = (plr.Character.HumanoidRootPart.Position - mob.HumanoidRootPart.Position).Magnitude
            if d < dist then
                dist = d
                closest = mob
            end
        end
    end
    return closest
end

local function attackMob(mob)
    repeat
        pcall(function()
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                plr.Character.HumanoidRootPart.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0, 15, 0)
                rs.Remotes.Combat:FireServer(mob)
            end
        end)
        task.wait(0.2)
    until not mob or mob.Humanoid.Health <= 0
end

print("Starting Superhuman AutoFarm & AutoBuy")

while currentStyleIndex <= #styles do
    local styleName = styles[currentStyleIndex]

    if not getStyleTool(styleName) then
        print("Buying missing style: "..styleName)
        buyStyle(styleName)
        task.wait(3)
    end

    if not equipStyle(styleName) then
        warn("Failed to equip style "..styleName..", retrying...")
        task.wait(2)
        continue
    end

    while getStyleMastery(styleName) < masteryGoal do
        local mob = getNearestMob()
        if mob then
            attackMob(mob)
        else
            warn("No mobs found! Waiting...")
            task.wait(2)
        end
        task.wait(0.1)
    end

    print(styleName.." mastery reached "..masteryGoal)
    currentStyleIndex = currentStyleIndex + 1
    task.wait(2)
end

print("✅ All styles farmed! You can now unlock Superhuman!")
