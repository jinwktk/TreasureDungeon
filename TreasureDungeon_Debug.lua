--[[
================================================================================
                      TreasureDungeon Debug Version v3.0.4
================================================================================

デバッグ専用版 - 関数定義と呼び出しのテスト

================================================================================
]]

-- ログ関数
local function DebugLog(message)
    yield("/echo [DEBUG] " .. tostring(message))
end

-- 地図購入関数（デバッグ版）
local function ExecuteMapPurchase(mapConfig)
    DebugLog("ExecuteMapPurchase関数が呼び出されました")
    DebugLog("mapConfig.searchTerm: " .. tostring(mapConfig.searchTerm))
    
    -- 実際のマーケットボード操作は行わない（テスト版）
    DebugLog("マーケットボード操作をシミュレート中...")
    
    return false -- テスト用にfalseを返す
end

-- 地図購入高度版（デバッグ版）
local function ExecuteMapPurchaseAdvanced(mapConfig)
    DebugLog("ExecuteMapPurchaseAdvanced関数が呼び出されました")
    DebugLog("mapConfig.itemId: " .. tostring(mapConfig.itemId))
    
    return false -- テスト用にfalseを返す
end

-- 設定
local CONFIG = {
    MAP_TYPE = "G10",
    MAPS = {
        G10 = {
            itemId = 17836,
            searchTerm = "G10"
        }
    }
}

-- メイン処理
local function TestMapPurchase()
    DebugLog("=== 関数存在テスト開始 ===")
    
    local mapConfig = CONFIG.MAPS[CONFIG.MAP_TYPE]
    
    -- 関数存在確認
    DebugLog("ExecuteMapPurchase type: " .. type(ExecuteMapPurchase))
    DebugLog("ExecuteMapPurchaseAdvanced type: " .. type(ExecuteMapPurchaseAdvanced))
    
    -- 関数呼び出しテスト
    if type(ExecuteMapPurchase) == "function" then
        local result = ExecuteMapPurchase(mapConfig)
        DebugLog("ExecuteMapPurchase result: " .. tostring(result))
    else
        DebugLog("ERROR: ExecuteMapPurchase not found")
    end
    
    if type(ExecuteMapPurchaseAdvanced) == "function" then
        local result = ExecuteMapPurchaseAdvanced(mapConfig)
        DebugLog("ExecuteMapPurchaseAdvanced result: " .. tostring(result))
    else
        DebugLog("ERROR: ExecuteMapPurchaseAdvanced not found")
    end
    
    DebugLog("=== テスト完了 ===")
end

-- 実行
TestMapPurchase()