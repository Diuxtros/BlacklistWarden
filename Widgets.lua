local AceGUI = LibStub("AceGUI-3.0")
local classColor={
    ["UNSPECIFIED"]={0.62,0.62,0.62},
    ["WARRIOR"]={0.78,0.61,0.43},
    ["PALADIN"]={0.96,0.55,0.73},
    ["HUNTER"]={0.67,0.83,0.45},
    ["ROGUE"]={1.00,0.96,0.41},
    ["PRIEST"]={1,1,1},
    ["SHAMAN"]={0.00,0.44,0.87},
    ["MAGE"]={0.25,0.78,0.92},
    ["WARLOCK"]={0.53,0.53,0.93},
    ["MONK"]={0.00,1.00,0.59},
    ["DRUID"]={1.00,0.49,0.04},
    ["DEMONHUNTER"]={0.64,0.19,0.79},
    ["DEATHKNIGHT"]={0.77,0.12,0.23},
    ["EVOKER"]={0.20, 0.58, 0.50},
}
function PersonalPlayerBlacklist:CreateStandardButton(text, width, parent)
    local button = {}
    button = AceGUI:Create("Button")
    button:SetText(text)
    button:SetWidth(width)
    button.frame:SetParent(parent)
    button.frame:Show()
    return button;
end

function PersonalPlayerBlacklist:CreateBlacklistWarningWindow()
    local container = PersonalPlayerBlacklist:CreateMainFrame("BlacklistWarningWindow", 280, 130)
    local frameConfig = PersonalPlayerBlacklist.db.profile.blacklistWarningFrame
    PersonalPlayerBlacklist:HandleFrameConfig(container, frameConfig)


    local savebutton = PersonalPlayerBlacklist:CreateStandardButton("Leave", 100, container)
    savebutton:SetCallback("OnClick", function(this)
        C_PartyInfo.LeaveParty()
        this.frame:GetParent():Hide()
    end)
    savebutton.frame:SetPoint("BOTTOM", container, "BOTTOM", -60, 20)

    local colorR, colorG, colorB, colorA = savebutton.frame:GetNormalFontObject():GetTextColor()


    local cancelbutton = PersonalPlayerBlacklist:CreateStandardButton("Stay", 100, container)
    cancelbutton:SetCallback("OnClick", function(this) this.frame:GetParent():Hide(); end)
    cancelbutton.frame:SetPoint("BOTTOM", container, "BOTTOM", 60, 20)



    local title = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", container, "TOPLEFT", 5, -10)
    title:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -5, 50)
    title:SetTextColor(colorR, colorG, colorB, colorA)

    container.title = title
    container:Hide()
    return container;
end

