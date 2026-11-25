---@diagnostic disable: need-check-nil
-- Main file, handles addon logic
local ADDON_NAME, addon = ...
addon.addonName = "BlacklistWarden"
addon.addonTitle = addon.L["Blacklist Warden"]

-- Addon namespace
BlacklistWarden = LibStub("AceAddon-3.0"):NewAddon(addon.addonName, "AceConsole-3.0", "AceHook-3.0", "AceEvent-3.0",
    "AceTimer-3.0")
-- Addon widgets
local blacklistPopupWindow = nil;
local blacklistPopupWarning = nil;
local blacklistListWindow = nil;
-- Minimap button setup
local LDB = LibStub("LibDataBroker-1.1"):NewDataObject(addon.addonName, {
    type = "data source",
    text = "PPB",
    icon = "Interface\\Icons\\Spell_Mage_Evanesce",
    OnTooltipShow = function(tooltip)
        tooltip:SetText(addon.L["Blacklist Warden"])
        tooltip:AddLine(" ")
        tooltip:AddLine(addon.L["Left click: |cffFFFFFFOpen player list"])
        tooltip:AddLine(addon.L["Right click: |cffFFFFFFOpen settings"])
        tooltip:Show()
    end,
    OnClick = function(frame, button)
        if button == "RightButton" then
            BlacklistWarden:OpenSettings()
        elseif button == "LeftButton" then
            BlacklistWarden:ShowListWindow()
        end
    end,
})


-- Settings options
local options = {
    name = addon.addonTitle,
    handler = BlacklistWarden,
    type = 'group',
    args = {
        headerGeneralOptions = {
            order = 0,
            type = "header",
            name = addon.L["General Options"],
        },
        blacklistPopup = {
            order = 1,
            type = 'toggle',
            name = addon.L['Toggle blacklist popup'],
            desc = addon.L['Shows a popup when blacklisting a player that lets you add extra information, otherwise adds the player with default values.'],
            set = "SetShowPopup",
            get = "GetShowPopup",
            width = "full"
        },
        blacklistAnnouncement = {
            order = 2,
            type = 'toggle',
            name = addon.L['Enable blacklist announcements'],
            desc = addon.L['Announces in the party channel when a blacklisted player is detected in the group.'],
            set = "SetBlacklistAnnouncement",
            get = "GetBlacklistAnnouncement",
            width = "full"
        },
        lockWindows = {
            order = 3,
            type = 'toggle',
            name = addon.L['Lock windows'],
            desc = addon.L['Locks the addon\'s windows, preventing them from moving.'],
            set = "SetLockWindows",
            get = "GetLockWindows",
            width = "full"
        },
        minimapIcon = {
            order = 4,
            type = 'toggle',
            name = addon.L['Toggle minimap icon'],
            desc = addon.L['Toggles the minimap icon.'],
            set = "SetShowIcon",
            get = "GetShowIcon",
            width = "full"
        },
        leaverText = {
            order = 5,
            type = 'toggle',
            name = addon.L['Toggle leaver messages'],
            desc = addon.L['Toggles a chat message when other players leave the group, which provides a link you can right click to make it easier to add leavers.'],
            set = "SetLeaverText",
            get = "GetLeaverText",
            width = "full"
        },
        headerCredits = {
            order = 11,
            type = "header",
            name = addon.L["Credits"],
        },
        creditsDescription1 = {
            order = 12,
            type = "description",
            name = addon.L["|cffF58CBADiuxtros|r @ Icecrown (US) - |cffFF8000Author|r"],
            width = "full"
        },
        creditsDescription2 = {
            order = 13,
            type = "description",
            name = addon.L["|cff3FC7EBMascascora|r @ Galakrond (CN) - |cffFF8000Chinese localization|r"],
            width = "full"
        },
    },
}
--AceDB defaults
local defaults = {
    global = {
        blacklistedPlayers = {},
        dataCleanupV1 = false,
        previousGroupSize = 0,
        blacklistPopupWindowOptions = {
            addon.L["All"],
            addon.L["Bad player"],
            addon.L["Quitter"],
            addon.L["AFKer"],
            addon.L["Toxic"],
            addon.L["Scammer"],
            addon.L["Bigot"],
            addon.L["Other"]
        }
    },
    profile = {
        showPopup = true,
        blacklistAnnouncement = false,
        minimap = {
            hide = false,
        },
        lockWindows = true,
        leaverText = true,
        blacklistPopupFrame = {
            point = "TOP",
            relativeFrame = nil,
            relativePoint = "TOP",
            ofsx = 0,
            ofsy = -50,
        },
        blacklistWarningFrame = {
            point = "TOP",
            relativeFrame = nil,
            relativePoint = "TOP",
            ofsx = 0,
            ofsy = -100,
        },
        listFrame = {
            point = "CENTER",
            relativeFrame = nil,
            relativePoint = "CENTER",
            ofsx = 0,
            ofsy = 0,
        },
    }
}
local classNamesById = {
    "WARRIOR",
    "PALADIN",
    "HUNTER",
    "ROGUE",
    "PRIEST",
    "DEATHKNIGHT",
    "SHAMAN",
    "MAGE",
    "WARLOCK",
    "MONK",
    "DRUID",
    "DEMONHUNTER",
    "EVOKER",
}
-- More libs
LibStub("AceConfig-3.0"):RegisterOptionsTable(addon.addonName, options)
local aceDialog = LibStub("AceConfigDialog-3.0");
local icon = LibStub("LibDBIcon-1.0")

