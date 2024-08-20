local _G = getfenv(0)
local ADDON_NAME, addon = ...
addon.addonName = "PersonalPlayerBlacklist"
addon.addonTitle = "Personal Player Blacklist"
PersonalPlayerBlacklist = LibStub("AceAddon-3.0"):NewAddon(addon.addonName, "AceConsole-3.0", "AceHook-3.0",
    "AceEvent-3.0", "AceTimer-3.0")
local blacklistPopupWindow = nil;
local blacklistPopupWarning = nil;
local blacklistListWindow = nil;
local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("PersonalPlayerBlacklist", {
    type = "data source",
    text = "PPB",
    icon = "Interface\\Icons\\Spell_Mage_Evanesce",
    OnTooltipShow = function(tooltip)
        tooltip:SetText("Global Player Blacklist")
        tooltip:AddLine(" ")
        tooltip:AddLine("Left click: |cffFFFFFFOpen player list")
        tooltip:AddLine("Right click: |cffFFFFFFOpen settings")
        tooltip:Show()
    end,
    OnClick = function(frame, button)
        if button == "RightButton" then
            Settings.OpenToCategory("PersonalPlayerBlacklist")
        elseif button == "LeftButton" then
            blacklistListWindow:Show()
        end
    end,
})
local icon = LibStub("LibDBIcon-1.0")
PersonalPlayerBlacklist:RegisterChatCommand("rl", "Reload")

function PersonalPlayerBlacklist:Reload()
    ReloadUI();
end

local options = {
    name = "Personal Player Blacklist",
    handler = PersonalPlayerBlacklist,
    type = 'group',
    args = {
        headerGeneralOptions = {
            order = 0,
            type = "header",
            name = "General Options",
        },
        blacklistPopup = {
            type = 'toggle',
            name = 'Detail popup',
            desc = 'Shows a popup when blacklisting a player that lets you add extra information, otherwise adds the player with default values.',
            set = "SetShowPopup",
            get = "GetShowPopup",
        },
        lockWindows = {
            type = 'toggle',
            name = 'Lock panels',
            desc = 'Locks the addon\'s windows, preventing them from moving.',
            set = "SetLockWindows",
            get = "GetLockWindows",
        },
        minimapIcon = {
            type = 'toggle',
            name = 'Minimap icon',
            desc = 'Toggles the minimap icon.',
            set = "SetShowIcon",
            get = "GetShowIcon",
        },
    },
}

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


LibStub("AceConfig-3.0"):RegisterOptionsTable(addon.addonName, options, { "PPB", "ppb" })

local aceDialog = LibStub("AceConfigDialog-3.0");


local playerInfo = {}
function PersonalPlayerBlacklist:OnInitialize()
    self:RegisterChatCommand("personalplayerblacklist", "SlashCommand")
    self:RegisterChatCommand("ppb", "SlashCommand")
    self.db = LibStub("AceDB-3.0"):New("PersonalPlayerBlacklistDB", defaults)
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addon.addonName, options)
    self.optionsFrame = aceDialog:AddToBlizOptions(addon.addonName, addon.addonName)
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "CheckPlayersOnGroupUpdate");
    icon:Register("PersonalPlayerBlacklist", LDB, PersonalPlayerBlacklist.db.profile.minimap)
end

function PersonalPlayerBlacklist:OnEnable()
    blacklistPopupWindow = PersonalPlayerBlacklist:CreateBlacklistPopupWindow();
    blacklistPopupWarning = PersonalPlayerBlacklist:CreateBlacklistWarningWindow();
    blacklistListWindow = PersonalPlayerBlacklist:CreateListFrame();
    blacklistPopupWindow:SetMovable(not PersonalPlayerBlacklist.db.profile.lockWindows)
    blacklistPopupWarning:SetMovable(not PersonalPlayerBlacklist.db.profile.lockWindows)
    blacklistListWindow:SetMovable(not PersonalPlayerBlacklist.db.profile.lockWindows)
end

function PersonalPlayerBlacklist:CheckPlayersOnGroupUpdate()
    local groupCount = GetNumGroupMembers()
    local name, realm;
    if groupCount > PersonalPlayerBlacklist.db.global.previousGroupSize then
        for i = 1, groupCount do
            if groupCount < 6 then
                name, realm = UnitName("party" .. i)
            else
                name, realm = UnitName("raid" .. i)
            end
            if not realm then realm = GetRealmName() end
            if name and realm then
                local fullname = name .. "-" .. realm;
                if PersonalPlayerBlacklist:IsPlayerInList(fullname) then
                    blacklistPopupWarning.setPlayerData(PersonalPlayerBlacklist.db.global.blacklistedPlayers[fullname])
                    blacklistPopupWarning:Show()
                end
            end
        end
    end
    PersonalPlayerBlacklist.db.global.previousGroupSize = groupCount;
end

function PersonalPlayerBlacklist:SlashCommand(msg)
    if not msg or msg:trim() == "" then
        Settings.OpenToCategory("PersonalPlayerBlacklist")
    else
        blacklistListWindow:Show()
    end
end

