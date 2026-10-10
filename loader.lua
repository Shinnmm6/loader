-- ============================================
-- LOADER — fetches WindUI + payload
-- ============================================
local API_URL   = "https://key-system-production-a74e.up.railway.app/auth"
local SCRIPT_ID = "default"
local KEY_FILE  = "myscript_key.txt"

-- WindUI source URL (update this if WindUI moves)
local WINDUI_URL = "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
-- ============================================

local HttpService = game:GetService("HttpService")

-- ---------- HWID ----------
local function getHWID()
    local ok, id = pcall(function()
        if gethwid then return gethwid() end
        if syn and syn.get_hwid then return syn.get_hwid() end
        if KRNL_LOADED and get_hwid then return get_hwid() end
        if identifyexecutor then
            return identifyexecutor() .. "-" .. game.PlaceId .. "-" .. game.JobId
        end
        return "unknown-" .. game.PlaceId
    end)
    return ok and tostring(id) or "unknown"
end

-- ---------- Key storage ----------
local function readKeyFile()
    if readfile and isfile and isfile(KEY_FILE) then
        local ok, data = pcall(readfile, KEY_FILE)
        if ok then return data end
    end
    return nil
end
local function writeKeyFile(k)
    if writefile then pcall(writefile, KEY_FILE, k) end
end

-- ---------- Auth ----------
local function authenticate(key)
    local body = HttpService:JSONEncode({
        key = key,
        hwid = getHWID(),
        script = SCRIPT_ID,
    })

    local ok, response = pcall(function()
        return request({
            Url = API_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body,
        })
    end)

    if not ok then return nil, "network error" end
    if not response or not response.Body then return nil, "empty response" end

    local decoded
    local ok2 = pcall(function() decoded = HttpService:JSONDecode(response.Body) end)
    if not ok2 or not decoded then return nil, "bad response" end
    if not decoded.ok then return nil, decoded.error or "auth failed" end

    return decoded.payload
end

-- ---------- WindUI loader ----------
local function loadWindUI()
    if getgenv().WindUI then return true end

    local ok, src = pcall(function()
        return game:HttpGet(WINDUI_URL)
    end)
    if not ok or not src or #src < 100 then
        warn("[Loader] Failed to fetch WindUI")
        return false
    end

    local fn, err = loadstring(src)
    if not fn then
        warn("[Loader] WindUI compile error: " .. tostring(err))
        return false
    end

    local ok2, ui = pcall(fn)
    if not ok2 or not ui then
        warn("[Loader] WindUI runtime error: " .. tostring(ui))
        return false
    end

    getgenv().WindUI = ui
    return true
end

-- ---------- Key UI (uses WindUI if available, else plain) ----------
local function createKeyUI()
    if getgenv()._keyUI then
        pcall(function() getgenv()._keyUI:Destroy() end)
        getgenv()._keyUI = nil
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "KeySystemUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not gui.Parent then
        pcall(function() gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end)
    end
    getgenv()._keyUI = gui

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 340, 0, 220)
    panel.Position = UDim2.new(0.5, -170, 0.5, -110)
    panel.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
    panel.BorderSizePixel = 0
    panel.Parent = gui
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(50, 58, 72)
    stroke.Parent = panel

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 44)
    title.Position = UDim2.new(0, 0, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = "Key System"
    title.TextColor3 = Color3.fromRGB(230, 232, 235)
    title.TextSize = 22
    title.Font = Enum.Font.GothamBold
    title.Parent = panel

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -20, 0, 18)
    sub.Position = UDim2.new(0, 10, 0, 52)
    sub.BackgroundTransparency = 1
    sub.Text = "Enter your key to continue"
    sub.TextColor3 = Color3.fromRGB(139, 147, 161)
    sub.TextSize = 13
    sub.Font = Enum.Font.Gotham
    sub.Parent = panel

    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(1, -40, 0, 42)
    inputFrame.Position = UDim2.new(0, 20, 0, 84)
    inputFrame.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = panel
    Instance.new("UICorner", inputFrame).CornerRadius = UDim.new(0, 8)

    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = Color3.fromRGB(42, 49, 64)
    inputStroke.Parent = inputFrame

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -20, 1, 0)
    input.Position = UDim2.new(0, 10, 0, 0)
    input.BackgroundTransparency = 1
    input.Text = ""
    input.PlaceholderText = "KEY-XXXXXXXX..."
    input.PlaceholderColor3 = Color3.fromRGB(90, 98, 112)
    input.TextColor3 = Color3.fromRGB(230, 232, 235)
    input.TextSize = 14
    input.Font = Enum.Font.Gotham
    input.ClearTextOnFocus = false
    input.TextXAlignment = Enum.TextXAlignment.Left
    input.Parent = inputFrame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -40, 0, 42)
    btn.Position = UDim2.new(0, 20, 0, 138)
    btn.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
    btn.Text = "Submit"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 15
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = panel
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -20, 0, 16)
    status.Position = UDim2.new(0, 10, 1, -22)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = Color3.fromRGB(248, 113, 113)
    status.TextSize = 12
    status.Font = Enum.Font.Gotham
    status.Parent = panel

    -- drag
    local dragging, dragStart, startPos
    panel.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = inp.Position; startPos = panel.Position
        end
    end)
    panel.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local delta = inp.Position - dragStart
            panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local function submit()
        local k = input.Text:gsub("%s+", "")
        if #k < 4 then
            status.Text = "Please enter a valid key"
            return
        end
        status.TextColor3 = Color3.fromRGB(251, 191, 36)
        status.Text = "Checking..."
        btn.Text = "..."

        task.spawn(function()
            local payload, err = authenticate(k)
            if not payload then
                status.TextColor3 = Color3.fromRGB(248, 113, 113)
                status.Text = tostring(err)
                btn.Text = "Submit"
                return
            end

            status.TextColor3 = Color3.fromRGB(126, 231, 135)
            status.Text = "Success!"
            btn.Text = "Loading..."
            writeKeyFile(k)
            task.wait(0.3)
            gui:Destroy()
            getgenv()._keyUI = nil

            -- Make sure WindUI is available before running the payload
            loadWindUI()

            local fn, compileErr = loadstring(payload)
            if not fn then
                warn("[Loader] Payload compile error: " .. tostring(compileErr))
                return
            end
            local ok, runErr = pcall(fn)
            if not ok then
                warn("[Loader] Payload runtime error: " .. tostring(runErr))
            end
        end)
    end

    btn.MouseButton1Click:Connect(submit)
    input.FocusLost:Connect(function(enter) if enter then submit() end end)
end

-- ---------- Main ----------
local function main()
    -- Pre-fetch WindUI silently so it's ready when payload runs
    task.spawn(loadWindUI)

    local saved = readKeyFile()
    if saved then
        saved = saved:gsub("%s+", "")
        if #saved > 0 then
            local payload, err = authenticate(saved)
            if payload then
                local fn, compileErr = loadstring(payload)
                if fn then
                    local ok, runErr = pcall(fn)
                    if not ok then warn("[Loader] Payload runtime error: " .. tostring(runErr)) end
                    return
                else
                    warn("[Loader] Payload compile error: " .. tostring(compileErr))
                end
            else
                warn("[Loader] Saved key failed: " .. tostring(err))
                if delfile and isfile and isfile(KEY_FILE) then pcall(delfile, KEY_FILE) end
            end
        end
    end

    createKeyUI()
end

main()