-- Register slash commands, init libraries
function BlacklistWarden:OnInitialize()
    self:RegisterChatCommand("blacklistwarden", "SlashCommand")
    self:RegisterChatCommand("BLW", "SlashCommand")
    self:RegisterChatCommand("blw", "SlashCommand")
    self.db = LibStub("AceDB-3.0"):New("BlacklistWardenDB", defaults)
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addon.addonName, options)
    self.optionsFrame, self.optionsId = aceDialog:AddToBlizOptions(addon.addonName, addon.addonName)
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "CheckPlayersOnGroupUpdate");
    icon:Register("BlacklistWarden", LDB, BlacklistWarden.db.profile.minimap)
end

function BlacklistWarden:ConverTableToLower()
    -- Temporary table to store modified keys
    local tempTable = {}

    -- Collect keys that need to be changed
    for key, value in pairs(BlacklistWarden.db.global.blacklistedPlayers) do
        tempTable[key:lower()] = value
    end

    -- Clear the original table and add the modified keys
    for key in pairs(BlacklistWarden.db.global.blacklistedPlayers) do
        BlacklistWarden.db.global.blacklistedPlayers[key] = nil
    end

    for key, value in pairs(tempTable) do
        BlacklistWarden.db.global.blacklistedPlayers[key] = value
        if BlacklistWarden.db.global.blacklistedPlayers[key]["muted"]==nil then 
            BlacklistWarden.db.global.blacklistedPlayers[key]["muted"]=true
        end
    end

    -- Print the modified original table to verify the changes
   -- for key, value in pairs(BlacklistWarden.db.global.blacklistedPlayers) do
    --    print(key, value)
   -- end
end

-- On Forever, re-key every saved entry with the name+surname key format. This also fixes
-- entries saved by older versions that used an empty realm. Safe to run on every load.
function BlacklistWarden:RekeyForForever()
    if not addon.isForever then return end
    local players = BlacklistWarden.db.global.blacklistedPlayers
    local rekeyed = {}
    for key, player in pairs(players) do
        if type(player) == "table" and player.name then
            player.server = player.server or ""
            rekeyed[BlacklistWarden:PlayerKey(player)] = player
        else
            rekeyed[key] = player
        end
    end
    for key in pairs(players) do players[key] = nil end
    for key, player in pairs(rekeyed) do players[key] = player end
end

-- Errors raised while building windows, shown by /blw debug
BlacklistWarden.initErrors = {}

-- Builds one window, catching errors so one broken window doesn't stop the others
-- from loading (and so the error can be reported instead of failing silently).
local function SafeCreate(label, builder)
    local ok, result = xpcall(builder, function(err)
        return tostring(err) .. "\n" .. (debugstack and debugstack(2, 8, 0) or "")
    end)
    if ok then return result end
    table.insert(BlacklistWarden.initErrors, label .. ": " .. tostring(result))
    print("|cffFF0000" .. addon.L["Blacklist Warden: "] .. "|r" .. label ..
        " failed to load. Type /blw debug for details.")
    return nil
end

-- Create and store widgets
function BlacklistWarden:OnEnable()
    if (not BlacklistWarden.db.global.dataCleanupV1) then
        BlacklistWarden:ConverTableToLower()
        BlacklistWarden.db.global.dataCleanupV1 = true
    end
    BlacklistWarden:RekeyForForever()

    local locked = BlacklistWarden.db.profile.lockWindows
    blacklistPopupWindow = SafeCreate("Popup window", function() return BlacklistWarden:CreateBlacklistPopupWindow() end)
    blacklistPopupWarning = SafeCreate("Warning window", function() return BlacklistWarden:CreateBlacklistWarningWindow() end)
    blacklistListWindow = SafeCreate("List window", function() return BlacklistWarden:CreateListFrame() end)
    if blacklistPopupWindow then blacklistPopupWindow:SetMovable(not locked) end
    if blacklistPopupWarning then blacklistPopupWarning:SetMovable(not locked) end
    if blacklistListWindow then blacklistListWindow:SetMovable(not locked) end
    BlacklistWarden.db.global.previousGroupSize = GetNumGroupMembers()
