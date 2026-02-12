local prevCur = nil
local prevCnt = nil
local prevMeterNewVDXW = nil
local prevAudioBandsStartPx = nil
local prevScale = nil
local pillPos = nil
local pillTarget = nil
local vdMax = nil
local cachedIdsRaw = nil
local cachedCurRaw = nil
local cachedCur = nil
local cachedCnt = nil
local mVDIDs = nil
local mVDCurrentGuid = nil
local mVDPlusX = nil
local startToggleState = 0
local commandPaletteToggleState = 0
local PILL_EASE = 0.35
local PILL_MIN_STEP = 0.02

function Initialize()
  -- Track previous values to avoid unnecessary writes and refreshes.
  prevCur = nil
  prevCnt = nil
  prevMeterNewVDXW = nil
  prevAudioBandsStartPx = nil
  prevScale = nil
  vdMax = tonumber(SKIN:GetVariable('VDMax')) or 7
  pillPos = tonumber(SKIN:GetVariable('VDPillPos')) or 1
  pillTarget = pillPos
  cachedIdsRaw = nil
  cachedCurRaw = nil
  cachedCur = nil
  cachedCnt = nil
  mVDIDs = SKIN:GetMeasure("MeasureVDIDs")
  mVDCurrentGuid = SKIN:GetMeasure("MeasureVDCurrentGuid")
  mVDPlusX = SKIN:GetMeasure("MeasureVDPlusX")
  startToggleState = tonumber(SKIN:GetVariable('StartToggleState')) or 0
  commandPaletteToggleState = tonumber(SKIN:GetVariable('CommandPaletteToggleState')) or 0
end

-- Converts a Rainmeter Registry REG_BINARY string to a clean hex string (no spaces/commas/0x)
local function normalizeHex(s)
  if not s then return "" end
  s = tostring(s)
  s = s:gsub("0x", "")
  s = s:gsub("[^0-9A-Fa-f]", "")
  return s:upper()
end

