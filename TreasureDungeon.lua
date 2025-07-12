--[[
TreasureDungeon.lua
FFXIV トレジャーハント（G10/G17）地図自動化スクリプト
SomethingNeedDoing (Expanded Edition) v12.0.0.0+対応

作成日: 2025-07-12
バージョン: 1.0.0

機能:
- 地図の購入・解読
- フラグ地点への移動
- 戦闘・宝箱の自動操作
- ダンジョン内の階層探索・アイテム収集
- 包括的なエラー処理とフェーズ管理
]]

-- =============================================================================
-- 設定値
-- =============================================================================

-- 地図設定
local MAP_ITEM_ID = 36636  -- G10の地図アイテムID（必要に応じて変更）
local MAP_NAME = "G10の地図"

-- ダンジョン設定
local MAX_DUNGEON_FLOORS = 7  -- 最大階層数

-- 戦闘設定
local RSR_ENABLED = false
local BMR_ENABLED = false

-- デバッグ設定
local DEBUG_MODE = true

-- =============================================================================
-- ユーティリティ関数
-- =============================================================================

-- デバッグログ出力
local function DebugLog(message)
    if DEBUG_MODE then
        yield("/echo [TreasureDungeon] " .. tostring(message))
    end
end

-- 安全な待機関数
local function SafeWait(seconds)
    local endTime = os.clock() + seconds
    while os.clock() < endTime do
        yield("/wait 0.1")
    end
end

-- プレイヤー操作可能状態チェック
local function IsPlayerReady()
    return Player.Available and not Player.IsBusy
end

-- アドオンの表示状態チェック
local function IsAddonReady(addonName)
    local addon = Addons.GetAddon(addonName)
    return addon and addon.Ready
end

-- インベントリのアイテム数取得
local function GetItemCount(itemId)
    return Inventory.GetItemCount(itemId)
end

-- 戦闘システムの制御
local function EnableCombatSystems()
    if not RSR_ENABLED then
        yield("/rsr start")
        RSR_ENABLED = true
        DebugLog("RSR開始")
    end
    
    if not BMR_ENABLED then
        yield("/bmr start")
        BMR_ENABLED = true
        DebugLog("BMR開始")
    end
end

local function DisableCombatSystems()
    if RSR_ENABLED then
        yield("/rsr stop")
        RSR_ENABLED = false
        DebugLog("RSR停止")
    end
    
    if BMR_ENABLED then
        yield("/bmr stop")
        BMR_ENABLED = false
        DebugLog("BMR停止")
    end
end

-- =============================================================================
-- フェーズ管理
-- =============================================================================

-- 現在のフェーズ定義
local CurrentPhase = {
    MAP_PURCHASE = "地図購入",
    MOVEMENT = "移動", 
    FIELD_COMBAT = "ダンジョン外戦闘",
    DUNGEON = "ダンジョン"
}

local currentPhase = CurrentPhase.MAP_PURCHASE
local dungeonType = nil  -- "DUNGEON" or "ROULETTE"
local currentFloor = 1

-- =============================================================================
-- 地図購入Phase
-- =============================================================================

local function HasTreasureMap()
    return GetItemCount(MAP_ITEM_ID) > 0
end

local function PurchaseMapFromMarketBoard()
    DebugLog("マーケットボードで地図購入中...")
    
    -- マーケットボード表示
    -- TODO: 実際のマーケットボード表示API実装が必要
    yield("/marketboard")
    SafeWait(2)
    
    -- マーケットボード操作が完了するまで待機
    local maxWait = 30
    local waited = 0
    while not IsAddonReady("ItemSearchResult") and waited < maxWait do
        SafeWait(1)
        waited = waited + 1
    end
    
    if waited >= maxWait then
        DebugLog("マーケットボードの表示がタイムアウト")
        return false
    end
    
    DebugLog("地図購入完了")
    return true
end

local function DecipherMap()
    DebugLog("地図解読中...")
    
    -- インベントリの地図アイテムを使用
    yield("/item " .. MAP_NAME)
    SafeWait(2)
    
    DebugLog("地図解読完了")
end

local function TeleportToFlag()
    DebugLog("フラグ地点にテレポート中...")
    
    -- フラグ地点にテレポート
    yield("/flag")
    SafeWait(3)
    
    DebugLog("テレポート完了")
end