end

-- Opens the list window, or explains why it can't
function BlacklistWarden:ShowListWindow()
    if blacklistListWindow then
        blacklistListWindow:Show()
    else
        print("|cffFF0000" .. addon.L["Blacklist Warden: "] .. "|rThe list window failed to load. Type /blw debug for details.")
    end
end

-- Temporary player info to store
local playerInfo = {}

local previousMembers = {}

local acknowledgedBlacklistPlayers = {}

-- Called by the warning window's "Stay" button so this specific blacklisted
-- player stops re-triggering the popup for the rest of the current group,
-- without affecting any other blacklisted player who might also be present.
function BlacklistWarden:AcknowledgeBlacklistedPlayer(fullnameLower)
    if fullnameLower then
        acknowledgedBlacklistPlayers[fullnameLower] = true
    end
end

-- Callback for GROUP_ROSTER_UPDATE, checks and warns if any player is in your blacklist
function BlacklistWarden:CheckPlayersOnGroupUpdate()
    local groupCount = GetNumGroupMembers()
    local name, realm;
    local newMembers = {}
    local unitID;
    for i = 1, groupCount do
        if groupCount < 6 then
            unitID = "party" .. i
        else
            unitID = "raid" .. i
        end
        name, realm = UnitName(unitID)
        if name and not (issecretvalue and issecretvalue(name)) then
            realm = BlacklistWarden:ResolveRealm(realm)
            local key = BlacklistWarden:MakeKey(name, realm)
            local displayName = BlacklistWarden:DisplayName(name, realm)
            local classBase, classId = UnitClassBase(unitID)
            newMembers[key] = { classId = classId, name = name, server = realm }
            -- Check only newly seen members. This also handles a member swap
            -- where the group size does not change, and joining an existing group.
            if not previousMembers[key] then
                local blacklistedPlayer = BlacklistWarden.db.global.blacklistedPlayers[key]
                if blacklistedPlayer and BlacklistWarden.db.profile.blacklistAnnouncement then
                    SendChatMessage(addon.L["Detected blacklisted member "] .. displayName ..
                        addon.L[", blacklist reason: "] ..
                        (blacklistedPlayer.reason or addon.L["Not specified"]), "PARTY")
                end
                if blacklistedPlayer and not acknowledgedBlacklistPlayers[key] then
                    if blacklistPopupWarning then
                        blacklistPopupWarning.setPlayerData(blacklistedPlayer)
                        blacklistPopupWarning:Show()
                    end
                end
            end
        end
    end
    local ownName, ownSecond = UnitName("player")
    local ownKey = BlacklistWarden:MakeKey(ownName, BlacklistWarden:ResolveRealm(ownSecond))
    if BlacklistWarden.db.profile.leaverText then
        for key, member in pairs(previousMembers) do
            if not newMembers[key] and key ~= ownKey and member.classId then
                -- Player has left the group. The link target uses Name-Second so the
                -- right-click menu splits it back into name and realm/surname.
                local linkTarget = member.server ~= "" and (member.name .. "-" .. member.server) or member.name
                print("|cffFFFF00" .. addon.L["Blacklist Warden: "] .. "|Hplayer:" ..
                    linkTarget .. ":" .. (member.classId + 4000000000) ..
                    "|h|cffd80000[" .. BlacklistWarden:DisplayName(member.name, member.server) ..
                    addon.L["]|r|h has left the group."])
            end
        end
    end


    previousMembers = newMembers
    BlacklistWarden.db.global.previousGroupSize = groupCount;

    if groupCount == 0 then
        acknowledgedBlacklistPlayers = {}
    end
end

-- Open the options panel on any client (Settings API on modern clients, legacy Interface Options otherwise)
function BlacklistWarden:OpenSettings()
    if Settings and Settings.OpenToCategory and self.optionsId then
        Settings.OpenToCategory(self.optionsId)
    elseif InterfaceOptionsFrame_OpenToCategory and self.optionsFrame then
        -- Called twice: the legacy panel often fails to scroll to the category on the first call
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    end
end

-- Slash commands
function BlacklistWarden:SlashCommand(msg)
    if not msg or msg:trim() == "" then
        print(addon.L["|cffFFFF00/blw settings -|r Opens the settings window"])
        print(addon.L["|cffFFFF00/blw list -|r Opens the list window"])
    elseif string.lower(msg:trim()) == "settings" then
        BlacklistWarden:OpenSettings()
    elseif string.lower(msg:trim()) == "list" then
        BlacklistWarden:ShowListWindow()
    elseif string.lower(msg:trim()) == "debug" then
        BlacklistWarden:PrintDebugInfo()
    end
end