function PersonalPlayerBlacklist:PrintPlayers()
    if not PersonalPlayerBlacklist.db.global.blacklistedPlayers then return end
    for key, value in pairs(PersonalPlayerBlacklist.db.global.blacklistedPlayers) do
        local name = "";
        local server = "";
        local class = "";
        local reason = "";
        local note = "";
        local date = "";
        if value["name"] then
            name = value["name"]
        end
        if value["server"] then
            server = value["server"]
        end
        if value["class"] then
            class = value["class"]
        end
        if value["reason"] then
            reason = value["reason"]
        end
        if value["notes"] then
            note = value["notes"]
        end
        if value["date"] then
            date = value["date"]
        end
        print(key .. " : " .. name .. " - " .. server .. " - " .. class ..
            " - " .. reason .. " - " .. note .. " - " .. date);
    end
end

function PersonalPlayerBlacklist:GetShowPopup(info)
    return PersonalPlayerBlacklist.db.profile.showPopup;
end

function PersonalPlayerBlacklist:SetShowPopup(info, value)
    PersonalPlayerBlacklist.db.profile.showPopup = value;
end

function PersonalPlayerBlacklist:GetLockWindows(info)
    return PersonalPlayerBlacklist.db.profile.lockWindows;
end

function PersonalPlayerBlacklist:SetLockWindows(info, value)
    PersonalPlayerBlacklist.db.profile.lockWindows = value;
    blacklistPopupWindow:SetMovable(not value)
    blacklistPopupWarning:SetMovable(not value)
    blacklistListWindow:SetMovable(not value)
end

function PersonalPlayerBlacklist:GetShowIcon(info)
    return not PersonalPlayerBlacklist.db.profile.minimap.hide;
end

function PersonalPlayerBlacklist:SetShowIcon(info, value)
    value = not value
    PersonalPlayerBlacklist.db.profile.minimap.hide = value;
    if value then
        icon:Hide("PersonalPlayerBlacklist")
    else
        icon:Show("PersonalPlayerBlacklist")
    end
end

function PersonalPlayerBlacklist:SavePlayerInfoValue(key, value)
    playerInfo[key] = value;
end

function PersonalPlayerBlacklist:FormatName(fullname)
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

function PersonalPlayerBlacklist:WritePlayerToDisk()
    local date = date("%m/%d/%Y %H:%M:%S")
    local playerName = playerInfo["playerName"] .. "-" .. playerInfo["playerServer"]
    local player = PersonalPlayerBlacklist.db.global.blacklistedPlayers[playerName]
    if player ~= nil then
        date = player["date"]
    end
    PersonalPlayerBlacklist.db.global.blacklistedPlayers[playerName] = {
        ["name"] = playerInfo["playerName"],
        ["server"] = playerInfo["playerServer"],
        ["class"] = playerInfo["playerClass"],
        ["reason"] = playerInfo["reason"],
        ["notes"] = playerInfo["notes"],
        ["date"] = date,
    }
    if not player then
        print("|cffFF0000" .. playerName .. "|r added to blacklist.")
        blacklistListWindow.addEntry(PersonalPlayerBlacklist.db.global.blacklistedPlayers[playerName])
    else
        print("|cffFF0000" .. playerName .. "|r successfully modified.")
        blacklistListWindow.updateEntry(PersonalPlayerBlacklist.db.global.blacklistedPlayers[playerName])
    end

    playerInfo = {}
end

function PersonalPlayerBlacklist:BlacklistButton()
    if PersonalPlayerBlacklist.db.profile.showPopup then
        blacklistPopupWindow.title:SetText("Add to blacklist")
        blacklistPopupWindow.setPlayerName({
            ["name"] = playerInfo["playerName"],
            ["server"] = playerInfo
                ["playerServer"],
            ["class"] = playerInfo["playerClass"]
        })
        blacklistPopupWindow.dropdown:SetValue(1)
        PersonalPlayerBlacklist:SavePlayerInfoValue("reason",
            PersonalPlayerBlacklist.db.global.blacklistPopupWindowOptions[1])
        blacklistPopupWindow.editbox:SetText("")
        blacklistPopupWindow:Show()
    else
        PersonalPlayerBlacklist:SavePlayerInfoValue("reason",
            PersonalPlayerBlacklist.db.global.blacklistPopupWindowOptions[1])
        PersonalPlayerBlacklist:SavePlayerInfoValue("notes", "")
        PersonalPlayerBlacklist:WritePlayerToDisk();
    end
end

function PersonalPlayerBlacklist:EditEntry(playername)
    local player = PersonalPlayerBlacklist.db.global.blacklistedPlayers[playername]
    playerInfo = {
        ["playerName"] = player["name"],
        ["playerServer"] = player["server"],
        ["playerClass"] = player["class"],
        ["reason"] = player["reason"]
    }
    blacklistPopupWindow.setPlayerName(player)
    blacklistPopupWindow.title:SetText("Edit")
    for i = 1, #PersonalPlayerBlacklist.db.global.blacklistPopupWindowOptions do
        if PersonalPlayerBlacklist.db.global.blacklistPopupWindowOptions[i] == player["reason"] then
            blacklistPopupWindow.dropdown:SetValue(i)
            break;
        end
    end

    blacklistPopupWindow.editbox:SetText(player["notes"])
    blacklistPopupWindow:Show()