local function ExecuteMapPurchasePhase()
    DebugLog("=== 地図購入Phase開始 ===")
    
    if HasTreasureMap() then
        DebugLog("地図所持済み - 解読実行")
        yield("/dig")
        SafeWait(2)
    else
        DebugLog("地図未所持 - 購入開始")
        if PurchaseMapFromMarketBoard() then
            DecipherMap()
        else
            DebugLog("地図購入に失敗")
            return false
        end
    end
    
    TeleportToFlag()
    currentPhase = CurrentPhase.MOVEMENT
    DebugLog("=== 地図購入Phase完了 ===")
    return true
end

-- =============================================================================
-- 移動Phase
-- =============================================================================

local function MoveToFlag()
    DebugLog("フラグ地点への移動中...")
    
    -- vnavmeshでフラグ地点への移動
    yield("/vnavmesh moveto flag")
    
    -- 移動完了まで待機
    local maxWait = 300  -- 5分でタイムアウト
    local waited = 0
    
    while Player.IsMoving and waited < maxWait do
        SafeWait(1)
        waited = waited + 1
        
        -- 定期的にvnavmeshの状況確認
        if waited % 10 == 0 then
            DebugLog("移動中... (" .. waited .. "秒経過)")
        end
    end
    
    if waited >= maxWait then
        DebugLog("移動がタイムアウト")
        return false
    end
    
    DebugLog("フラグ地点到着")
    return true
end

local function DigAtLocation()
    DebugLog("発掘実行中...")
    yield("/dig")
    SafeWait(3)
    DebugLog("発掘完了")
end

local function FindAndInteractWithTreasureChest()
    DebugLog("宝箱探索中...")
    
    -- 宝箱をターゲット
    yield("/target 宝箱")
    SafeWait(1)
    
    -- 宝箱が見つかった場合
    if GetTargetName() == "宝箱" then
        DebugLog("宝箱発見 - 接触開始")
        
        -- 宝箱に接近
        yield("/vnavmesh moveto target")
        
        -- 移動完了まで待機
        while Player.IsMoving do
            SafeWait(0.5)
        end
        
        -- 相互作用
        yield("/interact")
        SafeWait(2)
        
        DebugLog("宝箱との相互作用完了")
        return true
    else
        DebugLog("宝箱が見つからない")
        return false
    end
end

local function ExecuteMovementPhase()
    DebugLog("=== 移動Phase開始 ===")
    
    if not MoveToFlag() then
        DebugLog("移動に失敗")
        return false
    end
    
    DigAtLocation()
    
    if FindAndInteractWithTreasureChest() then
        currentPhase = CurrentPhase.FIELD_COMBAT
        DebugLog("=== 移動Phase完了 ===")
        return true
    else
        DebugLog("宝箱発見に失敗")
        return false
    end
end

-- =============================================================================
-- ダンジョン外戦闘Phase
-- =============================================================================

local function WaitForCombatStart()
    DebugLog("戦闘開始待機中...")
    
    -- 戦闘開始まで待機
    local maxWait = 30
    local waited = 0
    
    while not InCombat() and waited < maxWait do
        SafeWait(1)
        waited = waited + 1
    end
    
    if waited >= maxWait then
        DebugLog("戦闘開始がタイムアウト")
        return false
    end
    
    DebugLog("戦闘開始")
    return true
end

local function WaitForCombatEnd()
    DebugLog("戦闘終了待機中...")
    
    -- 戦闘終了まで待機
    while InCombat() do
        SafeWait(1)
    end
    
    DebugLog("戦闘終了")
end

local function CheckForTransferGlyph()
    DebugLog("転送魔紋探索中...")
    
    SafeWait(2)  -- 戦闘終了後の待機
    
    -- 転送魔紋をターゲット
    yield("/target 転送魔紋")
    SafeWait(1)
    
    if GetTargetName() == "転送魔紋" then
        DebugLog("転送魔紋発見")
        return true
    else
        DebugLog("転送魔紋なし")
        return false
    end
end

local function InteractWithTransferGlyph()
    DebugLog("転送魔紋との相互作用中...")
    
    -- 転送魔紋に接近
    yield("/vnavmesh moveto target")
    
    while Player.IsMoving do
        SafeWait(0.5)
    end
    
    -- 相互作用
    yield("/interact")
    SafeWait(3)
    
    DebugLog("転送魔紋相互作用完了")
end