-- GUID bytes in registry are little-endian for first 3 fields.
-- Given 32 hex chars (16 bytes), format as GUID string.
local function hex16ToGuid(h)
  if #h < 32 then return nil end
  local function revBytes(hex)
    -- hex length even
    local out = {}
    for i = #hex, 1, -2 do
      out[#out+1] = hex:sub(i-1, i)
    end
    return table.concat(out)
  end

  local d1 = revBytes(h:sub(1, 8))
  local d2 = revBytes(h:sub(9, 12))
  local d3 = revBytes(h:sub(13, 16))
  local d4 = h:sub(17, 20)
  local d5 = h:sub(21, 32)
  return string.format("%s-%s-%s-%s-%s", d1, d2, d3, d4, d5)
end

-- returns: currentNumber, count
local function computeVD()
  if not mVDIDs then mVDIDs = SKIN:GetMeasure("MeasureVDIDs") end
  if not mVDCurrentGuid then mVDCurrentGuid = SKIN:GetMeasure("MeasureVDCurrentGuid") end
  local idsRaw = mVDIDs and mVDIDs:GetStringValue() or ""
  local curRaw = mVDCurrentGuid and mVDCurrentGuid:GetStringValue() or ""
  idsRaw = tostring(idsRaw or "")
  curRaw = tostring(curRaw or "")

  if idsRaw == cachedIdsRaw and curRaw == cachedCurRaw and cachedCur and cachedCnt then
    return cachedCur, cachedCnt
  end

  local idsHex = normalizeHex(idsRaw)

  -- Each desktop ID is 16 bytes = 32 hex chars
  local count = math.floor(#idsHex / 32)
  if count < 1 then
    cachedIdsRaw = idsRaw
    cachedCurRaw = curRaw
    cachedCur = 1
    cachedCnt = 1
    return 1, 1
  end

  -- Fast path: when current desktop GUID didn't change, avoid GUID scan.
  if curRaw == cachedCurRaw and cachedCur then
    local currentNumber = cachedCur
    if currentNumber < 1 then currentNumber = 1 end
    if currentNumber > count then currentNumber = count end
    cachedIdsRaw = idsRaw
    cachedCurRaw = curRaw
    cachedCur = currentNumber
    cachedCnt = count
    return currentNumber, count
  end

  local curHex = normalizeHex(curRaw)

  local curGuid = hex16ToGuid(curHex:sub(1, 32))
  if not curGuid then
    cachedIdsRaw = idsRaw
    cachedCurRaw = curRaw
    cachedCur = 1
    cachedCnt = count
    return 1, count
  end

  local currentNumber = 1
  for i = 1, count do
    local chunk = idsHex:sub((i-1)*32 + 1, (i-1)*32 + 32)
    local g = hex16ToGuid(chunk)
    if g == curGuid then
      currentNumber = i
      break
    end
  end

  cachedIdsRaw = idsRaw
  cachedCurRaw = curRaw
  cachedCur = currentNumber
  cachedCnt = count
  return currentNumber, count
end

local function runJump(target)
  SKIN:Bang('!SetVariable', 'VDJumpTarget', tostring(target))
  SKIN:Bang('!UpdateMeasure', 'MeasureVDJump')
  SKIN:Bang('!CommandMeasure', 'MeasureVDJump', 'Run')
end

local function runDeleteAt(target, fallback)
  SKIN:Bang('!SetVariable', 'VDDeleteTarget', tostring(target))
  SKIN:Bang('!SetVariable', 'VDDeleteFallback', tostring(fallback))
  SKIN:Bang('!UpdateMeasure', 'MeasureVDDeleteAt')
  SKIN:Bang('!CommandMeasure', 'MeasureVDDeleteAt', 'Run')
end

function Update()
  local needsMainRedraw = false

  local cur, cnt = computeVD()
  vdMax = tonumber(SKIN:GetVariable('VDMax')) or vdMax or 7
  local max = vdMax
  local target = cur
  if target < 1 then target = 1 end
  if target > max then target = max end
  if pillTarget == nil then
    pillTarget = target
  end

  if pillPos == nil then
    pillPos = target
    SKIN:Bang('!SetVariable', 'VDPillPos', string.format('%.4f', pillPos))
    SKIN:Bang('!UpdateMeter', 'MeterVDActivePill')
    needsMainRedraw = true
  end

  local curChanged = (cur ~= prevCur)
  local cntChanged = (cnt ~= prevCnt)
  local vdChanged = curChanged or cntChanged
  if vdChanged then
    SKIN:Bang('!SetVariable', 'VDCurrent', tostring(cur))
    SKIN:Bang('!SetVariable', 'VDCount', tostring(cnt))

    -- Update only VD measures that depend on current/count.
    SKIN:Bang('!UpdateMeasure', 'MeasureVDCountClamped')
    SKIN:Bang('!UpdateMeasure', 'MeasureVDCurrentClamped')
    SKIN:Bang('!UpdateMeasure', 'MeasureVDActionIcon')
    if cntChanged then
      SKIN:Bang('!UpdateMeasure', 'MeasureVDPlusX')
    end

    pillTarget = target

    -- Update only affected meters.
    SKIN:Bang('!UpdateMeter', 'MeterVDInactive')
    SKIN:Bang('!UpdateMeter', 'MeterNewVD')
    if cntChanged then
      SKIN:Bang('!UpdateMeterGroup', 'VDHit')
    end
    needsMainRedraw = true
  end

  -- Smooth pill transition without ActionTimer (runs on normal Update ticks).
  if pillPos and pillTarget then
    local delta = pillTarget - pillPos
    if math.abs(delta) <= PILL_MIN_STEP then
      if pillPos ~= pillTarget then
        pillPos = pillTarget
        SKIN:Bang('!SetVariable', 'VDPillPos', string.format('%.4f', pillPos))
        SKIN:Bang('!UpdateMeter', 'MeterVDActivePill')
        needsMainRedraw = true
      end
    else
      local step = delta * PILL_EASE
      if math.abs(step) < PILL_MIN_STEP then
        if delta > 0 then
          step = PILL_MIN_STEP
        else
          step = -PILL_MIN_STEP
        end
      end
      if math.abs(step) > math.abs(delta) then
        step = delta
      end
      pillPos = pillPos + step
      SKIN:Bang('!SetVariable', 'VDPillPos', string.format('%.4f', pillPos))
      SKIN:Bang('!UpdateMeter', 'MeterVDActivePill')
      needsMainRedraw = true
    end
  end

  local scale = tonumber(SKIN:GetVariable('Scale')) or 1
  local layoutChanged = (cnt ~= prevCnt) or (scale ~= prevScale) or (prevMeterNewVDXW == nil)
  if not mVDPlusX then mVDPlusX = SKIN:GetMeasure("MeasureVDPlusX") end
  if mVDPlusX and scale > 0 then
    -- Ensure the calc measure is current after refresh / variable updates.
    SKIN:Bang('!UpdateMeasure', 'MeasureVDPlusX')
    local plusX = tonumber(mVDPlusX:GetValue()) or 0
    -- Guard against transient invalid reads during startup ordering.
    if plusX > 0 then
      local plusW = 15 * scale
      local meterNewVDXW = ((plusX + plusW) / scale) + 15
      local minVisibleDelta = 0.5 / scale
      if (prevMeterNewVDXW == nil) or (math.abs(meterNewVDXW - prevMeterNewVDXW) > minVisibleDelta) then
        local meterBandsStart = plusX + plusW + (35 * scale)
        local bandsStartFormatted = string.format('%.3f', meterBandsStart)

        -- Update live variables in the running skin first.
        SKIN:Bang('!SetVariable', 'MeterBandsStart', bandsStartFormatted)
        if layoutChanged then
          SKIN:Bang('!UpdateMeter', 'MeterTitle')
          needsMainRedraw = true
        end

        -- Always sync AudioCore variable to recover from refresh-order races.
        SKIN:Bang('!SetVariable', 'MeterBandsStart', bandsStartFormatted, 'WindowsBar\\AudioCore')
        -- Persist startup baseline so AudioCore doesn't boot from stale include values.
        SKIN:Bang('!WriteKeyValue', 'Variables', 'MeterBandsStart', bandsStartFormatted, '#@#Variables.inc')
        if layoutChanged then
          SKIN:Bang('!UpdateMeter', 'MeterBands', 'WindowsBar\\AudioCore')
        end
        if layoutChanged and ((prevAudioBandsStartPx == nil) or (math.abs(meterBandsStart - prevAudioBandsStartPx) >= 0.5)) then
          SKIN:Bang('!Redraw', 'WindowsBar\\AudioCore')
          prevAudioBandsStartPx = meterBandsStart
        end
        prevMeterNewVDXW = meterNewVDXW
      end
    else
      -- Retry layout sync on next update if startup ordering gave an invalid value.
      prevMeterNewVDXW = nil
    end
  end

  if needsMainRedraw then
    SKIN:Bang('!Redraw')
  end

  prevCur = cur
  prevCnt = cnt
  prevScale = scale
  return tostring(cur) -- Lua measure returns current desktop number
end

function MoveToDesktop(target)
  target = tonumber(target)
  if not target then
    return
  end

  local cur, cnt = computeVD()
  if cnt < 1 then cnt = 1 end
  if target < 1 then target = 1 end
  if target > cnt then target = cnt end
  if target > (vdMax or 7) then target = vdMax or 7 end

  local delta = target - cur
  if delta == 0 then
    return
  end

  -- Accessor executable performs direct jump by desktop index.
  runJump(target)
end

function OnNewVDButton()
  local cur, cnt = computeVD()
  local max = vdMax or tonumber(SKIN:GetVariable('VDMax')) or 7

  if cnt >= max then
    local fallback = cur - 1
    if fallback < 1 then
      fallback = 2
    end
    if fallback > cnt then
      fallback = cnt - 1
    end
    runDeleteAt(cur, fallback)
  else
    SKIN:Bang('!CommandMeasure', 'NewVD', 'Send')
  end
end

function DeleteDesktop(target)
  target = tonumber(target)
  if not target then
    return
  end

  local _, cnt = computeVD()
  if cnt <= 1 then
    return
  end

  if target < 1 then target = 1 end
  if target > cnt then target = cnt end
  if target > (vdMax or 7) then target = vdMax or 7 end

  local fallback = target - 1
  if fallback < 1 then
    fallback = 2
  end
  if fallback > cnt then
    fallback = cnt - 1
  end
  runDeleteAt(target, fallback)
end

function ToggleStart()
  if startToggleState == 0 then
    startToggleState = 1
    SKIN:Bang('!SetVariable', 'StartToggleState', '1')
    SKIN:Bang('!CommandMeasure', 'Windows', 'Send')
  else
    startToggleState = 0
    SKIN:Bang('!SetVariable', 'StartToggleState', '0')
    SKIN:Bang('!CommandMeasure', 'CloseStart', 'Send')
  end
end

function ToggleCommandPalette()
  if commandPaletteToggleState == 0 then
    commandPaletteToggleState = 1
    SKIN:Bang('!SetVariable', 'CommandPaletteToggleState', '1')
    SKIN:Bang('!CommandMeasure', 'CommandPalette', 'Send')
  else
    commandPaletteToggleState = 0
    SKIN:Bang('!SetVariable', 'CommandPaletteToggleState', '0')
    SKIN:Bang('!CommandMeasure', 'CloseStart', 'Send')
  end
end