-- /blw debug: prints what the addon sees on this client, to help diagnose problems
function BlacklistWarden:PrintDebugInfo()
    local function line(label, value) print("|cffFFC000" .. label .. ":|r " .. tostring(value)) end
    local version, build, _, toc = GetBuildInfo()
    print("|cffFFFF00--- Blacklist Warden debug ---|r")
    line("Client", tostring(version) .. " build " .. tostring(build) .. " interface " .. tostring(toc))
    line("WOW_PROJECT_ID", WOW_PROJECT_ID)
    line("Detected Forever", addon.isForever)
    line("GetRealmName()", "'" .. tostring(GetRealmName and GetRealmName()) .. "'")
    line("GetNormalizedRealmName()", "'" .. tostring(GetNormalizedRealmName and GetNormalizedRealmName()) .. "'")
    local n, s = UnitName("player")
    line("UnitName(player)", "'" .. tostring(n) .. "', '" .. tostring(s) .. "'")
    if UnitFullName then
        local fn, fs = UnitFullName("player")
        line("UnitFullName(player)", "'" .. tostring(fn) .. "', '" .. tostring(fs) .. "'")
    end
    if UnitExists("target") and UnitIsPlayer("target") then
        local tn, ts = UnitName("target")
        line("UnitName(target)", "'" .. tostring(tn) .. "', '" .. tostring(ts) .. "'")
        line("Target key", BlacklistWarden:MakeKey(tn, BlacklistWarden:ResolveRealm(ts)))
    end
    line("Own key", BlacklistWarden:MakeKey(n, BlacklistWarden:ResolveRealm(s)))
    line("Settings API", Settings and Settings.OpenToCategory and "yes" or "no")
    line("Menu API", Menu and Menu.ModifyMenu and "yes" or "no")
    line("MenuUtil", MenuUtil and MenuUtil.CreateContextMenu and "yes" or "no")
    line("TooltipDataProcessor", TooltipDataProcessor and "yes" or "no")
    line("C_LFGList", C_LFGList and "yes" or "no")
    line("Windows", "popup=" .. tostring(blacklistPopupWindow ~= nil) ..
        " warning=" .. tostring(blacklistPopupWarning ~= nil) ..
        " list=" .. tostring(blacklistListWindow ~= nil))
    local count = 0
    for _ in pairs(BlacklistWarden.db.global.blacklistedPlayers or {}) do count = count + 1 end
    line("Saved players", count)
    if #BlacklistWarden.initErrors == 0 then
        line("Load errors", "none")
    else
        for _, err in ipairs(BlacklistWarden.initErrors) do
            print("|cffFF0000Load error:|r " .. err)
        end
    end
end

-- Setters/getters for settings window
function BlacklistWarden:GetShowPopup(info)
    return BlacklistWarden.db.profile.showPopup;
end

function BlacklistWarden:SetShowPopup(info, value)
    BlacklistWarden.db.profile.showPopup = value;
end

function BlacklistWarden:GetBlacklistAnnouncement(info)
    return BlacklistWarden.db.profile.blacklistAnnouncement;
end

function BlacklistWarden:SetBlacklistAnnouncement(info, value)
    BlacklistWarden.db.profile.blacklistAnnouncement = value;
end

function BlacklistWarden:GetLeaverText(info)
    return BlacklistWarden.db.profile.leaverText;
end

function BlacklistWarden:SetLeaverText(info, value)
    BlacklistWarden.db.profile.leaverText = value;
end

function BlacklistWarden:GetLockWindows(info)
    return BlacklistWarden.db.profile.lockWindows;
end

function BlacklistWarden:SetLockWindows(info, value)
    BlacklistWarden.db.profile.lockWindows = value;
    if blacklistPopupWindow then blacklistPopupWindow:SetMovable(not value) end
    if blacklistPopupWarning then blacklistPopupWarning:SetMovable(not value) end
    if blacklistListWindow then blacklistListWindow:SetMovable(not value) end
end

function BlacklistWarden:GetShowIcon(info)
    return not BlacklistWarden.db.profile.minimap.hide;
end

function BlacklistWarden:SetShowIcon(info, value)
    value = not value
    BlacklistWarden.db.profile.minimap.hide = value;
    if value then
        icon:Hide("BlacklistWarden")
    else
        icon:Show("BlacklistWarden")
    end
end

-- Save temporary player info
function BlacklistWarden:SavePlayerInfoValue(key, value)
    playerInfo[key] = value;
end

--[[ Player identity
Every saved entry has `name` and `server`. What `server` means depends on the client:
  * Retail: the realm. Key "name-realm", shown as "Name-Realm".
  * WoW Forever: there are no realms (GetRealmName() returns ""). UnitName() returns
    (first name, surname), so `server` holds the surname, or "" if the character has none.
    Key "first surname" (or just "first"), shown as "First Surname".
All key and display building goes through the helpers below, so no other code needs to
know which client it is running on.
]]

local function IsUsableString(value)
    return type(value) == "string" and value ~= "" and not (issecretvalue and issecretvalue(value))
