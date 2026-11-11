local addonName = ...

local HIDE_ALT_TEXT = true

local function ForEachRegion(frame, callback)
    if not frame then return end

    for _, region in ipairs({ frame:GetRegions() }) do
        callback(region)
    end

    for _, child in ipairs({ frame:GetChildren() }) do
        ForEachRegion(child, callback)
    end
end

local function SetTextShown(text, shown)
    if text then
        text:SetAlpha(shown and 1 or 0)
        text:SetShown(shown)
    end
end

local function ApplyTextVisibility(bar)
    if not bar then return end

    if bar.overlay then
        bar.overlay:SetAlpha(HIDE_ALT_TEXT and 0 or 1)
    end

    for _, key in ipairs({ "TextString", "LeftText", "RightText" }) do
        SetTextShown(bar[key], not HIDE_ALT_TEXT)
    end

    ForEachRegion(bar, function(region)
        if region:IsObjectType("FontString") then
            region:SetAlpha(HIDE_ALT_TEXT and 0 or 1)
            region:SetShown(not HIDE_ALT_TEXT)
        end
    end)
end

local function AdjustManaBarGeometry(bar)
    if not bar or bar.CatManaCleanerGeometryV7 then return end

    local reference = _G.PlayerFrame
        and _G.PlayerFrame.PlayerFrameContent
        and _G.PlayerFrame.PlayerFrameContent.PlayerFrameContentMain
        and _G.PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea
        and _G.PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar

    if reference and reference:GetHeight() > 0 then
        local classicFrames = _G.BetterBlizzFramesDB and _G.BetterBlizzFramesDB.classicFrames
        bar:ClearAllPoints()
        -- Preserve the custom bar's original lower-row placement.
        -- Restore the earlier two-pixel-right placement that looked better.
        if classicFrames then
            bar:SetPoint("BOTTOMLEFT", _G.PlayerFrame, "BOTTOMLEFT", 97, 17)
        else
            bar:SetPoint("BOTTOMLEFT", _G.PlayerFrame, "BOTTOMLEFT", 87, 18)
        end
        -- Match the neighboring bar's exact width.
        bar:SetWidth(reference:GetWidth())
        bar:SetHeight(math.max(1, reference:GetHeight() - 1))
    else
        local point, relativeTo, relativePoint, xOffset, yOffset = bar:GetPoint(1)
        if not point then return end
        bar:ClearAllPoints()
        bar:SetPoint(point, relativeTo, relativePoint, (xOffset or 0) + 1, yOffset or 0)
        bar:SetHeight(math.max(1, bar:GetHeight() - 1))
    end

    bar.CatManaCleanerGeometryV7 = true
end

local function GetAltManaBar()
    return _G.PlayerFrame and _G.PlayerFrame.AltManaBarBBF
end

local function HookText(text)
    if not text or text.CatManaCleanerHooked then return end
    text.CatManaCleanerHooked = true

    hooksecurefunc(text, "SetText", function(self)
        if HIDE_ALT_TEXT then SetTextShown(self, false) end
    end)

    hooksecurefunc(text, "Show", function(self)
        if HIDE_ALT_TEXT then SetTextShown(self, false) end
    end)
end

local function Setup()
    local bar = GetAltManaBar()

    if bar and not bar.CatManaCleanerFrameHooked then
        bar.CatManaCleanerFrameHooked = true
        hooksecurefunc(bar, "Show", function() ApplyTextVisibility(bar) end)
        hooksecurefunc(bar, "SetShown", function() ApplyTextVisibility(bar) end)
    end

    if bar then
        AdjustManaBarGeometry(bar)
        HookText(bar.TextString)
        HookText(bar.LeftText)
        HookText(bar.RightText)
        ApplyTextVisibility(bar)
    end

    if _G.BBF and _G.BBF.CreateAltManaBar and not _G.BBF.CatManaCleanerHooked then
        _G.BBF.CatManaCleanerHooked = true
        hooksecurefunc(_G.BBF, "CreateAltManaBar", function()
            C_Timer.After(0, Setup)
        end)
    end
end

SLASH_CATMANA1 = "/catmana"
SlashCmdList.CATMANA = function(message)
    message = string.lower(message or "")

    if message == "text" then
        HIDE_ALT_TEXT = not HIDE_ALT_TEXT
    elseif message == "status" then
        local bar = GetAltManaBar()
        print("Cat Mana Cleaner: bar=" .. (bar and "found" or "missing") .. ", text=" .. (bar and bar.TextString and "found" or "missing") .. ".")
        return
    elseif message == "show" then
        HIDE_ALT_TEXT = false
    elseif message == "hide" or message == "" then
        HIDE_ALT_TEXT = true
    else
        print("Cat Mana Cleaner: /catmana [hide|show|text|status]")
        return
    end

    ApplyTextVisibility(GetAltManaBar())
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function()
    C_Timer.After(0, Setup)
    C_Timer.After(1, Setup)
    C_Timer.After(2, Setup)
end)