function PersonalPlayerBlacklist:CreateMainFrame(name, width, height)
    local container = CreateFrame("Frame", name, UIParent,
        BackdropTemplateMixin and "BackdropTemplate")
    container:SetFrameStrata("DIALOG")
    container:SetToplevel(true)
    container:SetWidth(width)
    container:SetHeight(height)
    container:SetScale(1 / UIParent:GetScale())
    container:SetBackdrop(
        {
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 15,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
    container:SetBackdropColor(0, 0, 0, 0.7)
    container:SetMovable(true)
    container:RegisterForDrag("LeftButton")
    container:SetScript("OnDragStart",
        function(this, button)
            this:StartMoving()
        end)
    container:EnableMouse(true)
    return container
end

function PersonalPlayerBlacklist:HandleFrameConfig(container, frameConfig)
    container:SetPoint(frameConfig.point,
        frameConfig.relativeFrame,
        frameConfig.relativePoint,
        frameConfig.ofsx,
        frameConfig.ofsy)

    container:SetScript("OnDragStop",
        function(this)
            this:StopMovingOrSizing()
            local point, relativeFrame, relativeTo, ofsx, ofsy = container:GetPoint()
            frameConfig.point = point
            frameConfig.relativeFrame = relativeFrame
            frameConfig.relativePoint = relativeTo
            frameConfig.ofsx = ofsx
            frameConfig.ofsy = ofsy
        end)
end

function PersonalPlayerBlacklist:CreateBlacklistPopupWindow()
    local container = PersonalPlayerBlacklist:CreateMainFrame("BlacklistPopupWindow", 250, 200)
    local frameConfig = PersonalPlayerBlacklist.db.profile.blacklistPopupFrame
    PersonalPlayerBlacklist:HandleFrameConfig(container, frameConfig)


    local savebutton = PersonalPlayerBlacklist:CreateStandardButton("Save", 100, container)
    savebutton.frame:SetPoint("BOTTOM", container, "BOTTOM", -60, 15)
    savebutton:SetCallback("OnClick",
        function(this)
            PersonalPlayerBlacklist:SavePlayerInfoValue("notes", container.editbox:GetText())
            PersonalPlayerBlacklist:WritePlayerToDisk()
            this.frame:GetParent():Hide()
        end)

    local colorR, colorG, colorB, colorA = savebutton.frame:GetNormalFontObject():GetTextColor()

    local cancelbutton = PersonalPlayerBlacklist:CreateStandardButton("Cancel", 100, container)
    cancelbutton.frame:SetPoint("BOTTOM", container, "BOTTOM", 60, 15)
    cancelbutton:SetCallback("OnClick", function(this) this.frame:GetParent():Hide(); end)

    local titleBg = CreateFrame("Frame", "titleBG", container,
        BackdropTemplateMixin and "BackdropTemplate")
    titleBg:SetWidth(150)
    titleBg:SetHeight(30)
    titleBg:SetBackdrop(
        {
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 15,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
    titleBg:SetBackdropColor(0, 0, 0, 1)
    titleBg:SetPoint("TOP", container, "TOP", 0, 13)

    local title = titleBg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("CENTER", titleBg, "CENTER", 0, 0)
    title:SetText("Add to Blacklist")
    title:SetTextColor(colorR, colorG, colorB, colorA)

    local playerName = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    playerName:SetPoint("TOP", container, "TOP", 0, -20)
    playerName:SetTextColor(216, 0, 0, 1)

    container.playerName = playerName;

    local drop = {}
    drop = AceGUI:Create("Dropdown")
    drop:SetList(PersonalPlayerBlacklist.db.global.blacklistPopupWindowOptions)
    drop:SetWidth(208)
    drop:SetValue(1)
    drop:SetLabel("Reason:")
    drop:SetCallback("OnValueChanged", function(this, event, item)
        PersonalPlayerBlacklist:SavePlayerInfoValue("reason",
            PersonalPlayerBlacklist.db.global.blacklistPopupWindowOptions[item])
    end
    )
    drop.frame:SetParent(container)
    drop.frame:Show()
    drop.frame:SetPoint("LEFT", container, "TOPLEFT", 20, -50)

    container.dropdown = drop;
    local noteLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    noteLabel:SetPoint("LEFT", drop.frame, "LEFT", 0, -30)
    noteLabel:SetTextColor(colorR, colorG, colorB, colorA)
    noteLabel:SetText("Note (optional):")

    local editBoxContainer = CreateFrame("Frame", nil, container, BackdropTemplateMixin and "BackdropTemplate")
    editBoxContainer:SetPoint("TOPLEFT", noteLabel, "BOTTOMLEFT", 0, -1)
    editBoxContainer:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -20, 49)
    editBoxContainer:SetBackdrop(
        {
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 3, top = 4, bottom = 3 }
        })
    editBoxContainer:SetBackdropColor(0, 0, 0, 0.6)

    local editbox = CreateFrame("EditBox", "NoteEditBox", container)
    editbox:SetPoint("TOPLEFT", editBoxContainer, "TOPLEFT", 5, -8)
    editbox:SetPoint("BOTTOMRIGHT", editBoxContainer, "BOTTOMRIGHT", -5, 0)
    editbox:SetFontObject("ChatFontSmall")
    editbox:SetMultiLine(true)
    editbox:SetAutoFocus(false)
    editbox:SetMaxLetters(140)
    --editbox:SetScript("OnShow", function(this) editbox:SetFocus() end)
    container.editbox = editbox;
    container:Hide()

    return container;
end

local UnfilteredScrollButtons = {}
local FilteredScrollButtons   = {}
local columnCount             = 0
local lastSort                = false;
local lastSortID              = 1;
function PersonalPlayerBlacklist:CreateListFrame()
    local container = PersonalPlayerBlacklist:CreateMainFrame("ListWindow", 800, 500)
    local frameConfig = PersonalPlayerBlacklist.db.profile.listFrame
    PersonalPlayerBlacklist:HandleFrameConfig(container, frameConfig)
    columnCount   = 0
    local heading = {}
    heading       = AceGUI:Create("Heading")
    heading:SetText("Global Player Blacklist")
    heading:SetWidth(container:GetWidth() - 5)
    heading.frame:SetParent(container)
    heading.frame:SetPoint("TOP", container, "TOP", 0, -20)
    heading.frame:Show()

    local closebutton = PersonalPlayerBlacklist:CreateStandardButton("Close", 80, container)
    closebutton.frame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -10, 10)
    closebutton:SetHeight(20)
    closebutton:SetCallback("OnClick",
        function(this)
            this.frame:GetParent():Hide()
        end)
        local scrollFrameBg = CreateFrame("Frame", "titleBG", container,
        BackdropTemplateMixin and "BackdropTemplate")
        scrollFrameBg:SetWidth(150)
        scrollFrameBg:SetHeight(30)
        scrollFrameBg:SetBackdrop(
        {
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 15,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        scrollFrameBg:SetBackdropColor(0, 0, 0, 1)
        scrollFrameBg:SetPoint("TOPLEFT", container, "TOPLEFT", 10, -80)
        scrollFrameBg:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -10, 40)
    -- Create the scrolling parent frame and size it to fit inside the texture
    local scrollFrame = CreateFrame("ScrollFrame", nil, scrollFrameBg, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", scrollFrameBg, "TOPLEFT", 0, -7)
    scrollFrame:SetPoint("BOTTOMRIGHT", scrollFrameBg, "BOTTOMRIGHT", -27, 5)
    -- Create the scrolling child frame, set its width to fit, and give it an arbitrary minimum height (such as 1)
    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetWidth(scrollFrame:GetWidth())
    scrollChild:SetHeight(1)

    PersonalPlayerBlacklist:CreateColumnHeader("Name", scrollFrame, 110, "scroll", scrollChild)
    PersonalPlayerBlacklist:CreateColumnHeader("Realm", scrollFrame, 105, "scroll", scrollChild)
    PersonalPlayerBlacklist:CreateColumnHeader("Class", scrollFrame, 110, "scroll", scrollChild)
    PersonalPlayerBlacklist:CreateColumnHeader("Reason", scrollFrame, 80, "scroll", scrollChild)
    PersonalPlayerBlacklist:CreateColumnHeader("Date", scrollFrame, 90, "scroll", scrollChild)
    PersonalPlayerBlacklist:CreateColumnHeader("Notes", scrollFrame, 260, "scroll", scrollChild)

    --PersonalPlayerBlacklist:CreateTableButton(scrollcontainer.frame,1);

    FilteredScrollButtons = {}
    local index = 1
    for key, value in pairs(PersonalPlayerBlacklist.db.global.blacklistedPlayers) do
        PersonalPlayerBlacklist:CreateTableButton(scrollChild, index, value);
        index = index + 1
    end

    container:Hide()
    local function AddEntry(player)
        PersonalPlayerBlacklist:CreateTableButton(scrollChild, index, player);
        index = index + 1
    end
    container.addEntry = AddEntry

    container:SetScript("OnShow",
    function(self)
        lastSort=true
        lastSortID=5
        PersonalPlayerBlacklist:SortPlayerBlacklist(5, scrollChild)
    end)
    return container;
end

function PersonalPlayerBlacklist:CreateColumnHeader(text, parent, width, name, child)
    local p = _G[name .. "Header1"]

    if p == nil then
        columnCount = 0
    end

    columnCount = columnCount + 1

    local Header = CreateFrame("Button", name .. "Header" .. columnCount, parent, "WhoFrameColumnHeaderTemplate")
    Header:SetWidth(width)
    _G[name .. "Header" .. columnCount .. "Middle"]:SetWidth(width - 9)
    Header:SetText(text)
    Header:SetNormalFontObject("GameFontHighlight")
    Header:SetID(columnCount)

    if columnCount == 1 then
        Header:SetPoint("TOPLEFT", parent, "TOPLEFT", 3, 29)
    else
        Header:SetPoint("LEFT", name .. "Header" .. columnCount - 1, "RIGHT", 0, 0)
    end
    local function SortPlayerBlacklist(self)
        PersonalPlayerBlacklist:SortPlayerBlacklist(self:GetID(), child)
    end
    Header:SetScript("OnClick", SortPlayerBlacklist)
end

function PersonalPlayerBlacklist:SortPlayerBlacklist(sortBy, parent)
    if lastSortID ~= sortBy then
        lastSort = false
    end
    table.sort(FilteredScrollButtons,
        function(a, b)
            if sortBy == 1 then
                if not lastSort then
                    return a.name:GetText() < b.name:GetText()
                else
                    return b.name:GetText() < a.name:GetText()
                end
            elseif sortBy == 2 then
                if not lastSort then
                    return a.server:GetText() < b.server:GetText()
                else
                    return b.server:GetText() < a.server:GetText()
                end
            elseif sortBy == 3 then
                if not lastSort then
                    return a.class:GetText() < b.class:GetText()
                else
                    return b.class:GetText() < a.class:GetText()
                end
            elseif sortBy == 4 then
                if not lastSort then
                    return a.reason:GetText() < b.reason:GetText()
                else
                    return b.reason:GetText() < a.reason:GetText()
                end
            elseif sortBy == 5 then
                local amonth, aday, ayear = strsplit("/", a.date:GetText())
                local dateTbla = {
                    year = ayear,
                    month = amonth,
                    day = aday,
                }
                local bmonth, bday, byear = strsplit("/", b.date:GetText())
                local dateTblb = {
                    year = byear,
                    month = bmonth,
                    day = bday,
                }
                local adate = time(dateTbla)

                local bdate = time(dateTblb)
                if not lastSort then
                    return adate < bdate
                else
                    return bdate < adate
                end
            elseif sortBy == 6 then
                if not lastSort then
                    return a.notes:GetText() < b.notes:GetText()
                else
                    return b.notes:GetText() < a.notes:GetText()
                end
            else
                return tostring(a["date"]) < tostring(b["date"])
            end
        end)
    lastSort = not lastSort
    lastSortID = sortBy
    for i = 1, #FilteredScrollButtons do
        if i == 1 then
            FilteredScrollButtons[i]:SetPoint("TOPLEFT", parent, -1, 0)
        else
            FilteredScrollButtons[i]:SetPoint("TOPLEFT", FilteredScrollButtons[i - 1], "BOTTOMLEFT")
        end
    end
end

function PersonalPlayerBlacklist:CreateTableButton(parent, index, player)
    FilteredScrollButtons[index] = CreateFrame("Button", nil, parent, "IgnoreListButtonTemplate")
    if index == 1 then
        FilteredScrollButtons[index]:SetPoint("TOPLEFT", parent, -1, 0)
    else
        FilteredScrollButtons[index]:SetPoint("TOPLEFT", FilteredScrollButtons[index - 1], "BOTTOMLEFT")
    end

    FilteredScrollButtons[index]:SetSize(800, 20)
    FilteredScrollButtons[index]:RegisterForClicks("LeftButtonUp")
    --UnfilteredScrollButtons[index]:SetScript("OnClick", FilterScrollClick)

    -- set name style
    FilteredScrollButtons[index].name:SetWidth(100)
    FilteredScrollButtons[index].name:SetText(player["name"])
    -- set active style
    FilteredScrollButtons[index].server = FilteredScrollButtons[index]:CreateFontString("FontString", "OVERLAY",
        "GameFontNormal")
    FilteredScrollButtons[index].server:SetPoint("LEFT", FilteredScrollButtons[index].name, "RIGHT", 10, 0)
    FilteredScrollButtons[index].server:SetWidth(100)
    FilteredScrollButtons[index].server:SetJustifyH("LEFT")
    FilteredScrollButtons[index].server:SetText(player["server"])
    -- create blocked style
    FilteredScrollButtons[index].class = FilteredScrollButtons[index]:CreateFontString("FontString", "OVERLAY",
        "GameFontHighlight")
    FilteredScrollButtons[index].class:SetPoint("LEFT", FilteredScrollButtons[index].server, "RIGHT", 6, 0)
    FilteredScrollButtons[index].class:SetWidth(100)
    FilteredScrollButtons[index].class:SetJustifyH("LEFT")
    --UnfilteredScrollButtons[index].class:SetWordWrap(false)
    FilteredScrollButtons[index].class:SetText(player["class"])
    local class=string.upper(player["class"]:gsub("%s+", ""))
    FilteredScrollButtons[index].class:SetTextColor(classColor[class][1],classColor[class][2],classColor[class][3],1);
    FilteredScrollButtons[index].reason = FilteredScrollButtons[index]:CreateFontString("FontString", "OVERLAY",
        "GameFontHighlight")
    FilteredScrollButtons[index].reason:SetPoint("LEFT", FilteredScrollButtons[index].class, "RIGHT", 10, 0)
    FilteredScrollButtons[index].reason:SetWidth(70)
    FilteredScrollButtons[index].reason:SetJustifyH("LEFT")
    FilteredScrollButtons[index].reason:SetText(player["reason"])
    if player["reason"] and player["reason"] ~= "" then
        FilteredScrollButtons[index].reason:SetText(player["reason"])
    else
        FilteredScrollButtons[index].reason:SetText(" ")
    end

    FilteredScrollButtons[index].date = FilteredScrollButtons[index]:CreateFontString("FontString", "OVERLAY",
        "GameFontHighlight")
    FilteredScrollButtons[index].date:SetPoint("LEFT", FilteredScrollButtons[index].reason, "RIGHT", 10, 0)
    FilteredScrollButtons[index].date:SetWidth(80)
    FilteredScrollButtons[index].date:SetJustifyH("LEFT")
    FilteredScrollButtons[index].date:SetText(player["date"])

    FilteredScrollButtons[index].notes = FilteredScrollButtons[index]:CreateFontString("FontString", "OVERLAY",
        "GameFontHighlight")
    FilteredScrollButtons[index].notes:SetPoint("LEFT", FilteredScrollButtons[index].date, "RIGHT", 10, 0)
    FilteredScrollButtons[index].notes:SetWidth(250)
    FilteredScrollButtons[index].notes:SetJustifyH("LEFT")
    if player["notes"] and player["notes"] ~= "" then
        FilteredScrollButtons[index].notes:SetText(player["notes"])
    else
        FilteredScrollButtons[index].notes:SetText(" ")
    end



    FilteredScrollButtons[index]:Show()
    -- create filter style
end
