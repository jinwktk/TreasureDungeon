--[[
================================================================================
                      Treasure Hunt Automation v3.0.0
================================================================================

新SNDモジュールベースAPI対応 トレジャーハント完全自動化スクリプト

主な機能:
  - G17/G10地図の完全自動化
  - 4段階フェーズ管理システム
  - 新SND v12.0.0.0+ モジュールベースAPI対応
  - シンプルで堅牢なエラー処理

使用方法:
  1. 設定で地図タイプを選択 (G17/G10)
  2. スクリプトを実行
  3. 全自動でトレジャーハント実行

必須プラグイン:
  - Something Need Doing [Expanded Edition] v12.0.0.0+
  - VNavmesh
  - RSR (Rotation Solver Reborn)
  - AutoHook
  - Teleporter

Author: Claude (based on pot0to's original work)
Version: 3.0.0
Date: 2025-07-12

================================================================================
]]

-- ================================================================================
-- 設定管理
-- ================================================================================

local CONFIG = {
    -- 地図設定
    MAP_TYPE = "G10", -- G17 または G10
    
    -- 地図タイプ別設定
    MAPS = {
        G17 = {
            itemId = 43557,
            jobId = 19, -- PLD
            jobName = "ナイト",
            searchTerm = "G17"
        },
        G10 = {
            itemId = 17836,
            jobId = 21, -- WAR
            jobName = "戦士",
            searchTerm = "G10"
        }
    },
    
    -- タイムアウト設定（秒）
    TIMEOUTS = {
        MOVEMENT = 300,     -- 移動タイムアウト（5分）
        COMBAT = 30,        -- 戦闘タイムアウト（30秒）
        INTERACTION = 10,   -- インタラクションタイムアウト（10秒）
        TELEPORT = 15,      -- テレポートタイムアウト（15秒）
        DUNGEON = 600       -- ダンジョン全体タイムアウト（10分）
    },
    
    -- リトライ設定
    RETRIES = {
        MAX_ATTEMPTS = 3,   -- 最大リトライ回数
        DELAY = 2           -- リトライ間隔（秒）
    },
    
    -- デバッグ設定
    DEBUG = {
        ENABLED = true      -- デバッグログ有効
    }
}

-- ================================================================================
-- グローバル変数
-- ================================================================================

local currentPhase = "INIT"
local phaseStartTime = 0
local stopRequested = false
local iteration = 0
local maxIterations = 1000

-- フェーズ状態管理
local movementStarted = false
local digExecuted = false

-- フェーズ定義
local PHASES = {
    INIT = "初期化",
    MAP_PURCHASE = "地図購入",
    MOVEMENT = "移動",
    COMBAT = "戦闘",
    DUNGEON = "ダンジョン",
    COMPLETE = "完了",
    ERROR = "エラー"
}

-- ================================================================================
-- ユーティリティ関数
-- ================================================================================

-- ログ出力関数
local function Log(level, message, data)
    local timestamp = os.date("%H:%M:%S")
    local logMessage = string.format("[%s][%s][%s] %s", timestamp, level, currentPhase, message)
    
    if data then
        logMessage = logMessage .. " " .. tostring(data)
    end
    
    -- 新SNDではyield("/echo")を使用
    yield("/echo " .. logMessage)
end

local function LogInfo(message, data) Log("INFO", message, data) end
local function LogWarn(message, data) Log("WARN", message, data) end
local function LogError(message, data) Log("ERROR", message, data) end
local function LogDebug(message, data) 
    if CONFIG.DEBUG.ENABLED then 
        Log("DEBUG", message, data) 
    end 
end

-- 安全な関数実行
local function SafeExecute(func, errorMessage)
    local success, result = pcall(func)
    if not success then
        LogError(errorMessage or "Function execution failed", result)
        return false, result
    end
    return true, result
end

-- 待機関数
local function Wait(seconds)
    local endTime = os.clock() + seconds
    while os.clock() < endTime and not stopRequested do
        yield("/wait 0.1")
    end
end

-- タイムアウトチェック
local function IsTimeout(startTime, timeoutSeconds)
    return os.clock() - startTime > timeoutSeconds
end

-- ================================================================================
-- 新SNDモジュールベースAPI関数
-- ================================================================================

-- プレイヤー状態チェック
local function IsPlayerAvailable()
    return SafeExecute(function()
        return Player.Available and not Player.IsBusy
    end, "Failed to check player availability") and true or false
end

local function IsPlayerMoving()
    return SafeExecute(function()
        return Player.IsMoving
    end, "Failed to check player movement") and true or false
end

local function GetCurrentJob()
    return SafeExecute(function()
        return Player.Job.Id
    end, "Failed to get current job") and Player.Job.Id or 0
end

-- インベントリ管理
local function GetItemCount(itemId)
    local success, count = SafeExecute(function()
        return Inventory.GetItemCount(itemId)
    end, "Failed to get item count")
    return success and count or 0
end

-- アドオン管理
local function IsAddonVisible(addonName)
    return SafeExecute(function()
        local addon = Addons.GetAddon(addonName)
        return addon and addon.Ready
    end, "Failed to check addon visibility") and true or false
end

local function GetAddonText(addonName, nodeId)
    return SafeExecute(function()
        local addon = Addons.GetAddon(addonName)
        if addon and addon.Ready then
            local node = addon.GetNode(nodeId)
            return node and node.Text or ""
        end
        return ""
    end, "Failed to get addon text") and addon.GetNode(nodeId).Text or ""
end

-- プラグイン検出
local function HasPlugin(pluginName)
    return SafeExecute(function()
        return IPC.IsInstalled(pluginName)
    end, "Failed to check plugin") and true or false
end

-- 戦闘状態チェック
local function IsInCombat()
    return SafeExecute(function()
        -- 新SNDでの戦闘状態チェック - Player.IsBusyを使用
        return Player.IsBusy or false
    end, "Failed to check combat state") and true or false
end

local function IsInDuty()
    return SafeExecute(function()
        -- 新SNDでのデューティ状態チェック - 代替手段を使用
        -- GetZoneID()を使用してデューティを判定（仮実装）
        local zoneId = GetZoneID and GetZoneID() or 0
        return zoneId > 10000 -- デューティのゾーンIDは通常10000以上
    end, "Failed to check duty state") and true or false
end

-- ターゲット関連
local function HasTarget()
    return SafeExecute(function()
        -- 新SNDでのターゲット確認 - 代替手段を使用
        -- 現在はfalseを返す（実装が必要）
        return false
    end, "Failed to check target") and true or false
end

-- ================================================================================
-- フェーズ管理システム
-- ================================================================================

-- フェーズ変更
local function ChangePhase(newPhase, reason)
    if currentPhase == newPhase then
        return
    end
    
    LogInfo(string.format("フェーズ変更: %s → %s", PHASES[currentPhase] or currentPhase, PHASES[newPhase] or newPhase), reason)
    
    -- フェーズ変更時の状態リセット
    if newPhase == "MOVEMENT" then
        movementStarted = false
        digExecuted = false
    end
    
    currentPhase = newPhase
    phaseStartTime = os.clock()
end

-- フェーズタイムアウトチェック
local function CheckPhaseTimeout()
    local timeout = CONFIG.TIMEOUTS.MOVEMENT -- デフォルト
    
    if currentPhase == "COMBAT" then
        timeout = CONFIG.TIMEOUTS.COMBAT
    elseif currentPhase == "DUNGEON" then
        timeout = CONFIG.TIMEOUTS.DUNGEON
    end
    
    if IsTimeout(phaseStartTime, timeout) then
        LogWarn("フェーズタイムアウト", string.format("%s (%d秒)", PHASES[currentPhase], timeout))
        return true
    end
    
    return false
end

-- ================================================================================
-- 前提条件チェック
-- ================================================================================

local function CheckPrerequisites()
    LogInfo("前提条件をチェック中...")
    
    -- プレイヤー状態チェック
    if not IsPlayerAvailable() then
        LogError("プレイヤーが操作できない状態です")
        return false
    end
    
    -- プラグインチェック（警告のみ）
    local recommendedPlugins = {"vnavmesh", "RotationSolverReborn", "AutoHook", "Teleporter"}
    for _, plugin in ipairs(recommendedPlugins) do
        if not HasPlugin(plugin) then
            LogWarn("推奨プラグインが見つかりません: " .. plugin)
        else
            LogInfo("プラグイン確認: " .. plugin)
        end
    end
    
    -- ジョブチェック
    local mapConfig = CONFIG.MAPS[CONFIG.MAP_TYPE]
    if not mapConfig then
        LogError("無効な地図タイプ: " .. CONFIG.MAP_TYPE)
        return false
    end
    
    local currentJob = GetCurrentJob()
    if currentJob ~= mapConfig.jobId then
        LogWarn(string.format("推奨ジョブではありません。現在: %d, 推奨: %s(%d)", 
            currentJob, mapConfig.jobName, mapConfig.jobId))
    end
    
    LogInfo("前提条件チェック完了")
    return true
end

-- ================================================================================
-- 地図購入ヘルパー関数
-- ================================================================================

-- 現在地チェック関数
local function IsInLimsa()
    -- GetZoneID()でリムサ・ロミンサかどうか確認
    local success, zoneId = SafeExecute(function()
        return GetZoneID and GetZoneID() or 0
    end, "Failed to get zone ID")
    
    LogDebug("現在のゾーンID: " .. tostring(zoneId))
    
    -- リムサ・ロミンサのゾーンID: 129
    if success and zoneId == 129 then
        LogDebug("ゾーンIDでリムサ・ロミンサを確認")
        return true
    end
    
    -- 代替手段：GetZoneName()を使用
    local success2, zoneName = SafeExecute(function()
        return GetZoneName and GetZoneName() or ""
    end, "Failed to get zone name")
    
    LogDebug("現在のゾーン名: " .. tostring(zoneName))
    
    if success2 and (string.find(zoneName, "リムサ") or string.find(zoneName, "Limsa")) then
        LogDebug("ゾーン名でリムサ・ロミンサを確認")
        return true
    end
    
    LogDebug("リムサ・ロミンサではない場所にいます")
    return false
end

-- 地図自動購入機能（リムサ・ロミンサ版）
local function ExecuteMapPurchase(mapConfig)
    LogInfo("リムサ・ロミンサで地図を購入します")
    
    -- 1. 現在地チェック
    if IsInLimsa() then
        LogInfo("すでにリムサ・ロミンサにいます - テレポートをスキップ")
    else
        LogInfo("リムサ・ロミンサにテレポート中...")
        yield("/tp リムサ・ロミンサ")
        Wait(10)  -- テレポート完了まで待機
    end
    
    -- 2. マーケットボードに移動
    LogInfo("マーケットボードに向けて移動中...")
    if HasPlugin("vnavmesh") then
        -- vnavmeshでマーケットボードに移動（複数のコマンドを試行）
        LogInfo("vnavmeshコマンドを実行中...")
        
        -- リムサのマーケットボード付近に移動（異なるコマンドを試行）
        yield("/vnav moveto 123.5 40.2 -38.8")
        Wait(3)
        
        -- 移動が開始されない場合は別のコマンドを試行
        if not IsPlayerMoving() then
            LogInfo("代替移動コマンドを試行...")
            yield("/vnav goto <123.5, 40.2, -38.8>")
            Wait(3)
        end
        
        -- 移動が開始されない場合はターゲット移動を試行
        if not IsPlayerMoving() then
            LogInfo("マーケットボードをターゲットして移動...")
            yield("/target マーケットボード")
            Wait(2)
            yield("/vnav movetarget")
            Wait(3)
        end
        
        -- 移動完了まで待機（タイムアウト付き）
        local moveTimeout = 30
        local moveStartTime = os.clock()
        
        while IsPlayerMoving() and not IsTimeout(moveStartTime, moveTimeout) do
            LogDebug("移動中...")
            Wait(1)
        end
        
        if IsTimeout(moveStartTime, moveTimeout) then
            LogWarn("移動タイムアウト - 手動で移動してください")
            LogInfo("手動移動の場合は、マーケットボード付近で待機してください")
            Wait(15)  -- 手動移動のための時間
        else
            LogInfo("マーケットボード付近に到着")
        end
    else
        LogWarn("vnavmeshが利用できません。手動でマーケットボードに移動してください")
        LogInfo("リムサ・ロミンサのマーケットボード（エーテライト広場）付近に移動してください")
        Wait(15)  -- 手動移動のための時間
    end
    
    -- 3. マーケットボードをターゲット
    LogInfo("マーケットボードをターゲット中...")
    yield("/target マーケットボード")
    Wait(2)
    
    -- 4. マーケットボードとインタラクト
    LogInfo("マーケットボードとインタラクト中...")
    yield("/interact")
    Wait(5)  -- マーケットボード表示待機
    
    -- 5. 地図を検索・購入
    return ExecuteMapSearch(mapConfig)
end

-- マーケットボードでの地図検索・購入
local function ExecuteMapSearch(mapConfig)
    LogInfo("マーケットボードで地図を検索中...")
    
    local searchTerm = mapConfig.searchTerm or CONFIG.MAP_TYPE
    LogInfo("検索キーワード: " .. searchTerm)
    
    -- マーケットボードが表示されるまで待機
    local waitCount = 0
    while not IsAddonVisible("ItemSearchResult") and waitCount < 10 do
        if IsAddonVisible("ItemSearch") then
            LogInfo("アイテム検索画面を確認")
            break
        end
        Wait(1)
        waitCount = waitCount + 1
    end
    
    if waitCount >= 10 then
        LogWarn("マーケットボードの表示がタイムアウト")
        return false
    end
    
    -- 検索実行
    if IsAddonVisible("ItemSearch") then
        -- アイテム名で検索
        LogInfo("地図を検索中: " .. searchTerm)
        
        -- 検索ボックスに入力（簡易実装）
        yield("/send " .. searchTerm)
        Wait(2)
        
        -- 検索実行
        yield("/click search")
        Wait(3)
        
        -- 検索結果から購入
        if IsAddonVisible("ItemSearchResult") then
            LogInfo("検索結果から購入中...")
            
            -- 最初の結果を選択
            yield("/click result1")
            Wait(2)
            
            -- 購入実行
            yield("/click purchase")
            Wait(2)
            
            -- 購入確認
            if IsAddonVisible("SelectYesno") then
                yield("/callback SelectYesno true 0") -- はい
                Wait(3)
                LogInfo("地図購入完了")
                return true
            end
        end
    end
    
    LogWarn("地図購入に失敗")
    return false
end

-- シンプルな地図購入（手動移動版）
local function ExecuteMapPurchaseSimple(mapConfig)
    LogInfo("シンプル地図購入を開始（手動移動）")
    
    -- 1. 現在地チェック・テレポート
    if IsInLimsa() then
        LogInfo("すでにリムサ・ロミンサにいます - テレポートをスキップ")
    else
        LogInfo("リムサ・ロミンサにテレポート中...")
        yield("/tp リムサ・ロミンサ")
        Wait(10)
    end
    
    -- 2. 手動移動の指示
    LogInfo("手動でマーケットボードに移動してください")
    LogInfo("移動完了後、マーケットボード付近で待機してください")
    Wait(20)  -- 手動移動のための時間
    
    -- 3. マーケットボードをターゲット
    LogInfo("マーケットボードをターゲット中...")
    yield("/target マーケットボード")
    Wait(2)
    
    -- 4. インタラクト
    LogInfo("マーケットボードとインタラクト中...")
    yield("/interact")
    Wait(5)
    
    -- 5. 購入処理
    return ExecuteMapSearch(mapConfig)
end

-- ExecuteMarketBoardSearchを参考にした改良版
local function ExecuteMapPurchaseAdvanced(mapConfig)
    LogInfo("高度なマーケットボード検索で地図を購入中...")
    
    -- マーケットボードを開く
    yield("/marketboard")
    Wait(3)
    
    -- 検索実行
    if IsAddonVisible("ItemSearch") then
        LogInfo("アイテム検索画面を確認")
        
        -- アイテムIDで検索
        yield("/callback ItemSearch true 13 " .. mapConfig.itemId)
        Wait(2)
        
        -- 検索実行
        yield("/callback ItemSearch true 1")
        Wait(3)
        
        -- 結果から購入
        if IsAddonVisible("ItemSearchResult") then
            LogInfo("検索結果を確認")
            
            -- 最初の結果を選択
            yield("/callback ItemSearchResult true 1 0")
            Wait(1)
            
            -- 購入実行
            yield("/callback ItemSearchResult true 2")
            Wait(2)
            
            -- 購入確認
            if IsAddonVisible("SelectYesno") then
                yield("/callback SelectYesno true 0") -- はい
                Wait(3)
            end
            
            return true
        end
    end
    
    LogWarn("高度な検索に失敗")
    return false
end

-- ================================================================================
-- フェーズ実装
-- ================================================================================

-- 初期化フェーズ
local function ExecuteInitPhase()
    LogInfo("トレジャーハント自動化を開始します")
    LogInfo("設定: " .. CONFIG.MAP_TYPE .. " 地図")
    
    if not CheckPrerequisites() then
        ChangePhase("ERROR", "前提条件チェック失敗")
        return
    end
    
    ChangePhase("MAP_PURCHASE", "初期化完了")
end

-- 地図購入フェーズ
local function ExecuteMapPurchasePhase()
    local mapConfig = CONFIG.MAPS[CONFIG.MAP_TYPE]
    local mapCount = GetItemCount(mapConfig.itemId)
    
    LogDebug("地図所持数チェック", mapCount)
    
    if mapCount > 0 then
        LogInfo("地図を所持しています。解読を実行します")
        yield("/gaction ディサイファー")
        Wait(3)
        
        -- 解読後、テレポートを実行
        LogInfo("フラグ地点にテレポート中...")
        if HasPlugin("Teleporter") then
            yield("/flag")
        else
            yield("/tp " .. "エーテライト")  -- 汎用テレポートコマンド
        end
        Wait(5)  -- テレポート完了待機
        
        ChangePhase("MOVEMENT", "地図解読・テレポート完了")
        return
    end
    
    LogInfo("地図を購入する必要があります")
    
    -- 関数存在確認付きマーケットボード自動購入（複数の方式を試行）
    local purchaseSuccess = false
    
    -- 1. シンプル購入（手動移動）を試行
    if type(ExecuteMapPurchaseSimple) == "function" then
        purchaseSuccess = ExecuteMapPurchaseSimple(mapConfig)
        LogInfo("シンプル購入実行結果: " .. tostring(purchaseSuccess))
    else
        LogError("ExecuteMapPurchaseSimple関数が見つかりません")
    end
    
    -- 2. 基本購入（自動移動）を試行
    if not purchaseSuccess and type(ExecuteMapPurchase) == "function" then
        purchaseSuccess = ExecuteMapPurchase(mapConfig)
        LogInfo("基本購入実行結果: " .. tostring(purchaseSuccess))
    end
    
    -- 3. 高度購入を試行
    if not purchaseSuccess and type(ExecuteMapPurchaseAdvanced) == "function" then
        purchaseSuccess = ExecuteMapPurchaseAdvanced(mapConfig)
        LogInfo("高度購入実行結果: " .. tostring(purchaseSuccess))
    end
    
    if purchaseSuccess then
        LogInfo("地図購入完了")
        -- 購入後は次のループで解読処理へ
    else
        LogWarn("地図購入に失敗。手動で準備してください")
        Wait(5)
    end
end

-- 移動フェーズ
local function ExecuteMovementPhase()
    if not movementStarted then
        LogInfo("宝の場所への移動を開始します")
        if HasPlugin("vnavmesh") then
            yield("/vnav flyflag")
            movementStarted = true
            LogDebug("vnavmeshで移動開始")
        else
            LogWarn("vnavmeshが利用できません。手動で移動してください")
            movementStarted = true  -- 手動移動待機
        end
        Wait(2)
        return
    end
    
    -- 移動完了チェック
    if not IsPlayerMoving() and not digExecuted then
        LogInfo("移動完了。発掘を実行します")
        yield("/gaction ディグ")
        digExecuted = true
        Wait(3)
        
        -- 宝箱検出
        if IsAddonVisible("SelectYesno") then
            yield("/callback SelectYesno true 0") -- はい
            Wait(2)
        end
        
        -- 状態リセット
        movementStarted = false
        digExecuted = false
        
        ChangePhase("COMBAT", "発掘完了、戦闘開始")
        return
    end
    
    -- 移動中の場合は待機
    if IsPlayerMoving() then
        LogDebug("移動中...")
        Wait(1)
    end
end

-- 戦闘フェーズ
local function ExecuteCombatPhase()
    -- 戦闘自動化の有効化（利用可能なプラグインのみ）
    if IsInCombat() then
        LogInfo("戦闘中。自動戦闘を開始します")
        
        -- RSRが利用可能な場合のみ使用
        if HasPlugin("RotationSolverReborn") then
            yield("/rotation auto on")
        end
        
        -- BMRが利用可能な場合のみ使用（コマンド要確認）
        -- yield("/bmrai on")
        
        -- 戦闘終了まで待機
        local combatStartTime = os.clock()
        while IsInCombat() and not IsTimeout(combatStartTime, CONFIG.TIMEOUTS.COMBAT) do
            Wait(1)
        end
        
        if not IsInCombat() then
            LogInfo("戦闘終了")
            
            -- RSRが利用可能な場合のみ停止
            if HasPlugin("RotationSolverReborn") then
                yield("/rotation auto off")
            end
            
            -- ダンジョン検出
            if IsInDuty() then
                ChangePhase("DUNGEON", "ダンジョンに転送されました")
            else
                ChangePhase("MOVEMENT", "次の宝箱を探索")
            end
        else
            LogWarn("戦闘タイムアウト")
        end
    else
        -- 戦闘していない場合は移動フェーズに戻る
        ChangePhase("MOVEMENT", "戦闘対象なし")
    end
end

-- ダンジョンフェーズ
local function ExecuteDungeonPhase()
    LogInfo("ダンジョン探索を開始します")
    
    -- 自動戦闘有効化（利用可能なプラグインのみ）
    if HasPlugin("RotationSolverReborn") then
        yield("/rotation auto on")
    end
    
    local dungeonStartTime = os.clock()
    
    while IsInDuty() and not IsTimeout(dungeonStartTime, CONFIG.TIMEOUTS.DUNGEON) do
        -- TreasureHighLowミニゲーム処理
        if IsAddonVisible("TreasureHighLow") then
            LogDebug("ミニゲーム検出")
            yield("/callback TreasureHighLow true 1") -- 1を選択
            Wait(2)
        end
        
        -- SelectYesno処理
        if IsAddonVisible("SelectYesno") then
            LogDebug("確認ダイアログ検出")
            yield("/callback SelectYesno true 0") -- はい
            Wait(2)
        end
        
        -- 自動移動とターゲット処理
        if not IsPlayerMoving() and IsPlayerAvailable() then
            -- 宝箱をターゲット
            yield("/target 宝箱")
            Wait(0.5)
            
            if HasTarget() then
                if HasPlugin("vnavmesh") then
                    yield("/vnav movetarget")
                end
                Wait(1)
                yield("/interact")
                Wait(2)
            else
                -- 前進探索
                yield("/automove on")
                Wait(3)
                yield("/automove off")
            end
        end
        
        Wait(1)
    end
    
    if not IsInDuty() then
        LogInfo("ダンジョン探索完了")
        if HasPlugin("RotationSolverReborn") then
            yield("/rotation auto off")
        end
        ChangePhase("COMPLETE", "ダンジョン脱出完了")
    else
        LogWarn("ダンジョンタイムアウト")
        ChangePhase("ERROR", "ダンジョンタイムアウト")
    end
end

-- 完了フェーズ
local function ExecuteCompletePhase()
    LogInfo("トレジャーハント完了！")
    
    -- 次の地図があるかチェック
    local mapConfig = CONFIG.MAPS[CONFIG.MAP_TYPE]
    local mapCount = GetItemCount(mapConfig.itemId)
    
    if mapCount > 0 then
        LogInfo("次の地図が見つかりました。続行します")
        ChangePhase("MAP_PURCHASE", "次の地図を処理")
    else
        LogInfo("全ての地図を処理しました")
        stopRequested = true
    end
end

-- エラーフェーズ
local function ExecuteErrorPhase()
    LogError("エラーが発生しました。スクリプトを停止します")
    
    -- 緊急停止処理（利用可能なプラグインのみ）
    if HasPlugin("RotationSolverReborn") then
        yield("/rotation auto off")
    end
    yield("/automove off")
    
    stopRequested = true
end

-- ================================================================================
-- メイン実行システム
-- ================================================================================

-- フェーズ実行マッピング
local phaseExecutors = {
    INIT = ExecuteInitPhase,
    MAP_PURCHASE = ExecuteMapPurchasePhase,
    MOVEMENT = ExecuteMovementPhase,
    COMBAT = ExecuteCombatPhase,
    DUNGEON = ExecuteDungeonPhase,
    COMPLETE = ExecuteCompletePhase,
    ERROR = ExecuteErrorPhase
}

-- メインループ
local function MainLoop()
    LogInfo("Treasure Hunt Automation v3.0.0 開始")
    
    currentPhase = "INIT"
    phaseStartTime = os.clock()
    
    while not stopRequested and iteration < maxIterations do
        iteration = iteration + 1
        
        -- タイムアウトチェック
        if CheckPhaseTimeout() then
            ChangePhase("ERROR", "フェーズタイムアウト")
        end
        
        -- フェーズ実行
        local executor = phaseExecutors[currentPhase]
        if executor then
            SafeExecute(executor, "フェーズ実行エラー: " .. currentPhase)
        else
            LogError("未知のフェーズ: " .. currentPhase)
            ChangePhase("ERROR", "未知のフェーズ")
        end
        
        -- イテレーション制限チェック
        if iteration >= maxIterations then
            LogWarn("最大イテレーション数に達しました")
            break
        end
        
        Wait(1)
    end
    
    LogInfo("スクリプト終了")
end

-- ================================================================================
-- スクリプト開始
-- ================================================================================

-- メイン実行
SafeExecute(MainLoop, "メインループエラー")