end

function PersonalPlayerBlacklist:RemovePlayer(name)
    if not PersonalPlayerBlacklist.db.global.blacklistedPlayers then PersonalPlayerBlacklist.db.global.blacklistedPlayers = {} end
    blacklistListWindow.removeEntry(PersonalPlayerBlacklist.db.global.blacklistedPlayers[name])
    PersonalPlayerBlacklist.db.global.blacklistedPlayers[name] = nil;
    print("|cFF00FF00" .. name .. "|r removed from blacklist.")
end

function PersonalPlayerBlacklist:IsPlayerInList(name)
    if not PersonalPlayerBlacklist.db.global.blacklistedPlayers or not PersonalPlayerBlacklist.db.global.blacklistedPlayers[name] then
        return false
    else
        return true
    end
end

do
    local function AddToTooltip(tooltip, player)
        tooltip:AddLine(" ")
        tooltip:AddLine("|cffFFC000Global Player Blacklist - |rBlacklisted", 1, 0, 0, false)
        tooltip:AddLine("|cffFFC000Reason: |r" .. player.reason .. "|r", 1, 1, 1, false)
        if player.notes and player.notes ~= "" then
            tooltip:AddLine("|cffFFC000Note: |r" .. player.notes, 1, 1, 1, true)
        end
        tooltip:AddLine(" ")
    end

    local function OnTooltipSetUnit(tooltip, data)
        if tooltip ~= GameTooltip then return end

        local _, unit = tooltip:GetUnit()
        if unit and UnitIsPlayer(unit) and not UnitIsUnit(unit, "player") then
            local name, realm = UnitName(unit)
            if not realm then realm = GetRealmName() end
            local fullname = name .. "-" .. realm;
            if not PersonalPlayerBlacklist:IsPlayerInList(fullname) then return end
            local player = PersonalPlayerBlacklist.db.global.blacklistedPlayers[fullname]

            AddToTooltip(tooltip, player);
        end
    end
    local function SetSearchEntry(tooltip, resultID, autoAcceptOption)
        if resultID then
            local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)
            if not searchResultInfo.leaderName then return end
            local name, realm = PersonalPlayerBlacklist:FormatName(searchResultInfo.leaderName)
            if not realm then realm = GetRealmName() end
            local fullname = name .. "-" .. realm
            if not PersonalPlayerBlacklist:IsPlayerInList(fullname) then return end
            local player = PersonalPlayerBlacklist.db.global.blacklistedPlayers[fullname]

            AddToTooltip(tooltip, player)
        end
    end

    local hooked = {}

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
                local name, realm = PersonalPlayerBlacklist:FormatName(fullName)
                fullName = name .. "-" .. realm;
                if not PersonalPlayerBlacklist:IsPlayerInList(fullName) then return end
                local player = PersonalPlayerBlacklist.db.global.blacklistedPlayers[fullName]
                --GameTooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 0, 0)
                AddToTooltip(GameTooltip, player)
                GameTooltip:Show()
            end
        end
    end

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


    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnTooltipSetUnit)
    hooksecurefunc("LFGListUtil_SetSearchEntryTooltip", SetSearchEntry)
end

do
    local module = PersonalPlayerBlacklist:NewModule("UnitPopupMenus")
    module.enabled = false

    function module:HasMenu()
        return Menu and Menu.ModifyMenu
    end

    local function IsValidName(contextData)
        return contextData.name and strsub(contextData.name, 1, 1) ~= "|"
    end


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


        PersonalPlayerBlacklist:SavePlayerInfoValue("playerServer", realm)
        PersonalPlayerBlacklist:SavePlayerInfoValue("playerName", name)
        local fullName = playerInfo["playerName"] .. "-" .. playerInfo["playerServer"]
        local isOnList = PersonalPlayerBlacklist:IsPlayerInList(fullName);
        local playername = UnitName("player")
        if fullName == playername .. "-" .. realm then return end

        PersonalPlayerBlacklist:SavePlayerInfoValue("playerClass", class)
        if not isOnList then
            popupText = "|cffd80000Blacklist player|r"
        else
            popupText = "|cFF00FF00Remove from blacklist|r"
        end

        rootDescription:CreateDivider();
        rootDescription:CreateTitle(addon.addonTitle);
        rootDescription:CreateButton(popupText, function()
            if not isOnList then
                PersonalPlayerBlacklist:BlacklistButton()
            else
                PersonalPlayerBlacklist:RemovePlayer(fullName)
            end
        end)
    end

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

    function module:GetLFGInfo(owner)
        local resultID = owner.resultID
        if resultID then
            local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)
            local name, realm = PersonalPlayerBlacklist:FormatName(searchResultInfo.leaderName)
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
        local name, realm = PersonalPlayerBlacklist:FormatName(fullName)

        return name, realm, class
    end

    function module:Setup()
        if self:HasMenu() then
            self:AddItemsWithMenu()
        end
        self.enabled = true
    end

    function module:OnEnable()
        self:Setup()
    end
end
