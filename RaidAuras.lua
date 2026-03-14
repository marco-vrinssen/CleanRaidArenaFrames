-- Manage raid frame auras by hiding extra debuffs and highlighting specific buffs because standard frames become unreadable in combat clumps

local trackedHealerSpellIds = {
    [194384]  = true, -- Atonement          (Discipline Priest)
    [156910]  = true, -- Beacon of Faith    (Holy Paladin)
    [1244893] = true, -- Beacon of Savior   (Holy Paladin)
    [53563]   = true, -- Beacon of Light    (Holy Paladin)
    [115175]  = true, -- Soothing Mist      (Mistweaver Monk)
    [33763]   = true, -- Lifebloom          (Restoration Druid)
}

local glowFrameCache = {}
local pendingGlowFrames = {}
local visitedBuffFrames = {}

-- Safely verify if a spell qualifies for healer tracking because Blizzard sometimes passes non-numeric data that breaks table lookups

local function isTrackedHealerAura(spellIdentifier)
    if type(spellIdentifier) ~= "number" then return false end

    local isSuccess, isTracked = pcall(function() return trackedHealerSpellIds[spellIdentifier] == true end)

    return isSuccess and isTracked
end

-- Return a cached overlay or construct a new glowing template frame because instantiating infinite animations depletes client memory quickly

local function getOrCreateGlowFrame(buffFrame)
    if glowFrameCache[buffFrame] then return glowFrameCache[buffFrame] end

    C_AddOns.LoadAddOn("Blizzard_ActionBar")

    local glowEffectFrame = CreateFrame("Frame", nil, buffFrame, "ActionButtonSpellAlertTemplate")

    glowEffectFrame:SetSize(buffFrame:GetWidth() * 1.4, buffFrame:GetHeight() * 1.4)
    glowEffectFrame:SetPoint("TOPLEFT", buffFrame, "TOPLEFT", -4, 4)
    glowEffectFrame:SetPoint("BOTTOMRIGHT", buffFrame, "BOTTOMRIGHT", 4, -4)
    glowEffectFrame.ProcStartFlipbook:Hide()
    glowEffectFrame:Hide()

    glowFrameCache[buffFrame] = glowEffectFrame

    return glowEffectFrame
end

-- Play the steady outer loop highlight animation immediately because the initial start flash creates visual artifacting on tiny raid buttons

local function showHealerGlow(buffFrame)
    local glowEffectFrame = getOrCreateGlowFrame(buffFrame)

    if glowEffectFrame.ProcStartAnim:IsPlaying() then glowEffectFrame.ProcStartAnim:Stop() end

    glowEffectFrame:Show()

    if not glowEffectFrame.ProcLoop:IsPlaying() then glowEffectFrame.ProcLoop:Play() end
end

-- Stop playing the highlight loop entirely because holding animations while invisible continues to waste processing cycles unnecessarily

local function hideHealerGlow(buffFrame)
    local glowEffectFrame = glowFrameCache[buffFrame]

    if not glowEffectFrame then return end

    glowEffectFrame.ProcLoop:Stop()
    glowEffectFrame.ProcStartAnim:Stop()
    glowEffectFrame:Hide()
end

-- Flag visited internal buff frames and prepare pending glows during the sorting pass because directly modifying them here causes tearing

local function evaluateHealerGlow(buffFrame, auraDataStructure)
    if not buffFrame then return end

    visitedBuffFrames[buffFrame] = true

    local spellIdentifier = auraDataStructure and type(auraDataStructure.spellId) == "number" and auraDataStructure.spellId

    if spellIdentifier and isTrackedHealerAura(spellIdentifier) then
        pendingGlowFrames[buffFrame] = true
    end
end

-- Resolve final glow states hiding extranous debuffs after setup completes because modifying frames before layout finishes overwrites our changes

local function onUpdateAuras(unitFrame)
    if not unitFrame then return end

    if unitFrame.buffFrames then
        for frameIndex = 1, #unitFrame.buffFrames do
            local buffFrame = unitFrame.buffFrames[frameIndex]

            if buffFrame then
                if visitedBuffFrames[buffFrame] then
                    if pendingGlowFrames[buffFrame] then
                        showHealerGlow(buffFrame)
                    else
                        hideHealerGlow(buffFrame)
                    end
                elseif not buffFrame:IsShown() then
                    hideHealerGlow(buffFrame)
                end
            end
        end
    end

    for clearedFrame in pairs(pendingGlowFrames) do pendingGlowFrames[clearedFrame] = nil end
    for clearedFrame in pairs(visitedBuffFrames) do visitedBuffFrames[clearedFrame] = nil end

    if unitFrame.debuffFrames then
        for frameIndex = 2, #unitFrame.debuffFrames do
            local debuffFrame = unitFrame.debuffFrames[frameIndex]
            if debuffFrame then debuffFrame:Hide() end
        end
    end
end

hooksecurefunc("CompactUnitFrame_UpdateAuras", onUpdateAuras)
hooksecurefunc("CompactUnitFrame_UtilSetBuff", evaluateHealerGlow)