end

-- Returns the realm (or the surname on Forever) to store for a player.
-- Retail: the given realm, or your own realm when it's missing (same-realm players).
-- Forever: the given surname, or "" when the character has none.
function BlacklistWarden:ResolveRealm(realm)
    if IsUsableString(realm) then
        return realm
    end
    if addon.isForever then
        return ""
    end
    local own = GetRealmName and GetRealmName()
    if not own or own == "" then
        own = GetNormalizedRealmName and GetNormalizedRealmName()
    end
    return own or ""
end

-- Lowercase lookup key for the saved blacklist
function BlacklistWarden:MakeKey(name, server)
    name = name or ""
    server = server or ""
    if addon.isForever then
        if server ~= "" then
            return (name .. " " .. server):lower()
        end
        return name:lower()
    end
    return (name .. "-" .. server):lower()
end

-- Text shown to the user for a player
function BlacklistWarden:DisplayName(name, server)
    name = name or ""
    server = server or ""
    if server == "" then return name end
    if addon.isForever then
        return name .. " " .. server
    end
    return name .. "-" .. server
end

function BlacklistWarden:PlayerKey(player)
    return BlacklistWarden:MakeKey(player["name"], player["server"])
end

function BlacklistWarden:PlayerDisplayName(player)
    return BlacklistWarden:DisplayName(player["name"], player["server"])
end

-- Splits a full name string into name and realm (or name and surname on Forever).
-- Accepts "Name-Realm", "Name", and on Forever also "First Surname" / "First-Surname".
-- Also accepts a key produced by MakeKey.
function BlacklistWarden:FormatName(fullname)
    if not IsUsableString(fullname) then return nil, BlacklistWarden:ResolveRealm() end
    fullname = fullname:match("^%s*(.-)%s*$")
    local name, realm
    if addon.isForever then
        -- Character names can't contain spaces or hyphens, so either one separates the surname
        name, realm = fullname:match("^([^%s%-]+)[%s%-]+(.+)$")
        if not name then name = fullname end
    elseif fullname:find("-", nil, true) then
        name, realm = strsplit("-", fullname, 2)
    else
        name = fullname
    end
    return name, BlacklistWarden:ResolveRealm(realm)
end

-- Turns any full name or key string into the saved-list key
function BlacklistWarden:KeyFromFullName(fullname)
    local name, realm = BlacklistWarden:FormatName(fullname)
    if not name then return nil end
    return BlacklistWarden:MakeKey(name, realm)
end

-- Returns the saved entry for a full name / key string, or nil
function BlacklistWarden:GetPlayer(fullname)
    if not BlacklistWarden.db then return nil end
    local players = BlacklistWarden.db.global.blacklistedPlayers
    if not players then return nil end
    local key = BlacklistWarden:KeyFromFullName(fullname)
    return key and players[key] or nil
end

-- Stores the temporary player info in the database
function BlacklistWarden:WritePlayerToDisk()
    local date = date("%m/%d/%Y %H:%M:%S")
    playerInfo["playerServer"] = BlacklistWarden:ResolveRealm(playerInfo["playerServer"])
    local playerName = BlacklistWarden:MakeKey(playerInfo["playerName"], playerInfo["playerServer"])
    local playerNameString = BlacklistWarden:DisplayName(playerInfo["playerName"], playerInfo["playerServer"])
    local player = BlacklistWarden.db.global.blacklistedPlayers[playerName]
    if player ~= nil then
        date = player["date"]
    end
    BlacklistWarden.db.global.blacklistedPlayers[playerName] = {
        ["name"] = playerInfo["playerName"],
        ["server"] = playerInfo["playerServer"],
        ["class"] = playerInfo["playerClass"],
        ["reason"] = playerInfo["reason"],
        ["notes"] = playerInfo["notes"],
        ["date"] = date,
        ["muted"]=playerInfo["muted"]
    }
    if not player then
        print("|cffFF0000" .. playerNameString .. "|r" .. addon.L[" added to blacklist."])
        if blacklistListWindow then
            blacklistListWindow.addEntry(BlacklistWarden.db.global.blacklistedPlayers
                [playerName])
        end
    else
        print("|cffFF0000" .. playerNameString .. "|r" .. addon.L[" successfully modified."])
        if blacklistListWindow then
            blacklistListWindow.updateEntry(BlacklistWarden.db.global.blacklistedPlayers
                [playerName])
        end
    end

    playerInfo = {}
end

