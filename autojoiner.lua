--==============================================================--
--  AWESOME AJ — AUTO JOINER (2025 CHILLI UPDATE, MINIMAL UI)
--  • AutoJoin toggle: T
--  • Tiny filter GUI (M/s)
--  • Premium stacked notifications (right side)
--==============================================================--

local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local parent = gethui and gethui() or game:GetService("CoreGui")

local SERVER_URL = "http://127.0.0.1:8765/latest_job"

local AutoJoinEnabled = false
local MinMoneyFilter = 0                     -- M/s filter (change in GUI)
local lastJobId = nil                        -- last joined / notified job
local notifications = {}                     -- active notification frames

--==============================================================--
--  TINY FILTER GUI (BOTTOM LEFT)
--==============================================================--

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AwesomeAJ_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = parent

local FilterFrame = Instance.new("Frame")
FilterFrame.Name = "FilterFrame"
FilterFrame.Size = UDim2.new(0, 180, 0, 60)
FilterFrame.Position = UDim2.new(0, 15, 1, -80)
FilterFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
FilterFrame.BackgroundTransparency = 0.1
FilterFrame.BorderSizePixel = 0
FilterFrame.Parent = ScreenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = FilterFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Thickness = 1
stroke.Transparency = 0.7
stroke.Parent = FilterFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -10, 0, 22)
Title.Position = UDim2.new(0, 8, 0, 4)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamSemibold
Title.TextSize = 14
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Text = "Filter (M/s) • T = AutoJoin"
Title.Parent = FilterFrame

local Input = Instance.new("TextBox")
Input.Size = UDim2.new(0, 70, 0, 24)
Input.Position = UDim2.new(0, 8, 0, 30)
Input.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Input.BorderSizePixel = 0
Input.ClearTextOnFocus = false
Input.Font = Enum.Font.Gotham
Input.TextSize = 14
Input.PlaceholderText = "0"
Input.Text = tostring(MinMoneyFilter)
Input.TextColor3 = Color3.fromRGB(255, 255, 255)
Input.Parent = FilterFrame

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 6)
inputCorner.Parent = Input

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, -90, 0, 24)
InfoLabel.Position = UDim2.new(0, 86, 0, 30)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.TextSize = 13
InfoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel.Text = "Only show ≥ filter"
InfoLabel.Parent = FilterFrame

Input.FocusLost:Connect(function()
    local num = tonumber(Input.Text)
    if num then
        MinMoneyFilter = num
        Input.Text = tostring(num)
    else
        Input.Text = tostring(MinMoneyFilter)
    end
end)

--==============================================================--
--  CLEAN NOTIFICATION SYSTEM (TOP RIGHT)
--==============================================================--

local NOTIF_WIDTH = 230
local NOTIF_HEIGHT = 40
local NOTIF_LIFETIME = 3.0   -- seconds

local function layoutNotifications()
    for i, frame in ipairs(notifications) do
        frame.Position = UDim2.new(
            1, -NOTIF_WIDTH - 20,
            0, 20 + (i - 1) * (NOTIF_HEIGHT + 6)
        )
    end
end

local function removeNotification(frame)
    for i, f in ipairs(notifications) do
        if f == frame then
            table.remove(notifications, i)
            break
        end
    end
    if frame then
        frame:Destroy()
    end
    layoutNotifications()
end

local function createNotification(name, money)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, NOTIF_WIDTH, 0, NOTIF_HEIGHT)
    frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = ScreenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.7
    stroke.Thickness = 1
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -10, 0, 22)
    title.Position = UDim2.new(0, 8, 0, 2)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamSemibold
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = tostring(name or "Unknown")
    title.Parent = frame

    local moneyLabel = Instance.new("TextLabel")
    moneyLabel.Size = UDim2.new(1, -10, 0, 16)
    moneyLabel.Position = UDim2.new(0, 8, 0, 22)
    moneyLabel.BackgroundTransparency = 1
    moneyLabel.Font = Enum.Font.Gotham
    moneyLabel.TextSize = 13
    moneyLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
    moneyLabel.Text = string.format("$%s M/s", tostring(money or "?"))
    moneyLabel.Parent = frame

    table.insert(notifications, frame)
    layoutNotifications()

    task.spawn(function()
        task.wait(NOTIF_LIFETIME)
        -- Simple fade out
        for i = 1, 10 do
            frame.BackgroundTransparency = 0.2 + i * 0.06
            title.TextTransparency = i * 0.06
            moneyLabel.TextTransparency = i * 0.06
            task.wait(0.03)
        end
        removeNotification(frame)
    end)
