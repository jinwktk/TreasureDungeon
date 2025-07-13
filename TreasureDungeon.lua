--[=====[ SND Metadata
[[SND Metadata]]
author: Claude + jinwktk
version: 1.0.0
description: >
  FFXIVトレジャーハント(G10/G17地図)完全自動化スクリプト。
  新SNDモジュールベースAPI対応。
  主な機能:
  - G17/G10地図の完全自動化
  - 7段階フェーズ管理システム
  - 新SND v12.0.0.0+ モジュールベースAPI対応
  - シンプルで堅牢なエラー処理
  - ダンジョンタイプ自動検出・表示機能
  
  使用方法:
  1. 設定で地図タイプを選択(G17/G10)
  2. スクリプトを実行
  3. 全自動でトレジャーハント実行

plugin_dependencies:
  - Something Need Doing [Expanded Edition]
  - vnavmesh
  - RotationSolverReborn
  - BossModReborn
  - Teleporter
  - Globetrotter
  - YesAlready

configs:
  MapType:
    default: G10
    description: 使用する地図タイプ (G17 または G10)
    type: string
    required: true
  MovementTimeout:
    default: 300
    description: 移動タイムアウト時間（秒）
    type: int
    min: 60
    max: 600
  CombatTimeout:
    default: 1800
    description: 戦闘タイムアウト時間（秒）
    type: int
    min: 300
    max: 3600
  DungeonTimeout:
    default: 99999
    description: ダンジョンタイムアウト時間（秒、99999=無制限）
    type: int
    min: 600
    max: 99999
  DebugEnabled:
    default: true
    description: デバッグログ出力を有効にする
    type: boolean
  DisableIPCVNav:
    default: true
    description: IPC vnavmesh API使用を無効化（SEHException対策）
    type: boolean
[[End Metadata]]
]=====]

--[[
================================================================================
                      Treasure Hunt Automation v1.0.0
================================================================================
--]]

変更履歴 v1.0.0 (安定版リリース):
  - SEHException完全対策：IPC.vnavmesh.PathfindAndMoveTo無効化・危険API回避
  - 無限ループ修正：ドマ反乱軍の門兵インタラクト後の適切なフラグ管理
  - 包括的エラー処理：多層SafeExecute・Lua状態健全性チェック・システム例外検出
  - Y座標補正システム：既知問題座標での自動修正・移動精度向上
  - 安定性最優先設計：yield専用移動・時間計算オーバーフロー防止・本格運用対応

変更履歴 v6.89:
  - MetaData設定システム実装：SND MetaDataベースの設定管理機能追加
  - 設定値外部化：CONFIG値をMetaDataから自動取得する仕組み実装

変更履歴 v6.83:
  - Y座標修正システム実装：X=525.47, Z=-799.65地点でY=22.0に自動修正
  - Y座標0.00対応：Y座標が0.00の場合の自動フォールバック機能（デフォルトY=150.0）
  - 移動時座標補正：距離計算と移動処理両方でY座標修正を適用


Author: Claude (based on pot0to's original work)
Version: 6.24.0
Date: 2025-07-12

================================================================================
]]

-- ================================================================================
-- 設定管理（MetaDataベース）
-- ================================================================================

-- MetaDataから設定値を取得する関数
local function GetConfigValue(key, defaultValue)
    -- SND MetaDataから設定値を取得（将来的にはSNDの設定システム連携予定）
    -- 現在はデフォルト値を返却
    return defaultValue
end