-- Onclick handler for the dropdown blacklist option
function BlacklistWarden:BlacklistButton()
    if BlacklistWarden.db.profile.showPopup then
        if blacklistPopupWindow then
            blacklistPopupWindow.title:SetText(addon.L["ADD TO BLACKLIST"])
            blacklistPopupWindow.setPlayerName({
                ["name"] = playerInfo["playerName"],
                ["server"] = playerInfo
                    ["playerServer"],
                ["class"] = playerInfo["playerClass"]
            })
            blacklistPopupWindow.dropdown:SetValue(1)
            BlacklistWarden:SavePlayerInfoValue("reason",
                BlacklistWarden.db.global.blacklistPopupWindowOptions[1])
            blacklistPopupWindow.editbox:SetText("")
            blacklistPopupWindow.checkbox:SetValue(true)
            blacklistPopupWindow:Show()
        end
    else
        BlacklistWarden:SavePlayerInfoValue("reason",
            BlacklistWarden.db.global.blacklistPopupWindowOptions[1])
        BlacklistWarden:SavePlayerInfoValue("notes", "")
        BlacklistWarden:SavePlayerInfoValue("muted", true)
        BlacklistWarden:WritePlayerToDisk();
    end
end

-- Edit player entry from the list window
function BlacklistWarden:EditEntry(playername)
    local player = BlacklistWarden:GetPlayer(playername)
    if not player or not blacklistPopupWindow then return end
    playerInfo = {
        ["playerName"] = player["name"],
        ["playerServer"] = player["server"],
        ["playerClass"] = player["class"],
        ["reason"] = player["reason"]
    }
    blacklistPopupWindow.setPlayerName(player)
    blacklistPopupWindow.title:SetText(addon.L["EDIT"])
    for i = 1, #BlacklistWarden.db.global.blacklistPopupWindowOptions do
        if BlacklistWarden.db.global.blacklistPopupWindowOptions[i] == player["reason"] then
            blacklistPopupWindow.dropdown:SetValue(i)
            break;
        end
    end
    blacklistPopupWindow.editbox:SetText(player["notes"])
    blacklistPopupWindow.checkbox:SetValue(player["muted"])
    BlacklistWarden:TogglePopupWindow(true)
end

function BlacklistWarden:TogglePopupWindow(on)
    if on then
        blacklistPopupWindow:Show()
    else
        blacklistPopupWindow:Hide()
    end
end

-- Remove player from blacklist
function BlacklistWarden:RemovePlayer(name)
    if not BlacklistWarden.db.global.blacklistedPlayers then BlacklistWarden.db.global.blacklistedPlayers = {} end
    local key = BlacklistWarden:KeyFromFullName(name) or name:lower()
    local player = BlacklistWarden.db.global.blacklistedPlayers[key]
    if not player then return end
    local displayName = BlacklistWarden:PlayerDisplayName(player)
    if blacklistListWindow then
        blacklistListWindow.removeEntry(player)
    end
    BlacklistWarden.db.global.blacklistedPlayers[key] = nil;
    print("|cFF00FF00" .. displayName .. "|r" .. addon.L[" removed from blacklist."])
end

--check if player is on blacklist
function BlacklistWarden:IsPlayerInList(name)
    return BlacklistWarden:GetPlayer(name) ~= nil
end

