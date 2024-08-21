---@diagnostic disable: need-check-nil
-- Main file, handles addon logic
local ADDON_NAME, addon = ...
addon.addonName = "BlacklistWarden"
addon.addonTitle = "Blacklist Warden"

-- Addon namespace
BlacklistWarden = LibStub("AceAddon-3.0"):NewAddon(addon.addonName, "AceConsole-3.0", "AceHook-3.0", "AceEvent-3.0",
    "AceTimer-3.0")
-- Addon widgets
local blacklistPopupWindow = nil;
local blacklistPopupWarning = nil;
local blacklistListWindow = nil;
-- Minimap button setup
local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("BlacklistWarden", {
    type = "data source",
    text = "PPB",
    icon = "Interface\\Icons\\Spell_Mage_Evanesce",
    OnTooltipShow = function(tooltip)
        tooltip:SetText("Blacklist Warden")
        tooltip:AddLine(" ")
        tooltip:AddLine("Left click: |cffFFFFFFOpen player list")
        tooltip:AddLine("Right click: |cffFFFFFFOpen settings")
        tooltip:Show()
    end,
    OnClick = function(frame, button)
        if button == "RightButton" then
            Settings.OpenToCategory("BlacklistWarden")
        elseif button == "LeftButton" then
            if blacklistListWindow then blacklistListWindow:Show() end
        end
    end,
})


-- Settings options
local options = {
    name = "Blacklist Warden",
    handler = BlacklistWarden,
    type = 'group',
    args = {
        headerGeneralOptions = {
            order = 0,
            type = "header",
            name = "General Options",
        },
        blacklistPopup = {
            order = 1,
            type = 'toggle',
            name = 'Toggle blacklist popup',
            desc =
            'Shows a popup when blacklisting a player that lets you add extra information, otherwise adds the player with default values.',
            set = "SetShowPopup",
            get = "GetShowPopup",
            width = "full"
        },
        lockWindows = {
            order = 4,
            type = 'toggle',
            name = 'Lock windows',
            desc = 'Locks the addon\'s windows, preventing them from moving.',
            set = "SetLockWindows",
            get = "GetLockWindows",
            width = "full"
        },
        minimapIcon = {
            order = 6,
            type = 'toggle',
            name = 'Toggle minimap icon',
            desc = 'Toggles the minimap icon.',
            set = "SetShowIcon",
            get = "GetShowIcon",
            width = "full"
        },
        spacer1 = {
            order = 2,
            type = "description",
            name = "\n\n\n\n",
        },
        spacer2 = {
            order = 5,
            type = "description",
            name = "\n\n\n\n",
        },
        headerCredits = {
            order = 9,
            type = "header",
            name = "Credits",
        },
        creditsDescription = {
            order = 10,
            type = "description",
            name = "|cffF58CBADiuxtros|r @ Icecrown (US) - |cffFF8000Author|r",
        },
    },
}
--AceDB defaults
local defaults = {
    global = {
        blacklistedPlayers = {},
        previousGroupSize = 0,
        blacklistPopupWindowOptions = {
            "All",
            "Bad player",
            "Quitter",
            "AFKer",
            "Toxic",
            "Scammer",
            "Bigot",
            "Other"
        }
    },
    profile = {
        showPopup = true,
        minimap = {
            hide = false,
        },
        lockWindows = true,
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
    self.optionsFrame = aceDialog:AddToBlizOptions(addon.addonName, addon.addonName)
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "CheckPlayersOnGroupUpdate");
    icon:Register("BlacklistWarden", LDB, BlacklistWarden.db.profile.minimap)
end

-- Create and store widgets
function BlacklistWarden:OnEnable()
    blacklistPopupWindow = BlacklistWarden:CreateBlacklistPopupWindow();
    blacklistPopupWarning = BlacklistWarden:CreateBlacklistWarningWindow();
    blacklistListWindow = BlacklistWarden:CreateListFrame();
    blacklistPopupWindow:SetMovable(not BlacklistWarden.db.profile.lockWindows)
    blacklistPopupWarning:SetMovable(not BlacklistWarden.db.profile.lockWindows)
    blacklistListWindow:SetMovable(not BlacklistWarden.db.profile.lockWindows)
    BlacklistWarden.db.global.previousGroupSize = GetNumGroupMembers()
end

-- Temporary player info to store
local playerInfo = {}

-- Callback for GROUP_ROSTER_UPDATE, checks and warns if any player is in your blacklist
function BlacklistWarden:CheckPlayersOnGroupUpdate()
    local groupCount = GetNumGroupMembers()
    local name, realm;
    if groupCount > BlacklistWarden.db.global.previousGroupSize then --check only if someone joined
        for i = 1, groupCount do
            if groupCount < 6 then
                name, realm = UnitName("party" .. i)
            else
                name, realm = UnitName("raid" .. i)
            end
            if not realm then realm = GetRealmName() end
            if name and realm then
                local fullname = name .. "-" .. realm;
                if BlacklistWarden:IsPlayerInList(fullname) then
                    if blacklistPopupWarning then
                        blacklistPopupWarning.setPlayerData(BlacklistWarden.db.global
                            .blacklistedPlayers[fullname])
                        blacklistPopupWarning:Show()
                    end
                end
            end
        end
    end
    BlacklistWarden.db.global.previousGroupSize = groupCount;
end

-- Slash commands
function BlacklistWarden:SlashCommand(msg)
    if not msg or msg:trim() == "" then
        print("|cffFFFF00/blw settings -|r Opens the settings window")
        print("|cffFFFF00/blw list -|r Opens the list window")
    elseif string.lower(msg:trim()) == "settings" then
        Settings.OpenToCategory("BlacklistWarden")
    elseif string.lower(msg:trim()) == "list" then
        if blacklistListWindow then blacklistListWindow:Show() end
    end
end

-- Setters/getters for settings window
function BlacklistWarden:GetShowPopup(info)
    return BlacklistWarden.db.profile.showPopup;
end

function BlacklistWarden:SetShowPopup(info, value)
    BlacklistWarden.db.profile.showPopup = value;
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

--Split fullname into name and realm
function BlacklistWarden:FormatName(fullname)
    local name, realm
    if fullname:find("-", nil, true) then
        name, realm = strsplit("-", fullname)
    else
        name = fullname
    end
    if not realm or realm == "" then
        realm = GetRealmName()
    end

    return name, realm
end

-- Stores the temporary player info in the database
function BlacklistWarden:WritePlayerToDisk()
    local date = date("%m/%d/%Y %H:%M:%S")
    local playerName = playerInfo["playerName"] .. "-" .. playerInfo["playerServer"]
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
    }
    if not player then
        print("|cffFF0000" .. playerName .. "|r added to blacklist.")
        if blacklistListWindow then
            blacklistListWindow.addEntry(BlacklistWarden.db.global.blacklistedPlayers
                [playerName])
        end
    else
        print("|cffFF0000" .. playerName .. "|r successfully modified.")
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
            blacklistPopupWindow.title:SetText("Add to blacklist")
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
            blacklistPopupWindow:Show()
        end
    else
        BlacklistWarden:SavePlayerInfoValue("reason",
            BlacklistWarden.db.global.blacklistPopupWindowOptions[1])
        BlacklistWarden:SavePlayerInfoValue("notes", "")
        BlacklistWarden:WritePlayerToDisk();
    end