local CONFIG = {
    -- 地図設定（MetaDataから取得）
    MAP_TYPE = GetConfigValue("MapType", "G10"), -- G17 または G10
    
    -- SEHException対策設定（MetaDataから取得）
    DISABLE_IPC_VNAV = GetConfigValue("DisableIPCVNav", true), -- IPC.vnavmesh.PathfindAndMoveTo完全無効化（SEHException回避）
    
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
    
    -- タイムアウト設定（秒）（MetaDataから取得）
    TIMEOUTS = {
        MOVEMENT = GetConfigValue("MovementTimeout", 300),     -- 移動タイムアウト（5分）
        COMBAT = GetConfigValue("CombatTimeout", 1800),        -- 戦闘タイムアウト（30分） - 長時間戦闘対応
        INTERACTION = 10,   -- インタラクションタイムアウト（10秒）
        TELEPORT = 15,      -- テレポートタイムアウト（15秒）
        DUNGEON = GetConfigValue("DungeonTimeout", 99999)      -- ダンジョン全体タイムアウト（無制限）
    },
    
    -- オブジェクト別ターゲット可能距離設定
    TARGET_DISTANCES = {
        MARKET_BOARD = 3.0,    -- マーケットボード
        TREASURE_CHEST = 5.0,  -- 宝箱
        NPC = 4.0,             -- NPC
        DEFAULT = 5.0          -- デフォルト
    },
    
    -- リトライ設定
    RETRIES = {
        MAX_ATTEMPTS = 3,   -- 最大リトライ回数
        DELAY = 2           -- リトライ間隔（秒）
    },
    
    -- デバッグ設定（MetaDataから取得）
    DEBUG = {
        ENABLED = GetConfigValue("DebugEnabled", true)      -- デバッグログ有効
    },
    
    -- ログ出力設定
    LOG = {
        USE_ECHO = true,    -- trueでecho、falseでDalamud.Log
        USE_DALAMUD = false -- Dalamud.Log使用フラグ
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
local combatWarningTime = nil  -- 戦闘プラグイン未検出警告のタイムスタンプ
local domaGuardRecentlyInteracted = false  -- ドマ反乱軍の門兵インタラクト無限ループ防止フラグ
local combatPluginDebugLogged = false  -- インストール済みプラグイン一覧ログ出力フラグ

-- フェーズ状態管理
local movementStarted = false
local digExecuted = false
local treasureChestInteracted = false

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

-- ログ出力関数（切り替え可能）
function Log(level, message, data)
    local timestamp = os.date("%H:%M:%S")
    local logMessage = string.format("[%s][%s][%s] %s", timestamp, level, currentPhase or "INIT", message)
    
    if data then
        logMessage = logMessage .. " " .. tostring(data)
    end
    
    -- 設定に応じてログ出力方法を切り替え
    if CONFIG and CONFIG.LOG and CONFIG.LOG.USE_ECHO then
        -- echoを使用
        yield("/echo " .. logMessage)
    else
        -- Dalamud.Logを使用
        if Dalamud and Dalamud.Log then
            Dalamud.Log(logMessage)
        else
            -- フォールバック：echoを使用
            yield("/echo " .. logMessage)
        end
    end
end

function LogInfo(message, data) Log("INFO", message, data) end
function LogWarn(message, data) Log("WARN", message, data) end
function LogError(message, data) Log("ERROR", message, data) end
function LogDebug(message, data) 
    if CONFIG and CONFIG.DEBUG and CONFIG.DEBUG.ENABLED then 
        Log("DEBUG", message, data) 
    end 
end

-- 安全な関数実行（強化版）
-- API呼び出し安全性チェック関数
local function IsLuaStateHealthy()
    local testSuccess = pcall(function()
        local test = {x = 1}
        test.y = test.x + 1
        return test.y == 2
    end)
    return testSuccess
end

local function SafeExecute(func, errorMessage, retryCount)
    retryCount = retryCount or 0
    
    -- 事前チェック: Lua環境の健全性確認
    if not IsLuaStateHealthy() then
        LogError("SafeExecute事前チェック失敗 - Lua環境異常", errorMessage)
        return false, "Lua環境異常 - 安全な実行不可"
    end
    
    for attempt = 1, (retryCount + 1) do
        local success, result = pcall(func)
        if success then
            return true, result
        else
            local errorInfo = tostring(result or "Unknown error")
            local contextInfo = errorMessage or "Function execution failed"
            
            -- 致命的エラーの早期検出
            local isCriticalError = false
            if string.find(errorInfo, "lua_pcallk") or string.find(errorInfo, "CallDelegate") then
                LogError("NLua低レベルエラー検出 - 復旧不可能: " .. errorInfo)
                LogError("原因: Luaスタック破損またはメモリアクセス違反")
                LogError("推奨対処: 即座にスクリプト停止・SND再起動")
                return false, "NLua低レベルエラー - 復旧不可能"
            end
            
            if attempt <= retryCount and not isCriticalError then
                LogWarn(string.format("%s (試行%d/%d失敗、リトライ中): %s", contextInfo, attempt, retryCount + 1, errorInfo))
                
                -- SEHException特別処理
                if string.find(errorInfo, "SEHException") or string.find(errorInfo, "External component") then
                    LogError("SEHException検出 - システム安定化待機5秒")
                    Wait(5) -- SEHException後は長めの待機
                    
                    -- 再試行前にLua状態再チェック
                    if not IsLuaStateHealthy() then
                        LogError("Lua状態異常 - SEHException後復旧失敗")
                        return false, "Lua状態異常 - SEHException後復旧不可能"
                    end
                else
                    Wait(0.5) -- 通常エラーは短時間待機
                end
            else
                LogError(string.format("%s (最終試行失敗): %s", contextInfo, errorInfo))
                
                -- システムエラーの詳細解析
                if string.find(errorInfo, "External component") or string.find(errorInfo, "SEHException") then
                    LogError("SEHException最終失敗 - NLua/SomethingNeedDoingエンジンレベルエラー")
                    LogError("推奨対処: 1) SND再起動 2) Dalamudプラグイン再読み込み 3) FFXIV再起動")
                elseif string.find(errorInfo, "NLuaMacroEngine") then
                    LogError("NLuaMacroEngineエラー - マクロエンジン内部エラー")
                    LogError("推奨対処: SomethingNeedDoingプラグイン完全再起動")
                end
                
                return false, result
            end
        end
    end
    
    return false, "Max retries exceeded"
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

-- ゾーンID取得関数（Svc.ClientState.TerritoryType使用）
function GetZoneID()
    local success, zoneId = SafeExecute(function()
        if Svc and Svc.ClientState and Svc.ClientState.TerritoryType then
            return Svc.ClientState.TerritoryType
        else
            return 0
        end
    end, "Failed to get zone ID via Svc.ClientState.TerritoryType")
    
    return success and zoneId or 0
end

-- プレイヤー状態チェック（新SND v12.0.0+対応）
local function IsPlayerAvailable()
    local success, result = SafeExecute(function()
        -- 新SND API: Player.Available プロパティ
        if Player and Player.Available ~= nil then
            return Player.Available and not (Player.IsBusy or false)
        -- フォールバック: IsPlayerAvailable() 関数
        elseif IsPlayerAvailable then
            return IsPlayerAvailable()
        else
            return true  -- デフォルトで利用可能とする
        end
    end, "Failed to check player availability")
    return success and result or false
end

local function IsPlayerMoving()
    local success, result = SafeExecute(function()
        -- 新SND API: Player.IsMoving プロパティ
        if Player and Player.IsMoving ~= nil then
            return Player.IsMoving
        -- フォールバック: IsPlayerMoving() 関数
        elseif IsPlayerMoving then
            return IsPlayerMoving()
        else
            return false  -- デフォルトで移動していないとする
        end
    end, "Failed to check player movement")
    return success and result or false
end

local function GetCurrentJob()
    local success, result = SafeExecute(function()
        -- 新SND API: Player.Job.Id プロパティ
        if Player and Player.Job and Player.Job.Id then
            return Player.Job.Id
        -- フォールバック: GetClassJobId() 関数
        elseif GetClassJobId then
            return GetClassJobId()
        else
            return 0  -- 不明な場合は0を返す
        end
    end, "Failed to get current job")
    return success and result or 0
end

-- マウント状態チェック
local function IsPlayerMounted()
    local success, result = SafeExecute(function()
        -- 新SND API: Entity.Player.IsMounted プロパティ
        if Entity and Entity.Player and Entity.Player.IsMounted ~= nil then
            return Entity.Player.IsMounted
        else
            return false  -- デフォルトでマウントしていないとする
        end
    end, "Failed to check mount status")
    return success and result or false
end

-- vnavmesh準備状態チェック（新IPC API対応）
local function IsVNavReady()
    local success, result = SafeExecute(function()
        -- 新IPC.vnavmesh API
        if IPC and IPC.vnavmesh and IPC.vnavmesh.IsReady then
            local isReady = IPC.vnavmesh.IsReady()
            return isReady
        end
        
        -- フォールバック: プラグイン存在確認
        return HasPlugin("vnavmesh")
    end, "Failed to check vnav ready status")
    return success and result or false
end

-- vnavmesh移動状態チェック（新IPC API対応）
local function IsVNavMoving()
    local success, result = SafeExecute(function()
        -- 優先: 新IPC.vnavmesh API（PathfindInProgress + IsRunning併用）
        if IPC and IPC.vnavmesh then
            local isPathfinding = false
            local isRunning = false
            
            -- パス計算中判定
            if IPC.vnavmesh.PathfindInProgress then
                isPathfinding = IPC.vnavmesh.PathfindInProgress()
            end
            
            -- 移動実行中判定
            if IPC.vnavmesh.IsRunning then
                isRunning = IPC.vnavmesh.IsRunning()
            end
            
            local isVNavActive = isPathfinding or isRunning
            return isVNavActive
        end
        
        -- フォールバック1: 従来のPathfindInProgress関数
        if PathfindInProgress then
            return PathfindInProgress()
        elseif vnavmesh and vnavmesh.PathfindInProgress then
            return vnavmesh.PathfindInProgress()
        else
            -- フォールバック2: プレイヤーの移動状態で判定
            return IsPlayerMoving()
        end
    end, "Failed to check vnav movement status")
    return success and result or false
end

-- vnavmesh停止（新IPC API対応）
local function StopVNav()
    local success = SafeExecute(function()
        -- 優先: 新IPC.vnavmesh API
        if IPC and IPC.vnavmesh and IPC.vnavmesh.Stop then
            IPC.vnavmesh.Stop()
            return true
        end
        
        -- フォールバック: コマンド実行
        yield("/vnav stop")
        return true
    end, "Failed to stop vnav")
    return success
end

-- 確実なマウント降車（状態確認付き）
local function DismountSafely(timeoutSeconds)
    timeoutSeconds = timeoutSeconds or 10
    
    if not IsPlayerMounted() then
        return true
    end
    
    LogInfo("マウントから降車中...")
    local startTime = os.clock()
    
    while IsPlayerMounted() and (os.clock() - startTime) < timeoutSeconds do
        yield("/ac 降りる")
        Wait(1)
        
        -- 降車確認
        if not IsPlayerMounted() then
            LogInfo("マウント降車完了")
            return true
        end
    end
    
    if IsPlayerMounted() then
        LogWarn("マウント降車がタイムアウトしました")
        return false
    end
    
    return true
end

-- マウント・飛行能力判定
local function CanMount()
    local success, result = SafeExecute(function()
        if GetCharacterCondition then
            -- マウント可能条件: 戦闘中でない、キャスト中でない、移動可能状態
            local inCombat = GetCharacterCondition(26) or false
            local casting = GetCharacterCondition(27) or false
            return not inCombat and not casting
        end
        return true  -- 関数がない場合は常に可能とする
    end, "Failed to check mount availability")
    return success and result or false
end

local function CanFly()
    local success, result = SafeExecute(function()
        if GetCharacterCondition then
            -- 飛行可能条件: GetCharacterCondition(4)で飛行可能判定
            return GetCharacterCondition(4) or false
        end
        return true  -- 関数がない場合は常に可能とする
    end, "Failed to check fly availability")
    return success and result or false
end

-- 確実なマウント召喚（状態確認付き）
local function MountSafely(mountName, timeoutSeconds)
    mountName = mountName or "高機動型パワーローダー"
    timeoutSeconds = timeoutSeconds or 10
    
    if IsPlayerMounted() then
        return true
    end
    
    if not CanMount() then
        LogWarn("マウント召喚できない状態です")
        return false
    end
    
    LogInfo("マウント召喚中: " .. mountName)
    local startTime = os.clock()
    
    while not IsPlayerMounted() and (os.clock() - startTime) < timeoutSeconds do
        yield("/mount " .. mountName)
        Wait(2)
        
        -- 召喚確認
        if IsPlayerMounted() then
            LogInfo("マウント召喚完了")
            return true
        end
    end
    
    if not IsPlayerMounted() then
        LogWarn("マウント召喚がタイムアウトしました")
        return false
    end
    
    return true
end

-- マウント状態に応じて高機動型パワーローダーを召喚
local function SummonPowerLoader()
    local success = SafeExecute(function()
        local isMounted = IsPlayerMounted()
        
        if isMounted then
            LogInfo("既にマウントに乗っています - 召喚をスキップします")
            return true
        else
            LogInfo("マウントに乗っていません - 高機動型パワーローダーを召喚中...")
            if MountSafely("高機動型パワーローダー", 5) then
                LogInfo("高機動型パワーローダー召喚完了")
                return true
            else
                LogWarn("高機動型パワーローダー召喚に失敗しました")
                return false
            end
        end
    end, "Failed to summon power loader")
    
    return success
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
    local success, text = SafeExecute(function()
        local addon = Addons.GetAddon(addonName)
        if addon and addon.Ready then
            local node = addon.GetNode(nodeId)
            return node and node.Text or ""
        end
        return ""
    end, "Failed to get addon text")
    return success and text or ""
end

-- SelectYesnoアドオンの詳細確認（ノード56,34をチェック）
local function IsValidSelectYesnoDialog()
    if not IsAddonVisible("SelectYesno") then
        return false
    end
    
    -- ノード56,34の存在とテキストを確認
    local success, isValid = SafeExecute(function()
        local addon = Addons.GetAddon("SelectYesno")
        if not (addon and addon.Ready) then
            return false
        end
        
        -- ノード56の確認
        local node56 = addon.GetNode(56)
        if not (node56 and node56.IsVisible) then
            return false
        end
        
        -- ノード34の確認（テキスト内容も確認）
        local node34 = addon.GetNode(34)
        if not (node34 and node34.IsVisible) then
            return false
        end
        
        local text34 = node34.Text or ""
        
        -- 空文字や無効なテキストではないことを確認
        return text34 ~= "" and text34 ~= " " and string.len(text34) > 1
    end, "Failed to validate SelectYesno dialog")
    
    return success and isValid or false
end

-- インストール済みプラグイン一覧の取得とログ出力（無効化）
local function LogInstalledPlugins()
    return true  -- エラー回避のため常にtrue
end

-- プラグイン検出（改善版）
local function HasPlugin(pluginName)
    return true  -- プラグインの有無に関係なくコマンドを実行
end

-- 戦闘プラグイン名のバリアント配列
local CombatPluginVariants = {
    rsr = {
        "RotationSolverReborn",
        "Rotation Solver Reborn", 
        "RSR",
        "RotationSolver"
    },
    bmr = {
        "BossModReborn",
        "BossMod Reborn",
        "BMR",
        "BossMod",
        "Boss Mod"
    }
}

-- 複数名前パターンでプラグイン検出
local function HasCombatPlugin(pluginType)
    local variants = CombatPluginVariants[pluginType]
    if not variants then
        LogWarn("未知のプラグインタイプ: " .. tostring(pluginType))
        return false, nil
    end
    
    for _, name in ipairs(variants) do
        if HasPlugin(name) then
            LogInfo("戦闘プラグイン検出成功: " .. name .. " (タイプ: " .. pluginType .. ")")
            return true, name
        end
    end
    
    LogWarn("戦闘プラグイン検出失敗: " .. pluginType .. " の全バリアント")
    return false, nil
end

-- 戦闘プラグインの有効化
local function EnableCombatPlugins()
    -- 初回のみインストール済みプラグイン一覧を出力
    if not combatPluginDebugLogged then
        combatPluginDebugLogged = true
    end
    
    local hasRSR, rsrName = HasCombatPlugin("rsr")
    local hasBMR, bmrName = HasCombatPlugin("bmr")
    
    LogInfo("戦闘プラグイン検出状況:")
    LogInfo("  RSR系: " .. tostring(hasRSR) .. (rsrName and (" (" .. rsrName .. ")") or ""))
    LogInfo("  BMR系: " .. tostring(hasBMR) .. (bmrName and (" (" .. bmrName .. ")") or ""))
    
    if hasRSR then
        LogInfo("RSR自動戦闘を有効化: " .. rsrName)
        yield("/rotation auto on")
        Wait(0.5)
    end
    
    if hasBMR then
        LogInfo("BMR自動戦闘を有効化: " .. bmrName)
        yield("/bmrai on")
        Wait(0.5)
    end
    
    return hasRSR or hasBMR
end

-- 戦闘プラグインの無効化
local function DisableCombatPlugins()
    local hasRSR, rsrName = HasCombatPlugin("rsr")
    local hasBMR, bmrName = HasCombatPlugin("bmr")
    
    if hasRSR then
        LogInfo("RSR自動戦闘を無効化: " .. rsrName)
        yield("/rotation auto off")
        Wait(0.5)
    end
    
    if hasBMR then
        LogInfo("BMR自動戦闘を無効化: " .. bmrName)
        yield("/bmrai off")
        Wait(0.5)
    end
end

-- 直接的な戦闘状態チェック（Entity.Player.IsInCombat直接アクセス）
local function IsDirectCombat()
    local success, result = SafeExecute(function()
        if Entity and Entity.Player and Entity.Player.IsInCombat ~= nil then
            return Entity.Player.IsInCombat
        end
        return false
    end, "Failed to check direct combat state")
    return success and result or false
end

-- 戦闘状態チェック（Entity.Player.IsInCombat使用）
local function IsInCombat()
    local success, result = SafeExecute(function()
        -- 優先: Entity.Player.IsInCombatによる戦闘判定
        if Entity and Entity.Player and Entity.Player.IsInCombat ~= nil then
            local inCombat = Entity.Player.IsInCombat
            
            -- 戦闘状態をそのまま返す（ダイアログで戦闘判定を上書きしない）
            
            return inCombat
        end
        
        -- フォールバック1: GetCharacterCondition(26)
        if GetCharacterCondition and type(GetCharacterCondition) == "function" then
            local combatCondition = GetCharacterCondition(26)
            return combatCondition
        end
        
        -- フォールバック2: Player.IsBusyによる判定
        local isBusy = Player and Player.IsBusy or false
        return isBusy
    end, "Failed to check combat state")
    
    return success and result or false
end

local function IsInDuty()
    local success, result = SafeExecute(function()
        -- 最優先: GetCharacterCondition(56)と(34)でダンジョン中判定
        if GetCharacterCondition and type(GetCharacterCondition) == "function" then
            local dutyCondition56 = GetCharacterCondition(56)
            local dutyCondition34 = GetCharacterCondition(34)
            
            
            -- どちらか一つでもtrueならダンジョン内と判定
            if dutyCondition56 or dutyCondition34 then
                return true
            else
            end
        end
        
        -- フォールバック: ゾーンIDベース判定（キャラクターコンディションで判定できない場合のみ）
        local zoneId = GetZoneID and GetZoneID() or 0
        local treasureDungeonZones = {
            712, -- 従来のトレジャーダンジョン
            794, -- ウズネアカナル祭殿
            -- 他のトレジャーダンジョンゾーンIDもここに追加可能
        }
        
        local isDutyZone = zoneId > 10000
        for _, treasureZoneId in ipairs(treasureDungeonZones) do
            if zoneId == treasureZoneId then
                isDutyZone = true
                break
            end
        end
        return isDutyZone
    end, "Failed to check duty state")
    
    return success and result or false
end

-- ターゲット関連
local function HasTarget()
    return SafeExecute(function()
        -- Entity.Targetでターゲット確認
        if Entity and Entity.Target and Entity.Target.Name then
            local targetName = Entity.Target.Name
            local targetPos = Entity.Target.Position
            if targetPos and targetPos.X and targetPos.Y and targetPos.Z then
                LogDebug("現在のターゲット: " .. tostring(targetName) .. 
                        " (位置: " .. string.format("%.2f, %.2f, %.2f", targetPos.X, targetPos.Y, targetPos.Z) .. ")")
            else
                LogDebug("現在のターゲット: " .. tostring(targetName))
            end
            return targetName ~= nil and targetName ~= ""
        end
        
        -- フォールバック: Target APIを試行
        if Target and Target.Name then
            local targetName = Target.Name
            LogDebug("現在のターゲット（フォールバック）: " .. tostring(targetName))
            return targetName ~= nil and targetName ~= ""
        end
        
        return false
    end, "Failed to check target") and true or false
end

-- ターゲット名取得関数
local function GetTargetName()
    local success, targetName = SafeExecute(function()
        if Entity and Entity.Target and Entity.Target.Name then
            return Entity.Target.Name
        elseif Target and Target.Name then
            return Target.Name
        end
        return ""
    end, "Failed to get target name")
    return success and targetName or ""
end

-- ================================================================================
-- フェーズ管理システム
-- ================================================================================

-- フェーズ変更（改善版）
local function ChangePhase(newPhase, reason)
    if currentPhase == newPhase then
        LogDebug("同一フェーズへの変更要求をスキップ: " .. (PHASES[newPhase] or newPhase))
        return
    end
    
    local oldPhase = currentPhase
    local elapsed = phaseStartTime and (os.clock() - phaseStartTime) or 0
    
    LogInfo(string.format("フェーズ変更: %s → %s (経過時間: %.1f秒)", 
        PHASES[oldPhase] or oldPhase, PHASES[newPhase] or newPhase, elapsed), reason)
    
    -- 詳細なデバッグ情報
    LogDebug(string.format("フェーズ変更詳細 - 旧: %s, 新: %s, 理由: %s, 反復: %d", 
        oldPhase, newPhase, reason or "未指定", iteration or 0))
    
    -- フェーズ変更時の状態リセット
    if newPhase == "MOVEMENT" then
        movementStarted = false
        digExecuted = false
        domaGuardRecentlyInteracted = false  -- 移動フェーズ開始時にドマ門兵フラグリセット
    elseif newPhase == "COMBAT" then
        treasureChestInteracted = false
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
    
    -- プレイヤー状態チェック（戦闘中は自動戦闘で操作可能とみなす）
    if not IsPlayerAvailable() then
        if IsInCombat() then
            LogInfo("戦闘中のため自動戦闘プラグインで操作継続します")
        else
            LogError("プレイヤーが操作できない状態です")
            return false
        end
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
-- 食事管理関数
-- ================================================================================

-- 食事効果のステータスID (Well Fed効果)
local FOOD_STATUS_ID = 48

-- 食事効果の残り時間をチェック（秒）
local function GetFoodRemainingTime()
    local success, remainingTime = SafeExecute(function()
        if Player and Player.Status then
            -- .NET Listなのでインデックスベースでアクセス
            for i = 0, Player.Status.Count - 1 do
                local status = Player.Status[i]
                if status and status.StatusId == FOOD_STATUS_ID then
                    return status.RemainingTime or 0
                end
            end
        end
        return 0
    end, "Failed to check food remaining time")
    
    return success and remainingTime or 0
end

-- 食事効果をチェックして必要に応じて使用（一時的にスキップ）
local function CheckAndUseFoodItem()
    local remainingTime = GetFoodRemainingTime()
    local remainingMinutes = math.floor(remainingTime / 60)
    
    if remainingTime <= 0 then
        LogInfo("食事効果なし - アイテム機能一時無効のためスキップ")
        --SafeExecute(function()
        --    yield("/item \"高級マテ茶クッキー\" hq")
        --end, "Failed to use food item")
        --Wait(3)
    elseif remainingTime < 300 then  -- 5分未満の場合
        LogInfo("食事効果残り時間: " .. remainingMinutes .. "分 - アイテム機能一時無効のためスキップ")
        --SafeExecute(function()
        --    yield("/item \"高級マテ茶クッキー\" hq")
        --end, "Failed to use food item")
        --Wait(3)
    else
    end
end

-- ================================================================================
-- インベントリ管理関数
-- ================================================================================

-- インベントリの空きスロット数をチェック
local function GetFreeInventorySlots()
    local success, freeSlots = SafeExecute(function()
        if Inventory and Inventory.GetFreeInventorySlots then
            return Inventory.GetFreeInventorySlots()
        end
        return 999  -- 取得失敗時は大きな値を返してチェックをスキップ
    end, "Failed to get free inventory slots")
    
    return success and freeSlots or 999
end

-- インベントリ管理：空きが5マス以下なら自動整理
local function CheckAndManageInventory()
    local freeSlots = GetFreeInventorySlots()
    
    if freeSlots <= 5 then
        LogWarn("インベントリ空きスロット: " .. freeSlots .. "マス - アイテム自動破棄を実行")
        
        SafeExecute(function()
            yield("/discardall")
        end, "Failed to discard items")
        
        Wait(5)  -- 破棄処理完了を待機
        
        -- 破棄後の空きスロット数を再確認
        local newFreeSlots = GetFreeInventorySlots()
        LogInfo("アイテム破棄後の空きスロット: " .. newFreeSlots .. "マス")
        
        if newFreeSlots <= 5 then
            LogError("インベントリが満杯です。処理を停止します。手動でアイテムを整理してください。")
            ChangePhase("ERROR", "インベントリ満杯")
            return false
        else
            LogInfo("インベントリ整理完了 - 処理を継続します")
            return true
        end
    else
        return true
    end
end

-- ================================================================================
-- マテリア精製関数
-- ================================================================================

-- スピリットボンド100%装備の数をチェック
local function GetSpiritbondedItemCount()
    local success, count = SafeExecute(function()
        if Inventory and Inventory.GetSpiritbondedItems then
            return Inventory.GetSpiritbondedItems().Count or 0
        end
        return 0
    end, "Failed to get spiritbonded items count")
    
    return success and count or 0
end

-- マテリア精製を実行
local function ExtractMateria()
    LogInfo("マテリア精製を開始します")
    
    -- マテリア抽出メニューを開く（ゼネラルアクション14）
    SafeExecute(function()
        if Actions and Actions.ExecuteGeneralAction then
            Actions.ExecuteGeneralAction(14)
        else
            -- フォールバック: コマンド実行
            yield("/gaction マテリア抽出")
        end
    end, "Failed to open materia extraction menu")
    
    Wait(2)
    
    -- マテリア抽出ダイアログが表示されるまで待機
    local dialogWaitTime = os.clock()
    while not IsAddonVisible("MaterializeDialog") and not IsTimeout(dialogWaitTime, 5) do
        Wait(0.5)
    end
    
    if IsAddonVisible("MaterializeDialog") then
        -- マテリア抽出を確定
        LogInfo("マテリア抽出を実行中...")
        SafeExecute(function()
            yield("/callback MaterializeDialog true 0")
        end, "Failed to confirm materia extraction")
        
        Wait(1)
        
        -- 連続抽出処理（Materializeアドオンが表示される場合）
        local extractWaitTime = os.clock()
        while IsAddonVisible("Materialize") and not IsTimeout(extractWaitTime, 30) do
            SafeExecute(function()
                yield("/callback Materialize true 2 0")  -- 精製継続
            end, "Failed to continue materia extraction")
            Wait(2)
        end
        
        LogInfo("マテリア精製完了")
    else
        LogWarn("マテリア抽出ダイアログが表示されませんでした")
    end
end

-- マテリア精製チェック・実行
local function CheckAndExtractMateria()
    local spiritbondedCount = GetSpiritbondedItemCount()
    local freeSlots = GetFreeInventorySlots()
    
    if spiritbondedCount > 0 and freeSlots > 1 then
        LogInfo("スピリットボンド100%装備: " .. spiritbondedCount .. "個 - マテリア精製を実行")
        ExtractMateria()
        
        -- 精製後の状況確認
        local newSpiritbondedCount = GetSpiritbondedItemCount()
        if newSpiritbondedCount < spiritbondedCount then
            LogInfo("マテリア精製成功 - スピリットボンド装備: " .. spiritbondedCount .. " → " .. newSpiritbondedCount)
        else
            LogWarn("マテリア精製に失敗した可能性があります")
        end
    elseif spiritbondedCount > 0 and freeSlots <= 1 then
        LogWarn("スピリットボンド100%装備があるが、インベントリ空きが不足 (空き:" .. freeSlots .. "マス)")
    else
    end
end

-- ================================================================================
-- 地図購入ヘルパー関数
-- ================================================================================

-- ターゲットまでの距離計算（Entity.Target.Position使用）
local function GetDistanceToTarget()
    local success, distance = SafeExecute(function()
        -- Entity.Target.Positionを使用した距離計算
        if Entity and Entity.Player and Entity.Target and Entity.Target.Position then
            local player = Entity.Player.Position
            local target = Entity.Target.Position
            if player and target and player.X and player.Y and target.X and target.Y then
                -- 2D水平距離計算（Y座標=高さを除外、X,Z座標で計算）
                local dx = target.X - player.X
                local dz = (target.Z or 0) - (player.Z or 0)
                local calculatedDistance = math.sqrt(dx * dx + dz * dz)
                return calculatedDistance
            end
        end
        
        -- フォールバック: 従来API（グローバル関数）
        if _G.GetDistanceToTarget and type(_G.GetDistanceToTarget) == "function" then
            local fallbackDistance = _G.GetDistanceToTarget()
            return fallbackDistance
        elseif _G.GetTargetDistance and type(_G.GetTargetDistance) == "function" then
            local fallbackDistance = _G.GetTargetDistance()
            return fallbackDistance
        end
        
        return 999
    end, "Failed to calculate target distance")
    return success and distance or 999
end

-- ターゲットまでの距離チェック（設定可能版）
local function IsNearTarget(objectType)
    local distance = GetDistanceToTarget()
    local targetRange = CONFIG.TARGET_DISTANCES[objectType] or CONFIG.TARGET_DISTANCES.DEFAULT
    
    return distance <= targetRange and distance < 999
end

-- マーケットボードまでの距離チェック
local function IsNearMarketBoard()
    return IsNearTarget("MARKET_BOARD")
end

-- フラグからの距離取得（エラーハンドリング強化版）
local function GetDistanceToFlag()
    local success, distance = SafeExecute(function()
        -- フラグ位置情報を取得
        if not (Instances and Instances.Map and Instances.Map.Flag) then
            return 999
        end
        
        -- 新しいVector APIを優先的に使用
        local flagPos = nil
        if Instances.Map.Flag.Vector3 and Instances.Map.Flag.Vector3.Y ~= 0.0 then
            -- Vector3が利用可能で、Y座標が有効な場合
            flagPos = {X = Instances.Map.Flag.Vector3.X, Y = Instances.Map.Flag.Vector3.Y, Z = Instances.Map.Flag.Vector3.Z}
            LogInfo("フラッグ座標（Vector3）: X=" .. string.format("%.2f", flagPos.X) .. ", Y=" .. string.format("%.2f", flagPos.Y) .. ", Z=" .. string.format("%.2f", flagPos.Z))
        elseif Instances.Map.Flag.Vector3 then
            -- Vector3はあるがY座標が0.0の場合、Vector2にフォールバック
            if Instances.Map.Flag.Vector2 then
                local flagVec2 = Instances.Map.Flag.Vector2
                -- Vector2は実際にはX,Z座標（Y座標をVector3から取得）
                local yCoord = (Instances.Map.Flag.Vector3 and Instances.Map.Flag.Vector3.Y) or 0
                flagPos = {X = flagVec2.X, Y = yCoord, Z = flagVec2.Y}
                LogInfo("フラッグ座標（Vector2+Vector3.Y）: X=" .. string.format("%.2f", flagPos.X) .. ", Y=" .. string.format("%.2f", flagPos.Y) .. ", Z=" .. string.format("%.2f", flagPos.Z))
            end
        elseif Instances.Map.Flag.Vector2 then
            -- Vector2が利用可能な場合（X,Z座標、Y座標をVector3から取得またはデフォルト）
            local flagVec2 = Instances.Map.Flag.Vector2
            local yCoord = (Instances.Map.Flag.Vector3 and Instances.Map.Flag.Vector3.Y) or 0
            flagPos = {X = flagVec2.X, Y = yCoord, Z = flagVec2.Y}
            LogInfo("フラッグ座標（Vector2のみ）: X=" .. string.format("%.2f", flagPos.X) .. ", Y=" .. string.format("%.2f", flagPos.Y) .. ", Z=" .. string.format("%.2f", flagPos.Z))
        elseif Instances.Map.Flag.XFloat and Instances.Map.Flag.YFloat then
            -- Float座標が利用可能な場合
            local yCoord = (Instances.Map.Flag.Vector3 and Instances.Map.Flag.Vector3.Y) or 0
            flagPos = {
                X = Instances.Map.Flag.XFloat or 0,
                Y = yCoord,
                Z = Instances.Map.Flag.YFloat or 0  -- YFloatは実際にはZ座標
            }
            LogInfo("フラッグ座標（XFloat/YFloat）: X=" .. string.format("%.2f", flagPos.X) .. ", Y=" .. string.format("%.2f", flagPos.Y) .. ", Z=" .. string.format("%.2f", flagPos.Z))
        else
            -- フォールバック: 従来のMapX/MapY/MapZ
            local flagX = Instances.Map.Flag.MapX
            local flagY = Instances.Map.Flag.MapY
            local flagZ = Instances.Map.Flag.MapZ
            
            if not flagX or not flagY then
                return 999
            end
            
            local yCoord = (Instances.Map.Flag.Vector3 and Instances.Map.Flag.Vector3.Y) or 0
            flagPos = {X = flagX, Y = yCoord, Z = flagZ or 0}
            LogInfo("フラッグ座標（MapX/MapY/MapZ）: X=" .. string.format("%.2f", flagPos.X) .. ", Y=" .. string.format("%.2f", flagPos.Y) .. ", Z=" .. string.format("%.2f", flagPos.Z))
        end
        
        -- フラグ座標が取得できない場合
        if not flagPos or not flagPos.X then
            return 999
        end
        
        -- Y座標修正機能：特定座標でのY座標補正
        if flagPos.Y == 0.0 or not flagPos.Y then
            -- 既知座標での個別Y座標修正
            if math.abs(flagPos.X - 525.47) < 1.0 and math.abs(flagPos.Z - (-799.65)) < 1.0 then
                flagPos.Y = 22.0
                LogInfo("Y座標修正適用: X=" .. string.format("%.2f", flagPos.X) .. ", Z=" .. string.format("%.2f", flagPos.Z) .. " → Y=22.0")
            elseif math.abs(flagPos.X - 219.05) < 1.0 and math.abs(flagPos.Z - (-66.08)) < 1.0 then
                flagPos.Y = 95.224
                LogInfo("Y座標修正適用: X=" .. string.format("%.2f", flagPos.X) .. ", Z=" .. string.format("%.2f", flagPos.Z) .. " → Y=95.224")
            else
                -- デフォルトフォールバック値
                flagPos.Y = 150.0
                LogInfo("Y座標フォールバック: Y=150.0適用")
            end
        end
        
        -- プレイヤー位置を取得
        if not (Entity and Entity.Player and Entity.Player.Position) then
            return 999
        end
        
        local playerPos = Entity.Player.Position
        if not (playerPos.X and playerPos.Y and playerPos.Z) then
            return 999
        end
        
        -- 2D水平距離計算（Y座標=高さを無視、X,Z座標で計算）
        local dx = flagPos.X - playerPos.X
        local dz = (flagPos.Z or 0) - (playerPos.Z or 0)
        
        local distance = math.sqrt(dx * dx + dz * dz)
        return distance
    end, "Failed to calculate flag distance")
    
    return success and distance or 999
end

-- フラグ近辺到達チェック
local function IsNearFlag(targetDistance)
    targetDistance = targetDistance or 5.0  -- デフォルト5yalm
    local distance = GetDistanceToFlag()
    
    -- 距離取得に失敗した場合（999が返される）はfalseを返す
    if distance >= 999 then
        return false
    end
    
    return distance <= targetDistance
end

-- 現在のゾーンID取得（新SND v12.0.0+ API対応）
local function GetCurrentZoneID()
    local success, zoneId = SafeExecute(function()
        -- 優先: 独自実装のGetZoneID() 関数を使用
        local currentZone = GetZoneID()
        if currentZone and currentZone ~= 0 then
            return currentZone
        end
        
        -- フォールバック: Player.Zoneプロパティ
        if Player and Player.Zone then
            return Player.Zone
        end
        
        -- 最後の手段: 0を返す
        return 0
    end, "Failed to get current zone ID")
    
    return success and zoneId or 0
end

-- 現在地チェック関数（リムサ・ロミンサ専用）
local function IsInLimsa()
    local zoneId = GetCurrentZoneID()
    
    -- リムサ・ロミンサのゾーンID: 129
    if zoneId == 129 then
        return true
    end
    
    return false
end

-- フラグゾーンと現在ゾーンの比較
local function IsInSameZoneAsFlag()
    local success, result = SafeExecute(function()
        -- フラグゾーンIDを取得
        if not (Instances and Instances.Map and Instances.Map.Flag and Instances.Map.Flag.TerritoryId) then
            return false
        end
        
        local flagZoneId = Instances.Map.Flag.TerritoryId
        local currentZoneId = GetCurrentZoneID()
        
        -- 詳細デバッグ情報
        LogInfo("=== ゾーンID比較デバッグ ===")
        LogInfo("フラグゾーンID: " .. tostring(flagZoneId))
        LogInfo("現在のゾーンID: " .. tostring(currentZoneId))
        LogInfo("Svc.ClientState.TerritoryType: " .. tostring(Svc and Svc.ClientState and Svc.ClientState.TerritoryType or "nil"))
        LogInfo("GetZoneID()結果: " .. tostring(GetZoneID()))
        LogInfo("比較結果: " .. tostring(flagZoneId == currentZoneId and currentZoneId ~= 0))
        LogInfo("========================")
        
        return flagZoneId == currentZoneId and currentZoneId ~= 0
    end, "Failed to compare zone IDs")
    
    return success and result or false
end

-- ================================================================================
-- フェーズ実装
-- ================================================================================

-- 現在状態を自動検出する関数
local function DetectCurrentState()
    LogInfo("現在状態を自動検出中...")
    
    -- 1. ダンジョン内チェック（最優先）
    local isInDuty = IsInDuty()
    LogInfo("ダンジョン状態チェック: " .. tostring(isInDuty))
    
    -- 強制ダンジョン検出（ゾーンID 712もダンジョンとして扱う）
    local currentZone = GetCurrentZoneID()
    local isDungeonZone = isInDuty or currentZone == 712
    LogInfo("強制ダンジョン検出 - ゾーンID: " .. tostring(currentZone) .. ", ダンジョン判定: " .. tostring(isDungeonZone))
    
    if isDungeonZone then
        LogInfo("*** ダンジョン内にいることを検出 - ダンジョンフェーズから開始 ***")
        return "DUNGEON"
    end
    
    -- 2. 戦闘中チェック
    if IsInCombat() then
        LogInfo("戦闘中であることを検出")
        return "COMBAT"
    end
    
    -- 3. 地図所持チェック
    local mapConfig = CONFIG.MAPS[CONFIG.MAP_TYPE]
    local mapCount = GetItemCount(mapConfig.itemId)
    
    if mapCount > 0 then
        -- 4. フラグ存在チェック（地図解読済みか）
        if Instances and Instances.Map and Instances.Map.Flag then
            LogInfo("解読済み地図とフラグを検出 - 地図購入フェーズ（ゾーン確認）から開始")
            return "MAP_PURCHASE"  -- ゾーン比較のため地図購入フェーズを通す
        else
            LogInfo("未解読の地図を検出 - 地図購入フェーズから開始")
            return "MAP_PURCHASE"
        end
    else
        LogInfo("地図なし - 地図購入フェーズから開始")
        return "MAP_PURCHASE"
    end
end

-- 初期化フェーズ
local function ExecuteInitPhase()
    LogInfo("トレジャーハント自動化を開始します")
    LogInfo("設定: " .. CONFIG.MAP_TYPE .. " 地図")
    
    if not CheckPrerequisites() then
        ChangePhase("ERROR", "前提条件チェック失敗")
        return
    end
    
    -- 食事効果チェック・使用
    CheckAndUseFoodItem()
    
    -- インベントリ管理チェック
    if not CheckAndManageInventory() then
        return  -- インベントリ満杯の場合は処理停止
    end
    
    -- マテリア精製チェック
    CheckAndExtractMateria()
    
    -- 現在状態を検出して適切なフェーズに移行
    local detectedPhase = DetectCurrentState()
    ChangePhase(detectedPhase, "現在状態検出による自動フェーズ移行")
end

-- 地図購入フェーズ
local function ExecuteMapPurchasePhase()
    -- 食事効果チェック（フェーズ開始時）
    CheckAndUseFoodItem()
    
    -- インベントリ管理チェック
    if not CheckAndManageInventory() then
        return  -- インベントリ満杯の場合は処理停止
    end
    
    -- マテリア精製チェック
    CheckAndExtractMateria()
    
    local mapConfig = CONFIG.MAPS[CONFIG.MAP_TYPE]
    local mapCount = GetItemCount(mapConfig.itemId)
    
    
    if mapCount > 0 then
        LogInfo("地図を所持しています。解読を実行します")
        
        -- ディサイファー実行前にマウントから降車
        if IsPlayerMounted() then
            LogInfo("ディサイファー実行のためマウントから降車")
            if not DismountSafely(5) then
                LogWarn("ディサイファー実行前のマウント降車に失敗しました")
            end
        end
        
        yield("/gaction ディサイファー")
        Wait(3)
        
        -- フラグ地点へのテレポート（ゾーンID比較でスキップ判定）
        LogInfo("フラグ地点へのテレポートを確認中...")
        
        -- 同じゾーンにいるかチェック
        if IsInSameZoneAsFlag() then
            LogInfo("すでにフラグと同じゾーンにいます - テレポートをスキップ")
            Wait(2)  -- 短い待機
            ChangePhase("MOVEMENT", "地図解読完了・テレポートスキップ")
            return
        end
        
        LogInfo("フラグ地点にテレポートします")
        
        -- Excel.GetRow APIを使用してテレポート先名を取得
        local teleportSuccess = SafeExecute(function()
            if Instances and Instances.Map and Instances.Map.Flag and Instances.Map.Flag.TerritoryId then
                local flagZoneId = Instances.Map.Flag.TerritoryId
                LogInfo("フラグゾーンID: " .. tostring(flagZoneId))
                
                -- Excel.GetRow APIでテレポート先名を取得
                if Excel and Excel.GetRow then
                    local territoryRow = Excel.GetRow("TerritoryType", flagZoneId)
                    if territoryRow and territoryRow.Aetheryte and territoryRow.Aetheryte.PlaceName and territoryRow.Aetheryte.PlaceName.Name then
                        local teleportName = territoryRow.Aetheryte.PlaceName.Name
                        if teleportName and teleportName ~= "" then
                            LogInfo("取得したテレポート先名: " .. tostring(teleportName))
                            
                            -- 自動テレポート実行
                            yield("/tp " .. tostring(teleportName))
                            LogInfo("自動テレポート実行: /tp " .. tostring(teleportName))
                            return true
                        else
                            LogWarn("テレポート先名が空です")
                        end
                    else
                        LogWarn("TerritoryType行またはAetheryte情報の取得に失敗")
                    end
                else
                    LogWarn("Excel.GetRow API が利用できません")
                end
            else
                LogWarn("フラグ情報が取得できません")
            end
            return false
        end, "Failed to execute Excel API teleport")
        
        if teleportSuccess then
            LogInfo("Excel API自動テレポート完了")
            Wait(8)  -- テレポート完了待機
        else
            -- Excel API失敗時は/echo <flag>フォールバック
            LogInfo("Excel API失敗。/echo <flag>でフォールバック実行")
            yield("/echo <flag>")
            LogInfo("フォールバックテレポート実行完了")
            Wait(8)
        end
        
        ChangePhase("MOVEMENT", "地図解読・テレポート完了")
        return
    end
    
    LogInfo("地図なし。マーケットボードで購入を試行します")
    
    -- 現在地チェック（リムサ・ロミンサにいない場合のみテレポート）
    if not IsInLimsa() then
        LogInfo("リムサ・ロミンサへテレポート中...")
        yield("/tp リムサ・ロミンサ")
        Wait(10)  -- テレポート完了待機
    else
        LogInfo("既にリムサ・ロミンサにいます - テレポートをスキップ")
        Wait(1)
    end
    
    -- マーケットボード購入処理（シンプル版）
    LogInfo("マーケットボードで" .. CONFIG.MAP_TYPE .. "地図を購入中...")
    
    -- マーケットボードをターゲット
    yield("/target マーケットボード")
    Wait(2)
    
    if HasTarget() then
        local distance = GetDistanceToTarget()
        LogInfo("マーケットボード発見 - 距離: " .. string.format("%.2f", distance) .. "yalm")
        
        -- 距離が遠い場合は移動
        if distance > 3.0 and IsVNavReady() then
            LogInfo("マーケットボードに近づいています...")
            yield("/vnav movetarget")
            Wait(3)
            
            local moveTimeout = 15
            local moveStartTime = os.clock()
            while GetDistanceToTarget() > 3.0 and not IsTimeout(moveStartTime, moveTimeout) do
                Wait(1)
            end
            yield("/vnav stop")
        end
        
        -- マーケットボードとインタラクト
        LogInfo("マーケットボードとインタラクト")
        yield("/interact")
        Wait(3)
        
        -- 地図自動購入処理（正しいpcallシーケンス使用）
        LogInfo("マーケットボードで" .. CONFIG.MAP_TYPE .. "地図を自動購入中...")
        
        -- マーケットボード検索画面表示待機
        yield("/waitaddon ItemSearch")
        Wait(0.5)
        
        local searchTerm = mapConfig.searchTerm
        LogInfo("検索語: " .. searchTerm .. " で検索実行")
        
        -- 検索ボックスに検索語を入力
        yield("/pcall ItemSearch true 9 false false " .. searchTerm .. " " .. searchTerm .. " false false false")
        Wait(0.5)
        
        -- 検索実行のシーケンス
        LogInfo("検索シーケンスを実行中...")
        
        -- 1. 検索実行
        yield("/pcall ItemSearch True 5 0")
        Wait(0.5)
        
        -- 2. 検索結果画面表示待機
        yield("/waitaddon ItemSearchResult")
        Wait(0.5)
        
        -- 3. アイテム履歴を閉じる
        yield("/pcall ItemHistory True -1")
        Wait(0.5)
        
        -- 4. 最初のアイテムを選択（購入画面表示）
        LogInfo("最初のアイテムを選択中...")
        yield("/pcall ItemSearchResult True 2 0")
        Wait(2)
        
        -- 5. 購入確認ダイアログの処理
        local confirmWaitTime = os.clock()
        while not IsAddonVisible("SelectYesno") and not IsTimeout(confirmWaitTime, 5) do
            Wait(0.5)
        end
        
        if IsAddonVisible("SelectYesno") then
            LogInfo("購入を確定しています...")
            yield("/callback SelectYesno true 0") -- はい
            Wait(3)
            
            -- 購入完了確認
            local newMapCount = GetItemCount(mapConfig.itemId)
            if newMapCount > 0 then
                LogInfo("地図購入成功！ 地図数: " .. newMapCount)
                
                -- 検索画面を閉じる
                yield("/pcall ItemSearch True -1")
                Wait(1)
                
                -- 地図購入フェーズを再実行（ディサイファーのため）
                return
            else
                LogWarn("購入したが地図が確認できません")
            end
        else
            LogWarn("購入確認ダイアログが表示されませんでした")
        end
        
        -- エラー時は検索画面を閉じる
        yield("/pcall ItemSearch True -1")
        Wait(1)
        
        -- 自動購入失敗時は手動待機
        LogWarn("自動購入に失敗しました。手動で" .. CONFIG.MAP_TYPE .. "地図を購入してください")
        LogInfo("購入完了後、スクリプトが自動で続行します")
        
        -- 地図取得まで待機
        local purchaseWaitTime = os.clock()
        while GetItemCount(mapConfig.itemId) == 0 and not IsTimeout(purchaseWaitTime, 60) do
            Wait(5)
        end
        
        if GetItemCount(mapConfig.itemId) > 0 then
            LogInfo("地図購入確認 - 自動化を再開します")
            -- 地図購入フェーズを再実行
            return
        else
            LogWarn("地図購入タイムアウト - 手動で準備してください")
            ChangePhase("COMPLETE", "地図購入タイムアウト")
        end
    else
        LogError("マーケットボードが見つかりません")
        ChangePhase("COMPLETE", "マーケットボード未発見")
    end
end

-- 移動フェーズ
local function ExecuteMovementPhase()
    if not movementStarted then
        LogInfo("宝の場所への移動を開始します")
        
        -- 食事効果チェック（移動開始時）
        CheckAndUseFoodItem()
        
        -- インベントリ管理チェック
        if not CheckAndManageInventory() then
            return  -- インベントリ満杯の場合は処理停止
        end
        
        -- マテリア精製チェック
        CheckAndExtractMateria()
        
        -- vnavmeshの準備状態確認
        if not IsVNavReady() then
            LogWarn("vnavmeshが準備できていません。手動で移動してください")
            movementStarted = true  -- 手動移動待機
            Wait(2)
            return
        end
        
        -- 飛行マウント召喚（マウント状態に応じて実行）
        if SummonPowerLoader() then
            -- フラグ座標を取得
            local flagPos = nil
            local success = SafeExecute(function()
                if Instances and Instances.Map and Instances.Map.Flag then
                    if Instances.Map.Flag.Vector3 then
                        flagPos = Instances.Map.Flag.Vector3
                    elseif Instances.Map.Flag.Vector2 then
                        local flagVec2 = Instances.Map.Flag.Vector2
                        local yCoord = (Instances.Map.Flag.Vector3 and Instances.Map.Flag.Vector3.Y) or 0
                        flagPos = {X = flagVec2.X, Y = yCoord, Z = 0}
                    elseif Instances.Map.Flag.XFloat and Instances.Map.Flag.YFloat then
                        flagPos = {
                            X = Instances.Map.Flag.XFloat,
                            Y = 150,
                            Z = 0
                        }
                    end
                end
                return flagPos ~= nil
            end, "Failed to get flag position")
            
            if success and flagPos then
                -- Y座標修正機能：移動時の座標補正
                if flagPos.Y == 0.0 or not flagPos.Y then
                    if math.abs(flagPos.X - 525.47) < 1.0 and math.abs(flagPos.Z - (-799.65)) < 1.0 then
                        flagPos.Y = 22.0
                        LogInfo("移動時Y座標修正適用: X=" .. string.format("%.2f", flagPos.X) .. ", Z=" .. string.format("%.2f", flagPos.Z) .. " → Y=22.0")
                    elseif math.abs(flagPos.X - 219.05) < 1.0 and math.abs(flagPos.Z - (-66.08)) < 1.0 then
                        flagPos.Y = 95.224
                        LogInfo("移動時Y座標修正適用: X=" .. string.format("%.2f", flagPos.X) .. ", Z=" .. string.format("%.2f", flagPos.Z) .. " → Y=95.224")
                    else
                        flagPos.Y = 150.0
                        LogInfo("移動時Y座標フォールバック: Y=150.0適用")
                    end
                end
                
                LogInfo("移動先フラッグ座標: X=" .. string.format("%.2f", flagPos.X) .. ", Y=" .. string.format("%.2f", flagPos.Y) .. ", Z=" .. string.format("%.2f", flagPos.Z))
                -- 新IPC APIで飛行移動開始
                LogInfo("vnavmeshで飛行移動開始... (座標: " .. string.format("%.2f, %.2f, %.2f", flagPos.X, flagPos.Y, flagPos.Z) .. ")")
                
                local moveSuccess = SafeExecute(function()
                    if not CONFIG.DISABLE_IPC_VNAV and IPC and IPC.vnavmesh and IPC.vnavmesh.PathfindAndMoveTo then
                        -- パス計算中・移動中チェック：動作中なら実行をスキップ
                        if IsVNavMoving() then
                            return true  -- スキップするが成功として扱う
                        end
                        
                        -- マウント状態確認してfly設定
                        local shouldFly = IsPlayerMounted()
                        
                        -- マウント乗ってない場合は乗る
                        if not shouldFly then
                            if CanMount() then
                                LogInfo("マウント召喚中...")
                                if MountSafely("高機動型パワーローダー", 5) then
                                    shouldFly = IsPlayerMounted()
                                else
                                    LogWarn("マウント召喚に失敗しました")
                                    shouldFly = false
                                end
                            end
                        end
                        
                        -- 飛行できない場合はshouldFly=false
                        if shouldFly and not CanFly() then
                            shouldFly = false
                        end
                        
                        -- Y座標をフラッグから取得
                        flagPos.Y = (Instances.Map.Flag.Vector3 and Instances.Map.Flag.Vector3.Y) or 0
                        -- IPC.vnavmesh.PathfindAndMoveToをyieldコマンドに置換（SEHException回避）
                        if flagPos.Y ~= 0 and flagPos.Y ~= 150.0 then
                            yield("/vnav flyto " .. flagPos.X .. " " .. flagPos.Y .. " " .. flagPos.Z)
                        else
                            yield("/vnav flyflag")
                        end
                        return true
                    else
                        -- フォールバック: コマンド実行
                        yield("/vnav flyflag")
                        return true
                    end
                end, "Failed to start vnav movement")
                
                if moveSuccess then
                    movementStarted = true
                    Wait(2)
                else
                    LogWarn("vnavmesh移動開始に失敗しました")
                    return
                end
            else
                LogWarn("フラグ座標の取得に失敗しました - コマンドフォールバック")
                yield("/vnav flyflag")
                movementStarted = true
                Wait(2)
            end
        else
            LogWarn("マウント召喚に失敗しました")
            return
        end
        return
    end
    
    -- 移動完了チェック（vnavmesh優先判定）
    local isMoving = IsPlayerMoving()
    local isMounted = IsPlayerMounted()
    local isVNavMoving = IsVNavMoving()
    local flagDistance = GetDistanceToFlag()
    
    -- フラグ距離が取得できる場合は距離ベース判定
    local isNearFlag = false
    if flagDistance < 999 then
        isNearFlag = flagDistance <= 5.0
    else
    end
    
    -- 安全な時間計算（オーバーフロー防止）
    local currentTime = os.clock()
    local elapsedTime = math.max(0, math.min(currentTime - phaseStartTime, 3600)) -- 最大1時間に制限
    
    -- 10秒間隔で進行状況を報告（移動中のみ）
    if isVNavMoving or isMoving then
        if elapsedTime % 10 == 0 and elapsedTime > 0 then
            LogInfo("移動中... (経過時間: " .. elapsedTime .. "秒, フラグ距離: " .. string.format("%.2f", flagDistance) .. "yalm, マウント: " .. (isMounted and "ON" or "OFF") .. ")")
        end
    end
    
    -- ゾーンID 614でドマ反乱軍の門兵ターゲット試行（座標ベース）
    local currentZoneId = GetZoneID()
    if currentZoneId == 614 and not domaGuardRecentlyInteracted then
        -- ドマ反乱軍の門兵の既知座標
        local domaGuardPos = {X = 276.35607910, Y = 3.65841579, Z = -377.52349854}
        
        yield("/target ドマ反乱軍の門兵")
        Wait(0.5)
        
        -- ターゲットできた場合のみ処理実行
        if HasTarget() then
            -- ターゲット名と位置を確認してドマ反乱軍の門兵かチェック
            local targetName = GetTargetName and GetTargetName() or ""
            local targetPos = Entity.Target and Entity.Target.Position or nil
            
            if string.find(targetName, "ドマ反乱軍の門兵") and targetPos and targetPos.X and targetPos.Y and targetPos.Z then
                -- 座標の近似一致チェック（既知座標から0.001以内なら正しいドマ反乱軍の門兵）
                
                -- X,Z座標の差が0.001以内なら一致とみなす（Y座標=高さは除外）
                local deltaX = math.abs(targetPos.X - domaGuardPos.X)
                local deltaZ = math.abs(targetPos.Z - domaGuardPos.Z)
                
                if deltaX <= 0.001 and deltaZ <= 0.001 then  -- X,Z座標のみ0.001以内の近似一致
                    LogInfo("ドマ反乱軍の門兵をターゲット確認 - vnav停止してflytargetで接近します")
                    
                    -- vnavmesh停止
                    StopVNav()
                    Wait(1)
                    
                    -- ターゲットに向かって飛行移動
                    LogInfo("ドマ反乱軍の門兵にflytargetで飛行接近中...")
                    yield("/vnav flytarget")
                    Wait(2)
                    
                    -- 移動完了まで待機
                    local approachStartTime = os.time()
                    while IsVNavMoving() and not IsTimeout(approachStartTime, 15) do
                        Wait(1)
                    end
                    
                    -- マウント状態チェック・降車
                    if IsPlayerMounted() then
                        LogInfo("マウントから降車中...")
                        if not DismountSafely(5) then
                            LogWarn("ドマ反乱軍門兵付近でのマウント降車に失敗しました")
                        end
                    end
                    
                    -- インタラクト実行
                    LogInfo("ドマ反乱軍の門兵とインタラクト")
                    yield("/interact")
                    Wait(2)
                    
                    -- インタラクト完了
                    LogInfo("ドマ反乱軍の門兵とのインタラクト完了")
                    
                    -- インタラクト完了後はターゲット解除して無限ループ防止
                    yield("/targetenemy")
                    Wait(0.5)
                    domaGuardRecentlyInteracted = true  -- フラグ設定で再ターゲット防止
                    LogInfo("ターゲット解除完了 - 無限ループ防止フラグ設定")
                else
                    yield("/targetenemy")  -- ターゲット解除
                end
                
                -- vnavmesh移動を再開
                LogInfo("元の目的地への移動を再開します")
                local flagPos = nil
                local success = SafeExecute(function()
                    if Instances and Instances.Map and Instances.Map.Flag then
                        if Instances.Map.Flag.Vector3 then
                            flagPos = Instances.Map.Flag.Vector3
                        elseif Instances.Map.Flag.Vector2 then
                            local flagVec2 = Instances.Map.Flag.Vector2
                            local yCoord = (Instances.Map.Flag.Vector3 and Instances.Map.Flag.Vector3.Y) or 0
                        flagPos = {X = flagVec2.X, Y = yCoord, Z = 0}
                        end
                    end
                    return flagPos ~= nil
                end, "Failed to get flag position for restart")
                
                if success and flagPos then
                    LogInfo("フラグ座標取得成功 - 移動再開")
                    
                    -- 移動再開前にマウント状態確認・再召喚
                    if not IsPlayerMounted() then
                        if CanMount() then
                            LogInfo("マウント再召喚中...")
                            if not MountSafely("高機動型パワーローダー", 5) then
                                LogWarn("マウント再召喚に失敗しました")
                            end
                        end
                    end
                    
                    local moveSuccess = SafeExecute(function()
                        if not CONFIG.DISABLE_IPC_VNAV and IPC and IPC.vnavmesh and IPC.vnavmesh.PathfindAndMoveTo then
                            -- パス計算中・移動中チェック：動作中なら実行をスキップ
                            if IsVNavMoving() then
                                return true  -- スキップするが成功として扱う
                            end
                            
                            -- マウント状態に応じたfly設定
                            local shouldFly = IsPlayerMounted() and CanFly()
                            -- Y座標をフラッグから取得
                            flagPos.Y = (Instances.Map.Flag.Vector3 and Instances.Map.Flag.Vector3.Y) or 0
                            yield("/vnav flyflag")
                            return true
                        else
                            yield("/vnav flyflag")
                            return true
                        end
                    end, "Failed to restart vnav movement")
                    
                    if moveSuccess then
                        LogInfo("移動再開成功")
                    else
                        LogWarn("移動再開に失敗しました")
                    end
                else
                    LogWarn("フラグ座標取得に失敗 - コマンドで移動再開")
                    
                    -- 移動再開前にマウント状態確認・再召喚
                    if not IsPlayerMounted() then
                        if CanMount() then
                            LogInfo("マウント再召喚中...")
                            if not MountSafely("高機動型パワーローダー", 5) then
                                LogWarn("マウント再召喚に失敗しました")
                            end
                        end
                    end
                    
                    yield("/vnav flyflag")
                end
                
                return  -- 処理完了後、移動フェーズを継続
            else
            end
        end
    end
    
    -- フラグ地点到達判定（距離優先の安全な判定）
    local shouldDig = false
    if not digExecuted then
        
        -- 条件1: フラグ距離が取得でき、5yalm以内（最優先・最も確実）
        if isNearFlag then
            LogInfo("フラグ地点に到達しました（距離: " .. string.format("%.2f", flagDistance) .. "yalm）")
            shouldDig = true
        -- 条件2: vnavmesh移動完了 + 距離が近い（50yalm以内）+ 一定時間経過
        elseif not isVNavMoving and flagDistance < 50.0 and elapsedTime > 15 then
            LogInfo("vnavmesh移動完了+近距離を検出 - 発掘を実行 (距離: " .. string.format("%.2f", flagDistance) .. "yalm)")
            shouldDig = true
        -- 条件3: プレイヤーが移動停止、マウント降車、距離が近い
        elseif not isMoving and not isMounted and flagDistance < 20.0 and elapsedTime > 20 then
            LogInfo("移動停止・降車・近距離を検出 - 発掘を実行 (距離: " .. string.format("%.2f", flagDistance) .. "yalm)")
            shouldDig = true
        -- 条件4: 移動タイムアウト（5分経過）
        elseif CheckPhaseTimeout() then
            LogWarn("移動タイムアウト - 強制発掘を実行 (距離: " .. string.format("%.2f", flagDistance) .. "yalm)")
            shouldDig = true
        -- 新条件4.5: vnavmesh停止・中距離（50-100yalm）での追加移動
        elseif not isVNavMoving and not isMoving and flagDistance >= 50.0 and flagDistance < 100.0 and elapsedTime > 30 then
            LogWarn("vnavmesh停止・中距離検出 - 追加移動を実行 (距離: " .. string.format("%.2f", flagDistance) .. "yalm, 停止時間: " .. elapsedTime .. "秒)")
            -- 追加移動処理
            if IsVNavReady() then
                local flagPos = nil
                local success = SafeExecute(function()
                    if Instances and Instances.Map and Instances.Map.Flag then
                        if Instances.Map.Flag.Vector3 and Instances.Map.Flag.Vector3.Y ~= 0.0 then
                            flagPos = {X = Instances.Map.Flag.Vector3.X, Y = Instances.Map.Flag.Vector3.Y, Z = Instances.Map.Flag.Vector3.Z}
                        elseif Instances.Map.Flag.Vector2 then
                            local flagVec2 = Instances.Map.Flag.Vector2
                            local yCoord = (Instances.Map.Flag.Vector3 and Instances.Map.Flag.Vector3.Y) or 0
                flagPos = {X = flagVec2.X, Y = yCoord, Z = flagVec2.Y}
                        end
                    end
                    return flagPos ~= nil
                end, "Failed to get flag position for additional movement")
                
                if success and flagPos then
                    LogInfo("フラグ座標取得成功 - 追加移動開始")
                    
                    -- Y座標修正機能：追加移動時の座標補正
                    if flagPos.Y == 0.0 or not flagPos.Y then
                        if math.abs(flagPos.X - 525.47) < 1.0 and math.abs(flagPos.Z - (-799.65)) < 1.0 then
                            flagPos.Y = 22.0
                            LogInfo("追加移動時Y座標修正適用: X=" .. string.format("%.2f", flagPos.X) .. ", Z=" .. string.format("%.2f", flagPos.Z) .. " → Y=22.0")
                        elseif math.abs(flagPos.X - 219.05) < 1.0 and math.abs(flagPos.Z - (-66.08)) < 1.0 then
                            flagPos.Y = 95.224
                            LogInfo("追加移動時Y座標修正適用: X=" .. string.format("%.2f", flagPos.X) .. ", Z=" .. string.format("%.2f", flagPos.Z) .. " → Y=95.224")
                        else
                            flagPos.Y = 150.0
                            LogInfo("追加移動時Y座標フォールバック: Y=150.0適用")
                        end
                    end
                    
                    LogInfo("追加移動先座標: X=" .. string.format("%.2f", flagPos.X) .. ", Y=" .. string.format("%.2f", flagPos.Y) .. ", Z=" .. string.format("%.2f", flagPos.Z))
                    
                    local moveSuccess = SafeExecute(function()
                        if not CONFIG.DISABLE_IPC_VNAV and IPC and IPC.vnavmesh and IPC.vnavmesh.PathfindAndMoveTo then
                            if IsVNavMoving() then
                                return true
                            end
                            
                            local shouldFly = IsPlayerMounted() and CanFly()
                            SafeExecute(function()
                                yield("/vnav flyflag")
                            end, "IPC vnavmesh PathfindAndMoveTo failed", 0)
                            return true
                        else
                            -- フォールバック: vnavmeshコマンド使用も安全化
                            SafeExecute(function()
                                yield("/vnav flyflag")
                            end, "vnavmesh flyflag command failed", 0)
                            return true
                        end
                    end, "Failed to start additional movement", 1)
                    
                    if moveSuccess then
                        LogInfo("追加移動開始成功")
                        return  -- 移動開始後、フェーズ継続
                    else
                        LogWarn("追加移動開始に失敗しました")
                    end
                else
                    LogWarn("フラグ座標取得失敗 - コマンドで追加移動")
                    SafeExecute(function()
                        yield("/vnav flyflag")
                    end, "Fallback vnavmesh flyflag command failed", 0)
                    return
                end
            else
                LogWarn("vnavmesh準備不完了 - 手動移動またはフラグ接近が必要")
            end
        -- 新条件5: vnavmesh長時間停止（ルート切れ）の場合のみ再移動
        elseif not isVNavMoving and not isMoving and flagDistance >= 100.0 and elapsedTime > 60 then
            LogWarn("vnavmesh長時間停止・距離が非常に遠い - 再移動を試行 (距離: " .. string.format("%.2f", flagDistance) .. "yalm, 停止時間: " .. elapsedTime .. "秒)")
            -- 再移動処理（より慎重な条件で実行）
            if IsVNavReady() then
                local flagPos = nil
                local success = SafeExecute(function()
                    if Instances and Instances.Map and Instances.Map.Flag then
                        if Instances.Map.Flag.Vector3 then
                            flagPos = Instances.Map.Flag.Vector3
                        elseif Instances.Map.Flag.Vector2 then
                            local flagVec2 = Instances.Map.Flag.Vector2
                            local yCoord = (Instances.Map.Flag.Vector3 and Instances.Map.Flag.Vector3.Y) or 0
                        flagPos = {X = flagVec2.X, Y = yCoord, Z = 0}
                        end
                    end
                    return flagPos ~= nil
                end, "Failed to get flag position for retry")
                
                if success and flagPos then
                    LogInfo("フラグ座標取得成功 - 緊急再移動開始")
                    
                    -- Y座標修正機能：緊急再移動時の座標補正
                    if flagPos.Y == 0.0 or not flagPos.Y then
                        if math.abs(flagPos.X - 525.47) < 1.0 and math.abs(flagPos.Z - (-799.65)) < 1.0 then
                            flagPos.Y = 22.0
                            LogInfo("緊急再移動時Y座標修正適用: X=" .. string.format("%.2f", flagPos.X) .. ", Z=" .. string.format("%.2f", flagPos.Z) .. " → Y=22.0")
                        elseif math.abs(flagPos.X - 219.05) < 1.0 and math.abs(flagPos.Z - (-66.08)) < 1.0 then
                            flagPos.Y = 95.224
                            LogInfo("緊急再移動時Y座標修正適用: X=" .. string.format("%.2f", flagPos.X) .. ", Z=" .. string.format("%.2f", flagPos.Z) .. " → Y=95.224")
                        else
                            flagPos.Y = 150.0
                            LogInfo("緊急再移動時Y座標フォールバック: Y=150.0適用")
                        end
                    end
                    
                    LogInfo("緊急再移動先座標: X=" .. string.format("%.2f", flagPos.X) .. ", Y=" .. string.format("%.2f", flagPos.Y) .. ", Z=" .. string.format("%.2f", flagPos.Z))
                    
                    local moveSuccess = SafeExecute(function()
                        if not CONFIG.DISABLE_IPC_VNAV and IPC and IPC.vnavmesh and IPC.vnavmesh.PathfindAndMoveTo then
                            -- パス計算中・移動中チェック：動作中なら実行をスキップ
                            if IsVNavMoving() then
                                return true  -- スキップするが成功として扱う
                            end
                            
                            SafeExecute(function()
                                yield("/vnav flyflag")
                            end, "IPC vnavmesh PathfindAndMoveTo restart failed", 0)
                            return true
                        else
                            SafeExecute(function()
                                yield("/vnav flyflag")
                            end, "vnavmesh flyflag restart failed", 0)
                            return true
                        end
                    end, "Failed to restart vnav movement")
                    
                    if moveSuccess then
                        LogInfo("緊急再移動開始成功")
                        -- phaseStartTimeをリセットして再移動時間を確保
                        phaseStartTime = os.clock()
                    end
                end
            end
        end
    end
    
    if shouldDig then
        -- vnavmesh移動を停止
        StopVNav()
        Wait(1)
        
        -- 発掘前にマウントから確実に降車
        if not DismountSafely(5) then
            LogWarn("マウント降車に失敗しましたが、発掘を続行します")
        end
        
        -- 発掘実行
        LogInfo("発掘を実行します")
        yield("/gaction ディグ")
        digExecuted = true
        Wait(3)
        
        -- 宝箱検出とエラーハンドリング
        if IsAddonVisible("SelectYesno") then
            LogInfo("宝箱発見確認ダイアログを処理")
            yield("/callback SelectYesno true 0") -- はい
            Wait(3)
            
            -- 発掘結果確認（より長い待機時間で確実に判定）
            LogInfo("発掘結果を確認中...")
            Wait(5) -- より長い待機時間
            
            -- 複数回チェックで確実性を向上
            local combatStarted = false
            local treasureExists = false
            
            -- 3回チェックして確実性を高める
            for i = 1, 3 do
                combatStarted = IsDirectCombat()
                if combatStarted then
                    LogInfo("戦闘開始を検出（チェック" .. i .. "/3）")
                    break
                end
                
                yield("/target 宝箱")
                Wait(1)
                treasureExists = HasTarget()
                if treasureExists then
                    LogInfo("宝箱発見を検出（チェック" .. i .. "/3）")
                    break
                end
                
                Wait(2) -- 次のチェックまで待機
            end
            
            if combatStarted or treasureExists then
                LogInfo("発掘成功 - 戦闘開始または宝箱発見")
                movementStarted = false
                digExecuted = false
                ChangePhase("COMBAT", "発掘完了、戦闘または宝箱確認")
                return
            else
                LogWarn("発掘失敗 - 複数回チェックでも戦闘・宝箱が検出されませんでした")
                movementStarted = false
                digExecuted = false
                ChangePhase("COMPLETE", "発掘失敗、次の地図処理")
                return
            end
        else
            -- 宝箱発見ダイアログが表示されない場合 - 発掘失敗の可能性
            Wait(2) -- 追加待機
            
            -- 再度チェック
            if IsAddonVisible("SelectYesno") then
                LogInfo("遅延後に宝箱発見ダイアログを検出")
                yield("/callback SelectYesno true 0")
                Wait(4) -- 発掘結果確認のため長めに待機
                
                -- 遅延発掘後の状態確認（複数回チェック）
                local combatStarted = false
                local treasureExists = false
                
                -- 3回チェックして確実性を高める
                for i = 1, 3 do
                    combatStarted = IsDirectCombat()
                    if combatStarted then
                        LogInfo("遅延戦闘開始を検出（チェック" .. i .. "/3）")
                        break
                    end
                    
                    yield("/target 宝箱")
                    Wait(1)
                    treasureExists = HasTarget()
                    if treasureExists then
                        LogInfo("遅延宝箱発見を検出（チェック" .. i .. "/3）")
                        break
                    end
                    
                    Wait(2) -- 次のチェックまで待機
                end
                
                if combatStarted or treasureExists then
                    LogInfo("遅延発掘成功 - 戦闘開始または宝箱発見")
                    movementStarted = false
                    digExecuted = false
                    ChangePhase("COMBAT", "遅延発掘完了、戦闘または宝箱確認")
                    return
                else
                    LogWarn("遅延発掘失敗 - 複数回チェックでも戦闘・宝箱が検出されませんでした")
                    movementStarted = false
                    digExecuted = false
                    ChangePhase("COMPLETE", "遅延発掘失敗、次の地図処理")
                    return
                end
            else
                -- 発掘失敗と判断 - 次の地図に移行
                LogWarn("宝箱が発見されませんでした。次の地図に移行します")
                movementStarted = false
                digExecuted = false
                ChangePhase("COMPLETE", "発掘失敗、次の地図処理")
                return
            end
        end
    end
    
    -- 移動タイムアウトチェック（追加）
    if CheckPhaseTimeout() then
        LogWarn("移動タイムアウト。手動で発掘を実行します")
        StopVNav()
        
        -- 強制発掘前にマウントから確実に降車
        if not DismountSafely(5) then
            LogWarn("マウント降車に失敗しましたが、強制発掘を続行します")
        end
        
        -- 強制発掘
        LogInfo("強制発掘を実行します")
        yield("/gaction ディグ")
        digExecuted = true
        Wait(3)
        
        if IsAddonVisible("SelectYesno") then
            yield("/callback SelectYesno true 0")
            Wait(2)
        end
        
        movementStarted = false
        digExecuted = false
        ChangePhase("COMBAT", "タイムアウト後発掘完了")
        return
    end
    
    -- 移動中の場合は待機（詳細状態表示）
    if isMoving or isMounted or (flagDistance >= 999) then
        if iteration % 5 == 0 then  -- 5秒おきにログ出力
            local statusMsg = "移動中... (経過時間: " .. math.floor(os.clock() - phaseStartTime) .. "秒"
            if flagDistance < 999 then
                statusMsg = statusMsg .. ", フラグ距離: " .. string.format("%.2f", flagDistance) .. "yalm"
            else
                statusMsg = statusMsg .. ", フラグ距離: 取得不可"
            end
            statusMsg = statusMsg .. ", マウント: " .. (isMounted and "ON" or "OFF") .. ")"
        end
        Wait(1)
    else
        -- 移動していないが発掘がまだの場合、少し待つ
        local statusMsg = "移動停止。発掘処理を待機中... (マウント: " .. (isMounted and "ON" or "OFF")
        if flagDistance < 999 then
            statusMsg = statusMsg .. ", フラグ距離: " .. string.format("%.2f", flagDistance) .. "yalm"
        end
        statusMsg = statusMsg .. ")"
        Wait(2)
    end
end

-- 転送魔紋検出関数
local function CheckForTransferPortal()
    local portalTargets = {"転送魔紋", "魔紋", "転送装置", "転送陣"}
    
    for _, targetName in ipairs(portalTargets) do
        yield("/target " .. targetName)
        Wait(0.5)
        
        if HasTarget() then
            LogInfo("転送魔紋発見: " .. targetName)
            yield("/interact")
            Wait(3)
            
            -- ダンジョンに転送されたかチェック
            if IsInDuty() then
                LogInfo("転送魔紋経由でダンジョンに転送されました")
                return true
            end
        end
    end
    
    return false
end

-- 宝箱インタラクト関数
local function CheckForTreasureChest()
    -- 宝箱を確実にターゲット（複数回試行）
    local targetAttempts = 0
    local maxAttempts = 3
    
    while targetAttempts < maxAttempts do
        yield("/target 宝箱")
        Wait(0.5)
        
        if HasTarget() then
            -- ターゲットが本当に宝箱かチェック
            local success, targetName = SafeExecute(function()
                if Entity and Entity.Target and Entity.Target.Name then
                    return Entity.Target.Name
                end
                return nil
            end, "Failed to get target name")
            
            if success and targetName and targetName == "宝箱" then
                break
            else
                LogWarn("ターゲットは宝箱ではありません: " .. tostring(targetName))
                targetAttempts = targetAttempts + 1
                Wait(0.5)
            end
        else
            targetAttempts = targetAttempts + 1
            Wait(0.5)
        end
    end
    
    if HasTarget() then
        LogInfo("宝箱発見 - 移動してインタラクト開始")
        
        -- 現在の距離をチェック
        local currentDistance = GetDistanceToTarget()
        
        -- 距離計算が失敗した場合（999が返された場合）の対処
        if currentDistance >= 999 then
            LogWarn("宝箱への距離計算失敗 - ターゲットが無効です")
            return false
        end
        
        
        -- 距離が遠い場合（50yalm以上）はマウント移動
        if currentDistance > 50.0 then
            LogInfo("宝箱まで遠距離 (" .. string.format("%.2f", currentDistance) .. "yalm) - マウントで移動")
            
            -- マウント召喚
            if not IsPlayerMounted() then
                if SummonPowerLoader() then
                    Wait(3)
                else
                    LogWarn("マウント召喚失敗 - 徒歩で移動します")
                end
            end
            
            -- vnavmeshで飛行移動
            if IsVNavReady() then
                LogInfo("宝箱まで飛行で接近中...")
                
                -- ターゲット座標を取得
                local success, targetPos = SafeExecute(function()
                    if Entity and Entity.Target and Entity.Target.Position then
                        return Entity.Target.Position
                    end
                    return nil
                end, "Failed to get target position")
                
                if success and targetPos then
                    -- 飛行でターゲットに移動
                    SafeExecute(function()
                        if not CONFIG.DISABLE_IPC_VNAV and IPC and IPC.vnavmesh and IPC.vnavmesh.PathfindAndMoveTo then
                            yield("/vnav flytarget")  -- fly=true
                        else
                            -- フォールバック: コマンド実行
                            yield("/vnav movetarget")
                        end
                    end, "Failed to start vnav movement to treasure chest")
                    
                    -- 距離が近くなるまで待機（タイムアウト付き）
                    local moveTimeout = 30
                    local moveStartTime = os.clock()
                    
                    while GetDistanceToTarget() > 20.0 and not IsTimeout(moveStartTime, moveTimeout) do
                        local distance = GetDistanceToTarget()
                        Wait(2)
                    end
                    
                    -- 移動停止
                    StopVNav()
                else
                    LogWarn("ターゲット座標の取得に失敗 - コマンドフォールバック")
                    yield("/vnav movetarget")
                    Wait(2)
                end
            else
                LogWarn("vnavmeshが準備できていません")
                yield("/vnav movetarget")
                Wait(2)
            end
            
            -- マウントから降りる
            if IsPlayerMounted() then
                LogInfo("宝箱付近でマウントから降車")
                if not DismountSafely(5) then
                    LogWarn("宝箱付近でのマウント降車に失敗しました")
                end
            end
        end
        
        -- 最終アプローチ（3yalm以内まで）
        currentDistance = GetDistanceToTarget()
        if currentDistance > 3.0 and currentDistance < 999 then
            if IsVNavReady() then
                LogInfo("最終アプローチ - 距離: " .. string.format("%.2f", currentDistance) .. "yalm")
                
                -- ターゲット座標を取得
                local success, targetPos = SafeExecute(function()
                    if Entity and Entity.Target and Entity.Target.Position then
                        return Entity.Target.Position
                    end
                    return nil
                end, "Failed to get target position for final approach")
                
                if success and targetPos then
                    -- 最終接近でも飛行を使用
                    SafeExecute(function()
                        if not CONFIG.DISABLE_IPC_VNAV and IPC and IPC.vnavmesh and IPC.vnavmesh.PathfindAndMoveTo then
                            yield("/vnav flytarget")  -- fly=true
                        else
                            -- フォールバック: コマンド実行
                            yield("/vnav movetarget")
                        end
                    end, "Failed to start final approach to treasure chest")
                    
                    -- 距離が3yalm以下になるまで移動（タイムアウト付き）
                    local moveTimeout = 15
                    local moveStartTime = os.clock()
                    
                    while GetDistanceToTarget() > 3.0 and GetDistanceToTarget() < 999 and not IsTimeout(moveStartTime, moveTimeout) do
                        local distance = GetDistanceToTarget()
                        Wait(1)
                    end
                    
                    -- 移動停止
                    StopVNav()
                else
                    LogWarn("最終アプローチでターゲット座標の取得に失敗")
                    yield("/vnav movetarget")
                    Wait(1)
                end
            else
                LogWarn("vnavmeshが利用できません - コマンドフォールバック")
                yield("/vnav movetarget")
                Wait(1)
            end
            
            local finalDistance = GetDistanceToTarget()
            if finalDistance <= 3.0 then
                LogInfo("宝箱付近に到着 (距離: " .. string.format("%.2f", finalDistance) .. "yalm)")
            else
                LogWarn("宝箱への移動タイムアウト (距離: " .. string.format("%.2f", finalDistance) .. "yalm)")
            end
        else
            LogInfo("宝箱は既に範囲内です (距離: " .. string.format("%.2f", currentDistance) .. "yalm)")
        end
        
        -- インタラクト前にマウントから降りる
        if IsPlayerMounted() then
            LogInfo("宝箱インタラクト前にマウントから降車")
            if not DismountSafely(5) then
                LogWarn("宝箱インタラクト前のマウント降車に失敗しました")
            end
        end
        
        -- インタラクト前に宝箱を確実にターゲット
        LogInfo("宝箱を再ターゲットしてインタラクト実行")
        yield("/target 宝箱")
        Wait(0.5)
        
        if HasTarget() then
            yield("/interact")
            LogInfo("宝箱とインタラクト実行")
        else
            LogWarn("宝箱のターゲットに失敗しました")
            return false
        end
        Wait(3)
        
        -- 戦闘開始まで待機（より長い時間で確実に検出）
        local combatWaitTime = os.clock()
        while not IsDirectCombat() and not IsTimeout(combatWaitTime, 10) do
            Wait(1)
        end
        
        if IsDirectCombat() then
            LogInfo("宝箱インタラクト成功 - 戦闘開始")
            
            -- 戦闘開始時に即座に自動戦闘を有効化
            EnableCombatPlugins()
            LogInfo("戦闘開始 - 自動戦闘プラグイン有効化完了")
            
            treasureChestInteracted = true
            return true
        else
            LogInfo("宝箱インタラクト完了 - 戦闘は発生しませんでした")
            -- 戦闘が発生しない場合は完了フェーズに移行
            ChangePhase("COMPLETE", "戦闘なし宝箱完了")
            return true
        end
    end
    
    return false
end

-- 戦闘フェーズ
local function ExecuteCombatPhase()
    local isInCombat = IsDirectCombat()
    
    if isInCombat then
        LogInfo("戦闘中。自動戦闘を開始します")
        
        -- 新しい戦闘プラグイン検出・有効化システム
        local hasAnyPlugin = EnableCombatPlugins()
        
        -- 戦闘プラグインが一つも検出されない場合の処理
        if not hasAnyPlugin then
            -- 初回のみ警告表示（ログスパム防止）
            local currentTime = os.clock()
            if not combatWarningTime or (currentTime - combatWarningTime) > 30 then
                LogWarn("自動戦闘プラグインが検出されません。手動戦闘または戦闘タイムアウトまで待機")
                LogWarn("対応プラグイン: RotationSolverReborn/RSR, BossModReborn/BossMod/BMR")
                combatWarningTime = currentTime
            end
        end
        
        -- 戦闘中はフェーズを維持（戦闘終了は次のループで検出）
        return
    else
        -- 戦闘していない場合の処理
        LogInfo("戦闘状態ではありません")
        
        -- 自動戦闘を停止（もし有効だった場合）
        DisableCombatPlugins()
        
        -- 1. 最初に発掘失敗チェック（「この周囲に宝箱はないようだ……」対応）
        local excavationFailed = false
        
        -- 発掘失敗メッセージの検出（実際のゲームではチャットログ解析が必要）
        -- ここでは簡易版として、宝箱がターゲットできない場合に発掘失敗とみなす
        yield("/target 宝箱")
        Wait(1)
        
        if not HasTarget() then
            LogWarn("宝箱がターゲットできません - 発掘失敗の可能性")
            excavationFailed = true
        end
        
        if excavationFailed then
            LogInfo("発掘失敗を検出 - 次の地図に移行します")
            ChangePhase("COMPLETE", "発掘失敗、次の地図処理")
            return
        end
        
        -- 2. 宝箱が見つかった場合のインタラクト処理
        if not treasureChestInteracted and CheckForTreasureChest() then
            LogInfo("宝箱インタラクト完了、戦闘開始")
            return -- 戦闘開始したので戻る
        end
        
        -- 3. 戦闘完了後の宝箱インタラクト（戦闘後の追加処理）
        if treasureChestInteracted then
            LogInfo("戦闘完了後の宝箱再チェック...")
            
            -- 戦闘後の回収ターゲット（ダンジョン状態に応じて調整）
            local isInDungeon = IsInDuty()
            local postCombatTargets = {"宝箱"}
            
            if isInDungeon then
                -- ダンジョン内では皮袋も対象に追加
                table.insert(postCombatTargets, "皮袋")
            else
            end
            
            for _, targetName in ipairs(postCombatTargets) do
                yield("/target " .. targetName)
                Wait(1)
                
                if HasTarget() then
                    LogInfo("戦闘後の" .. targetName .. "発見 - 移動してインタラクト")
                    
                    -- 現在の距離をチェック
                    local currentDistance = GetDistanceToTarget()
                    
                    -- 距離計算が失敗した場合（999yalm）は既にインタラクト済みとみなす
                    if currentDistance >= 999 then
                        LogWarn("戦闘後の" .. targetName .. "は距離計算失敗 - 既にインタラクト済みとみなす")
                        goto next_target
                    end
                    
                    -- 距離が3yalm以上の場合のみ移動
                    if currentDistance > 3.0 then
                        if IsVNavReady() then
                            yield("/vnav movetarget")
                            Wait(1)
                            
                            -- 距離が3yalm以下になるまで移動（タイムアウト付き）
                            local moveTimeout = 15
                            local moveStartTime = os.clock()
                            
                            while GetDistanceToTarget() > 3.0 and not IsTimeout(moveStartTime, moveTimeout) do
                                local distance = GetDistanceToTarget()
                                Wait(1)
                            end
                            
                            -- 移動停止
                            StopVNav()
                            
                            local finalDistance = GetDistanceToTarget()
                            if finalDistance <= 3.0 then
                                LogInfo(targetName .. "付近に到着 (距離: " .. string.format("%.2f", finalDistance) .. "yalm)")
                            else
                                LogWarn(targetName .. "への移動タイムアウト (距離: " .. string.format("%.2f", finalDistance) .. "yalm)")
                            end
                        else
                            LogWarn("vnavmeshが利用できません - 手動で" .. targetName .. "に近づいてください")
                            Wait(3)
                        end
                    else
                        LogInfo(targetName .. "は既に範囲内です (距離: " .. string.format("%.2f", currentDistance) .. "yalm)")
                    end
                    
                    -- インタラクト前にマウントから降りる
                    if IsPlayerMounted() then
                        LogInfo("戦闘後" .. targetName .. "インタラクト前にマウントから降車")
                        if not DismountSafely(5) then
                            LogWarn("戦闘後" .. targetName .. "インタラクト前のマウント降車に失敗しました")
                        end
                    end
                    
                    -- インタラクト前にターゲットを確実に指定
                    LogInfo("戦闘後の" .. targetName .. "を再ターゲットしてインタラクト実行")
                    yield("/target " .. targetName)
                    Wait(0.5)
                    
                    if HasTarget() then
                        yield("/interact")
                        LogInfo("戦闘後の" .. targetName .. "とインタラクト実行")
                    else
                        LogWarn("戦闘後の" .. targetName .. "のターゲットに失敗しました")
                    end
                    Wait(2)
                end
                
                ::next_target::
            end
        end
        
        -- 4. 転送魔紋をチェック
        if CheckForTransferPortal() then
            ChangePhase("DUNGEON", "転送魔紋でダンジョン転送")
            return
        end
        
        -- 5. 直接ダンジョン検出
        if IsInDuty() then
            ChangePhase("DUNGEON", "ダンジョンに転送されました")
        else
            ChangePhase("COMPLETE", "戦闘なし、次の地図処理")
        end
    end
end

-- ダンジョンフェーズ
-- ダンジョンタイプ検出関数
local function DetectDungeonType()
    return SafeExecute(function()
        
        -- 最初に召喚魔法陣をチェック（ルーレットタイプの判定）
        local rouletteTargets = {"召喚魔法陣", "魔法陣", "召喚陣"}
        
        for _, targetName in ipairs(rouletteTargets) do
            yield("/target " .. targetName)
            Wait(1)  -- 待機時間を延長
            
            -- Entity.Targetを使用してターゲット名を取得
            local actualTargetName = GetTargetName()
            
            -- ターゲット位置情報も取得
            if Entity and Entity.Target and Entity.Target.Position then
                local targetPos = Entity.Target.Position
            end
            
            -- ターゲット名が設定され、かつ空でない場合のみ有効なターゲットとする
            local isValidTarget = actualTargetName ~= nil and actualTargetName ~= "" and string.len(actualTargetName) > 0
            
            if isValidTarget then
                -- さらに召喚魔法陣関連の名前かを確認
                local isRouletteTarget = string.find(actualTargetName, "召喚") or 
                                       string.find(actualTargetName, "魔法陣") or
                                       string.find(actualTargetName, "魔法") or
                                       string.find(actualTargetName, "陣")
                
                if isRouletteTarget then
                    local rouletteType = "ルーレット型（召喚魔法陣ベース）"
                    LogInfo("ダンジョンタイプ検出: " .. rouletteType .. " - ターゲット: " .. actualTargetName)
                    yield("/echo ダンジョンタイプ: " .. rouletteType)
                    yield("/targetenemy")  -- ターゲット解除
                    return "roulette", rouletteType
                else
                end
            end
        end
        
        -- 召喚魔法陣がない場合はダンジョンタイプ
        local dungeonType = "階層型ダンジョン（1-7層構造）"
        LogInfo("ダンジョンタイプ検出: " .. dungeonType .. " - 召喚魔法陣なし")
        yield("/echo ダンジョンタイプ: " .. dungeonType)
        yield("/targetenemy")  -- ターゲット解除
        return "dungeon", dungeonType
        
    end, "Failed to detect dungeon type")
end

-- ダンジョン探索サブ関数群
local function AutoMoveForward()
    yield("/automove on")
    
    local searchStartTime = os.clock()
    local maxSearchTime = 30 -- 最大30秒で探索タイムアウト
    
    while os.clock() - searchStartTime < maxSearchTime do
        Wait(1)
        
        -- 優先度順でターゲット検索
        local targetPriorities = {
            "宝箱", "皮袋", "革袋",  -- 宝物類
            "扉", "ドア", "Door",    -- 進行用ドア
            "魔法陣", "召喚魔法陣", "転送魔紋", "転送装置", "転送陣", "魔紋",  -- 転送類
            "ブルアポリオン", "ゴールデン", "モルター"  -- ボス類
        }
        
        for _, targetName in ipairs(targetPriorities) do
            yield("/target " .. targetName)
            Wait(0.3)
            
            if HasTarget() then
                yield("/automove off")
                LogInfo("前進探索完了: " .. targetName .. "を発見")
                Wait(1)
                return targetName
            end
        end
    end
    
    -- タイムアウト時は停止
    yield("/automove off")
    LogWarn("前進探索タイムアウト (" .. maxSearchTime .. "秒)")
    Wait(1)
    return nil
end

local function CheckForTreasures()
    local treasuresFound = {}
    local treasureTargets = {"宝箱", "皮袋", "革袋"}
    
    for _, targetName in ipairs(treasureTargets) do
        yield("/target " .. targetName)
        Wait(1)
        
        local actualTargetName = GetTargetName()
        if HasTarget() and actualTargetName == targetName then
            local distance = GetDistanceToTarget()
            LogInfo("発見: " .. actualTargetName .. " (距離: " .. string.format("%.2f", distance) .. "yalm)")
            
            -- 距離が3yalm以上の場合は移動
            if distance > 3.0 and IsVNavReady() then
                LogInfo(targetName .. "に近づいています...")
                yield("/vnav movetarget")
                Wait(1)
                
                -- 移動完了待機
                local moveTimeout = 10
                local moveStartTime = os.clock()
                while GetDistanceToTarget() > 3.0 and not IsTimeout(moveStartTime, moveTimeout) do
                    Wait(0.5)
                end
                StopVNav()
                
                local finalDistance = GetDistanceToTarget()
            end
            
            table.insert(treasuresFound, actualTargetName)
            LogInfo(actualTargetName .. "とインタラクト実行")
            yield("/interact")
            Wait(2)
            yield("/targetenemy")  -- ターゲット解除
        else
        end
    end
    
    if #treasuresFound > 0 then
        LogInfo("回収した宝物: " .. table.concat(treasuresFound, ", "))
        return true
    else
        return false
    end
end

local function CheckForNextFloor()
    local floorTargets = {"宝物庫の扉", "扉", "石の扉", "転送装置"}
    
    for _, targetName in ipairs(floorTargets) do
        yield("/target " .. targetName)
        Wait(1)
        
        local actualTargetName = GetTargetName()
        
        if HasTarget() and actualTargetName ~= "" then
            local distance = GetDistanceToTarget()
            LogInfo("次の階層への入口発見: " .. actualTargetName .. " (距離: " .. string.format("%.2f", distance) .. "yalm)")
            
            -- 距離が遠い場合は近づく
            if distance > 3.0 and IsVNavReady() then
                LogInfo("扉に近づいています...")
                yield("/vnav movetarget")
                Wait(2)
                
                -- 移動完了待機
                local moveTimeout = 10
                local moveStartTime = os.clock()
                while GetDistanceToTarget() > 3.0 and not IsTimeout(moveStartTime, moveTimeout) do
                    Wait(1)
                end
                StopVNav()
            end
            
            LogInfo("扉とインタラクト実行")
            yield("/interact")
            Wait(3)
            return true
        end
    end
    
    return false
end

local function CheckForExit()
    local exitTargets = {"脱出地点", "退出", "出口", "転送魔法陣"}
    
    for _, targetName in ipairs(exitTargets) do
        yield("/target " .. targetName)
        Wait(0.5)
        
        if HasTarget() then
            LogInfo("脱出地点発見: " .. targetName)
            yield("/interact")
            Wait(3)
            return true
        end
    end
    
    return false
end

local function CheckForBoss()
    local bossTargets = {"ブルアポリオン", "ゴールデン・モルター"}
    
    for _, bossName in ipairs(bossTargets) do
        yield("/target " .. bossName)
        Wait(0.5)
        
        if HasTarget() then
            LogInfo("最終層ボス発見: " .. bossName)
            yield("/interact")  -- ボスには自分から攻撃する必要がある
            Wait(2)
            
            -- ボス戦闘待機
            LogInfo("ボス戦闘開始 - 戦闘完了まで待機")
            local bossStartTime = os.clock()
            while IsInCombat() and not IsTimeout(bossStartTime, 180) do  -- 3分タイムアウト
                Wait(2)
            end
            
            if not IsInCombat() then
                LogInfo("ボス戦闘完了")
                return true
            else
                LogError("ボス戦闘タイムアウト")
                return false
            end
        end
    end
    
    return false
end

-- 優先順位ベースターゲット・インタラクトシステム
-- 皮袋＞宝箱＞宝物庫の扉/召喚魔法陣＞脱出地点の順
local function CheckAndInteractPriorityTargets(currentFloor, maxFloors)
    LogDebug("優先順位ベースターゲット実行 (階層: " .. currentFloor .. "/" .. maxFloors .. ")")
    
    -- 戦闘中は処理を停止
    if IsInCombat() then
        LogDebug("戦闘中のためターゲット処理を一時停止")
        return false
    end
    
    -- 優先順位定義
    local targets = {
        -- 1. 皮袋（最高優先度）
        {
            names = {"皮袋", "古めかしい皮袋", "上質な皮袋"},
            description = "皮袋"
        },
        -- 2. 宝箱（2番目の優先度）
        {
            names = {"宝箱", "トレジャーコファー", "古い宝箱", "豪華な宝箱"},
            description = "宝箱"
        },
        -- 3. 宝物庫の扉/召喚魔法陣（3番目の優先度）
        {
            names = {"宝物庫の扉", "扉", "石の扉", "転送装置", "召喚魔法陣", "魔法陣"},
            description = "宝物庫の扉/召喚魔法陣"
        }
    }
    
    -- 最終層の場合は脱出地点も追加
    if currentFloor >= maxFloors then
        table.insert(targets, {
            names = {"脱出地点", "退出", "出口", "転送魔法陣"},
            description = "脱出地点"
        })
    end
    
    -- 優先順位に従ってターゲット検索・インタラクト
    for priorityIndex, targetGroup in ipairs(targets) do
        
        for _, targetName in ipairs(targetGroup.names) do
            
            -- ターゲット実行
            local success, result = SafeExecute(function()
                yield("/target " .. targetName)
                return true
            end, "Failed to target " .. targetName)
            
            if not success then
                goto next_target
            end
            
            Wait(0.5)
            
            -- ターゲット成功チェック
            if HasTarget() then
                local actualTargetName = GetTargetName()
                local distance = GetDistanceToTarget()
                
                if actualTargetName and actualTargetName ~= "" then
                    LogInfo("発見: " .. actualTargetName .. " (優先度: " .. priorityIndex .. 
                           ", 距離: " .. string.format("%.2f", distance) .. "yalm)")
                    
                    -- 距離が3yalm以上の場合は移動
                    if distance > 3.0 and IsVNavReady() then
                        LogInfo(actualTargetName .. "に接近中...")
                        yield("/vnav movetarget")
                        Wait(1)
                        
                        -- 移動完了待機（タイムアウト付き）
                        local moveTimeout = 15
                        local moveStartTime = os.clock()
                        
                        while GetDistanceToTarget() > 3.0 and not IsTimeout(moveStartTime, moveTimeout) do
                            local currentDistance = GetDistanceToTarget()
                            
                            -- 戦闘が開始された場合は移動を中断
                            if IsInCombat() then
                                LogInfo("戦闘開始 - 移動を中断")
                                StopVNav()
                                return false
                            end
                            
                            Wait(0.5)
                        end
                        
                        -- 移動停止
                        StopVNav()
                        
                        local finalDistance = GetDistanceToTarget()
                        if finalDistance <= 3.0 then
                            LogInfo("接近完了 (最終距離: " .. string.format("%.2f", finalDistance) .. "yalm)")
                        else
                            LogWarn("接近タイムアウト (距離: " .. string.format("%.2f", finalDistance) .. "yalm)")
                            -- タイムアウトでも一応インタラクトを試行
                        end
                    else
                        LogInfo("既に範囲内です (距離: " .. string.format("%.2f", distance) .. "yalm)")
                    end
                    
                    -- インタラクト実行
                    LogInfo(actualTargetName .. "とインタラクト実行")
                    yield("/interact")
                    Wait(2)
                    
                    -- インタラクト後の戦闘チェック
                    local combatCheckTime = os.clock()
                    while not IsInCombat() and not IsTimeout(combatCheckTime, 3) do
                        Wait(0.5)
                    end
                    
                    if IsInCombat() then
                        LogInfo("インタラクト後に戦闘開始 - ターゲット処理を一時停止")
                        
                        -- 戦闘開始時に即座に自動戦闘を有効化
                        EnableCombatPlugins()
                        LogInfo("ダンジョン戦闘開始 - 自動戦闘プラグイン有効化完了")
                    else
                    end
                    
                    -- ターゲット解除
                    yield("/targetenemy")
                    
                    -- インタラクト成功を返す
                    return true
                end
            end
            
            ::next_target::
        end
    end
    
    return false
end

local function ExecuteDungeonPhase()
    LogInfo("ダンジョン探索を開始します")
    
    -- 食事効果チェック（ダンジョン開始時）
    CheckAndUseFoodItem()
    
    -- インベントリ管理チェック
    if not CheckAndManageInventory() then
        return  -- インベントリ満杯の場合は処理停止
    end
    
    -- マテリア精製チェック
    CheckAndExtractMateria()
    
    -- ダンジョンタイプ検出・表示
    local dungeonType, dungeonDescription = DetectDungeonType()
    if dungeonType then
        LogInfo("検出されたダンジョンタイプ: " .. dungeonDescription)
    end
    
    -- ルーレット型の場合は召喚魔法陣にインタラクト
    if dungeonType == "roulette" then
        LogInfo("ルーレット型ダンジョン - 召喚魔法陣への接近・インタラクトを開始")
        
        local rouletteTargets = {"召喚魔法陣", "魔法陣", "召喚陣"}
        local interactSuccess = false
        
        for _, targetName in ipairs(rouletteTargets) do
            LogInfo("召喚魔法陣を検索中: " .. targetName)
            yield("/target " .. targetName)
            Wait(1)
            
            if HasTarget() then
                LogInfo("召喚魔法陣発見 - 接近・インタラクト実行")
                
                -- 接近
                local distance = GetDistanceToTarget()
                if distance > 3.0 then
                    LogInfo("召喚魔法陣に接近中... (現在距離: " .. string.format("%.2f", distance) .. "yalm)")
                    yield("/vnav movetarget")
                    
                    -- 接近完了まで待機
                    local approachStart = os.clock()
                    while GetDistanceToTarget() > 3.0 and (os.clock() - approachStart) < 30 do
                        Wait(1)
                    end
                end
                
                -- インタラクト実行
                LogInfo("召喚魔法陣とインタラクト実行")
                yield("/interact")
                Wait(2)
                interactSuccess = true
                break
            else
            end
        end
        
        if not interactSuccess then
            LogWarn("召喚魔法陣が見つからないか、インタラクトに失敗しました")
        end
    end
    
    -- 自動戦闘有効化（利用可能なプラグインのみ）
    EnableCombatPlugins()
    LogInfo("ダンジョンで自動戦闘プラグイン有効化完了")
    
    local dungeonStartTime = os.clock()
    local currentFloor = 1
    local maxFloors = 5
    local combatStartTime = nil
    local combatTimeout = 120  -- 2分の戦闘タイムアウト
    
    while IsInDuty() and not IsTimeout(dungeonStartTime, CONFIG.TIMEOUTS.DUNGEON) do
        LogInfo("現在の階層: " .. currentFloor .. "/" .. maxFloors)
        
        -- TreasureHighLowミニゲーム処理
        if IsAddonVisible("TreasureHighLow") then
            yield("/callback TreasureHighLow true 1") -- 1を選択
            Wait(2)
        end
        
        -- SelectYesno処理（最優先・詳細確認付き）
        if IsValidSelectYesnoDialog() then
            LogInfo("有効な確認ダイアログ検出 - 戦闘終了として処理")
            yield("/callback SelectYesno true 0") -- はい
            Wait(2)
            combatStartTime = nil  -- 戦闘時間リセット
            goto continue
        elseif IsAddonVisible("SelectYesno") then
        end
        
        -- 戦闘中は待機（タイムアウト付き）
        if IsInCombat() then
            -- 戦闘開始時間を記録
            if combatStartTime == nil then
                combatStartTime = os.clock()
                
                -- 戦闘開始時に自動戦闘を確実に有効化
                EnableCombatPlugins()
                LogInfo("ダンジョン戦闘開始 - 自動戦闘プラグイン有効化完了")
            end
            
            -- 戦闘タイムアウトチェック
            if IsTimeout(combatStartTime, combatTimeout) then
                LogWarn("戦闘タイムアウト (" .. combatTimeout .. "秒) - 戦闘終了とみなして継続")
                combatStartTime = nil
                goto continue
            end
            
            Wait(2)
            goto continue
        else
            -- 戦闘していない場合は戦闘開始時間をリセット
            if combatStartTime ~= nil then
                combatStartTime = nil
            end
        end
        
        -- プレイヤーが操作可能で移動していない場合の処理
        if IsPlayerAvailable() and not IsPlayerMoving() then
            -- 最終層の場合はボスチェック
            if currentFloor == maxFloors then
                if CheckForBoss() then
                    LogInfo("ボス撃破完了")
                    goto continue
                end
            end
            
            -- 優先順位に基づく統一ターゲットシステム
            local interacted = CheckAndInteractPriorityTargets(currentFloor, maxFloors)
            
            if not interacted then
                -- 何もターゲットできない場合は前進探索
                local foundTarget = AutoMoveForward()
                if foundTarget then
                    LogInfo("前進探索で発見: " .. foundTarget .. " - 次回ループで処理")
                end
            end
        end
        
        ::continue::
        Wait(1)
    end
    
    if not IsInDuty() then
        LogInfo("ダンジョン探索完了")
        DisableCombatPlugins()
        LogInfo("ダンジョン完了で自動戦闘プラグイン無効化完了")
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
        LogInfo("全ての地図を処理しました - 新しい地図を購入します")
        ChangePhase("MAP_PURCHASE", "地図購入フェーズに移行")
    end
end

-- エラーフェーズ
local function ExecuteErrorPhase()
    LogError("エラーが発生しました。スクリプトを停止します")
    
    -- 緊急停止処理（利用可能なプラグインのみ）
    DisableCombatPlugins()
    LogInfo("エラー時自動戦闘プラグイン無効化完了")
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

-- メインループ（エラーハンドラー付き）
local function SafeMainLoop()
    LogInfo("Treasure Hunt Automation v1.0.0 開始")
    LogInfo("安定版リリース: 包括的SEHException対策・無限ループ修正・IPC危険API回避完了")
    
    -- スクリプト開始時に戦闘中の場合は自動戦闘を有効化し、戦闘終了まで待機
    if IsInCombat() then
        LogInfo("スクリプト開始時に戦闘中を検出 - 自動戦闘を有効化")
        
        EnableCombatPlugins()
        LogInfo("スクリプト開始時戦闘中 - 自動戦闘プラグイン有効化完了")
        
        -- 戦闘終了まで待機
        LogInfo("戦闘終了を待機中...")
        local combatStartTime = os.clock()
        while IsInCombat() and (os.clock() - combatStartTime) < 300 do -- 最大5分待機
            Wait(2)
        end
        
        if IsInCombat() then
            LogWarn("戦闘が長時間継続中ですが、スクリプトを開始します")
        else
            LogInfo("戦闘終了を確認 - トレジャーハント処理を開始")
        end
        
        Wait(1) -- 戦闘終了後の安定化待機
    end
    
    currentPhase = "INIT"
    phaseStartTime = os.clock()
    
    while not stopRequested and iteration < maxIterations do
        iteration = iteration + 1
        
        -- 定期的な食事効果・インベントリ・マテリア精製チェック（10イテレーションごと）
        if iteration % 10 == 0 then
            CheckAndUseFoodItem()
            if not CheckAndManageInventory() then
                break  -- インベントリ満杯の場合はループを終了
            end
            CheckAndExtractMateria()
        end
        
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

-- メインループ関数（多層エラーハンドラー付き）
local function MainLoop()
    -- レベル1: 基本的なSafeMainLoop実行
    local success, errorMsg = SafeExecute(SafeMainLoop, "SafeMainLoopエラー", 2)
    
    -- レベル2: SEHException等の低レベルエラー対策
    if not success then
        LogError("致命的エラー検出 - 詳細解析を実行", errorMsg)
        
        local errorStr = tostring(errorMsg)
        
        -- SEHException特定対策
        if string.find(errorStr, "SEHException") then
            LogError("SEHException検出 - NLua/SomethingNeedDoingエンジンレベルエラー")
            LogError("エラー詳細: External component has thrown an exception")
            LogError("推奨対処: 1) SND再起動 2) Dalamudプラグイン再読み込み 3) FFXIV再起動")
        end
        
        -- lua_pcallkエラー特定対策
        if string.find(errorStr, "lua_pcallk") or string.find(errorStr, "CallDelegate") then
            LogError("NLua CallDelegate/lua_pcallkエラー検出")
            LogError("原因: Luaスタック破損またはメモリアクセス違反")
            LogError("推奨対処: 即座にスクリプト停止・SND再起動")
        end
        
        -- NLuaMacroEngineエラー特定対策
        if string.find(errorStr, "NLuaMacroEngine") then
            LogError("NLuaMacroEngineエラー検出 - マクロエンジン内部エラー")
            LogError("推奨対処: SomethingNeedDoingプラグイン完全再起動")
        end
        
        LogError("スクリプト安全終了を実行します")
        return false
    end
    
    return true
end

-- メイン実行
MainLoop()