--Tooltip module
do
    --Add info on tooltip for blacklisted players
    local function AddToTooltip(tooltip, player)
        tooltip:AddLine(" ")
        tooltip:AddLine("|cffFFC000" .. addon.L["Blacklist Warden - |rBlacklisted"], 1, 0, 0, false)
        tooltip:AddLine("|cffFFC000" .. addon.L["Reason: |r"] .. player.reason .. "|r", 1, 1, 1, false)
        if player.notes and player.notes ~= "" then
            tooltip:AddLine("|cffFFC000" .. addon.L["Note: |r"] .. player.notes, 1, 1, 1, true)
        end
        tooltip:AddLine(" ")
    end

    --Callback for unit tooltips
    local function OnTooltipSetUnit(tooltip, data)
        if tooltip ~= GameTooltip then return end

        local _, unit = tooltip:GetUnit()

        -- issecretvalue only exists on retail (Midnight); Forever may not have it
        if issecretvalue and issecretvalue(unit) then return end

        if unit and UnitIsPlayer(unit) and not UnitIsUnit(unit, "player") then
            local name, realm = UnitName(unit)
            if not IsUsableString(name) then return end
            local key = BlacklistWarden:MakeKey(name, BlacklistWarden:ResolveRealm(realm))
            local player = BlacklistWarden.db.global.blacklistedPlayers[key]
            if not player then return end

            AddToTooltip(tooltip, player);
        end
    end

    --Hook for leader tooltips in LFG
    local function SetSearchEntry(tooltip, resultID, autoAcceptOption)
        if resultID then
            local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)
            if not searchResultInfo or not searchResultInfo.leaderName then return end
            if issecretvalue and issecretvalue(searchResultInfo.leaderName) then return end
            local player = BlacklistWarden:GetPlayer(searchResultInfo.leaderName)
            if not player then return end

            AddToTooltip(tooltip, player)
        end
    end

    local hooked = {}

    --Callback for applicants in lFG
    local function OnEnterHook(self)
        if self.applicantID and self.Members then
            for i = 1, #self.Members do
                local b = self.Members[i]
                if not hooked[b] then
                    hooked[b] = 1
                    b:HookScript("OnEnter", OnEnterHook)
                end
            end
        elseif self.memberIdx then
            local fullName = C_LFGList.GetApplicantMemberInfo(self:GetParent().applicantID, self.memberIdx)
            if IsUsableString(fullName) then
                local player = BlacklistWarden:GetPlayer(fullName)
                if not player then return end
                local hasOwner = GameTooltip:GetOwner()
                if not hasOwner then
                    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                end
                --GameTooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 0, 0)
                AddToTooltip(GameTooltip, player)
                GameTooltip:Show()
            end
        end
    end

    --Hook for applicants in LFG (not every client has the same group finder UI)
    local function HookApplicationViewer(self)
        local scrollBox = LFGListFrame and LFGListFrame.ApplicationViewer and LFGListFrame.ApplicationViewer.ScrollBox
        if not scrollBox then return end
        if scrollBox.buttons then
            for i = 1, #scrollBox.buttons do
                local button = scrollBox.buttons[i]
                if not hooked[button] then
                    button:HookScript("OnEnter", OnEnterHook)
                    hooked[button] = true
                end
            end
        end
        local frames = scrollBox.GetFrames and scrollBox:GetFrames()
        if frames and frames[1] then
            for i = 1, #frames do
                local button = frames[i]
                if not hooked[button] then
                    button:HookScript("OnEnter", OnEnterHook)
                    hooked[button] = true
                end
            end
        end
    end

    if LFGListApplicationViewer_UpdateResults then
        hooksecurefunc("LFGListApplicationViewer_UpdateResults", HookApplicationViewer)
    end

    --Unit tooltips: use TooltipDataProcessor when available, otherwise OnTooltipSetUnit
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnTooltipSetUnit)
    else
        GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnit)
    end

    if LFGListUtil_SetSearchEntryTooltip then
        hooksecurefunc("LFGListUtil_SetSearchEntryTooltip", SetSearchEntry)
    end
end

