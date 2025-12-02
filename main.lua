--==============================================================--
-- AwesomeAJ • GitHub Loader (ThanHub-Style Key System)
--==============================================================--

if not script_key or not discord_id or script_key == "" or discord_id == "" then
    warn("[AwesomeAJ] Missing script_key or discord_id!")
    return
end

local HttpService = game:GetService("HttpService")

-- GitHub raw URLs
local key_url = "https://raw.githubusercontent.com/galvaomart/awesomeaj-public/main/keys.json"
local script_url = "https://raw.githubusercontent.com/galvaomart/awesomeaj-public/main/script.lua"

-- function to GET from GitHub
local function httpget(u)
    local req = request or http_request or syn and syn.request
    if req then
        local r = req({Url = u, Method = "GET"})
        return r.Body
    else
        return game:HttpGet(u)
    end
end

-- fetch key database
local ok, rawKeys = pcall(function()
    return httpget(key_url)
end)

if not ok then
    warn("[AwesomeAJ] Failed to download key database.")
    return
end

local keys = {}

local success, json = pcall(function()
    keys = HttpService:JSONDecode(rawKeys)
end)

if not success then
    warn("[AwesomeAJ] keys.json is invalid!")
    return
end

-- validate key
local entry = keys[script_key]

if not entry then
    warn("[AwesomeAJ] Invalid key.")
    return
end

if tostring(entry.discord_id) ~= tostring(discord_id) then
    warn("[AwesomeAJ] This key does not belong to this Discord ID.")
    return
end

-- Expiry check
local now = os.time()
local expiry_time = os.time(DateTime.fromIsoDate(entry.expires_at):ToUniversalTime())

if now > expiry_time then
    warn("[AwesomeAJ] Key expired.")
    return
end

print("[AwesomeAJ] Key verified. Loading script...")

-- download & execute real script
local real_code = httpget(script_url)
loadstring(real_code)()
