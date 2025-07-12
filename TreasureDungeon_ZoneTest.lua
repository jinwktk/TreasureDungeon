--[[
================================================================================
                      Zone Detection Test v1.0.0
================================================================================

新SND v12.0.0+でのゾーン検出APIテスト専用スクリプト

================================================================================
]]

-- ログ関数
local function TestLog(message)
    yield("/echo [ZoneTest] " .. tostring(message))
end

-- 複数のゾーン検出方法をテスト
local function TestZoneDetection()
    TestLog("=== ゾーン検出APIテスト開始 ===")
    
    -- 方法1: Svc.ClientState.TerritoryType（正しいAPI）
    local success1, result1 = pcall(function()
        if Svc and Svc.ClientState and Svc.ClientState.TerritoryType then
            return Svc.ClientState.TerritoryType
        end
        return nil
    end)
    TestLog("Svc.ClientState.TerritoryType: " .. tostring(success1) .. " -> " .. tostring(result1))
    
    -- 方法2: Player.Territory
    local success2, result2 = pcall(function()
        if Player and Player.Territory then
            return Player.Territory
        end
        return nil
    end)
    TestLog("Player.Territory: " .. tostring(success2) .. " -> " .. tostring(result2))
    
    -- 方法3: Entity.Player の位置情報
    local success3, result3 = pcall(function()
        if Entity and Entity.Player and Entity.Player.Territory then
            return Entity.Player.Territory
        end
        return nil
    end)
    TestLog("Entity.Player.Territory: " .. tostring(success3) .. " -> " .. tostring(result3))
    
    -- 方法4: GetZoneID関数（従来API）
    local success4, result4 = pcall(function()
        if GetZoneID then
            return GetZoneID()
        end
        return nil
    end)
    TestLog("GetZoneID(): " .. tostring(success4) .. " -> " .. tostring(result4))
    
    -- 方法5: yield経由でゾーン情報取得
    local success5, result5 = pcall(function()
        -- /whereami コマンドの結果をキャプチャ（仮）
        return "yield_method_not_implemented"
    end)
    TestLog("yield method: " .. tostring(success5) .. " -> " .. tostring(result5))
    
    -- どの方法が使えるかの判定
    local workingMethods = {}
    if success1 and result1 and result1 ~= 0 then
        table.insert(workingMethods, "Player.Territory")
        TestLog("Working: Player.Territory = " .. tostring(result1))
    end
    if success2 and result2 and result2 ~= 0 then
        table.insert(workingMethods, "Instances.ClientState.TerritoryType")
        TestLog("Working: Instances.ClientState.TerritoryType = " .. tostring(result2))
    end
    if success3 and result3 and result3 ~= 0 then
        table.insert(workingMethods, "Entity.Player.Territory")
        TestLog("Working: Entity.Player.Territory = " .. tostring(result3))
    end
    if success4 and result4 and result4 ~= 0 then
        table.insert(workingMethods, "GetZoneID()")
        TestLog("Working: GetZoneID() = " .. tostring(result4))
    end
    
    TestLog("利用可能なメソッド数: " .. #workingMethods)
    
    -- リムサ・ロミンサ判定テスト（ゾーンID: 129）
    local isLimsa = false
    if success1 and result1 == 129 then
        isLimsa = true
        TestLog("Svc.ClientState.TerritoryTypeでリムサ・ロミンサを検出!")
    elseif success2 and result2 == 129 then
        isLimsa = true
        TestLog("Player.Territoryでリムサ・ロミンサを検出!")
    elseif success3 and result3 == 129 then
        isLimsa = true
        TestLog("Entity.Player.Territoryでリムサ・ロミンサを検出!")
    elseif success4 and result4 == 129 then
        isLimsa = true
        TestLog("GetZoneID()でリムサ・ロミンサを検出!")
    end
    
    TestLog("リムサ・ロミンサ判定結果: " .. tostring(isLimsa))
    TestLog("=== テスト完了 ===")
    
    return isLimsa
end

-- 実行
TestZoneDetection()