--Context menu module
do
    local module = BlacklistWarden:NewModule("ContextMenuModule")
    module.enabled = false

    function module:HasMenu()
        return Menu and Menu.ModifyMenu
    end

    local function IsValidName(contextData)
        return contextData.name and strsub(contextData.name, 1, 1) ~= "|"
    end

    --Handles the blacklist option on the context menu when right clicking a player
    function module:MenuHandler(owner, rootDescription, contextData)
        local realm;
        local name;
        local class = nil;
        local _;

        if not contextData then
            if rootDescription.tag == "MENU_LFG_FRAME_SEARCH_ENTRY" or rootDescription.tag == "MENU_LFG_FRAME_MEMBER_APPLY" then
                name, realm, class = self:GetLFGInfo(owner)
            end
        else
            if not IsValidName(contextData) then return end
            -- Some clients pass "Name-Realm" (or "First Surname" on Forever) in name,
            -- or an empty string instead of nil for server
            name, realm = BlacklistWarden:FormatName(contextData.name)
            if IsUsableString(contextData.server) then
                realm = contextData.server
            end
            -- When the menu is for a unit, UnitName is the most reliable source:
            -- (name, realm) on Retail, (first name, surname) on Forever
            if contextData.unit and UnitExists(contextData.unit) then
                local unitName, unitSecond = UnitName(contextData.unit)
                if IsUsableString(unitName) then
                    name, realm = unitName, unitSecond
                end
            end
            local guid

            if contextData.lineID then
                if tonumber(contextData.lineID) < 4000000000 then
                    guid = C_ChatInfo.GetChatLineSenderGUID(contextData.lineID)
                else
                    class = classNamesById[tonumber(contextData.lineID) - 4000000000]
                end
            elseif contextData.unit then
                guid = UnitGUID(contextData.unit)
            else
                return
            end
            if not class and guid then
                local guidRealm
                _, class, _, _, _, _, guidRealm = GetPlayerInfoByGUID(guid)
                -- guidRealm is "" for players on your own realm. Forever has no realms, so skip it there.
                if not addon.isForever and not IsUsableString(contextData.server) and IsUsableString(guidRealm) then
                    realm = guidRealm
                end
            end
        end
        if not class then return end
        if not name or name == "" then return end
        realm = BlacklistWarden:ResolveRealm(realm)
        local popupText = "";

        BlacklistWarden:SavePlayerInfoValue("playerServer", realm)
        BlacklistWarden:SavePlayerInfoValue("playerName", name)
        BlacklistWarden:SavePlayerInfoValue("playerClass", class)
        local fullName = BlacklistWarden:MakeKey(name, realm)
        local isOnList = BlacklistWarden.db.global.blacklistedPlayers[fullName] ~= nil
        local ownName, ownSecond = UnitName("player")
        if fullName == BlacklistWarden:MakeKey(ownName, BlacklistWarden:ResolveRealm(ownSecond)) then return end

        if not isOnList then
            popupText = "|cffd80000" .. addon.L["Blacklist player|r"]
        else
            popupText = "|cFF00FF00" .. addon.L["Remove from blacklist|r"]
        end

        rootDescription:CreateDivider();
        rootDescription:CreateTitle(addon.addonTitle);
        rootDescription:CreateButton(popupText, function()
            if not isOnList then
                BlacklistWarden:BlacklistButton()
            else
                BlacklistWarden:RemovePlayer(fullName)
            end
        end)
    end

    -- Adds allowed units for contextmenu
    function module:AddItemsWithMenu()
        if not self:HasMenu() then return end

        -- Find via /run Menu.PrintOpenMenuTags()
        local menuTags = {
            ["MENU_UNIT_PLAYER"] = true,
            ["MENU_UNIT_ENEMY_PLAYER"] = true,
            ["MENU_UNIT_PARTY"] = true,
            ["MENU_UNIT_RAID_PLAYER"] = true,
            ["MENU_UNIT_FRIEND"] = true,
            ["MENU_UNIT_COMMUNITIES_GUILD_MEMBER"] = true,
            ["MENU_UNIT_COMMUNITIES_MEMBER"] = true,
            ["MENU_LFG_FRAME_SEARCH_ENTRY"] = true,
            ["MENU_LFG_FRAME_MEMBER_APPLY"] = true,
        }

        for tag, enabled in pairs(menuTags) do
            Menu.ModifyMenu(tag, GenerateClosure(self.MenuHandler, self))
        end
    end

    --Retrieves data for the LFG context menu
    -- True when a value exists and isn't a restricted (secret) value on clients that have them
    local function IsUsable(value)
        if value == nil then return false end
        if issecretvalue and issecretvalue(value) then return false end
        return true
    end

    -- Finds the listing leader's class file name (e.g. "MAGE"). The member-info API differs
    -- between clients (GetSearchResultMemberInfo was removed on retail), so try each in turn.
    local function GetSearchResultLeaderClass(resultID, numMembers)
        if C_LFGList.GetSearchResultLeaderInfo then
            local leaderInfo = C_LFGList.GetSearchResultLeaderInfo(resultID)
            if leaderInfo and IsUsable(leaderInfo.classFilename) then
                return leaderInfo.classFilename
            end
        end
        if C_LFGList.GetSearchResultPlayerInfo and numMembers then
            for i = 1, numMembers do
                local playerInfo = C_LFGList.GetSearchResultPlayerInfo(resultID, i)
                if playerInfo and playerInfo.isLeader and IsUsable(playerInfo.classFilename) then
                    return playerInfo.classFilename
                end
            end
        end
        if C_LFGList.GetSearchResultMemberInfo and numMembers then
            for i = 1, numMembers do
                local _, class, _, _, isLeader = C_LFGList.GetSearchResultMemberInfo(resultID, i)
                if isLeader and IsUsable(class) then
                    return class
                end
            end
        end
    end

    function module:GetLFGInfo(owner)
        if not C_LFGList then return end
        local resultID = owner.resultID
        if resultID then
            local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)
            if not searchResultInfo or not IsUsable(searchResultInfo.leaderName) then return end
            local name, realm = BlacklistWarden:FormatName(searchResultInfo.leaderName)
            local class = GetSearchResultLeaderClass(resultID, searchResultInfo.numMembers)
            return name, realm, class
        end
        local memberIdx = owner.memberIdx
        if not memberIdx then
            return
        end
        local parent = owner:GetParent()
        if not parent then
            return
        end
        local applicantID = parent.applicantID
        if not applicantID then
            return
        end
        local fullName, class, localizedClass = C_LFGList.GetApplicantMemberInfo(applicantID, memberIdx)
        if not IsUsable(fullName) or not IsUsable(class) then return end
        local name, realm = BlacklistWarden:FormatName(fullName)

        return name, realm, class
    end

    function module:OnEnable()
        if self:HasMenu() then
            self:AddItemsWithMenu()
        end
        self.enabled = true
    end
end

local function FilterChat(self, event, msg, author, ...)
    -- author is "Name-Realm" on Retail; on Forever it may be "First-Surname" or "First Surname"
    local player = BlacklistWarden:GetPlayer(author)
    return player ~= nil and player["muted"] == true
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", FilterChat)
ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", FilterChat)
ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", FilterChat)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", FilterChat)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", FilterChat)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", FilterChat)
ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", FilterChat)
ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE", FilterChat)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", FilterChat)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", FilterChat)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_WARNING", FilterChat)