end

-- Edit player entry from the list window
function BlacklistWarden:EditEntry(playername)
    local player = BlacklistWarden.db.global.blacklistedPlayers[playername]
    playerInfo = {
        ["playerName"] = player["name"],
        ["playerServer"] = player["server"],
        ["playerClass"] = player["class"],
        ["reason"] = player["reason"]
    }
    blacklistPopupWindow.setPlayerName(player)
    blacklistPopupWindow.title:SetText("Edit")
    for i = 1, #BlacklistWarden.db.global.blacklistPopupWindowOptions do
        if BlacklistWarden.db.global.blacklistPopupWindowOptions[i] == player["reason"] then
            blacklistPopupWindow.dropdown:SetValue(i)
            break;
        end
    end
    blacklistPopupWindow.editbox:SetText(player["notes"])
    blacklistPopupWindow:Show()
end

-- Remove player from blacklist
function BlacklistWarden:RemovePlayer(name)
    if not BlacklistWarden.db.global.blacklistedPlayers then BlacklistWarden.db.global.blacklistedPlayers = {} end
    blacklistListWindow.removeEntry(BlacklistWarden.db.global.blacklistedPlayers[name])
    BlacklistWarden.db.global.blacklistedPlayers[name] = nil;
    print("|cFF00FF00" .. name .. "|r removed from blacklist.")
end

--check if player is on blacklist
function BlacklistWarden:IsPlayerInList(name)
    if not BlacklistWarden.db.global.blacklistedPlayers or not BlacklistWarden.db.global.blacklistedPlayers[name] then
        return false
    else
        return true
    end
end