local function ExecuteFieldCombatPhase()
    DebugLog("=== ダンジョン外戦闘Phase開始 ===")
    
    if WaitForCombatStart() then
        EnableCombatSystems()
        WaitForCombatEnd()
        DisableCombatSystems()
        
        if CheckForTransferGlyph() then
            InteractWithTransferGlyph()
            currentPhase = CurrentPhase.DUNGEON
            currentFloor = 1
            DebugLog("=== ダンジョン外戦闘Phase完了 - ダンジョン突入 ===")
            return true
        else
            DebugLog("転送魔紋なし - 地図購入Phaseに復帰")
            currentPhase = CurrentPhase.MAP_PURCHASE
            return true
        end
    else
        DebugLog("戦闘開始に失敗")
        return false
    end
end

-- =============================================================================
-- ダンジョンPhase
-- =============================================================================

local function DetectDungeonType()
    DebugLog("ダンジョンタイプ検出中...")
    
    SafeWait(3)  -- ダンジョン突入後の待機
    
    -- 召喚魔法陣を検索
    yield("/target 召喚魔法陣")
    SafeWait(1)
    
    if GetTargetName() == "召喚魔法陣" then
        dungeonType = "ROULETTE"
        DebugLog("ルーレットタイプを検出")
    else
        dungeonType = "DUNGEON"
        DebugLog("ダンジョンタイプを検出")
    end
end

-- ダンジョンタイプの処理
local function ExecuteDungeonTypeFloor()
    DebugLog("ダンジョンタイプ第" .. currentFloor .. "階処理中...")
    
    -- 自動移動
    yield("/automove on")
    SafeWait(2)
    
    -- 宝箱探索
    yield("/target 宝箱")
    SafeWait(1)
    
    if GetTargetName() == "宝箱" then
        yield("/automove off")
        
        -- 宝箱に接近
        yield("/vnavmesh moveto target")
        while Player.IsMoving do
            SafeWait(0.5)
        end
        
        -- 相互作用
        yield("/interact")
        SafeWait(2)
        
        DebugLog("宝箱相互作用完了")
    end
    
    -- 最終階層のボス戦チェック
    if currentFloor == MAX_DUNGEON_FLOORS then
        yield("/target ゴールデン・モルター")
        if GetTargetName() ~= "ゴールデン・モルター" then
            yield("/target ブルアポリオン")
        end
        
        if GetTargetName() == "ゴールデン・モルター" or GetTargetName() == "ブルアポリオン" then
            DebugLog("最終階層ボス戦開始")
            EnableCombatSystems()
            
            -- 戦闘終了まで待機
            while InCombat() do
                SafeWait(1)
            end
            
            DisableCombatSystems()
            DebugLog("最終階層ボス戦完了")
        end
    end
    
    -- アイテム回収の処理
    local function CollectLoot()
        local items = {"宝箱", "皮袋"}
        for _, item in ipairs(items) do
            yield("/target " .. item)
            SafeWait(1)
            if GetTargetName() == item then
                yield("/vnavmesh moveto target")
                while Player.IsMoving do
                    SafeWait(0.5)
                end
                yield("/interact")
                SafeWait(2)
                DebugLog(item .. "を回収")
            end
        end
    end
    
    CollectLoot()
    
    -- 次の階層への移動
    if currentFloor < MAX_DUNGEON_FLOORS then
        yield("/target 次の階層へ")
        SafeWait(1)
        if GetTargetName() == "次の階層へ" then
            yield("/vnavmesh moveto target")
            while Player.IsMoving do
                SafeWait(0.5)
            end
            yield("/interact")
            SafeWait(3)
            currentFloor = currentFloor + 1
            DebugLog("第" .. currentFloor .. "階に移動")
        end
    else
        -- 最終階層脱出
        yield("/target 脱出地点")
        SafeWait(1)
        if GetTargetName() == "脱出地点" then
            yield("/vnavmesh moveto target")
            while Player.IsMoving do
                SafeWait(0.5)
            end
            yield("/interact")
            SafeWait(3)
            DebugLog("ダンジョン脱出")
            return true  -- ダンジョン完了
        end
    end
    
    return false  -- 継続必要
end

