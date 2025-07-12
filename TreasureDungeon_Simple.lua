--[[
================================================================================
                      Treasure Hunt Automation v3.0.1 (Simple Test Version)
================================================================================

新SNDモジュールベースAPI対応 トレジャーハント自動化スクリプト（テスト版）

主な機能:
  - 基本的なAPIテスト
  - ログ出力テスト
  - 新SND v12.0.0.0+ モジュールベースAPI確認

Author: Claude
Version: 3.0.1-simple
Date: 2025-07-12

================================================================================
]]

-- ================================================================================
-- 基本設定
-- ================================================================================

local CONFIG = {
    MAP_TYPE = "G10",
    MAPS = {
        G17 = { itemId = 43557, jobId = 19, jobName = "ナイト" },
        G10 = { itemId = 17836, jobId = 21, jobName = "戦士" }
    }
}

-- ================================================================================
-- ログ関数（簡易版）
-- ================================================================================

local function SimpleLog(message)
    yield("/echo [TreasureTest] " .. tostring(message))
end

-- ================================================================================
-- API テスト関数
-- ================================================================================

local function TestNewAPIs()
    SimpleLog("=== 新SND API テスト開始 ===")
    
    -- Player API テスト
    local success, result = pcall(function()
        SimpleLog("Player.Available: " .. tostring(Player.Available))
        SimpleLog("Player.IsBusy: " .. tostring(Player.IsBusy))
        SimpleLog("Player.IsMoving: " .. tostring(Player.IsMoving))
        if Player.Job then
            SimpleLog("Player.Job.Id: " .. tostring(Player.Job.Id))
        end
    end)
    
    if not success then
        SimpleLog("Player API エラー: " .. tostring(result))
    end
    
    -- Inventory API テスト
    success, result = pcall(function()
        local mapConfig = CONFIG.MAPS[CONFIG.MAP_TYPE]
        local itemCount = Inventory.GetItemCount(mapConfig.itemId)
        SimpleLog("地図所持数 (" .. CONFIG.MAP_TYPE .. "): " .. tostring(itemCount))
    end)
    
    if not success then
        SimpleLog("Inventory API エラー: " .. tostring(result))
    end
    
    -- IPC API テスト
    success, result = pcall(function()
        local plugins = {"vnavmesh", "RotationSolverReborn", "AutoHook", "Teleporter"}
        for _, plugin in ipairs(plugins) do
            local installed = IPC.IsInstalled(plugin)
            SimpleLog("プラグイン " .. plugin .. ": " .. tostring(installed))
        end
    end)
    
    if not success then
        SimpleLog("IPC API エラー: " .. tostring(result))
    end
    
    -- Addons API テスト
    success, result = pcall(function()
        local addon = Addons.GetAddon("SelectYesno")
        if addon then
            SimpleLog("SelectYesno addon.Ready: " .. tostring(addon.Ready))
        else
            SimpleLog("SelectYesno addon: nil")
        end
    end)
    
    if not success then
        SimpleLog("Addons API エラー: " .. tostring(result))
    end
    
    SimpleLog("=== API テスト完了 ===")
end

-- ================================================================================
-- メイン実行
-- ================================================================================

local function Main()
    SimpleLog("TreasureDungeon v3.0.1 Simple Test 開始")
    
    -- 基本的な Lua 関数テスト
    SimpleLog("現在時刻: " .. os.date("%H:%M:%S"))
    SimpleLog("設定地図タイプ: " .. CONFIG.MAP_TYPE)
    
    -- 新SND API テスト
    TestNewAPIs()
    
    SimpleLog("テスト完了")
end

-- 実行
Main()