--Tooltip module
do
    --Add info on tooltip for blacklisted players
    local function AddToTooltip(tooltip, player)
        tooltip:AddLine(" ")
        tooltip:AddLine("|cffFFC000Blacklist Warden - |rBlacklisted", 1, 0, 0, false)
        tooltip:AddLine("|cffFFC000Reason: |r" .. player.reason .. "|r", 1, 1, 1, false)
        if player.notes and player.notes ~= "" then
            tooltip:AddLine("|cffFFC000Note: |r" .. player.notes, 1, 1, 1, true)
        end
        tooltip:AddLine(" ")
    end

    --Callback for unit tooltips
    local function OnTooltipSetUnit(tooltip, data)
        if tooltip ~= GameTooltip then return end

        local _, unit = tooltip:GetUnit()
        if unit and UnitIsPlayer(unit) and not UnitIsUnit(unit, "player") then
            local name, realm = UnitName(unit)
            if not realm then realm = GetRealmName() end
            local fullname = name .. "-" .. realm;
            if not BlacklistWarden:IsPlayerInList(fullname) then return end
            local player = BlacklistWarden.db.global.blacklistedPlayers[fullname]

            AddToTooltip(tooltip, player);
        end
    end

    --Hook for leader tooltips in LFG
    local function SetSearchEntry(tooltip, resultID, autoAcceptOption)
        if resultID then
            local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)
            if not searchResultInfo.leaderName then return end
            local name, realm = BlacklistWarden:FormatName(searchResultInfo.leaderName)
            if not realm then realm = GetRealmName() end
            local fullname = name .. "-" .. realm
            if not BlacklistWarden:IsPlayerInList(fullname) then return end
            local player = BlacklistWarden.db.global.blacklistedPlayers[fullname]

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
            if fullName then
                local hasOwner = GameTooltip:GetOwner()
                if not hasOwner then
                    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                end
                local name, realm = BlacklistWarden:FormatName(fullName)
                fullName = name .. "-" .. realm;
                if not BlacklistWarden:IsPlayerInList(fullName) then return end
                local player = BlacklistWarden.db.global.blacklistedPlayers[fullName]
                --GameTooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 0, 0)
                AddToTooltip(GameTooltip, player)
                GameTooltip:Show()
            end
        end
    end

    --Hook for applicants in LFG
    hooksecurefunc("LFGListApplicationViewer_UpdateResults", function(self)
        local scrollBox = LFGListFrame.ApplicationViewer.ScrollBox
        if scrollBox.buttons then
            for i = 1, #scrollBox.buttons do
                local button = scrollBox.buttons[i]
                if not hooked[button] then
                    button:HookScript("OnEnter", OnEnterHook)
                    hooked[button] = true
                end
            end
        end
        local frames = scrollBox:GetFrames()
        if frames and frames[1] then
            for i = 1, #frames do
                local button = frames[i]
                if not hooked[button] then
                    button:HookScript("OnEnter", OnEnterHook)
                    hooked[button] = true
                end
            end
        end
    end)

    --More hooks
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnTooltipSetUnit)
    hooksecurefunc("LFGListUtil_SetSearchEntryTooltip", SetSearchEntry)
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
        local class;
        local _;
        if not contextData then
            if rootDescription.tag == "MENU_LFG_FRAME_SEARCH_ENTRY" or rootDescription.tag == "MENU_LFG_FRAME_MEMBER_APPLY" then
                name, realm, class = self:GetLFGInfo(owner)
            end
        else
            if not IsValidName(contextData) then return end
            if not contextData.server then
                realm = GetRealmName()
            else
                realm = contextData.server
            end
            name = contextData.name
            local guid

            if contextData.lineID then
                guid = C_ChatInfo.GetChatLineSenderGUID(contextData.lineID)
            elseif contextData.unit then
                guid = UnitGUID(contextData.unit)
            else
                return
            end

            _, class, _, _, _, _ = GetPlayerInfoByGUID(guid)
        end

        local popupText = "";

        BlacklistWarden:SavePlayerInfoValue("playerServer", realm)
        BlacklistWarden:SavePlayerInfoValue("playerName", name)
        local fullName = playerInfo["playerName"] .. "-" .. playerInfo["playerServer"]
        local isOnList = BlacklistWarden:IsPlayerInList(fullName);
        local playername = UnitName("player")
        if fullName == playername .. "-" .. GetRealmName() then return end

        BlacklistWarden:SavePlayerInfoValue("playerClass", class)
        if not isOnList then
            popupText = "|cffd80000Blacklist player|r"
        else
            popupText = "|cFF00FF00Remove from blacklist|r"
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
    function module:GetLFGInfo(owner)
        local resultID = owner.resultID
        if resultID then
            local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)
            local name, realm = BlacklistWarden:FormatName(searchResultInfo.leaderName)
            local _, class, isLeader
            for i = 1, searchResultInfo.numMembers do
                _, class, _, _, isLeader = C_LFGList.GetSearchResultMemberInfo(resultID, i)
                if isLeader then
                    break
                end
            end
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
