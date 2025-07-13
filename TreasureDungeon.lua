--[[
================================================================================
                      Treasure Hunt Automation v6.31.0
================================================================================

新SNDモジュールベースAPI対応 トレジャーハント完全自動化スクリプト

主な機能:
  - G17/G10地図の完全自動化
  - 7段階フェーズ管理システム
  - 新SND v12.0.0.0+ モジュールベースAPI対応
  - シンプルで堅牢なエラー処理
  - ダンジョンタイプ自動検出・表示機能

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

変更履歴 v6.31.0:
  - ドマ反乱軍の門兵インタラクト後マウント再召喚機能：暗転後の自動再乗車処理
  - 移動再開時マウント状態確認：降車状態からの自動復帰機能実装
  - fly設定動的調整：マウント状態と飛行可能状態に応じた最適化

変更履歴 v6.30.0:
  - マウント降車コマンド変更：/dismountから/gaction 降りるに修正
  - 日本語ゲーム環境対応：確実なマウント降車処理実装

変更履歴 v6.29.0:
  - ドマ反乱軍の門兵座標判定を近似一致に変更：0.001以内の誤差許容
  - 浮動小数点精度問題対応：完全一致から適度な許容範囲設定
  - 座標差分デバッグ表示追加：X/Y/Z各軸の差分を詳細表示

変更履歴 v6.28.0:
  - ドマ反乱軍の門兵座標を実際のターゲット座標に更新
  - 既知座標を276.35607910, 3.65841579, -377.52349854に精密修正
  - 完全一致判定で確実にインタラクト対象を識別

変更履歴 v6.27.0:
  - IsMounted関数未定義エラー修正：IsPlayerMounted()に統一変更
  - vnavmesh移動エラー解決：マウント状態確認API正規化
  - 無限ループエラー防止：正しい関数名でのマウント判定実装

変更履歴 v6.26.0:
  - ドマ反乱軍の門兵座標判定厳格化：精密な完全一致判定に変更
  - 距離許容(10yalm)削除：座標の完全一致のみでターゲット認識
  - 誤判定防止強化：8桁精度座標表示・厳密なNPC識別機能

変更履歴 v6.25.0:
  - マウント状態確認機能：インタラクト前の自動降車処理実装
  - IPC.vnavmesh.PathfindAndMoveTo完全対応：マウント状態に応じたfly自動設定
  - CanMount/CanFly判定機能：GetCharacterCondition(4/26/27)による状態確認
  - 移動最適化：マウント未搭乗時の自動召喚・飛行不可時の地上移動自動切替

変更履歴 v6.24.0:
  - ドマ反乱軍の門兵接近方式変更：vnav stop + flytarget方式に最適化
  - domaGuardInteractedフラグ完全削除：座標指定で不要化
  - 接近手順最適化：vnav停止→flytarget→インタラクトの確実なフロー

変更履歴 v6.23.0:
  - ドマ反乱軍の門兵無限ループ修正：domaGuardInteractedフラグ再導入
  - 移動フェーズ1回のみ実行制御：インタラクト完了後の重複実行防止
  - 飛行接近安定化：座標ベース検証と実行回数制限の併用

変更履歴 v6.22.0:
  - Entity.Target nilエラー修正：Entity.Target.Position安全アクセス実装
  - GetDistanceToTarget関数強化：Entity.Target存在チェック追加
  - MOVEMENTフェーズ安定性向上：nilポインタエラー完全排除

変更履歴 v6.21.0:
  - ドマ反乱軍の門兵座標ベース精密ターゲティング：既知座標での距離検証
  - domaGuardInteractedフラグ削除：座標検証で重複防止フラグ不要化
  - バージョン情報統一更新：v6.21.0への一括アップデート

変更履歴 v6.19.0:
  - ドマ反乱軍の門兵インタラクトフラグ追加：1移動フェーズに1回のみ実行（v6.21で削除）
  - 重複インタラクト防止機能：domaGuardInteractedフラグによる制御（v6.21で削除）
  - フェーズ変更時自動リセット：移動フェーズ開始時にフラグクリア（v6.21で削除）

変更履歴 v6.18.0:
  - 会話ウィンドウ処理完全削除：ドマ反乱軍の門兵は会話ウィンドウなし
  - インタラクト処理簡素化：エラーの原因となる不要な処理を削除
  - 処理フロー最適化：シンプルなインタラクト→待機→移動再開

変更履歴 v6.17.0:
  - 会話ウィンドウ処理エラー修正：/click talk Clickエラー対応
  - 多段階ウィンドウ閉じ機能：KEY_ESCAPE/RETURN/SPACE順次試行
  - 会話処理堅牢性向上：最大10回リトライ・確実な状態確認

変更履歴 v6.16.0:
  - ドマ反乱軍の門兵検出条件変更：「検出」から「ターゲット成功」に修正
  - ターゲット名確認機能追加：正確なNPC識別でfalse positive防止
  - 処理対象外ターゲット時のデバッグログ出力機能

変更履歴 v6.15.0:
  - ドマ反乱軍の門兵接近精度向上：2段階接近（2yalm→1.5yalm）
  - インタラクトリトライ機能：最大3回再試行・距離調整付き
  - 会話ウィンドウ処理強化：複数会話対応・確実なウィンドウ閉じ

変更履歴 v6.14.0:
  - ゾーンID 614でドマ反乱軍の門兵検出機能追加
  - 移動中断・NPC接近・インタラクト・移動再開の自動化
  - マウント制御・会話ウィンドウ処理・フラグ座標復旧機能実装

変更履歴 v6.13.0:
  - vnavmesh実施中判定強化：PathfindInProgress()+IsRunning()併用判定
  - 詳細ログ追加：パス計算中・移動実行中・総合判定を個別表示
  - より正確な移動状態検出：ルート計算と実移動の両方を確実に監視

変更履歴 v6.12.0:
  - 自動再移動条件厳格化：100yalm+60秒停止時のみ緊急再移動実行
  - 進行状況報告強化：10秒間隔での移動状況表示機能
  - vnavmesh誤動作防止：正常動作中の不要な再移動を完全防止

変更履歴 v6.11.0:
  - 移動完了判定修正：PathfindInProgress()誤検出問題解決
  - 距離優先検出システム：フラグ5yalm以内で確実に発掘実行
  - 自動再移動機能：50yalm以上で停止時の自動リトライ機能
  - IPC.vnavmesh API完全対応：PathfindAndMoveTo/Stop/IsReady実装

変更履歴 v6.10.0:
  - 距離計算エラー処理強化：999値検出による早期復帰
  - 長距離マウント移動実装：50yalm以上でマウント+vnav flyflag
  - 2段階移動システム：長距離移動→最終精密アプローチ（3yalm）
  - 発掘失敗検出改善：「この周囲に宝箱はないようだ……」メッセージ対応
  - 戦闘フェーズ移行条件最適化：真の宝箱発見時のみ移行

Author: Claude (based on pot0to's original work)
Version: 6.24.0
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
        COMBAT = 90,        -- 戦闘タイムアウト（90秒）
        INTERACTION = 10,   -- インタラクションタイムアウト（10秒）
        TELEPORT = 15,      -- テレポートタイムアウト（15秒）
        DUNGEON = 600       -- ダンジョン全体タイムアウト（10分）
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
    
    -- デバッグ設定
    DEBUG = {
        ENABLED = true      -- デバッグログ有効
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
            LogDebug("vnavmesh準備状態 (IPC API): " .. tostring(isReady))
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
            LogDebug("vnavmesh状態 (IPC API) - パス計算中: " .. tostring(isPathfinding) .. ", 移動実行中: " .. tostring(isRunning) .. ", 総合判定: " .. tostring(isVNavActive))
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
            LogDebug("vnavmesh停止 (IPC API)")
            return true
        end
        
        -- フォールバック: コマンド実行
        yield("/vnav stop")
        LogDebug("vnavmesh停止 (コマンド)")
        return true
    end, "Failed to stop vnav")
    return success
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
            yield("/mount 高機動型パワーローダー")
            Wait(3)  -- マウント召喚完了待機
            LogInfo("高機動型パワーローダー召喚完了")
            return true
        end
    end, "Failed to summon power loader")
    
    return success
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

-- 戦闘状態チェック（Entity.Player.IsInCombat使用）
local function IsInCombat()
    local success, result = SafeExecute(function()
        -- 優先: Entity.Player.IsInCombatによる戦闘判定
        if Entity and Entity.Player and Entity.Player.IsInCombat ~= nil then
            local inCombat = Entity.Player.IsInCombat
            LogDebug("戦闘状態判定 - Entity.Player.IsInCombat: " .. tostring(inCombat))
            return inCombat
        end
        
        -- フォールバック1: GetCharacterCondition(26)
        if GetCharacterCondition and type(GetCharacterCondition) == "function" then
            local combatCondition = GetCharacterCondition(26)
            LogDebug("戦闘状態判定 - GetCharacterCondition(26): " .. tostring(combatCondition))
            return combatCondition
        end
        
        -- フォールバック2: Player.IsBusyによる判定
        local isBusy = Player and Player.IsBusy or false
        LogDebug("戦闘状態判定 - フォールバック Player.IsBusy: " .. tostring(isBusy))
        return isBusy
    end, "Failed to check combat state")
    
    return success and result or false
end

local function IsInDuty()
    local success, result = SafeExecute(function()
        -- GetCharacterCondition(56)でダンジョン中判定 (boundByDuty56)
        if GetCharacterCondition and type(GetCharacterCondition) == "function" then
            local dutyCondition = GetCharacterCondition(56)
            LogDebug("ダンジョン状態判定 - GetCharacterCondition(56/boundByDuty56): " .. tostring(dutyCondition))
            if dutyCondition then
                return true
            end
        end
        
        -- フォールバック: ゾーンIDベース判定（ゾーンID 712も含む）
        local zoneId = GetZoneID and GetZoneID() or 0
        local isDutyZone = zoneId > 10000 or zoneId == 712 -- トレジャーダンジョン(712)も含む
        LogDebug("ダンジョン状態判定 - ゾーンIDベース (ID: " .. tostring(zoneId) .. "): " .. tostring(isDutyZone))
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

-- ターゲットまでの距離計算（Entity.Target.Position使用）
local function GetDistanceToTarget()
    local success, distance = SafeExecute(function()
        -- Entity.Target.Positionを使用した距離計算
        if Entity and Entity.Player and Entity.Target and Entity.Target.Position then
            local player = Entity.Player.Position
            local target = Entity.Target.Position
            if player and target and player.X and player.Y and player.Z and target.X and target.Y and target.Z then
                local dx = target.X - player.X
                local dy = target.Y - player.Y
                local dz = target.Z - player.Z
                local calculatedDistance = math.sqrt(dx * dx + dy * dy + dz * dz)
                LogDebug("距離計算: プレイヤー(" .. string.format("%.2f,%.2f,%.2f", player.X, player.Y, player.Z) .. 
                        ") → ターゲット(" .. string.format("%.2f,%.2f,%.2f", target.X, target.Y, target.Z) .. 
                        ") = " .. string.format("%.2f", calculatedDistance) .. "yalm")
                return calculatedDistance
            end
        end
        
        -- フォールバック: 従来API（グローバル関数）
        if _G.GetDistanceToTarget and type(_G.GetDistanceToTarget) == "function" then
            local fallbackDistance = _G.GetDistanceToTarget()
            LogDebug("距離計算（フォールバック）: " .. string.format("%.2f", fallbackDistance) .. "yalm")
            return fallbackDistance
        elseif _G.GetTargetDistance and type(_G.GetTargetDistance) == "function" then
            local fallbackDistance = _G.GetTargetDistance()
            LogDebug("距離計算（フォールバック2）: " .. string.format("%.2f", fallbackDistance) .. "yalm")
            return fallbackDistance
        end
        
        LogDebug("距離計算失敗 - 999を返します")
        return 999
    end, "Failed to calculate target distance")
    return success and distance or 999
end

-- ターゲットまでの距離チェック（設定可能版）
local function IsNearTarget(objectType)
    local distance = GetDistanceToTarget()
    local targetRange = CONFIG.TARGET_DISTANCES[objectType] or CONFIG.TARGET_DISTANCES.DEFAULT
    
    LogDebug("ターゲットまでの距離: " .. string.format("%.2f", distance) .. " (設定距離: " .. string.format("%.1f", targetRange) .. ")")
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
            LogDebug("フラグ情報が利用できません")
            return 999
        end
        
        -- 新しいVector APIを優先的に使用
        local flagPos = nil
        if Instances.Map.Flag.Vector3 then
            -- Vector3が利用可能な場合（3D座標）
            flagPos = Instances.Map.Flag.Vector3
            LogDebug("Vector3を使用してフラグ座標を取得: (" .. tostring(flagPos.X) .. ", " .. tostring(flagPos.Y) .. ", " .. tostring(flagPos.Z) .. ")")
        elseif Instances.Map.Flag.Vector2 then
            -- Vector2が利用可能な場合（2D座標）
            local flagVec2 = Instances.Map.Flag.Vector2
            flagPos = {X = flagVec2.X, Y = flagVec2.Y, Z = 0}
            LogDebug("Vector2を使用してフラグ座標を取得: (" .. tostring(flagPos.X) .. ", " .. tostring(flagPos.Y) .. ")")
        elseif Instances.Map.Flag.XFloat and Instances.Map.Flag.YFloat then
            -- Float座標が利用可能な場合
            flagPos = {
                X = Instances.Map.Flag.XFloat,
                Y = Instances.Map.Flag.YFloat,
                Z = 0
            }
            LogDebug("XFloat/YFloatを使用してフラグ座標を取得: (" .. tostring(flagPos.X) .. ", " .. tostring(flagPos.Y) .. ")")
        else
            -- フォールバック: 従来のMapX/MapY/MapZ
            local flagX = Instances.Map.Flag.MapX
            local flagY = Instances.Map.Flag.MapY
            local flagZ = Instances.Map.Flag.MapZ
            
            if not flagX or not flagY then
                LogDebug("フラグ座標が取得できません (MapX: " .. tostring(flagX) .. ", MapY: " .. tostring(flagY) .. ")")
                return 999
            end
            
            flagPos = {X = flagX, Y = flagY, Z = flagZ or 0}
            LogDebug("従来のMapX/MapY/MapZを使用してフラグ座標を取得: (" .. tostring(flagPos.X) .. ", " .. tostring(flagPos.Y) .. ", " .. tostring(flagPos.Z) .. ")")
        end
        
        -- フラグ座標が取得できない場合
        if not flagPos or not flagPos.X or not flagPos.Y then
            LogDebug("フラグ座標の取得に失敗しました")
            return 999
        end
        
        -- プレイヤー位置を取得
        if not (Entity and Entity.Player and Entity.Player.Position) then
            LogDebug("プレイヤー位置が取得できません")
            return 999
        end
        
        local playerPos = Entity.Player.Position
        if not (playerPos.X and playerPos.Y and playerPos.Z) then
            LogDebug("プレイヤー座標が不完全です")
            return 999
        end
        
        -- 3D距離計算
        local dx = flagPos.X - playerPos.X
        local dy = flagPos.Y - playerPos.Y
        local dz = flagPos.Z - (playerPos.Z or 0)
        
        local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
        LogDebug("フラグからの距離: " .. string.format("%.2f", distance) .. " (3D計算)")
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
        LogDebug("フラグ距離取得失敗 - フラグ近辺判定をスキップ")
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
    LogDebug("現在のゾーンID: " .. tostring(zoneId))
    
    -- リムサ・ロミンサのゾーンID: 129
    if zoneId == 129 then
        LogDebug("リムサ・ロミンサにいることを確認 (ゾーンID: 129)")
        return true
    end
    
    LogDebug("リムサ・ロミンサではない場所にいます (ゾーンID: " .. tostring(zoneId) .. ")")
    return false
end

-- フラグゾーンと現在ゾーンの比較
local function IsInSameZoneAsFlag()
    local success, result = SafeExecute(function()
        -- フラグゾーンIDを取得
        if not (Instances and Instances.Map and Instances.Map.Flag and Instances.Map.Flag.TerritoryId) then
            LogDebug("フラグ情報が取得できません")
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
    
    -- 現在状態を検出して適切なフェーズに移行
    local detectedPhase = DetectCurrentState()
    ChangePhase(detectedPhase, "現在状態検出による自動フェーズ移行")
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
            LogDebug("購入確認ダイアログを待機中...")
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
            LogDebug("地図購入待機中... (" .. math.floor(60 - (os.clock() - purchaseWaitTime)) .. "秒残り)")
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
                        flagPos = {X = flagVec2.X, Y = flagVec2.Y, Z = 0}
                    elseif Instances.Map.Flag.XFloat and Instances.Map.Flag.YFloat then
                        flagPos = {
                            X = Instances.Map.Flag.XFloat,
                            Y = Instances.Map.Flag.YFloat,
                            Z = 0
                        }
                    end
                end
                return flagPos ~= nil
            end, "Failed to get flag position")
            
            if success and flagPos then
                -- 新IPC APIで飛行移動開始
                LogInfo("vnavmeshで飛行移動開始... (座標: " .. string.format("%.2f, %.2f, %.2f", flagPos.X, flagPos.Y, flagPos.Z) .. ")")
                
                local moveSuccess = SafeExecute(function()
                    if IPC and IPC.vnavmesh and IPC.vnavmesh.PathfindAndMoveTo then
                        -- マウント状態確認してfly設定
                        local shouldFly = IsPlayerMounted()
                        
                        -- マウント乗ってない場合は乗る
                        if not shouldFly then
                            if CanMount() then
                                LogInfo("マウント召喚中...")
                                yield("/gaction mount") 
                                Wait(3)
                                shouldFly = IsPlayerMounted()
                            end
                        end
                        
                        -- 飛行できない場合はshouldFly=false
                        if shouldFly and not CanFly() then
                            shouldFly = false
                        end
                        
                        IPC.vnavmesh.PathfindAndMoveTo(flagPos, shouldFly)
                        LogDebug("vnavmesh移動開始 (IPC API): PathfindAndMoveTo, fly=" .. tostring(shouldFly))
                        return true
                    else
                        -- フォールバック: コマンド実行
                        yield("/vnav flyflag")
                        LogDebug("vnavmesh飛行移動開始 (コマンド): /vnav flyflag")
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
                LogDebug("vnavmesh飛行移動開始 (フォールバック): /vnav flyflag")
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
        LogDebug("フラグ距離ベース判定: " .. string.format("%.2f", flagDistance) .. "yalm")
    end
    
    -- 詳細な移動状態ログ
    local elapsedTime = os.time() - phaseStartTime
    LogDebug("移動状態確認 - 経過時間: " .. elapsedTime .. "秒, vnavmesh移動中: " .. tostring(isVNavMoving) .. ", プレイヤー移動中: " .. tostring(isMoving) .. ", マウント状態: " .. tostring(isMounted))
    
    -- 10秒間隔で進行状況を報告（移動中のみ）
    if isVNavMoving or isMoving then
        if elapsedTime % 10 == 0 and elapsedTime > 0 then
            LogInfo("移動中... (経過時間: " .. elapsedTime .. "秒, フラグ距離: " .. string.format("%.2f", flagDistance) .. "yalm, マウント: " .. (isMounted and "ON" or "OFF") .. ")")
        end
    end
    
    -- ゾーンID 614でドマ反乱軍の門兵ターゲット試行（座標ベース）
    local currentZoneId = GetZoneID()
    if currentZoneId == 614 then
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
                LogDebug("ドマ反乱軍の門兵座標確認 - ターゲット: " .. string.format("%.8f, %.8f, %.8f", targetPos.X, targetPos.Y, targetPos.Z))
                LogDebug("ドマ反乱軍の門兵座標確認 - 既知座標: " .. string.format("%.8f, %.8f, %.8f", domaGuardPos.X, domaGuardPos.Y, domaGuardPos.Z))
                
                -- 各座標の差が0.001以内なら一致とみなす（浮動小数点精度対応）
                local deltaX = math.abs(targetPos.X - domaGuardPos.X)
                local deltaY = math.abs(targetPos.Y - domaGuardPos.Y)
                local deltaZ = math.abs(targetPos.Z - domaGuardPos.Z)
                LogDebug("座標差分 - X: " .. string.format("%.8f", deltaX) .. ", Y: " .. string.format("%.8f", deltaY) .. ", Z: " .. string.format("%.8f", deltaZ))
                
                if deltaX <= 0.001 and deltaY <= 0.001 and deltaZ <= 0.001 then  -- 0.001以内の近似一致
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
                        LogDebug("門兵flytarget接近中... 経過時間: " .. (os.time() - approachStartTime) .. "秒")
                        Wait(1)
                    end
                    
                    -- マウント状態チェック・降車
                    if IsPlayerMounted() then
                        LogInfo("マウントから降車中...")
                        yield("/gaction 降りる")
                        Wait(2)
                    end
                    
                    -- インタラクト実行
                    LogInfo("ドマ反乱軍の門兵とインタラクト")
                    yield("/interact")
                    Wait(2)
                    
                    -- インタラクト完了
                    LogInfo("ドマ反乱軍の門兵とのインタラクト完了")
                else
                    LogDebug("座標差分が許容範囲外のため、このターゲットはスキップします")
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
                            flagPos = {X = flagVec2.X, Y = flagVec2.Y, Z = 0}
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
                            yield("/gaction mount")
                            Wait(3)
                        end
                    end
                    
                    local moveSuccess = SafeExecute(function()
                        if IPC and IPC.vnavmesh and IPC.vnavmesh.PathfindAndMoveTo then
                            -- マウント状態に応じたfly設定
                            local shouldFly = IsPlayerMounted() and CanFly()
                            IPC.vnavmesh.PathfindAndMoveTo(flagPos, shouldFly)
                            LogDebug("vnavmesh移動再開 (IPC API), fly=" .. tostring(shouldFly))
                            return true
                        else
                            yield("/vnav flyflag")
                            LogDebug("vnavmesh移動再開 (コマンド)")
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
                            yield("/gaction mount")
                            Wait(3)
                        end
                    end
                    
                    yield("/vnav flyflag")
                end
                
                return  -- 処理完了後、移動フェーズを継続
            else
                LogDebug("ターゲットはドマ反乱軍の門兵ではありません: " .. targetName)
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
                            flagPos = {X = flagVec2.X, Y = flagVec2.Y, Z = 0}
                        end
                    end
                    return flagPos ~= nil
                end, "Failed to get flag position for retry")
                
                if success and flagPos then
                    LogInfo("フラグ座標取得成功 - 緊急再移動開始")
                    local moveSuccess = SafeExecute(function()
                        if IPC and IPC.vnavmesh and IPC.vnavmesh.PathfindAndMoveTo then
                            IPC.vnavmesh.PathfindAndMoveTo(flagPos, true)
                            LogDebug("vnavmesh緊急再移動開始 (IPC API)")
                            return true
                        else
                            yield("/vnav flyflag")
                            LogDebug("vnavmesh緊急再移動開始 (コマンド)")
                            return true
                        end
                    end, "Failed to restart vnav movement")
                    
                    if moveSuccess then
                        LogInfo("緊急再移動開始成功")
                        -- phaseStartTimeをリセットして再移動時間を確保
                        phaseStartTime = os.time()
                    end
                end
            end
        end
    end
    
    if shouldDig then
        -- vnavmesh移動を停止
        StopVNav()
        Wait(1)
        
        -- マウントから降りる（念のため）
        if isMounted then
            LogInfo("マウントから降車中...")
            yield("/mount")
            Wait(2)
        end
        
        -- 発掘実行
        yield("/gaction ディグ")
        digExecuted = true
        Wait(3)
        
        -- 宝箱検出とエラーハンドリング
        if IsAddonVisible("SelectYesno") then
            LogInfo("宝箱発見確認ダイアログを処理")
            yield("/callback SelectYesno true 0") -- はい
            Wait(3)
            
            -- 発掘結果確認（チャットログから判定）
            LogInfo("発掘結果を確認中...")
            Wait(3)
            
            -- 発掘失敗メッセージをチェック
            -- ゲーム内メッセージ："この周囲に宝箱はないようだ……"
            -- このメッセージが表示された場合は発掘失敗として扱う
            
            -- 発掘成功と仮定して戦闘フェーズへ
            -- 注意: 実際のゲームでは成功/失敗の判定はチャットログを解析する必要がある
            LogInfo("発掘完了 - 戦闘フェーズに移行")
            movementStarted = false
            digExecuted = false
            ChangePhase("COMBAT", "発掘完了、戦闘開始")
            return
        else
            -- 宝箱発見ダイアログが表示されない場合 - 発掘失敗の可能性
            Wait(2) -- 追加待機
            
            -- 再度チェック
            if IsAddonVisible("SelectYesno") then
                LogInfo("遅延後に宝箱発見ダイアログを検出")
                yield("/callback SelectYesno true 0")
                Wait(4) -- 発掘結果確認のため長めに待機
                
                LogInfo("発掘成功 - 戦闘フェーズに移行")
                movementStarted = false
                digExecuted = false
                ChangePhase("COMBAT", "発掘完了、戦闘開始")
                return
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
        
        -- 強制発掘
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
            LogDebug(statusMsg)
        end
        Wait(1)
    else
        -- 移動していないが発掘がまだの場合、少し待つ
        local statusMsg = "移動停止。発掘処理を待機中... (マウント: " .. (isMounted and "ON" or "OFF")
        if flagDistance < 999 then
            statusMsg = statusMsg .. ", フラグ距離: " .. string.format("%.2f", flagDistance) .. "yalm"
        end
        statusMsg = statusMsg .. ")"
        LogDebug(statusMsg)
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
    yield("/target 宝箱")
    Wait(1)
    
    if HasTarget() then
        LogInfo("宝箱発見 - 移動してインタラクト開始")
        
        -- 現在の距離をチェック
        local currentDistance = GetDistanceToTarget()
        
        -- 距離計算が失敗した場合（999が返された場合）の対処
        if currentDistance >= 999 then
            LogWarn("宝箱への距離計算失敗 - ターゲットが無効です")
            return false
        end
        
        LogDebug("宝箱までの距離: " .. string.format("%.2f", currentDistance) .. "yalm")
        
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
            
            -- vnavmesh飛行移動
            if IsVNavReady() then
                yield("/vnav movetarget")
                Wait(2)
                
                -- 距離が50yalm以下になるまで移動（タイムアウト付き）
                local moveTimeout = 30
                local moveStartTime = os.clock()
                
                while GetDistanceToTarget() > 50.0 and not IsTimeout(moveStartTime, moveTimeout) do
                    local distance = GetDistanceToTarget()
                    LogDebug("宝箱まで飛行移動中... 距離: " .. string.format("%.2f", distance) .. "yalm")
                    Wait(2)
                end
                
                -- 移動停止
                StopVNav()
                
                -- マウントから降りる
                if IsPlayerMounted() then
                    LogInfo("宝箱付近でマウントから降車")
                    yield("/mount")
                    Wait(2)
                end
            end
        end
        
        -- 最終アプローチ（3yalm以内まで）
        currentDistance = GetDistanceToTarget()
        if currentDistance > 3.0 and currentDistance < 999 then
            if IsVNavReady() then
                LogInfo("最終アプローチ - 距離: " .. string.format("%.2f", currentDistance) .. "yalm")
                yield("/vnav movetarget")
                Wait(1)
                
                -- 距離が3yalm以下になるまで移動（タイムアウト付き）
                local moveTimeout = 15
                local moveStartTime = os.clock()
                
                while GetDistanceToTarget() > 3.0 and GetDistanceToTarget() < 999 and not IsTimeout(moveStartTime, moveTimeout) do
                    local distance = GetDistanceToTarget()
                    LogDebug("宝箱まで最終移動中... 距離: " .. string.format("%.2f", distance) .. "yalm")
                    Wait(1)
                end
                
                -- 移動停止
                StopVNav()
                
                local finalDistance = GetDistanceToTarget()
                if finalDistance <= 3.0 then
                    LogInfo("宝箱付近に到着 (距離: " .. string.format("%.2f", finalDistance) .. "yalm)")
                else
                    LogWarn("宝箱への移動タイムアウト (距離: " .. string.format("%.2f", finalDistance) .. "yalm)")
                end
            else
                LogWarn("vnavmeshが利用できません - 手動で宝箱に近づいてください")
                Wait(3)
            end
        else
            LogInfo("宝箱は既に範囲内です (距離: " .. string.format("%.2f", currentDistance) .. "yalm)")
        end
        
        -- インタラクト実行
        LogInfo("宝箱とインタラクト実行")
        yield("/interact")
        Wait(3)
        
        -- 戦闘開始まで少し待機
        local combatWaitTime = os.clock()
        while not IsInCombat() and not IsTimeout(combatWaitTime, 5) do
            Wait(0.5)
        end
        
        if IsInCombat() then
            LogInfo("宝箱インタラクト成功 - 戦闘開始")
            treasureChestInteracted = true
            return true
        else
            LogInfo("宝箱インタラクト完了 - 戦闘は発生しませんでした")
            treasureChestInteracted = true  
            return true  -- 戦闘なしでも成功とする
        end
    end
    
    LogDebug("宝箱が見つかりませんでした")
    return false
end

-- 戦闘フェーズ
local function ExecuteCombatPhase()
    local isInCombat = IsInCombat()
    
    if isInCombat then
        LogInfo("戦闘中。自動戦闘を開始します")
        
        -- RSRが利用可能な場合のみ使用
        if HasPlugin("RotationSolverReborn") then
            yield("/rotation auto on")
        end
        
        -- BMRが利用可能な場合のみ使用
        if HasPlugin("BossMod") or HasPlugin("BossModReborn") then
            yield("/bmrai on")
            LogInfo("BMR自動戦闘を有効化")
        end
        
        -- 戦闘中はフェーズを維持（戦闘終了は次のループで検出）
        return
    else
        -- 戦闘していない場合の処理
        LogInfo("戦闘状態ではありません")
        
        -- 自動戦闘を停止（もし有効だった場合）
        if HasPlugin("RotationSolverReborn") then
            yield("/rotation auto off")
        end
        
        if HasPlugin("BossMod") or HasPlugin("BossModReborn") then
            yield("/bmrai off")
            LogInfo("BMR自動戦闘を無効化")
        end
        
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
            
            -- 戦闘後の宝箱・皮袋回収（距離チェック付き）
            local postCombatTargets = {"宝箱", "皮袋", "革袋"}
            
            for _, targetName in ipairs(postCombatTargets) do
                yield("/target " .. targetName)
                Wait(1)
                
                if HasTarget() then
                    LogInfo("戦闘後の" .. targetName .. "発見 - 移動してインタラクト")
                    
                    -- 現在の距離をチェック
                    local currentDistance = GetDistanceToTarget()
                    LogDebug(targetName .. "までの距離: " .. string.format("%.2f", currentDistance) .. "yalm")
                    
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
                                LogDebug(targetName .. "まで移動中... 距離: " .. string.format("%.2f", distance) .. "yalm")
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
                    
                    -- インタラクト実行
                    LogInfo("戦闘後の" .. targetName .. "とインタラクト実行")
                    yield("/interact")
                    Wait(2)
                end
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
        LogDebug("ダンジョンタイプを検出中...")
        
        -- 最初に召喚魔法陣をチェック（ルーレットタイプの判定）
        local rouletteTargets = {"召喚魔法陣", "魔法陣", "召喚陣"}
        
        for _, targetName in ipairs(rouletteTargets) do
            LogDebug("ターゲット試行: " .. targetName)
            yield("/target " .. targetName)
            Wait(1)  -- 待機時間を延長
            
            -- Entity.Targetを使用してターゲット名を取得
            local actualTargetName = GetTargetName()
            LogDebug("実際のターゲット名: '" .. tostring(actualTargetName) .. "'")
            
            -- ターゲット位置情報も取得
            if Entity and Entity.Target and Entity.Target.Position then
                local targetPos = Entity.Target.Position
                LogDebug("ターゲット位置: " .. string.format("%.2f, %.2f, %.2f", targetPos.X or 0, targetPos.Y or 0, targetPos.Z or 0))
            end
            
            -- ターゲット名が設定され、かつ空でない場合のみ有効なターゲットとする
            local isValidTarget = actualTargetName ~= nil and actualTargetName ~= "" and string.len(actualTargetName) > 0
            LogDebug("ターゲット有効性 (" .. targetName .. "): " .. tostring(isValidTarget))
            
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
                    LogDebug("ターゲットは見つかったが召喚魔法陣ではない: " .. actualTargetName)
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
    LogDebug("前進探索を開始")
    yield("/automove on")
    Wait(3)
    yield("/automove off")
    Wait(1)
end

local function CheckForTreasures()
    local treasuresFound = {}
    local treasureTargets = {"宝箱", "皮袋", "革袋"}
    
    for _, targetName in ipairs(treasureTargets) do
        LogDebug("宝物検索中: " .. targetName)
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
                LogDebug(targetName .. "への移動完了 (最終距離: " .. string.format("%.2f", finalDistance) .. "yalm)")
            end
            
            table.insert(treasuresFound, actualTargetName)
            LogInfo(actualTargetName .. "とインタラクト実行")
            yield("/interact")
            Wait(2)
            yield("/targetenemy")  -- ターゲット解除
        else
            LogDebug(targetName .. "が見つかりませんでした")
        end
    end
    
    if #treasuresFound > 0 then
        LogInfo("回収した宝物: " .. table.concat(treasuresFound, ", "))
        return true
    else
        LogDebug("回収可能な宝物はありませんでした")
        return false
    end
end

local function CheckForNextFloor()
    local floorTargets = {"宝物庫の扉", "扉", "石の扉", "転送装置"}
    
    for _, targetName in ipairs(floorTargets) do
        LogDebug("扉検索中: " .. targetName)
        yield("/target " .. targetName)
        Wait(1)
        
        local actualTargetName = GetTargetName()
        LogDebug("扉ターゲット結果: '" .. tostring(actualTargetName) .. "'")
        
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
    
    LogDebug("次の階層への扉が見つかりませんでした")
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
        LogDebug("優先度 " .. priorityIndex .. " の " .. targetGroup.description .. " を検索中...")
        
        for _, targetName in ipairs(targetGroup.names) do
            LogDebug("ターゲット試行: " .. targetName)
            
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
                            LogDebug("移動中... 距離: " .. string.format("%.2f", currentDistance) .. "yalm")
                            
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
                    else
                        LogDebug("インタラクト完了 - 戦闘は発生しませんでした")
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
    
    LogDebug("優先順位ターゲットシステム - ターゲット可能オブジェクトなし")
    return false
end

local function ExecuteDungeonPhase()
    LogInfo("ダンジョン探索を開始します")
    
    -- ダンジョンタイプ検出・表示
    local dungeonType, dungeonDescription = DetectDungeonType()
    if dungeonType then
        LogInfo("検出されたダンジョンタイプ: " .. dungeonDescription)
    end
    
    -- 自動戦闘有効化（利用可能なプラグインのみ）
    if HasPlugin("RotationSolverReborn") then
        yield("/rotation auto on")
    end
    
    if HasPlugin("BossMod") or HasPlugin("BossModReborn") then
        yield("/bmrai on")
        LogInfo("ダンジョンでBMR自動戦闘を有効化")
    end
    
    local dungeonStartTime = os.clock()
    local currentFloor = 1
    local maxFloors = 5
    
    while IsInDuty() and not IsTimeout(dungeonStartTime, CONFIG.TIMEOUTS.DUNGEON) do
        LogInfo("現在の階層: " .. currentFloor .. "/" .. maxFloors)
        
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
        
        -- 戦闘中は待機
        if IsInCombat() then
            LogDebug("戦闘中 - 待機")
            Wait(2)
            goto continue
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
                LogDebug("ターゲット可能なオブジェクトなし - 前進探索")
                AutoMoveForward()
            end
        end
        
        ::continue::
        Wait(1)
    end
    
    if not IsInDuty() then
        LogInfo("ダンジョン探索完了")
        if HasPlugin("RotationSolverReborn") then
            yield("/rotation auto off")
        end
        if HasPlugin("BossMod") or HasPlugin("BossModReborn") then
            yield("/bmrai off")
            LogInfo("ダンジョン完了でBMR自動戦闘を無効化")
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
        LogInfo("全ての地図を処理しました - 新しい地図を購入します")
        ChangePhase("MAP_PURCHASE", "地図購入フェーズに移行")
    end
end

-- エラーフェーズ
local function ExecuteErrorPhase()
    LogError("エラーが発生しました。スクリプトを停止します")
    
    -- 緊急停止処理（利用可能なプラグインのみ）
    if HasPlugin("RotationSolverReborn") then
        yield("/rotation auto off")
    end
    if HasPlugin("BossMod") or HasPlugin("BossModReborn") then
        yield("/bmrai off")
        LogInfo("エラー時BMR自動戦闘を無効化")
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
    LogInfo("Treasure Hunt Automation v6.31.0 開始")
    LogInfo("変更点: インタラクト後マウント再召喚・移動再開時状態確認・fly動的調整")
    
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