end

--==============================================================--
--  AUTOJOIN TOGGLE (KEYBIND ONLY)
--==============================================================--

local function printToggle()
    local state = AutoJoinEnabled and "ON" or "OFF"
    print("[AwesomeAJ] AutoJoin:", state)
    createNotification("AutoJoin " .. state, MinMoneyFilter .. "+ M/s filter")
end

UIS.InputBegan:Connect(function(key, gp)
    if gp then return end
    if key.KeyCode == Enum.KeyCode.T then
        AutoJoinEnabled = not AutoJoinEnabled
        printToggle()
    end
end)

--==============================================================--
--  CHILLI UI DETECTION (WORKING VERSION)
--==============================================================--

local function findUI()
    local inputBox
    local joinButton

    for _, obj in ipairs(parent:GetDescendants()) do
        local path = obj:GetFullName():lower()

        -- Only look inside the ChilliLibUI ContentHolder tree
        if path:find("chillilibui") and path:find("contentholder") then
            if obj:IsA("TextBox") then
                inputBox = obj
            end

            if obj:IsA("TextButton") and obj.Text and obj.Text:lower():find("join job") then
                joinButton = obj
            end
        end
    end

    return inputBox, joinButton
end

local function fireSafe(signal, ...)
    if firesignal and signal then
        pcall(firesignal, signal, ...)
    end
end

local function pressJoin(btn)
    if not btn then return end
    fireSafe(btn.MouseButton1Down)
    fireSafe(btn.MouseButton1Click)
    fireSafe(btn.MouseButton1Up)
    pcall(function() btn:Activate() end)
end

local function applyJob(jobId)
    local inputBox, joinButton = findUI()

    if not inputBox or not joinButton then
        -- no Chilli UI yet
        return
    end

    pcall(function() inputBox:CaptureFocus() end)
    task.wait(0.05)

    inputBox.Text = jobId
    task.wait(0.05)

    fireSafe(inputBox:GetPropertyChangedSignal("Text"), jobId)
    fireSafe(inputBox.FocusLost, true)

    pcall(function() inputBox:ReleaseFocus() end)
    task.wait(0.1)

    pressJoin(joinButton)
end

--==============================================================--
--  MAIN LOOP: FETCH FROM PYTHON + NOTIFY + AUTOJOIN
--==============================================================--

task.spawn(function()
    print("[AwesomeAJ] Auto Joiner listening on:", SERVER_URL)

    while true do
        task.wait(0.25)

        local ok, raw = pcall(function()
            return game:HttpGet(SERVER_URL)
        end)

        if not ok or not raw or raw == "" then
            -- Python not ready yet
            continue
        end

        local data
        local parsed = pcall(function()
            data = HttpService:JSONDecode(raw)
        end)

        if not parsed or not data or not data.job_id or data.job_id == "" then
            continue
        end

        local jobId = data.job_id
        local name = data.name or "Unknown"
        local moneyVal = tonumber(data.money) or 0

        -- Filter: only brainrots above threshold
        if moneyVal < MinMoneyFilter then
            continue
        end

        -- Prevent repeated spam for same job
        if lastJobId == jobId then
            continue
        end
        lastJobId = jobId

        -- Notification
        createNotification(name, moneyVal)

        -- AutoJoin if enabled
        if AutoJoinEnabled then
            applyJob(jobId)
        end
    end
end)

print("🔥 Awesome AJ Auto Joiner loaded. T = toggle AutoJoin, edit filter in bottom-left GUI.")