-- ルーレットタイプの処理
local function ExecuteRouletteTypeFloor()
    DebugLog("ルーレットタイプ第" .. currentFloor .. "階処理中...")
    
    -- 召喚魔法陣に接近
    yield("/target 召喚魔法陣")
    SafeWait(1)
    
    if GetTargetName() == "召喚魔法陣" then
        yield("/vnavmesh moveto target")
        while Player.IsMoving do
            SafeWait(0.5)
        end
        
        -- 相互作用
        yield("/interact")
        SafeWait(3)
        
        DebugLog("召喚魔法陣相互作用完了")
        
        -- 戦闘開始待機
        if WaitForCombatStart() then
            EnableCombatSystems()
            WaitForCombatEnd()
            DisableCombatSystems()
            
            -- アイテム回収の処理
            local function CollectLoot()
                local items = {"宝箱", "皮袋"}
                for _, item in ipairs(items) do
                    yield("/target " .. item)
                    SafeWait(1)
                    if GetTargetName() == item then
                        yield("/vnavmesh moveto target")
                        while Player.IsMoving do
                            SafeWait(0.5)
                        end
                        yield("/interact")
                        SafeWait(2)
                        DebugLog(item .. "を回収")
                    end
                end
            end
            
            CollectLoot()
            
            -- 次の階層への移動
            if currentFloor < MAX_DUNGEON_FLOORS then
                yield("/target 召喚魔法陣")
                SafeWait(1)
                if GetTargetName() == "召喚魔法陣" then
                    yield("/vnavmesh moveto target")
                    while Player.IsMoving do
                        SafeWait(0.5)
                    end
                    yield("/interact")
                    SafeWait(3)
                    currentFloor = currentFloor + 1
                    DebugLog("第" .. currentFloor .. "階に移動")
                end
            else
                -- 最終階層脱出
                yield("/target 脱出地点")
                SafeWait(1)
                if GetTargetName() == "脱出地点" then
                    yield("/vnavmesh moveto target")
                    while Player.IsMoving do
                        SafeWait(0.5)
                    end
                    yield("/interact")
                    SafeWait(3)
                    DebugLog("ダンジョン脱出")
                    return true  -- ダンジョン完了
                end
            end
        end
    end
    
    return false  -- 継続必要
end

local function ExecuteDungeonPhase()
    DebugLog("=== ダンジョンPhase開始 ===")
    
    if not dungeonType then
        DetectDungeonType()
    end
    
    local dungeonCompleted = false
    
    if dungeonType == "DUNGEON" then
        dungeonCompleted = ExecuteDungeonTypeFloor()
    elseif dungeonType == "ROULETTE" then
        dungeonCompleted = ExecuteRouletteTypeFloor()
    end
    
    if dungeonCompleted then
        DebugLog("=== ダンジョンPhase完了 ===")
        currentPhase = CurrentPhase.MAP_PURCHASE
        dungeonType = nil
        currentFloor = 1
        return true
    end
    
    return false
end

-- =============================================================================
-- メイン処理
-- =============================================================================

local function PerformMaintenance()
    DebugLog("メンテナンス実行中...")
    
    -- 包括的な修復
    -- TODO: 実際の修復API実装
    
    -- インベントリ整理
    -- TODO: 実際のインベントリAPI実装
    
    -- エラー状態修復
    -- TODO: 実際のエラー修復API実装
    
    DebugLog("メンテナンス完了")
end

local function MainLoop()
    DebugLog("=== TreasureDungeon.lua 開始 ===")
    
    local maxIterations = 1000  -- 無限ループ防止
    local iteration = 0
    
    while iteration < maxIterations do
        iteration = iteration + 1
        
        -- プレイヤー状態チェック
        if not IsPlayerReady() then
            DebugLog("プレイヤー操作不可 - 待機中...")
            SafeWait(5)
            goto continue
        end
        
        -- フェーズ別処理実行
        local success = false
        
        if currentPhase == CurrentPhase.MAP_PURCHASE then
            success = ExecuteMapPurchasePhase()
        elseif currentPhase == CurrentPhase.MOVEMENT then
            success = ExecuteMovementPhase()
        elseif currentPhase == CurrentPhase.FIELD_COMBAT then
            success = ExecuteFieldCombatPhase()
        elseif currentPhase == CurrentPhase.DUNGEON then
            success = ExecuteDungeonPhase()
        end
        
        if not success then
            DebugLog("フェーズ実行に失敗: " .. currentPhase)
            SafeWait(5)
        end
        
        -- メンテナンス
        if iteration % 10 == 0 then
            PerformMaintenance()
        end
        
        ::continue::
        SafeWait(1)
    end
    
    DebugLog("=== TreasureDungeon.lua 終了 ===")
end

-- =============================================================================
-- スクリプト開始
-- =============================================================================

-- 必須APIの存在確認
if not Player or not Addons or not Inventory then
    yield("/echo [エラー] 必須APIが利用できません。SomethingNeedDoing v12.0.0.0+の使用が必要です。")
    return
end

-- メイン実行
MainLoop()