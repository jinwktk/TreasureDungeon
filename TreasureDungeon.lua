--[[
================================================================================
                      Treasure Hunt Automation v2.5.4
================================================================================
FFXIV トレジャーハント完全自動化スクリプト

主な機能:
  - G17/G10地図の完全自動化
  - 7段階フェーズ管理システム
  - SND v12.0.0.0+ モジュールベースAPI対応

必須プラグイン:
  - Something Need Doing [Expanded Edition] v12.0.0.0+
  - VNavmesh
  - RSR (Rotation Solver Reborn)
  - AutoHook
  - Teleporter
  - CBT (ChatCoordinates + Teleport)
  - AutoDuty - 定期修理機能
  - Lifestream - ワールド変更機能（価格制限時・緊急帰還機能）
  - VT (VoidToolkit) - Optional

Author: Claude + jinwktk
Date: 2025-07-22

変更履歴:
v2.5.4 (2025-07-22):
- 戦闘終了判定早すぎ問題緊急修正: 戦闘終了後5秒間の様子見機能追加
- combatEndTime変数追加: 戦闘終了瞬間記録・5秒間様子見期間制御
- 戦闘再開時リセット機能: 様子見期間中の戦闘再開を正確に検出
- ユーザー報告即座対応: 「まだ戦闘中なのに戦闘判定が消えた」問題の根本解決

v2.5.3 (2025-07-22):
- ダンジョン内宝箱・ターゲット検出停止問題緊急修正: 非戦闘中goto continue削除
- 探索処理復旧: ExecuteDungeonPhase内でCheckAndInteractPriorityTargets呼び出し復活
- ユーザー報告即座対応: 「宝箱ターゲット検出しなくなった」問題の根本解決

v2.5.2 (2025-07-22):
- v2.4.4→v2.5.2メジャーアップデート: 包括的バージョン管理・安定性向上完了
- 長期実行安定性確保: エラーハンドリング・フェーズ遷移・システム安定性総合テスト済み
- 技術ドキュメント完全更新: CLAUDE.md・README.md開発履歴・使用方法最新化
- Git管理整理完了: 変更履歴整合性確保・適切なコミット・プッシュ実施

v2.4.4 (2025-07-22):
- 戦闘判定修正: 敵ターゲット存在判定を無効化してプレイヤー戦闘状態のみで判定
- 宝箱検出阻害問題解決: 宝箱ターゲット時の誤戦闘判定を完全除去
- IsInCombat関数簡素化: Entity.Player.IsInCombatのみで戦闘状態判定

v2.4.0 (2025-07-22):
- 戦闘終了判定改善: 敵の存在チェック強化で戦闘中誤判定を解決
- 包括的戦闘状態検証: Player.InCombat + 敵ターゲット存在 + HP状態の多角的判定

v2.3.9 (2025-07-22):
- エラー時緊急帰還機能強化: Lifestream /li inn実行による安全な宿屋帰還

v2.3.8 (2025-07-21):
- 戦闘フェーズ無限ループ修正: treasureChestInteractedフラグ管理の最適化
- 戦闘フェーズ長期化防止: 30秒タイムアウトによる強制完了処理追加

v2.3.6 (2025-07-21):
- 最終層脱出地点優先検索: 宝箱・皮袋未発見時の積極的な脱出地点検索を実装
- 脱出地点常時追加: 最終層検出問題対策で脱出地点を常にターゲットリストに追加
- 脱出地点接近改善: vnav movetargetによる確実な脱出地点到達機能

v2.3.5 (2025-07-21):
- ダンジョン内宝箱移動改善: 距離が縮まらない問題にvnav moveto追加
- 前進探索最適化: automoveとvnavmeshを併用した確実なターゲット到達
- タイムアウト制御追加: vnav移動10秒制限とフォールバック処理

v2.3.4 (2025-07-21):
- 宝箱回収後ターゲット解除: 戦闘後の宝箱インタラクト後に/target clearを追加
- 転送魔紋検索精度向上: 宝箱ターゲット状態による転送魔紋検出阻害を修正

v2.3.3 (2025-07-21):
- 戦闘開始時刻記録修正: EnableCombatPlugins()内でcombatStartTimeを確実に設定
- タイムアウト処理強化: combatStartTime未記録時のフォールバック処理追加
- デバッグログ追加: 戦闘開始時刻記録の確認ログを追加

v2.3.2 (2025-07-21):
- 転送魔紋待機時間短縮: 3分→1分に短縮して実用性向上
- 経過時間ログ追加: 転送魔紋待機中の進捗を「XX秒/60秒」形式で表示
- 実用性重視の調整: 転送魔紋が出ない場合の待機時間を最適化

v2.3.1 (2025-07-21):
- 戦闘後転送魔紋無限ループ修正: 転送魔紋待機に3分タイムアウト制御を追加
- 戦闘開始時刻記録機能: combatStartTime変数で戦闘経過時間を追跡
- 強制完了処理実装: 転送魔紋が出現しない場合の自動完了機能

v2.3.0 (2025-07-21):
- ダンジョン判定修正: boundByDuty34からboundByDuty56に変更（ユーザー指定通り）
- IsInDuty()関数更新: boundByDuty56を正式なダンジョン判定条件として採用
- デバッグログ更新: boundByDuty56の状態をログ出力

v2.2.9 (2025-07-21):
- ダンジョン判定修正: boundByDuty56からboundByDuty34に戻す（ログでCondition[34]=true確認済み）
- Svc.Conditionダンプ無効化: 重複ログ出力を停止してログの可読性向上
- IsInDuty()実測値対応: 実際のSvc.Condition状態に基づく正確な判定実装

v2.2.8 (2025-07-21):
- 戦闘フェーズ転送魔紋チェック追加: 戦闘後の宝箱回収後に転送魔紋検出処理を実装
- 転送魔紋見落とし問題修正: 「宝物庫に至る、転送魔紋が発生した！」メッセージ後の自動検出
- CheckForTransferPortal()呼び出し追加: 戦闘完了後の転送魔紋インタラクト処理

v2.2.7 (2025-07-21):
- ダンジョン判定修正: boundByDuty34からboundByDuty56に変更
- IsInDuty()関数更新: ユーザー指摘によりboundByDuty56を正式なダンジョン判定条件として採用
- デバッグログ更新: boundByDuty56の状態をログ出力

v2.2.6 (2025-07-21):
- Svc.Conditionデバッグ機能追加: DebugSvcCondition()とDumpAllSvcConditions()関数実装
- 戦闘フェーズでSvc.Condition全値ダンプ: フィールド戦闘時の状態を詳細確認
- デバッグ情報強化: CONFIG.DEBUG.ENABLEDでCondition[0-100]の全値を出力

v2.2.5 (2025-07-21):
- IsInDuty()関数簡素化: ユーザー指摘により既知ゾーン判定を削除、boundByDuty34のみによる単純判定に変更
- 不要な複雑性除去: ゾーンIDチェックを完全削除してシンプルなロジックに統一
- デバッグログ最適化: boundByDuty34の状態のみをログ出力

v2.2.3 (2025-07-21):
- SEHException緊急対策: _ToDoList API呼び出しを完全無効化してSEHException (0x80004005)を回避
- GetCurrentFloorFromTodoList()関数簡素化: 危険なAddons.GetAddon("_ToDoList")アクセスを削除
- 安定性最優先: デフォルト階層管理(1/5)に戻して確実な動作を保証

v2.2.2 (2025-07-21):
- NLua Unicode文字列エラー修正: 4210行目周辺の日本語コメントを英語に変更してエスケープシーケンスエラーを解決

v2.1.2 (2025-07-20):
- ダンジョンフェーズ転送魔紋検出強化: メインループと前進探索前に転送魔紋チェック追加
- 転送魔紋発生後の前進探索防止: 転送魔紋検出時は即座にループ継続で無駄な前進探索を回避
- 転送タイムアウト問題解決: ダンジョン内で転送魔紋を見落とす問題を根本修正

v2.1.1 (2025-07-20):
- boundByDuty厳密判定実装: フォールバックのゾーンIDベース判定を完全削除
- IsInDuty関数強化: boundByDuty=trueのみダンジョン内判定、それ以外は全てダンジョン外
- ジョブ変更コマンド修正: /gearset change でJobIDではなくJobName（PLD/WAR）を使用

v2.1.0 (2025-07-20):
- 地図タイプ別自動ジョブ変更機能実装: G17→PLD、G10→WAR自動変更システム追加
- ChangeJobForMapType関数実装: /gearset changeコマンドによる確実なジョブ変更処理
- 初期化フェーズにジョブ変更追加: 食事チェック後、インベントリチェック前に実行

v2.0.4 (2025-07-20):
- ダンジョン判定条件修正: boundByDutyを使用して正確なダンジョン判定を実現
- boundByDuty=True時のみダンジョン内と判定するよう修正、フィールドゾーンでの誤検出を完全防止

v2.2.2 (2025-07-21):
-- NLua Unicode文字列エラー修正: 4210行目周辺の日本語コメントを英語に変更してエスケープシーケンスエラーを解決

v2.2.1 (2025-07-21):
-- _TodoList統合実装: GetNode(1,4,10)形式で漢数字階層情報（例：「第三区画の攻略」）を動的取得
-- 階層管理の完全動的化: ハードコード値（1/5）から_TodoListベースのリアルタイム階層検出に変更
-- 漢数字変換機能追加: 「一二三四五六七八九十」からアラビア数字への自動変換システム
-- 階層進行精度向上: 進行時に_TodoListから最新階層情報を再同期してズレを防止

v2.0.3 (2025-07-20):
- ダンジョンフェーズ脱出チェック修正: ExecuteDungeonPhase内でも共通のダンジョン判定関数を使用
- IsCurrentlyInTreasureDungeon関数追加: DetectCurrentStateと同じロジックでダンジョン判定の一貫性を確保
- フィールドでの前進探索停止: ダンジョン外では即座にCOMPLETEフェーズに移行し前進探索を防止

v2.0.2 (2025-07-20):
- ダンジョン判定ロジック修正: ゾーンID 1191等のフィールドゾーンでの誤検出を防止
- フィールドゾーン除外リスト: 明確にフィールドと判明したゾーンをダンジョン判定から除外

v2.0.1 (2025-07-20):
- 転送魔紋インタラクト強化: BMRai無効化・マウント降車・距離チェック・接近移動を追加し確実なインタラクト実行
- 転送待機時間延長: 3秒→5秒に延長、転送処理の安定性向上

v2.0.0 (2025-07-20):
- 戦闘フェーズ大幅リファクタリング: 複雑な戦闘後処理を削除し、シンプルで確実な転送魔紋検出ロジックに変更
- 最大イテレーション数拡大: 3000→6000回（約10分）に延長、長時間戦闘対応

v1.9.0 (2025-07-19):
- ボス戦無限ループ修正: bossDefeatedフラグでブルアポリオン重複撃破を完全防止
- インベントリ満杯エラー対策: ボス戦前のインベントリチェック・自動管理機能追加

v1.8.5 (2025-07-19):
- インベントリ満杯対策強化: discardallを最大5回試行する機能を実装

v1.8.0 (2025-07-17):
- 5層以上のダンジョン継続機能: 最終層超過時も継続探索する仕様に変更
- インベントリ満杯時の再処理機能: discardall実行後に空きスロット再確認・再実行機能追加
- エラー閾値調整: インベントリ満杯判定を1スロット以下に変更（従来5スロット以下）

v1.7.0 (2025-07-17):
- 食事バフ自動再摂取機能実装: 残り時間10分以下でCtrl+Shift+F9を自動実行

v1.5.9 (2025-07-16):
- BMR制御改善: 宝箱インタラクト前にBMRを確実にオフにする処理を強化
- 非戦闘時BMR制御: 地図購入・移動・完了フェーズでBMRを自動的にオフ
- HasCombatPlugin関数使用: より確実なBMRプラグイン検出とフォールバック処理
--]]

--[=====[
[[SND Metadata]]
configs:
  MAP_TYPE:
    default: "G17"
    description: 地図のタイプを指定します（G17, G10, G10_DEEP）
    type: string
  MAX_PRICE:
    default: 20000
    description: 地図の最大購入価格（ギル）
    type: int
    min: 1000
    max: 100000
[[End Metadata]]
]=====]

-- ================================================================================
-- SND Config設定取得
-- ================================================================================

-- ================================================================================
-- ユーティリティ関数
-- ================================================================================

-- CharacterCondition定数定義
local CharacterCondition = {
    dead=2,
    mounted=4,
    inCombat=26,
    casting=27,
    occupiedInEvent=31,
    occupiedInQuestEvent=32,
    occupied=33,
    boundByDuty34=34,
    occupiedMateriaExtractionAndRepair=39,
    betweenAreas=45,
    jumping48=48,
    wellFed=49,
    jumping61=61,
    occupiedSummoningBell=50,
    betweenAreasForDuty=51,
    boundByDuty56=56,
    mounting57=57,
    mounting64=64,
    beingMoved=70,
    flying=77
}

-- GetCharacterCondition関数の実装
function GetCharacterCondition(zup)
    return Svc.Condition[zup]
end

-- ================================================================================
-- 設定管理
-- ================================================================================

local CONFIG = {
    -- 地図設定（SND Configから取得）
    MAP_TYPE = Config.Get("MAP_TYPE"), -- SND Configから取得
    
    -- vnavmesh設定（v2.4.0シンプル版）
    USE_SIMPLE_VNAV = true, -- シンプルなyield vnavコマンド使用
    
    -- ジョブ変更設定
    AUTO_JOB_CHANGE = true, -- 地図タイプ別の自動ジョブ変更機能
    
    -- 地図タイプ別設定
    MAPS = {
        G17 = {
            itemId = 43557,
            jobId = 19, -- PLD
            jobName = "PLD",
            searchTerm = "G17"
        },
        G10 = {
            itemId = 17836,
            jobId = 21, -- WAR
            jobName = "WAR",
            searchTerm = "G10"
        },
        G10_DEEP = {
            itemId = 19770,
            jobId = 21, -- WAR
            jobName = "WAR",
            searchTerm = "深層"
        }
    },
    
    -- 価格制限設定（SND Configから取得）
    PRICE_LIMITS = {
        ENABLED = true,           -- 価格制限機能有効
        MAX_PRICE = Config.Get("MAX_PRICE"),  -- SND Configから取得
        SKIP_EXPENSIVE = true     -- 高額時は購入をスキップ
    },
    
    -- タイムアウト設定（秒）
    TIMEOUTS = {
        MOVEMENT = 600,     -- 移動タイムアウト（10分） - より長時間の移動に対応
        COMBAT = 1800,      -- 戦闘タイムアウト（30分） - 長時間戦闘対応
        INTERACTION = 10,   -- インタラクションタイムアウト（10秒）
        TELEPORT = 15,      -- テレポートタイムアウト（15秒）
        DUNGEON = 99999     -- ダンジョン全体タイムアウト（無制限）
    },
    
    -- オブジェクト別ターゲット可能距離設定
    TARGET_DISTANCES = {
        MARKET_BOARD = 3.0,    -- マーケットボード
        TREASURE_CHEST = 3.0,  -- 宝箱
        NPC = 3.0,             -- NPC
        DEFAULT = 3.0          -- デフォルト
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
    },
    
    -- CBTプラグイン設定
    CBT = {
        USE_TPFLAG = true,        -- /tpflagコマンド使用（CBTプラグイン必須）
        FALLBACK_ENABLED = true   -- CBT未使用時のフォールバック機能
    },
    
    -- AutoDuty修理設定
    AUTO_REPAIR = {
        ENABLED = true,           -- 自動修理機能有効
        INTERVAL = 300,          -- 修理実行間隔（5分=300秒）
        COMMAND = "/ad repair"   -- AutoDutyの修理コマンド
    },
    
    -- 食事バフ自動再摂取設定
    AUTO_FOOD = {
        ENABLED = true,           -- 食事バフ自動再摂取機能有効
        KEY_COMBINATION = "SHIFT+CONTROL+F9", -- 食事実行キーコンビネーション
        CHECK_INTERVAL = 30,      -- バフチェック間隔（30秒）
        DISABLE_IN_COMBAT = true, -- 戦闘中は食事実行を無効化
        TIME_THRESHOLD = 600      -- 食事バフ残り時間の閾値（10分=600秒）
    },
    
    -- Lifestreamワールド変更設定
    LIFESTREAM = {
        ENABLED = true,           -- ワールド変更機能有効
        AUTO_CHANGE_ON_EXPENSIVE = true,  -- 高額時の自動ワールド変更
        WORLDS = {               -- 巡回ワールドリスト（日本全サーバー）
            -- Elemental DC
            "Aegis", "Atomos", "Carbuncle", "Garuda", "Gungnir", "Kujata", "Tonberry", "Typhon",
            -- Gaia DC
            "Alexander", "Bahamut", "Durandal", "Fenrir", "Ifrit", "Ridill", "Tiamat", "Ultima",
            -- Mana DC
            "Anima", "Asura", "Chocobo", "Hades", "Ixion", "Masamune", "Pandaemonium", "Titan",
            -- Meteor DC
            "Belias", "Mandragora", "Ramuh", "Shinryu", "Unicorn", "Valefor", "Yojimbo", "Zeromus"
        },
        CURRENT_INDEX = 1,       -- 現在のワールドインデックス
        MAX_RETRIES = 32,        -- 最大試行回数（全ワールド1周）
        CHANGE_TIMEOUT = 300     -- ワールド変更タイムアウト（5分=300秒）
    },
    
    -- 座標別テレポート設定（フォールバック用）
    COORDINATE_TELEPORTS = {
        -- 他の座標とテレポート先を追加可能
        -- {
        --     x = 219.05,
        --     z = -66.08,
        --     y = 95.224,
        --     teleport = "イシュガルド：下層",
        --     description = "イシュガルド地図座標"
        -- }
    }
}

-- ================================================================================
-- グローバル変数
-- ================================================================================

local currentPhase = "INIT"
local phaseStartTime = 0
local stopRequested = false
local iteration = 0
local maxIterations = 3000  -- より長時間の処理に対応（1000→3000）
local combatWarningTime = nil  -- 戦闘プラグイン未検出警告のタイムスタンプ
local domaGuardRecentlyInteracted = false  -- ドマ反乱軍の門兵インタラクト無限ループ防止フラグ
local combatPluginDebugLogged = false  -- インストール済みプラグイン一覧ログ出力フラグ
local combatPluginsEnabled = false  -- 戦闘プラグイン有効化状態フラグ
local combatStartTime = 0  -- 戦闘開始時刻（戦闘後タイムアウト制御用）
local combatEndTime = nil  -- 戦闘終了時刻（v2.5.4: 5秒間様子見用）
local flagCoordinatesLogged = false  -- フラッグ座標ログ重複防止フラグ
local yCoordinateWarningLogged = false  -- Y座標警告ログ重複防止フラグ
local lastRepairTime = 0  -- 最後の修理実行時刻
local lastFoodCheckTime = 0  -- 最後の食事バフチェック時刻

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

-- ユーティリティ関数

-- 待機関数
local function Wait(seconds)
    local endTime = os.clock() + seconds
    while os.clock() < endTime and not stopRequested do
        yield("/wait 0.1")
    end
end


-- 座標別テレポート処理関数（フォールバック用）
local function HandleCoordinateTeleport(x, z, y_corrected)
    if not CONFIG.COORDINATE_TELEPORTS then
        return false
    end
    
    for _, coordTp in ipairs(CONFIG.COORDINATE_TELEPORTS) do
        if math.abs(x - coordTp.x) < 1.0 and math.abs(z - coordTp.z) < 1.0 then
            if coordTp.teleport then
                LogInfo(string.format("座標マッチ: %s - %s へテレポート実行", coordTp.description or "不明", coordTp.teleport))
                yield("/tp " .. coordTp.teleport)
                Wait(3)
                return true
            end
        end
    end
    
    return false
end

-- 修理関数
-- 【使用箇所】宝箱インタラクト前（CheckForTreasureChest関数内）でのみ呼び出し
-- MOVEMENTフェーズやメインループでは呼び出さない
local function PerformRepair()
    if not CONFIG.AUTO_REPAIR.ENABLED then
        return
    end
    
    local currentTime = os.clock()
    
    -- 前回の修理から指定した間隔が経過した場合のみ実行
    if currentTime - lastRepairTime >= CONFIG.AUTO_REPAIR.INTERVAL then
        LogInfo("定期修理実行: " .. CONFIG.AUTO_REPAIR.COMMAND)
        yield(CONFIG.AUTO_REPAIR.COMMAND)
        lastRepairTime = currentTime
        LogInfo("修理実行中 - 5秒待機")
        Wait(5)  -- 修理処理の完了待機を5秒に延長
    end
end

-- ================================================================================
-- 食事バフ管理システム
-- ================================================================================

-- ステータス残り時間取得関数（GitHubコード参考）
local function GetStatusTimeRemaining(statusID)
    local success, result = pcall(function()
        if Player and Player.StatusList then
            local statuses = Player.StatusList
            for i = 0, statuses.Length - 1 do
                local status = statuses[i]
                if status and status.StatusId == statusID then
                    return status.RemainingTime or 0
                end
            end
        end
        return 0
    end)
    
    return success and result or 0
end

-- 食事バフ存在チェック関数
local function HasFoodBuff()
    local success, result = pcall(function()
        -- SND v12.0.0+: Player.HasStatus APIを使用して食事バフを確認
        if Player and Player.HasStatus then
            -- 食事バフのStatus ID: 48（Well Fed）
            return Player.HasStatus(48)
        -- フォールバック: GetCharacterCondition使用
        elseif GetCharacterCondition then
            -- CharacterCondition.wellFed = Well Fed
            return GetCharacterCondition(CharacterCondition.wellFed)
        else
            LogDebug("食事バフ確認API利用不可 - スキップ")
            return true  -- API利用不可時はバフありと仮定
        end
    end)
    
    return success and result or true
end

-- 食事バフ残り時間チェック関数（10分以下で実行）
local function ShouldUseFoodBuff()
    -- 食事バフの残り時間を取得（秒）
    local remainingTime = GetStatusTimeRemaining(48)
    
    -- 残り時間が設定閾値以下または0（バフなし）の場合は食事実行
    if remainingTime <= CONFIG.AUTO_FOOD.TIME_THRESHOLD then
        if remainingTime > 0 then
            local remainingMinutes = math.floor(remainingTime / 60)
            LogInfo(string.format("食事バフ残り時間: %d分%d秒 - 閾値以下のため食事実行", 
                remainingMinutes, remainingTime % 60))
        else
            LogInfo("食事バフなし - 食事実行")
        end
        return true
    else
        local remainingMinutes = math.floor(remainingTime / 60)
        LogDebug(string.format("食事バフ残り時間: %d分%d秒 - 十分", 
            remainingMinutes, remainingTime % 60))
        return false
    end
end

-- 戦闘状態チェック関数
-- 包括的戦闘状態判定関数（v2.4.0強化版 - Entity.Player.IsInCombat統合）
local function IsInCombat()
    local success, result = pcall(function()
        -- プレイヤーの戦闘状態をチェック（優先順位順）
        local playerInCombat = false
        
        -- 1. Entity.Player.IsInCombat（最優先・SND v12.0.0+）
        if Entity and Entity.Player and Entity.Player.IsInCombat ~= nil then
            playerInCombat = Entity.Player.IsInCombat
            LogDebug("戦闘判定: Entity.Player.IsInCombat = " .. tostring(playerInCombat))
        -- 2. Player.InCombat（モジュールベースAPI）
        elseif Player and Player.InCombat ~= nil then
            playerInCombat = Player.InCombat
            LogDebug("戦闘判定: Player.InCombat = " .. tostring(playerInCombat))
        -- 3. GetCharacterCondition（フォールバック）
        elseif GetCharacterCondition then
            playerInCombat = GetCharacterCondition(CharacterCondition.inCombat)
            LogDebug("戦闘判定: GetCharacterCondition(inCombat) = " .. tostring(playerInCombat))
        end
        
        -- 敵対ターゲットの存在をチェック
        local hostileTargetExists = false
        if Entity and Entity.Target then
            local target = Entity.Target
            if target.Name and target.Type == 2 then  -- BattleNpc
                -- HPが0以上で生存している敵
                if target.CurrentHp and target.CurrentHp > 0 then
                    hostileTargetExists = true
                    LogDebug("生存敵発見: " .. target.Name .. " (HP: " .. target.CurrentHp .. "/" .. (target.MaxHp or "?") .. ")")
                end
            end
        end
        
        -- v2.4.4: プレイヤー戦闘状態のみで判定（敵ターゲット判定無効化）
        local inCombat = playerInCombat
        
        if inCombat then
            LogDebug("戦闘状態: Player=" .. tostring(playerInCombat))
        end
        
        return inCombat
    end)
    
    return success and result or false
end

-- 周辺敵検索関数（v2.4.0追加）
local function CheckForNearbyEnemies()
    local success, enemiesFound = pcall(function()
        -- 様々な敵名をターゲット検索で確認
        local enemyNames = {
            "テリトリアル・ネクローシス", "テリトリアル・トォーソク", 
            "敵", "モンスター", "ネクローシス", "トォーソク",
            "Territorial", "Necro", "Torso"
        }
        
        for _, enemyName in ipairs(enemyNames) do
            yield("/target " .. enemyName)
            Wait(0.5)
            
            if HasTarget() then
                local target = Entity.Target
                if target and target.Type == 2 and target.CurrentHp and target.CurrentHp > 0 then
                    LogInfo("周辺敵検出: " .. target.Name .. " (HP: " .. target.CurrentHp .. ")")
                    return true
                end
            end
        end
        
        return false
    end)
    
    return success and enemiesFound or false
end

-- v2.4.0: シンプルなvnavmesh操作関数

-- v2.4.0: 食事機能はシンプル版のみ


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
                        -- 重大なシステムエラー時の緊急帰還
                        LogInfo("重大エラー検出 - 緊急安全帰還を実行中...")
                        pcall(function() yield("/li inn") end)
                        return false, "Lua状態異常 - SEHException後復旧不可能"
                    end
                else
                    Wait(0.5) -- 通常エラーは短時間待機
                end
            else
                LogError(string.format("%s (最終試行失敗): %s", contextInfo, errorInfo))
                
                -- システムエラーの詳細解析と緊急帰還
                if string.find(errorInfo, "External component") or string.find(errorInfo, "SEHException") then
                    LogError("SEHException最終失敗 - NLua/SomethingNeedDoingエンジンレベルエラー")
                    LogError("推奨対処: 1) SND再起動 2) Dalamudプラグイン再読み込み 3) FFXIV再起動")
                    -- 重大なシステムエラー時の緊急帰還
                    LogInfo("重大システムエラー - 緊急安全帰還を実行中...")
                    pcall(function() yield("/li inn") end)
                elseif string.find(errorInfo, "NLuaMacroEngine") then
                    LogError("NLuaMacroEngineエラー - マクロエンジン内部エラー")
                    LogError("推奨対処: SomethingNeedDoingプラグイン完全再起動")
                    -- マクロエンジンエラー時の緊急帰還
                    LogInfo("マクロエンジンエラー - 緊急安全帰還を実行中...")
                    pcall(function() yield("/li inn") end)
                end
                
                return false, result
            end
        end
    end
    
    return false, "Max retries exceeded"
end

-- 食事実行関数
local function ExecuteFood()
    if not CONFIG.AUTO_FOOD.ENABLED then
        return
    end
    
    -- 戦闘中チェック（設定で無効化されている場合）
    if CONFIG.AUTO_FOOD.DISABLE_IN_COMBAT and IsInCombat() then
        LogDebug("戦闘中のため食事実行をスキップ")
        return
    end
    
    -- プレイヤー状態チェック（簡易版）
    local playerAvailable = false
    local success, result = pcall(function()
        if Player and Player.Available ~= nil then
            return Player.Available and not (Player.IsBusy or false)
        else
            return true  -- API利用不可時は利用可能と仮定
        end
    end)
    playerAvailable = success and result or true
    
    if not playerAvailable then
        LogDebug("プレイヤーが利用不可のため食事実行をスキップ")
        return
    end
    
    LogInfo("食事バフ切れ検出 - " .. CONFIG.AUTO_FOOD.KEY_COMBINATION .. " 実行")
    
    -- キーコンビネーション送信（hold/release方式）
    local success = SafeExecute(function()
        yield("/hold " .. CONFIG.AUTO_FOOD.KEY_COMBINATION)
        Wait(0.1)  -- 短時間保持
        yield("/release " .. CONFIG.AUTO_FOOD.KEY_COMBINATION)
    end, "食事キーコンビネーション送信エラー")
    
    if success then
        LogInfo("食事実行完了 - 3秒待機")
        Wait(3)  -- 食事処理の完了待機
    else
        LogError("食事実行失敗")
    end
end

-- CBTプラグイン使用フラグテレポート関数
local function TeleportToFlag()
    -- CBTプラグインが有効かつ設定でtpflag使用が有効な場合
    local hasCBT = SafeExecute(function()
        return IPC.IsInstalled("ChatCoordinates") and IPC.Automaton.IsTweakEnabled('Commands')
    end, "CBTプラグインチェック失敗")
    
    if CONFIG.CBT.USE_TPFLAG and hasCBT then
        -- フラグマーカー設定チェック
        local isFlagSet = SafeExecute(function()
            return Instances.Map.IsFlagMarkerSet
        end, "フラグマーカー状態チェック失敗")
        
        if not isFlagSet then
            LogInfo("フラグマーカー未設定 - /tmap で地図を開いてマーカーを設定")
            yield("/tmap")
            Wait(3)  -- 地図開始待機
            
            -- 地図が開いたら少し待ってからフラグ設定を再確認
            Wait(2)
            local isFlagSetAfterTmap = SafeExecute(function()
                return Instances.Map.IsFlagMarkerSet
            end, "地図開始後フラグマーカー状態チェック失敗")
            
            if not isFlagSetAfterTmap then
                LogWarn("地図開始後もフラグマーカーが設定されていません - 手動設定が必要")
                return false
            end
        end
        
        LogInfo("CBT /tpflag コマンドでフラグ地点にテレポートします")
        yield("/tpflag")
        Wait(8)  -- テレポート完了待機
        return true
    end
    
    -- CBT未使用またはフォールバック有効時の従来処理
    if CONFIG.CBT.FALLBACK_ENABLED then
        LogInfo("CBT未使用 - 従来のテレポート処理にフォールバック")
        return false  -- 従来処理を継続
    end
    
    LogError("CBTプラグインが見つからず、フォールバックも無効です")
    return false
end


-- マーケットボード価格取得関数（ノード26-2-5対応版）
local function GetMarketBoardPrice(searchTerm)
    if not CONFIG.PRICE_LIMITS.ENABLED then
        return nil -- 価格制限機能が無効の場合はnilを返す
    end
    
    local success, result = SafeExecute(function()
        -- マーケットボード検索結果から価格を取得
        if Addons and Addons.GetAddon then
            local itemSearchAddon = Addons.GetAddon("ItemSearchResult")
            if itemSearchAddon and itemSearchAddon.Ready then
                -- 正しいノード構造 1,26,4,5 で価格を取得
                local priceNode = itemSearchAddon:GetNode(1,26,4,5)
                if priceNode and priceNode.Text then
                    local priceText = priceNode.Text
                    LogDebug("価格テキスト取得: " .. priceText)
                    -- 価格テキストから数値を抽出（例: "24,000" → 24000）
                    local cleanPrice = priceText:gsub(",", ""):gsub("[^%d]", "")
                    LogDebug("価格クリーニング結果: " .. tostring(cleanPrice))
                    local price = tonumber(cleanPrice)
                    LogDebug("tonumber結果: " .. tostring(price))
                    if price and price > 0 then
                        LogDebug("価格変換成功: " .. price .. "ギル")
                        return price
                    else
                        LogWarn("価格変換失敗: 元テキスト=" .. tostring(priceText) .. ", クリーン=" .. tostring(cleanPrice) .. ", 数値=" .. tostring(price))
                        return nil
                    end
                else
                    LogWarn("価格ノードが見つかりません")
                    return nil
                end
            else
                LogWarn("ItemSearchResultアドオンが準備できていません")
                return nil
            end
        else
            LogWarn("Addons.GetAddonが利用できません")
            return nil
        end
    end, "Failed to get market board price")
    
    LogDebug("SafeExecute結果 - success: " .. tostring(success) .. ", result: " .. tostring(result))
    
    if success and result then
        return result
    else
        return nil
    end
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

-- Lifestreamワールド変更機能
local function ChangeToNextWorld()
    if not CONFIG.LIFESTREAM.ENABLED then
        LogInfo("Lifestreamワールド変更機能は無効です")
        return false
    end
    
    -- Lifestreamプラグインの存在確認
    local hasLifestream = SafeExecute(function()
        return IPC.IsInstalled("Lifestream")
    end, "Lifestreamプラグイン確認失敗")
    
    if not hasLifestream then
        LogError("Lifestreamプラグインが見つかりません - ワールド変更をスキップ")
        return false
    end
    
    -- 次のワールドを取得
    local currentIndex = CONFIG.LIFESTREAM.CURRENT_INDEX
    local worlds = CONFIG.LIFESTREAM.WORLDS
    local nextWorld = worlds[currentIndex]
    
    if not nextWorld then
        LogError("無効なワールドインデックス: " .. tostring(currentIndex))
        return false
    end
    
    LogInfo("ワールド変更開始: " .. nextWorld .. " (" .. currentIndex .. "/" .. #worlds .. ")")
    
    -- ワールド変更実行
    local changeSuccess = SafeExecute(function()
        IPC.Lifestream.ChangeWorld(nextWorld)
        return true
    end, "Lifestreamワールド変更失敗")
    
    if not changeSuccess then
        LogError("ワールド変更コマンド失敗: " .. nextWorld)
        -- 次のワールドインデックスを更新（循環）して次回に備える
        CONFIG.LIFESTREAM.CURRENT_INDEX = (currentIndex % #worlds) + 1
        return false
    end
    
    -- ワールド変更完了待機
    LogInfo("ワールド変更中... 完了を待機")
    local changeStartTime = os.clock()
    
    while IsTimeout(changeStartTime, CONFIG.LIFESTREAM.CHANGE_TIMEOUT) == false do
        local success, isBusy = SafeExecute(function()
            return IPC.Lifestream.IsBusy()
        end, "Lifestream状態確認失敗")
        
        if success and not isBusy then
            LogInfo("ワールド変更完了: " .. nextWorld)
            
            -- 次のワールドインデックスを更新（循環）
            CONFIG.LIFESTREAM.CURRENT_INDEX = (currentIndex % #worlds) + 1
            
            -- マーケットボード情報リセット
            Wait(5)  -- ワールド変更後の安定化待機
            return true
        end
        
        Wait(1)
    end
    
    LogError("ワールド変更タイムアウト: " .. nextWorld .. " (30秒)")
    -- タイムアウト時も次のワールドインデックスを更新
    CONFIG.LIFESTREAM.CURRENT_INDEX = (currentIndex % #worlds) + 1
    return false
end

-- 価格制限チェック時のワールド変更処理
local function HandleExpensiveItem(price, itemName)
    if not CONFIG.LIFESTREAM.AUTO_CHANGE_ON_EXPENSIVE then
        LogInfo("ワールド変更は無効 - 高額アイテムをスキップ")
        return false
    end
    
    LogWarn(string.format("高額アイテム検出: %s (%d ギル) - ワールド変更を試行", 
                         itemName or "不明", price or 0))
    
    -- 全ワールド試行済みチェック
    local triedWorlds = CONFIG.LIFESTREAM.CURRENT_INDEX - 1
    if triedWorlds >= CONFIG.LIFESTREAM.MAX_RETRIES then
        LogError("全ワールドで価格制限を超過 - ワールド変更を諦めて購入実行")
        CONFIG.LIFESTREAM.CURRENT_INDEX = 1  -- リセット
        return false  -- 購入を続行
    end
    
    -- 検索画面を閉じる
    LogInfo("検索画面を閉じてからワールド変更を実行します")
    yield("/pcall ItemSearch True -1")
    Wait(2)
    
    -- 次のワールドに変更
    if ChangeToNextWorld() then
        LogInfo("ワールド変更成功 - マーケットボードに再接近してプロセス再開")
        
        -- マーケットボードに戻る
        if ReturnToMarketboard() then
            LogInfo("マーケットボード再接近成功 - 購入プロセスを再開")
            return true  -- 購入フェーズを再実行
        else
            LogError("マーケットボード再接近失敗 - 現在のワールドで購入続行")
            return false
        end
    else
        LogError("ワールド変更失敗 - 現在のワールドで購入続行")
        return false
    end
end

-- ワールド変更後のマーケットボード再接近機能
local function ReturnToMarketboard()
    LogInfo("マーケットボードに再接近を開始")
    
    -- リムサ・ロミンサ下甲板層のマーケットボード座標
    local marketboardPos = "83.0 40.0 -7.8"
    
    -- 現在のゾーンチェック
    local zoneName = ""
    if Instances and Instances.ContentFinder then
        zoneName = Instances.ContentFinder.LocationName or ""
    end
    
    -- リムサ以外の場合はテレポート
    if not string.find(zoneName, "リムサ") then
        LogInfo("リムサ・ロミンサにテレポート中")
        yield("/tp リムサ・ロミンサ:下甲板層")
        Wait(5)
        
        -- テレポート完了まで待機
        local teleportStart = os.clock()
        while Player.IsBusy and not IsTimeout(teleportStart, CONFIG.TIMEOUTS.TELEPORT) do
            Wait(1)
        end
        
        if IsTimeout(teleportStart, CONFIG.TIMEOUTS.TELEPORT) then
            LogError("テレポートタイムアウト")
            return false
        end
    end
    
    -- マーケットボードに移動
    LogInfo("マーケットボードに移動中")
    -- v2.4.0新API: 座標による直接移動（マーケットボード座標は文字列のため特別処理）
    LogInfo("マーケットボード移動（従来コマンド使用）: " .. marketboardPos)
    yield("/vnav moveto " .. marketboardPos) -- 座標文字列のため従来方式維持
    Wait(2)
    
    -- 移動完了まで待機
    local moveStart = os.clock()
    while Player.IsMoving and not IsTimeout(moveStart, 30) do
        Wait(1)
    end
    
    if IsTimeout(moveStart, 30) then
        LogError("マーケットボード移動タイムアウト")
        return false
    end
    
    -- マーケットボードを探してインタラクト
    LogInfo("マーケットボードを探索中")
    for i = 1, 5 do
        yield("/target マーケットボード")
        Wait(0.5)
        
        if HasTarget() then
            LogInfo("マーケットボードを発見 - インタラクト実行")
            yield("/interact")
            Wait(3)
            
            -- マーケットボードUI確認
            if SafeExecute(function()
                return Addons.GetAddon("RetainerSell") and Addons.GetAddon("RetainerSell").Ready
            end, "マーケットボードUI確認失敗") then
                LogInfo("マーケットボード再接近完了")
                return true
            end
        end
        
        LogDebug("マーケットボード検索中... (" .. i .. "/5)")
        Wait(1)
    end
    
    LogError("マーケットボードが見つかりません")
    return false
end

-- 価格制限チェック関数（Lifestreamワールド変更対応）
local function CheckPriceLimit(price, itemName)
    if not CONFIG.PRICE_LIMITS.ENABLED or not price then
        return true, false -- 価格制限無効または価格取得失敗時は購入許可、ワールド変更なし
    end
    
    if price > CONFIG.PRICE_LIMITS.MAX_PRICE then
        LogWarn(string.format("%s の価格が制限値を超過: %d ギル (制限: %d ギル)", 
                             itemName or "アイテム", price, CONFIG.PRICE_LIMITS.MAX_PRICE))
        
        if CONFIG.PRICE_LIMITS.SKIP_EXPENSIVE then
            -- 高額時のワールド変更処理
            local shouldChangeWorld = HandleExpensiveItem(price, itemName)
            if shouldChangeWorld then
                LogInfo("ワールド変更後に価格再チェック実行")
                return false, true  -- 購入スキップ、ワールド変更実行
            else
                LogInfo("ワールド変更なし - 価格制限により購入をスキップ")
                return false, false -- 購入スキップ、ワールド変更なし
            end
        end
    else
        LogInfo(string.format("%s の価格: %d ギル (制限内)", itemName or "アイテム", price))
    end
    
    return true, false  -- 購入許可、ワールド変更なし
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

-- ジョブ変更機能
local function ChangeJobForMapType()
    if not CONFIG.AUTO_JOB_CHANGE then
        LogDebug("自動ジョブ変更が無効化されています")
        return true
    end
    
    local success, result = SafeExecute(function()
        local mapConfig = CONFIG.MAPS[CONFIG.MAP_TYPE]
        if not mapConfig then
            LogError("無効な地図タイプ: " .. CONFIG.MAP_TYPE)
            return false
        end
        
        local targetJobId = mapConfig.jobId
        local targetJobName = mapConfig.jobName
        local currentJobId = GetCurrentJob()
        
        -- 既に目標ジョブの場合はスキップ
        if currentJobId == targetJobId then
            LogInfo("既に" .. targetJobName .. "です（JobID: " .. targetJobId .. "）")
            return true
        end
        
        LogInfo(CONFIG.MAP_TYPE .. "地図用に" .. targetJobName .. "（JobID: " .. targetJobId .. "）に変更中...")
        
        -- ギアセット変更コマンド実行
        yield("/gearset change " .. targetJobName)
        Wait(3) -- ジョブ変更待機時間
        
        -- 変更確認
        local newJobId = GetCurrentJob()
        if newJobId == targetJobId then
            LogInfo("ジョブ変更完了: " .. targetJobName)
            return true
        else
            LogWarn("ジョブ変更に失敗しました（現在JobID: " .. newJobId .. "、目標JobID: " .. targetJobId .. "）")
            return false
        end
    end, "Failed to change job for map type")
    
    return success and result
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

-- vnavmesh停止（v2.4.0シンプル版）
local function StopVNav()
    yield("/vnav stop")
    return true
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
            local inCombat = GetCharacterCondition(CharacterCondition.inCombat) or false
            local casting = GetCharacterCondition(CharacterCondition.casting) or false
            return not inCombat and not casting
        end
        return true  -- 関数がない場合は常に可能とする
    end, "Failed to check mount availability")
    return success and result or false
end

local function CanFly()
    local success, result = SafeExecute(function()
        if GetCharacterCondition then
            -- 飛行可能条件: GetCharacterCondition(mounted)で飛行可能判定
            return GetCharacterCondition(CharacterCondition.mounted) or false
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
    local success, result = SafeExecute(function()
        if IPC and IPC.IsInstalled then
            return IPC.IsInstalled(pluginName)
        end
        return false
    end, "HasPlugin check failed")
    return success and result
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
    -- 既に有効化済みなら何もしない
    if combatPluginsEnabled then
        return true  -- 既に有効化済み
    end
    
    local hasRSR, rsrName = HasCombatPlugin("rsr")
    local hasBMR, bmrName = HasCombatPlugin("bmr")
    
    -- 初回のみ戦闘プラグイン検出状況をログ出力
    if not combatPluginDebugLogged then
        LogInfo("戦闘プラグイン検出状況:")
        LogInfo("  RSR系: " .. tostring(hasRSR) .. (rsrName and (" (" .. rsrName .. ")") or ""))
        LogInfo("  BMR系: " .. tostring(hasBMR) .. (bmrName and (" (" .. bmrName .. ")") or ""))
        combatPluginDebugLogged = true
    end
    
    if hasRSR then
        LogInfo("RSR自動戦闘を有効化: " .. rsrName)
        yield("/rotation auto on")
        Wait(0.5)
    else
        -- RSRが検出されない場合でも一般的なコマンドを試行
        LogInfo("RSR未検出 - 一般的な/rotation auto onコマンドを試行")
        yield("/rotation auto on")
        Wait(0.5)
    end
    
    if hasBMR then
        LogInfo("BMR自動戦闘を有効化: " .. bmrName)
        yield("/bmrai on")
        Wait(0.5)
    else
        -- BMRが検出されない場合でも一般的なコマンドを試行
        LogInfo("BMR未検出 - 一般的な/bmrai onコマンドを試行")
        yield("/bmrai on")
        Wait(0.5)
    end
    
    combatPluginsEnabled = true
    
    -- 戦闘開始時刻を記録（タイムアウト制御用）
    if combatStartTime == 0 then
        combatStartTime = os.clock()
        LogDebug(string.format("戦闘開始時刻記録: %.2f", combatStartTime))
    end
    
    return true  -- フォールバックコマンドを実行したので常にtrueを返す
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
    
    -- 戦闘プラグイン無効化完了フラグをリセット
    combatPluginsEnabled = false
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
-- 重複するIsInCombat関数は削除済み（v2.4.0で統合）

-- Svc.Conditionデバッグ関数
local function DebugSvcCondition()
    local success = SafeExecute(function()
        if Svc and Svc.Condition then
            LogInfo("=== Svc.Condition デバッグ情報 ===")
            
            -- 重要なCondition値を確認
            local conditions = {
                [1] = "normalConditions",
                [2] = "mounted",
                [4] = "inCombat", 
                [26] = "casting",
                [27] = "unknown27",
                [28] = "unknown28",
                [31] = "occupiedInEvent",
                [32] = "occupiedInQuestEvent",
                [33] = "occupied",
                [34] = "boundByDuty34",
                [39] = "occupiedMateriaExtractionAndRepair",
                [45] = "betweenAreas",
                [48] = "jumping48",
                [50] = "occupiedSummoningBell",
                [51] = "betweenAreasForDuty",
                [56] = "boundByDuty56",
                [57] = "mounting57",
                [61] = "jumping61",
                [64] = "mounting64",
                [70] = "beingMoved",
                [77] = "flying"
            }
            
            for id, name in pairs(conditions) do
                local value = Svc.Condition[id]
                if value then
                    LogInfo("Condition[" .. id .. "] (" .. name .. ") = " .. tostring(value))
                end
            end
            
            LogInfo("=== Svc.Condition デバッグ終了 ===")
        else
            LogWarn("Svc.Conditionが利用できません")
        end
    end, "Failed to debug Svc.Condition")
    
    return success
end

-- Svc.Conditionの全ての値をダンプする関数
local function DumpAllSvcConditions()
    local success = SafeExecute(function()
        if Svc and Svc.Condition then
            LogInfo("=== Svc.Condition 全値ダンプ ===")
            
            -- 0から100まで全てチェック
            for i = 0, 100 do
                local value = Svc.Condition[i]
                if value then
                    LogInfo("Condition[" .. i .. "] = " .. tostring(value))
                end
            end
            
            LogInfo("=== Svc.Condition 全値ダンプ終了 ===")
        else
            LogWarn("Svc.Conditionが利用できません")
        end
    end, "Failed to dump all Svc.Condition")
    
    return success
end

local function IsInDuty()
    local success, result = SafeExecute(function()
        -- boundByDuty56によるダンジョン判定（ユーザー指定）
        if GetCharacterCondition and type(GetCharacterCondition) == "function" then
            local dutyCondition56 = GetCharacterCondition(CharacterCondition.boundByDuty56)
            
            -- デバッグログで現在の状態を確認
            LogDebug("IsInDuty判定: boundByDuty56=" .. tostring(dutyCondition56))
            
            -- 詳細デバッグが必要な場合にSvc.Conditionの中身を確認
            if CONFIG.DEBUG.VERBOSE then
                DebugSvcCondition()
            end
            
            -- boundByDuty56がtrueの場合のみダンジョン内と判定
            return dutyCondition56 == true
        end
        
        -- GetCharacterConditionが利用できない場合は常にダンジョン外と判定
        return false
    end, "Failed to check duty state")
    
    return success and result or false
end

-- ターゲット関連
local function HasTarget()
    local success, result = SafeExecute(function()
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
    end, "Failed to check target")
    
    return success and result or false
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

-- _TodoListから階層情報取得
-- 漢数字からアラビア数字への変換テーブル
local kanjiToNumber = {
    ["一"] = 1, ["二"] = 2, ["三"] = 3, ["四"] = 4, ["五"] = 5,
    ["六"] = 6, ["七"] = 7, ["八"] = 8, ["九"] = 9, ["十"] = 10
}

-- 漢数字をアラビア数字に変換する関数
local function ConvertKanjiToNumber(kanjiText)
    if not kanjiText or kanjiText == "" then
        return nil
    end
    
    -- シンプルな漢数字のマッチング
    for kanji, number in pairs(kanjiToNumber) do
        if string.find(kanjiText, kanji) then
            return number
        end
    end
    
    -- 通常の数字が含まれている場合
    local number = string.match(kanjiText, "(%d+)")
    if number then
        return tonumber(number)
    end
    
    return nil
end

-- SEHException対策: _ToDoList機能を無効化
local function GetCurrentFloorFromTodoList()
    -- SEHException (System.Runtime.InteropServices.SEHException) を回避するため、
    -- _ToDoList API呼び出しを完全に無効化してデフォルト値を返す
    LogDebug("SEHException対策により_ToDoList機能は無効化 - デフォルト値(1/5)を使用")
    return 1, 5
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
        combatStartTime = 0  -- 戦闘フェーズ開始時にタイマーリセット
        -- treasureChestInteracted = false  -- 戦闘フェーズでリセットしない（無限ループ防止）
    elseif newPhase == "DUNGEON" then
        bossDefeated = false  -- ダンジョンフェーズ開始時にボス撃破フラグリセット
    elseif newPhase == "COMPLETE" or newPhase == "MAP_PURCHASE" then
        combatStartTime = 0  -- 完了・地図購入フェーズでタイマーリセット
        bossDefeated = false  -- 次の地図処理でフラグリセット
        treasureChestInteracted = false  -- 次の地図処理でフラグリセット
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
    local recommendedPlugins = {"vnavmesh", "RotationSolverReborn", "AutoHook", "Teleporter", "ChatCoordinates", "Lifestream"}
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
        LogInfo("食事効果なし - " .. CONFIG.AUTO_FOOD.KEY_COMBINATION .. " で食事実行")
        ExecuteFood()
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

-- インベントリ管理：空きが5マス以下なら自動整理（5回試行ロジック）
local function CheckAndManageInventory()
    local freeSlots = GetFreeInventorySlots()
    
    if freeSlots <= 5 then
        LogWarn("インベントリ空きスロット: " .. freeSlots .. "マス - アイテム自動破棄を実行")
        
        local maxAttempts = 5
        local currentSlots = freeSlots
        
        for attempt = 1, maxAttempts do
            LogInfo("discardall実行（" .. attempt .. "/" .. maxAttempts .. "回目）")
            
            SafeExecute(function()
                yield("/discardall")
            end, "Failed to discard items attempt " .. attempt)
            
            Wait(5)  -- 破棄処理完了を待機
            
            local newSlots = GetFreeInventorySlots()
            LogInfo("破棄後の空きスロット: " .. newSlots .. "マス（前回: " .. currentSlots .. "マス）")
            
            -- スロット数に改善があるかチェック
            if newSlots > currentSlots then
                LogInfo("スロットが増加しました: +" .. (newSlots - currentSlots) .. "マス")
                currentSlots = newSlots
                
                -- 十分な空きができたら終了
                if currentSlots >= 10 then
                    LogInfo("十分な空きスロット（" .. currentSlots .. "マス）を確保しました")
                    break
                end
            else
                LogWarn("スロット数に変化がありません（" .. attempt .. "回目）")
            end
            
            -- 最後の試行で空きが不足している場合はエラー
            if attempt == maxAttempts and currentSlots <= 1 then
                LogError("インベントリが満杯です（" .. maxAttempts .. "回試行後：" .. currentSlots .. "マス）。処理を停止します。手動でアイテムを整理してください。")
                ChangePhase("ERROR", "インベントリ満杯")
                return false
            end
        end
        
        LogInfo("インベントリ整理完了 - 最終空きスロット: " .. currentSlots .. "マス")
        return true
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
                if not flagCoordinatesLogged then
                    LogInfo("フラッグ座標（Vector2+Vector3.Y）: X=" .. string.format("%.2f", flagPos.X) .. ", Y=" .. string.format("%.2f", flagPos.Y) .. ", Z=" .. string.format("%.2f", flagPos.Z))
                    flagCoordinatesLogged = true
                end
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
            -- 座標別Y修正とテレポート処理
            local teleportHandled = false
            
            if math.abs(flagPos.X - 525.47) < 1.0 and math.abs(flagPos.Z - (-799.65)) < 1.0 then
                flagPos.Y = 22.0
                LogInfo("Y座標修正適用: X=" .. string.format("%.2f", flagPos.X) .. ", Z=" .. string.format("%.2f", flagPos.Z) .. " → Y=22.0")
                -- テレポートは実行しない（烈士庵削除）
            elseif math.abs(flagPos.X - 219.05) < 1.0 and math.abs(flagPos.Z - (-66.08)) < 1.0 then
                flagPos.Y = 95.224
                LogInfo("Y座標修正適用: X=" .. string.format("%.2f", flagPos.X) .. ", Z=" .. string.format("%.2f", flagPos.Z) .. " → Y=95.224")
                teleportHandled = HandleCoordinateTeleport(flagPos.X, flagPos.Z, flagPos.Y)
            else
                -- Y座標が0の場合はそのまま使用（フォールバック無し）
                if not yCoordinateWarningLogged then
                    LogWarn("Y座標が0です。そのまま使用します")
                    yCoordinateWarningLogged = true
                end
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

-- 共通ダンジョン判定関数（DetectCurrentStateと同じロジック）
local function IsCurrentlyInTreasureDungeon()
    local isInDuty = IsInDuty()
    local currentZone = GetCurrentZoneID()
    
    -- トレジャーハント専用ダンジョンゾーンIDリスト
    local treasureDungeonZones = {
        712,  -- 既知のダンジョン
        -- 必要に応じて追加
    }
    
    -- ゾーンIDによる厳密なダンジョン判定
    local isTreasureDungeon = false
    for _, zoneId in ipairs(treasureDungeonZones) do
        if currentZone == zoneId then
            isTreasureDungeon = true
            break
        end
    end
    
    -- フィールドゾーン（ダンジョンではない）の除外リスト
    local fieldZones = {
        1191, -- 誤検出されたゾーン
        -- 他のフィールドゾーンも必要に応じて追加
    }
    
    local isFieldZone = false
    for _, zoneId in ipairs(fieldZones) do
        if currentZone == zoneId then
            isFieldZone = true
            break
        end
    end
    
    -- ダンジョン判定ロジック
    local isDungeonZone = false
    if isFieldZone then
        isDungeonZone = false
    elseif isTreasureDungeon then
        isDungeonZone = true
    elseif isInDuty and currentZone ~= 0 then
        isDungeonZone = true
    else
        isDungeonZone = false
    end
    
    return isDungeonZone
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
    
    -- 1. ダンジョン内チェック（共通関数使用）
    local isDungeonZone = IsCurrentlyInTreasureDungeon()
    local currentZone = GetCurrentZoneID()
    LogInfo("最終ダンジョン判定: " .. tostring(isDungeonZone) .. " (ゾーンID: " .. tostring(currentZone) .. ")")
    
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
    LogInfo("トレジャーハント自動化 v2.4.0 を開始します (シンプル版)")
    LogInfo("設定: " .. CONFIG.MAP_TYPE .. " 地図")
    
    if not CheckPrerequisites() then
        ChangePhase("ERROR", "前提条件チェック失敗")
        return
    end
    
    -- 食事効果チェック・使用
    -- v2.4.0: 食事機能簡略化
    
    -- 地図タイプ別ジョブ変更
    if not ChangeJobForMapType() then
        LogWarn("ジョブ変更に失敗しましたが処理を継続します")
    end
    
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
    -- 非戦闘時はBMRをオフにする（地図購入中は戦闘しないため）
    local hasBMR, bmrName = HasCombatPlugin("bmr")
    if hasBMR or true then  -- 常に実行（プラグイン検出失敗時も対応）
        yield("/bmrai off")
        LogInfo("地図購入フェーズ開始 - BMRai無効化 (非戦闘時)")
        Wait(0.5)
    end
    
    -- 食事効果チェック（フェーズ開始時）
    -- v2.4.0: 食事機能簡略化
    
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
        
        -- テレポート前に検索画面が開いている場合は閉じる
        if IsAddonVisible("ItemSearch") then
            LogInfo("検索画面を閉じてからテレポートします")
            yield("/pcall ItemSearch True -1")
            Wait(2)
        end
        
        -- CBT /tpflagコマンドを優先使用
        if TeleportToFlag() then
            LogInfo("CBT /tpflag テレポート完了")
            ChangePhase("MOVEMENT", "地図解読・CBTテレポート完了")
            return
        end
        
        -- CBT未使用時のフォールバック処理
        LogInfo("CBT未使用 - 従来のテレポート処理を実行")
        
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
                            
                            -- 座標別テレポート先変更チェック
                            if Instances.Map.Flag.Vector3 then
                            end
                            
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
        -- テレポート前に検索画面が開いている場合は閉じる
        if IsAddonVisible("ItemSearch") then
            LogInfo("検索画面を閉じてからリムサ・ロミンサにテレポートします")
            yield("/pcall ItemSearch True -1")
            Wait(2)
        end
        
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
            yield("/vnav movetarget")  -- v2.4.0: シンプルな移動
            Wait(3)
            
            local moveTimeout = 15
            local moveStartTime = os.clock()
            while GetDistanceToTarget() > 3.0 and not IsTimeout(moveStartTime, moveTimeout) do
                Wait(1)
            end
            yield("/vnav stop") -- v2.4.0シンプル版
        end
        
        -- マーケットボードとインタラクト
        LogInfo("マーケットボードとインタラクト")
        yield("/interact")
        Wait(3)
        
        -- 地図自動購入処理（正しいpcallシーケンス使用）
        LogInfo("マーケットボードで" .. CONFIG.MAP_TYPE .. "地図を自動購入中...")
        
        -- マーケットボード検索画面表示待機（手動チェック）
        LogInfo("マーケットボード検索画面の表示を待機中...")
        local searchWaitTime = os.clock()
        while not IsAddonVisible("ItemSearch") and not IsTimeout(searchWaitTime, 10) do
            Wait(0.5)
        end
        
        if IsAddonVisible("ItemSearch") then
            LogInfo("ItemSearch画面表示確認")
        else
            LogWarn("ItemSearch画面表示タイムアウト - 手動操作を推奨")
        end
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
        
        -- 2. 検索結果画面表示待機（手動チェック）
        LogInfo("検索結果画面の表示を待機中...")
        local resultWaitTime = os.clock()
        while not IsAddonVisible("ItemSearchResult") and not IsTimeout(resultWaitTime, 10) do
            Wait(0.5)
        end
        
        if IsAddonVisible("ItemSearchResult") then
            LogInfo("ItemSearchResult画面表示確認")
        else
            LogWarn("ItemSearchResult画面表示タイムアウト - 手動操作を推奨")
        end
        Wait(0.5)
        
        -- 3. アイテム履歴を閉じる
        yield("/pcall ItemHistory True -1")
        Wait(0.5)
        
        -- 4. 価格チェック（価格制限機能有効時）
        if CONFIG.PRICE_LIMITS.ENABLED then
            LogInfo("価格情報を取得中...")
            Wait(1) -- 価格情報表示待機
            
            local price = GetMarketBoardPrice(searchTerm)
            if price then
                local canPurchase, shouldChangeWorld = CheckPriceLimit(price, CONFIG.MAP_TYPE .. "地図")
                
                if not canPurchase then                   
                    if shouldChangeWorld then
                        LogInfo("ワールド変更処理を実行します")
                        -- ワールド変更は HandleExpensiveItem 内で実行される
                        -- 成功した場合はマーケットボード再接近も完了している
                        -- MAP_PURCHASEフェーズを継続（最初から再実行）
                        return
                    else
                        -- 検索画面を閉じる（ワールド変更なしの場合のみ）
                        yield("/pcall ItemSearch True -1")
                        Wait(2)
                        
                        LogWarn("価格制限により地図購入をスキップしました")
                        LogInfo("手動で" .. CONFIG.MAP_TYPE .. "地図を準備してください")
                        ChangePhase("COMPLETE", "価格制限による購入スキップ")
                        return
                    end
                end
            else
                LogWarn("価格情報を取得できませんでした - 購入を続行します")
            end
        end
        
        -- 5. 最初のアイテムを選択（購入画面表示）
        LogInfo("最初のアイテムを選択中...")
        yield("/pcall ItemSearchResult True 2 0")
        Wait(2)
        
        -- 6. 購入確認ダイアログの処理
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
        
        -- 新しい移動開始時にログフラグをリセット
        flagCoordinatesLogged = false
        yCoordinateWarningLogged = false
        
        -- 非戦闘時はBMRをオフにする
        local hasBMR, bmrName = HasCombatPlugin("bmr")
        if hasBMR or true then  -- 常に実行（プラグイン検出失敗時も対応）
            yield("/bmrai off")
            LogInfo("移動フェーズ開始 - BMRai無効化 (非戦闘時)")
            Wait(0.5)
        end
        
        -- 食事効果チェック（移動開始時）
        -- v2.4.0: 食事機能簡略化
        
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
                    -- 座標別Y修正とテレポート処理
                    local teleportHandled = false
                    
                    if math.abs(flagPos.X - 525.47) < 1.0 and math.abs(flagPos.Z - (-799.65)) < 1.0 then
                        flagPos.Y = 22.0
                        LogInfo("移動時Y座標修正適用: X=" .. string.format("%.2f", flagPos.X) .. ", Z=" .. string.format("%.2f", flagPos.Z) .. " → Y=22.0")
                        -- テレポートは実行しない（烈士庵削除）
                    elseif math.abs(flagPos.X - 219.05) < 1.0 and math.abs(flagPos.Z - (-66.08)) < 1.0 then
                        flagPos.Y = 95.224
                        LogInfo("移動時Y座標修正適用: X=" .. string.format("%.2f", flagPos.X) .. ", Z=" .. string.format("%.2f", flagPos.Z) .. " → Y=95.224")
                        teleportHandled = HandleCoordinateTeleport(flagPos.X, flagPos.Z, flagPos.Y)
                    else
                        if not yCoordinateWarningLogged then
                            LogWarn("移動時Y座標が0です。そのまま使用します")
                            yCoordinateWarningLogged = true
                        end
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
                        
                        -- v2.4.0: シンプルな飛行移動
                        yield("/vnav flyflag")
                        return true
                    else
                        -- フォールバック: シンプルな飛行移動
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
                LogWarn("フラグ座標の取得に失敗しました - シンプル飛行移動")
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
                    
                    -- ターゲットに向かって飛行移動（v2.4.0新API）
                    LogInfo("ドマ反乱軍の門兵にVNavMoveToTargetで飛行接近中...")
                    yield("/vnav movetarget")  -- v2.4.0: シンプルな移動
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
                        if false then  -- 従来コマンド使用に統一
                            -- パス計算中・移動中チェック：動作中なら実行をスキップ
                            if IsVNavMoving() then
                                return true  -- スキップするが成功として扱う
                            end
                            
                            -- v2.4.0: シンプルな移動
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
                    
                    yield("/vnav flyflag")  -- v2.4.0: シンプルな飛行
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
                        -- 座標別Y修正とテレポート処理
                        local teleportHandled = false
                        
                        if math.abs(flagPos.X - 525.47) < 1.0 and math.abs(flagPos.Z - (-799.65)) < 1.0 then
                            flagPos.Y = 22.0
                            LogInfo("追加移動時Y座標修正適用: X=" .. string.format("%.2f", flagPos.X) .. ", Z=" .. string.format("%.2f", flagPos.Z) .. " → Y=22.0")
                            -- テレポートは実行しない（烈士庵削除）
                        elseif math.abs(flagPos.X - 219.05) < 1.0 and math.abs(flagPos.Z - (-66.08)) < 1.0 then
                            flagPos.Y = 95.224
                            LogInfo("追加移動時Y座標修正適用: X=" .. string.format("%.2f", flagPos.X) .. ", Z=" .. string.format("%.2f", flagPos.Z) .. " → Y=95.224")
                            teleportHandled = HandleCoordinateTeleport(flagPos.X, flagPos.Z, flagPos.Y)
                        else
                            if not yCoordinateWarningLogged then
                                LogWarn("追加移動時Y座標が0です。そのまま使用します")
                                yCoordinateWarningLogged = true
                            end
                        end
                    end
                    
                    LogInfo("追加移動先座標: X=" .. string.format("%.2f", flagPos.X) .. ", Y=" .. string.format("%.2f", flagPos.Y) .. ", Z=" .. string.format("%.2f", flagPos.Z))
                    
                    local moveSuccess = SafeExecute(function()
                        if false then  -- 従来コマンド使用に統一
                            if IsVNavMoving() then
                                return true
                            end
                            
                            local shouldFly = IsPlayerMounted() and CanFly()
                            SafeExecute(function()
                                yield("/vnav flyflag")  -- v2.4.0: シンプルな飛行
                            end, "IPC vnavmesh PathfindAndMoveTo failed", 0)
                            return true
                        else
                            -- フォールバック: vnavmeshコマンド使用も安全化
                            SafeExecute(function()
                                yield("/vnav flyflag")  -- v2.4.0: シンプルな飛行
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
                        yield("/vnav flyflag")  -- v2.4.0: シンプルな飛行
                    end, "Fallback vnav flyflag failed", 0)
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
                        -- 座標別Y修正とテレポート処理
                        local teleportHandled = false
                        
                        if math.abs(flagPos.X - 525.47) < 1.0 and math.abs(flagPos.Z - (-799.65)) < 1.0 then
                            flagPos.Y = 22.0
                            LogInfo("緊急再移動時Y座標修正適用: X=" .. string.format("%.2f", flagPos.X) .. ", Z=" .. string.format("%.2f", flagPos.Z) .. " → Y=22.0")
                            -- テレポートは実行しない（烈士庵削除）
                        elseif math.abs(flagPos.X - 219.05) < 1.0 and math.abs(flagPos.Z - (-66.08)) < 1.0 then
                            flagPos.Y = 95.224
                            LogInfo("緊急再移動時Y座標修正適用: X=" .. string.format("%.2f", flagPos.X) .. ", Z=" .. string.format("%.2f", flagPos.Z) .. " → Y=95.224")
                            teleportHandled = HandleCoordinateTeleport(flagPos.X, flagPos.Z, flagPos.Y)
                        else
                            if not yCoordinateWarningLogged then
                                LogWarn("緊急再移動時Y座標が0です。そのまま使用します")
                                yCoordinateWarningLogged = true
                            end
                        end
                    end
                    
                    LogInfo("緊急再移動先座標: X=" .. string.format("%.2f", flagPos.X) .. ", Y=" .. string.format("%.2f", flagPos.Y) .. ", Z=" .. string.format("%.2f", flagPos.Z))
                    
                    local moveSuccess = SafeExecute(function()
                        if false then  -- 従来コマンド使用に統一
                            -- パス計算中・移動中チェック：動作中なら実行をスキップ
                            if IsVNavMoving() then
                                return true  -- スキップするが成功として扱う
                            end
                            
                            SafeExecute(function()
                                yield("/vnav flyflag")  -- v2.4.0: シンプルな飛行
                            end, "vnav flyflag restart failed", 0)
                            return true
                        else
                            SafeExecute(function()
                                yield("/vnav flyflag")  -- v2.4.0: シンプルな飛行
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

-- 転送魔紋検出・インタラクト関数（強化版）
local function CheckForTransferPortal()
    local portalTargets = {"転送魔紋", "魔紋", "転送装置", "転送陣"}
    
    for _, targetName in ipairs(portalTargets) do
        yield("/target " .. targetName)
        Wait(1)
        
        if HasTarget() then
            -- 実際のターゲット名を確認
            local actualTargetName = GetTargetName()
            LogDebug("転送魔紋検索: " .. targetName .. " → ターゲット: " .. tostring(actualTargetName))
            
            if actualTargetName and string.find(actualTargetName, targetName) then
                LogInfo("転送魔紋発見: " .. targetName .. " (実際: " .. actualTargetName .. ")")
            
            -- インタラクト前の準備
            -- 1. BMRaiを無効化
            yield("/bmrai off")
            Wait(0.5)
            
            -- 2. マウントから降車
            if IsPlayerMounted() then
                LogInfo("転送魔紋インタラクト前にマウントから降車")
                yield("/mount")
                Wait(2)
            end
            
            -- 3. 距離チェックと移動
            local distance = GetDistanceToTarget()
            if distance > 5.0 then
                LogInfo("転送魔紋に接近中... (距離: " .. string.format("%.2f", distance) .. "yalm)")
                yield("/automove on")
                
                -- 接近タイムアウト（10秒）
                local moveTimeout = 10
                local moveStart = os.clock()
                
                while GetDistanceToTarget() > 5.0 and os.clock() - moveStart < moveTimeout do
                    Wait(0.5)
                end
                
                yield("/automove off")
                LogInfo("転送魔紋に接近完了 (距離: " .. string.format("%.2f", GetDistanceToTarget()) .. "yalm)")
            end
            
            -- 4. 転送魔紋を再ターゲットしてインタラクト
            LogInfo("転送魔紋とインタラクト実行: " .. targetName)
            yield("/target " .. targetName)
            Wait(0.5)
            
            if HasTarget() then
                yield("/interact")
                LogInfo("転送魔紋インタラクト完了")
                Wait(5) -- 転送待機時間を延長
                
                -- ダンジョンに転送されたかチェック
                if IsInDuty() then
                    LogInfo("転送魔紋経由でダンジョンに転送されました")
                    return true
                else
                    LogWarn("転送魔紋インタラクト後もダンジョンに移行していません - 再試行")
                    -- 再試行のため次のターゲットに進む
                end
            else
                LogWarn("転送魔紋の再ターゲットに失敗: " .. targetName)
            end
            else
                LogDebug("ターゲット名が一致しません: " .. tostring(actualTargetName) .. " ≠ " .. targetName)
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
        LogInfo("宝箱発見 - インタラクト前に修理実行")
        
        -- 【修理実行箇所】宝箱インタラクト前にのみ修理を実行
        -- この箇所以外では修理を実行しない
        PerformRepair()
        
        LogInfo("修理完了 - 宝箱への移動とインタラクト開始")
        
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
                    -- v2.4.0新API: VNavMoveToTargetで移動
                    SafeExecute(function()
                        return yield("/vnav movetarget")  -- v2.4.0: シンプルな移動
                    end, "Failed to start VNavMoveToTarget to treasure chest")
                    
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
                    yield("/vnav movetarget")  -- v2.4.0: シンプルな移動
                    Wait(2)
                end
            else
                LogWarn("vnavmeshが準備できていません")
                yield("/vnav movetarget")  -- v2.4.0: シンプルな移動
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
                        if false then  -- 従来コマンド使用に統一
                            VNavMoveToTarget(true) -- v2.4.0新API: 飛行移動  -- fly=true
                        else
                            -- フォールバック: コマンド実行
                            yield("/vnav movetarget")  -- v2.4.0: シンプルな移動
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
                    yield("/vnav movetarget")  -- v2.4.0: シンプルな移動
                    Wait(1)
                end
            else
                LogWarn("vnavmeshが利用できません - コマンドフォールバック")
                yield("/vnav movetarget")  -- v2.4.0: シンプルな移動
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
        
        -- インタラクト前にBMRaiを無効化（自動移動阻害防止）
        -- HasCombatPlugin関数を使用して確実に検出
        local hasBMR, bmrName = HasCombatPlugin("bmr")
        if hasBMR then
            yield("/bmrai off")
            LogInfo("宝箱インタラクト前にBMRai無効化 (プラグイン: " .. tostring(bmrName) .. ")")
            Wait(0.5)
        else
            -- フォールバック: 直接コマンドを試行
            yield("/bmrai off")
            LogDebug("BMRプラグイン未検出 - 念のためBMRaiオフコマンド実行")
            Wait(0.5)
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
    -- デバッグダンプは一時無効化（ログが埋まるため）
    -- if CONFIG.DEBUG.ENABLED then
    --     LogInfo("=== 戦闘フェーズ開始 - Svc.Condition状態確認 ===")
    --     DumpAllSvcConditions()
    -- end
    
    local isInCombat = IsInCombat()
    
    -- 戦闘中の処理
    if isInCombat then
        -- 戦闘開始時にcombatEndTimeをリセット（v2.5.4追加）
        if combatEndTime then
            LogDebug("戦闘再開検出 - 様子見期間をリセット")
            combatEndTime = nil
        end
        
        if not combatPluginsEnabled then
            LogInfo("戦闘開始 - 自動戦闘プラグイン有効化中")
            EnableCombatPlugins()
            LogInfo("自動戦闘プラグイン有効化完了")
        end
        return -- 戦闘中は待機
    else
        -- 戦闘終了後の処理（v2.5.4強化: 5秒間様子見機能追加）
        -- combatEndTimeが未設定なら設定（戦闘終了の瞬間を記録）
        if not combatEndTime then
            combatEndTime = os.clock()
            LogInfo("戦闘終了を仮検出 - 5秒間様子見開始")
            return -- 様子見期間開始
        end
        
        -- 5秒間の様子見期間中
        local combatEndElapsed = os.clock() - combatEndTime
        if combatEndElapsed < 5.0 then
            LogDebug(string.format("戦闘終了様子見中... (%.1f/5.0秒)", combatEndElapsed))
            return -- まだ様子見期間中
        end
        
        LogInfo("5秒間の様子見完了 - 戦闘終了を確定")
        combatEndTime = nil -- リセット
        
        -- 追加確認: 周辺敵の存在チェック
        if CheckForNearbyEnemies() then
            LogWarn("様子見後に周辺敵を検出 - 戦闘継続")
            if not combatPluginsEnabled then
                EnableCombatPlugins()
                LogInfo("周辺敵検出により戦闘プラグイン再有効化")
            end
            return -- 戦闘継続
        end
        
        if combatPluginsEnabled then
            LogInfo("戦闘終了確認 - 自動戦闘プラグイン無効化")
            DisableCombatPlugins()
            Wait(2) -- 状態安定化待機
        end
        
        -- ダンジョン検出（GetCharacterCondition(34)のみ）
        if IsInDuty() then
            ChangePhase("DUNGEON", "ダンジョンに転送されました")
            return
        end
        
        -- 宝箱インタラクト処理（初回のみ）
        if not treasureChestInteracted then
            if CheckForTreasureChest() then
                LogInfo("宝箱インタラクト完了、戦闘開始")
                return
            end
            
            -- 宝箱が見つからない場合は発掘失敗
            LogInfo("発掘失敗を検出 - 次の地図に移行します")
            ChangePhase("COMPLETE", "発掘失敗、次の地図処理")
            return
        end
        
        -- 宝箱インタラクト済みの場合：戦闘終了後の処理
        
        -- 戦闘後の簡単な宝箱回収
        yield("/target 宝箱")
        Wait(1)
        if HasTarget() and GetDistanceToTarget() <= 10 then
            yield("/interact")
            Wait(2)
            LogInfo("戦闘後の宝箱回収完了")
            
            -- 宝箱インタラクト後のターゲット解除
            yield("/target clear")
            Wait(0.5)
            LogDebug("宝箱回収後のターゲット解除完了")
        end
        
        -- 転送魔紋チェック（戦闘後に発生する可能性）
        if CheckForTransferPortal() then
            LogInfo("戦闘後に転送魔紋を検出しました")
            return -- ダンジョンフェーズに自動移行
        end
        
        -- 戦闘後タイムアウト制御（転送魔紋が出現しない場合の強制完了）
        if combatStartTime > 0 then
            local combatElapsedTime = os.clock() - combatStartTime
            if combatElapsedTime > 60 then -- 1分間転送魔紋を待機
                LogWarn(string.format("転送魔紋待機タイムアウト（%.1f秒経過） - 戦闘完了として処理", combatElapsedTime))
                ChangePhase("COMPLETE", "転送魔紋タイムアウト、戦闘完了")
                return
            end
        else
            -- combatStartTimeが設定されていない場合のフォールバック
            LogWarn("戦闘開始時刻が未記録 - 戦闘完了として処理")
            ChangePhase("COMPLETE", "戦闘開始時刻未記録、戦闘完了")
            return
        end
        
        -- 完了処理（転送魔紋が見つからない場合）
        if combatStartTime > 0 then
            local combatElapsedTime = os.clock() - combatStartTime
            LogDebug(string.format("転送魔紋未検出 - 継続待機中...（経過時間: %.1f秒/60秒）", combatElapsedTime))
        else
            LogDebug("転送魔紋未検出 - 継続待機中...")
        end
        
        -- 戦闘フェーズ長期化防止：30秒以上経過した場合は強制完了
        local currentTime = os.clock()
        if phaseStartTime > 0 and (currentTime - phaseStartTime) > 30 then
            LogWarn(string.format("戦闘フェーズ長期化検出（%.1f秒経過） - 強制完了", currentTime - phaseStartTime))
            ChangePhase("COMPLETE", "戦闘フェーズタイムアウト")
            return
        end
        return -- 継続して転送魔紋を待機
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
            "宝箱"  -- 宝箱のみ
        }
        
        for _, targetName in ipairs(targetPriorities) do
            yield("/target " .. targetName)
            Wait(0.3)
            
            if HasTarget() then
                local distance = GetDistanceToTarget()
                local targetDistance = CONFIG.TARGET_DISTANCES.TREASURE_CHEST
                
                -- 距離999.0の場合、ダンジョン脱出をチェック
                if distance >= 999.0 then
                    if not IsInDuty() then
                        yield("/automove off")
                        LogInfo("ダンジョン脱出を検出 - 前進探索を停止")
                        return "dungeon_exit"
                    end
                end
                
                if distance <= targetDistance then
                    yield("/automove off")
                    LogInfo("前進探索完了: " .. targetName .. "を発見（距離: " .. string.format("%.1f", distance) .. "）")
                    Wait(1)
                    return targetName
                else
                    LogInfo("" .. targetName .. "発見（距離: " .. string.format("%.1f", distance) .. "）- vnavでターゲット移動中")
                    
                    -- vnavmeshを使ってターゲットに移動
                    yield("/automove off")
                    Wait(0.5)
                    yield("/vnav movetarget")  -- v2.4.0: シンプルな移動
                    Wait(1)
                    
                    -- 移動開始確認のため少し待機
                    local moveStartTime = os.clock()
                    while os.clock() - moveStartTime < 10 and HasTarget() do
                        local currentDistance = GetDistanceToTarget()
                        if currentDistance <= targetDistance then
                            yield("/vnav stop") -- v2.4.0シンプル版
                            LogInfo("vnav移動完了: " .. targetName .. " (最終距離: " .. string.format("%.1f", currentDistance) .. ")")
                            Wait(1)
                            return targetName
                        end
                        Wait(0.5)
                    end
                    
                    -- vnavでの移動が完了しない場合は従来の前進継続
                    yield("/vnav stop") -- v2.4.0シンプル版
                    LogInfo("vnav移動タイムアウト - automove前進に切り替え")
                    yield("/automove on")
                end
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
                yield("/vnav movetarget")  -- v2.4.0: シンプルな移動
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
            
            -- インタラクト前にBMRaiを無効化
            local hasBMR, bmrName = HasCombatPlugin("bmr")
            if hasBMR then
                yield("/bmrai off")
                LogInfo("ダンジョン宝物インタラクト前にBMRai無効化 (プラグイン: " .. tostring(bmrName) .. ")")
                Wait(0.5)
            else
                yield("/bmrai off")
                LogDebug("BMRプラグイン未検出 - 念のためダンジョン宝物インタラクトBMRaiオフコマンド実行")
                Wait(0.5)
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
                yield("/vnav movetarget")  -- v2.4.0: シンプルな移動
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

-- ボス撃破フラグ（無限ループ防止）
local bossDefeated = false

local function CheckForBoss()
    -- 既にボスを撃破済みの場合はスキップ
    if bossDefeated then
        return false
    end
    
    local bossTargets = {"ブルアポリオン", "ゴールデン・モルター"}
    
    for _, bossName in ipairs(bossTargets) do
        yield("/target " .. bossName)
        Wait(0.5)
        
        if HasTarget() then
            LogInfo("最終層ボス発見: " .. bossName)
            
            -- インベントリチェック（ボス戦前）
            local inventoryResult = CheckAndManageInventory()
            if not inventoryResult then
                LogError("インベントリ満杯でボス戦を開始できません")
                ChangePhase("ERROR", "インベントリ満杯")
                return false
            end
            
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
                bossDefeated = true  -- ボス撃破フラグを設定
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
-- 戻り値: インタラクト成功, 階層進行フラグ
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
    
    -- 脱出地点を常に追加（最終層検出問題対策）
    -- 宝箱・皮袋がない場合に脱出地点をターゲット
    table.insert(targets, {
        names = {"脱出地点", "退出", "出口", "転送魔法陣", "帰還魔法陣"},
        description = "脱出地点"
    })
    
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
                        yield("/vnav movetarget")  -- v2.4.0: シンプルな移動
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
                    
                    -- インタラクト前にBMRaiを無効化
                    local hasBMR, bmrName = HasCombatPlugin("bmr")
                    if hasBMR then
                        yield("/bmrai off")
                        LogInfo("ダンジョン内ターゲットインタラクト前にBMRai無効化 (プラグイン: " .. tostring(bmrName) .. ")")
                        Wait(0.5)
                    else
                        yield("/bmrai off")
                        LogDebug("BMRプラグイン未検出 - 念のためダンジョン内ターゲットインタラクトBMRaiオフコマンド実行")
                        Wait(0.5)
                    end
                    
                    -- インタラクト実行
                    LogInfo(actualTargetName .. "とインタラクト実行")
                    yield("/interact")
                    Wait(2)
                    
                    -- 階層進行検出（宝物庫の扉/召喚魔法陣のみ）
                    local floorProgressDetected = false
                    if priorityIndex == 3 then  -- 宝物庫の扉/召喚魔法陣グループ
                        -- 階層進行判定のため少し待機
                        LogDebug("階層進行検出のため追加待機中...")
                        Wait(3)
                        
                        -- プレイヤーがまだダンジョン内にいる場合は階層進行とみなす
                        if IsInDuty() and not IsInCombat() then
                            floorProgressDetected = true
                            LogInfo("階層進行検出: " .. actualTargetName .. "により次の階層へ移動")
                        end
                    end
                    
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
                    
                    -- インタラクト成功と階層進行フラグを返す
                    return true, floorProgressDetected
                end
            end
            
            ::next_target::
        end
    end
    
    return false, false  -- インタラクト失敗, 階層進行なし
end

local function ExecuteDungeonPhase()
    LogInfo("ダンジョン探索を開始します")
    
    -- ダンジョン脱出チェック（最優先）- 共通関数使用
    if not IsCurrentlyInTreasureDungeon() then
        LogInfo("ダンジョン外にいることを検出 - 完了フェーズに移行")
        ChangePhase("COMPLETE", "ダンジョン脱出完了")
        return
    end
    
    -- ダンジョン開始時に戦闘プラグインを有効化
    if IsInCombat() then
        EnableCombatPlugins()
        local hasBMR, bmrName = HasCombatPlugin("bmr")
        if hasBMR then
            yield("/bmrai on")
            LogInfo("ダンジョン開始時戦闘中: BMRAIを有効化 (プラグイン: " .. tostring(bmrName) .. ")")
            Wait(0.5)
        else
            yield("/bmrai on")
            LogInfo("ダンジョン開始時戦闘中: BMRAIを有効化 (フォールバック)")
            Wait(0.5)
        end
    end
    
    -- 食事効果チェック（ダンジョン開始時）
    -- v2.4.0: 食事機能簡略化
    
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
                    yield("/vnav movetarget")  -- v2.4.0: シンプルな移動
                    
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
    
    -- 戦闘プラグインは戦闘時のみ有効化するため、ここでは無効化状態を確保
    if combatPluginsEnabled then
        LogInfo("ダンジョン開始前に戦闘プラグインを無効化")
        DisableCombatPlugins()
    end
    
    local dungeonStartTime = os.clock()
    
    -- _TodoListから動的に階層情報を取得
    local currentFloor, maxFloors = GetCurrentFloorFromTodoList()
    LogInfo("_TodoListから取得した初期階層情報: " .. currentFloor .. "/" .. maxFloors)
    
    local combatStartTime = nil
    local combatTimeout = 120  -- 2分の戦闘タイムアウト
    
    while IsInDuty() and not IsTimeout(dungeonStartTime, CONFIG.TIMEOUTS.DUNGEON) do
        -- プレイヤー状態変数をループの先頭で宣言（gotoスコープ対策）
        local playerAvailable, playerMoving
        
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
            -- 戦闘開始時の処理
            if combatStartTime == nil then
                combatStartTime = os.clock()
                LogInfo("ダンジョン戦闘開始を検出")
            end
            
            -- 戦闘プラグインが無効化されていれば有効化
            if not combatPluginsEnabled then
                LogInfo("戦闘中 - 自動戦闘プラグイン有効化")
                EnableCombatPlugins()
            end
            
            -- 戦闘タイムアウトチェック
            if IsTimeout(combatStartTime, combatTimeout) then
                LogWarn("戦闘タイムアウト (" .. combatTimeout .. "秒) - 戦闘終了とみなして継続")
                combatStartTime = nil
                -- タイムアウト時は戦闘プラグインを無効化
                if combatPluginsEnabled then
                    LogInfo("戦闘タイムアウト - 戦闘プラグイン無効化")
                    DisableCombatPlugins()
                end
                goto continue
            end
            
            Wait(2)
        else
            -- 戦闘終了後の処理
            if combatStartTime ~= nil then
                LogInfo("戦闘終了を検出")
                combatStartTime = nil  -- リセット
                
                -- 戦闘終了時に戦闘プラグインを無効化
                if combatPluginsEnabled then
                    LogInfo("戦闘終了 - 戦闘プラグイン無効化")
                    DisableCombatPlugins()
                    Wait(1)
                end
            end
            
            -- 戦闘していない場合は戦闘プラグインが有効なら無効化
            if combatPluginsEnabled then
                LogInfo("非戦闘中 - 戦闘プラグイン無効化")
                DisableCombatPlugins()
            end
            -- v2.5.3修正: goto continue削除 - 非戦闘中でも探索処理を継続
        end
        
        -- プレイヤーが操作可能で移動していない場合の処理
        -- ローカル変数はループ先頭で宣言済み、ここで値を取得
        playerAvailable = IsPlayerAvailable()
        playerMoving = IsPlayerMoving()
        LogInfo(string.format("プレイヤー状態チェック: Available=%s, Moving=%s", tostring(playerAvailable), tostring(playerMoving)))
        
        if playerAvailable and not playerMoving then
            -- ボスチェック（全階層で実行）
            if CheckForBoss() then
                LogInfo("ボス撃破完了")
                goto continue
            end
            
            -- Priority-based unified target system
            LogDebug("ターゲット検索システム呼び出し中...")
            local interacted, floorProgressed = CheckAndInteractPriorityTargets(currentFloor, maxFloors)
            LogDebug(string.format("ターゲット検索結果: interacted=%s, floorProgressed=%s", tostring(interacted), tostring(floorProgressed)))
            
            -- Floor progression check
            if floorProgressed then
                local oldFloor = currentFloor
                currentFloor = currentFloor + 1
                
                -- Sync latest floor info from _ToDoList
                local todoCurrentFloor, todoMaxFloors = GetCurrentFloorFromTodoList()
                if todoCurrentFloor >= currentFloor then
                    currentFloor = todoCurrentFloor
                    maxFloors = todoMaxFloors
                    LogInfo("階層進行: " .. oldFloor .. "/" .. maxFloors .. " → " .. currentFloor .. "/" .. maxFloors .. " (_ToDoList同期済み)")
                else
                    LogInfo("階層進行: " .. oldFloor .. "/" .. maxFloors .. " → " .. currentFloor .. "/" .. maxFloors .. " (ローカル推定)")
                end
                
                -- Final floor check (continue even beyond 5F)
                -- Continue dungeon exploration even when floor > 5
                LogDebug("現在の階層: " .. currentFloor .. "/" .. maxFloors .. " (継続探索)")
            end
            
            if not interacted then
                -- 宝箱・皮袋が見つからない場合、脱出地点を積極的に検索
                LogInfo("宝箱・皮袋未発見 - 脱出地点を優先検索中...")
                
                local exitTargets = {"脱出地点", "退出", "出口", "転送魔法陣", "帰還魔法陣"}
                local exitFound = false
                
                for _, exitName in ipairs(exitTargets) do
                    yield("/target " .. exitName)
                    Wait(0.5)
                    if HasTarget() then
                        local targetName = GetTargetName()
                        local distance = GetDistanceToTarget()
                        LogInfo("脱出地点発見: " .. targetName .. " (距離: " .. string.format("%.2f", distance) .. "yalm)")
                        
                        -- 距離が遠い場合は接近
                        if distance > 3.0 and IsVNavReady() then
                            LogInfo("脱出地点に接近中...")
                            yield("/vnav movetarget")  -- v2.4.0: シンプルな移動
                            Wait(2)
                            
                            -- 接近完了待機
                            local approachTimeout = 10
                            local approachStart = os.clock()
                            while GetDistanceToTarget() > 3.0 and not IsTimeout(approachStart, approachTimeout) do
                                Wait(0.5)
                            end
                            yield("/vnav stop") -- v2.4.0シンプル版
                        end
                        
                        -- 脱出地点インタラクト
                        yield("/interact")
                        Wait(2)
                        LogInfo("脱出地点インタラクト実行 - ダンジョン脱出中")
                        exitFound = true
                        break
                    end
                end
                
                if not exitFound then
                    -- 脱出地点も見つからない場合は前進探索
                    local foundTarget = AutoMoveForward()
                    if foundTarget then
                        if foundTarget == "dungeon_exit" then
                            LogInfo("ダンジョン脱出を検出 - 完了フェーズに移行")
                            ChangePhase("COMPLETE", "ダンジョン脱出完了")
                            return
                        else
                            LogInfo("前進探索で発見: " .. foundTarget .. " - 次回ループで処理")
                        end
                    end
                end
            end
        else
            -- プレイヤーが操作不可能または移動中の場合
            if not playerAvailable then
                LogDebug("プレイヤーが操作不可能状態 - 待機中")
            elseif playerMoving then
                LogDebug("プレイヤー移動中 - 待機中")
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

-- 地図購入失敗カウンター（グローバル変数）
local mapPurchaseFailCount = 0
local MAX_PURCHASE_FAIL_COUNT = 3

-- 完了フェーズ
local function ExecuteCompletePhase()
    LogInfo("トレジャーハント完了！")
    
    -- 完了時も戦闘プラグインを無効化
    DisableCombatPlugins()
    LogInfo("完了フェーズ - 自動戦闘プラグイン無効化")
    
    -- 次の地図があるかチェック
    local mapConfig = CONFIG.MAPS[CONFIG.MAP_TYPE]
    local mapCount = GetItemCount(mapConfig.itemId)
    
    if mapCount > 0 then
        LogInfo("次の地図が見つかりました。続行します")
        mapPurchaseFailCount = 0  -- 成功時はカウンターリセット
        ChangePhase("MAP_PURCHASE", "次の地図を処理")
    else
        -- 地図購入失敗が連続している場合は終了
        if mapPurchaseFailCount >= MAX_PURCHASE_FAIL_COUNT then
            LogInfo("地図購入に" .. MAX_PURCHASE_FAIL_COUNT .. "回連続で失敗しました。スクリプトを終了します")
            LogInfo("手動で地図を準備するか、マーケットボードの近くで再実行してください")
            return  -- スクリプト終了
        else
            LogInfo("全ての地図を処理しました - 新しい地図を購入します (失敗回数: " .. mapPurchaseFailCount .. "/" .. MAX_PURCHASE_FAIL_COUNT .. ")")
            ChangePhase("MAP_PURCHASE", "地図購入フェーズに移行")
        end
    end
end

-- エラーフェーズ
local function ExecuteErrorPhase()
    LogError("エラーが発生しました。スクリプトを停止します")
    
    -- 緊急停止処理（利用可能なプラグインのみ）
    DisableCombatPlugins()
    LogInfo("エラー時自動戦闘プラグイン無効化完了")
    yield("/automove off")
    
    -- エラー時安全帰還処理
    LogInfo("エラー時安全帰還: /li innを実行中...")
    yield("/li inn")
    Wait(2)
    LogInfo("安全帰還処理完了")
    
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
    LogInfo("==================== TREASURE HUNT AUTOMATION v2.5.4 開始 ====================")
    LogInfo("【戦闘判定強化版】戦闘終了後5秒間様子見機能・早期判定問題根本解決完了")
    LogInfo("==================== システム初期化中 ====================")
    
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
            -- v2.4.0: 食事機能簡略化
            if not CheckAndManageInventory() then
                break  -- インベントリ満杯の場合はループを終了
            end
            CheckAndExtractMateria()
            -- 【重要】修理は宝箱インタラクト前（CheckForTreasureChest関数内）でのみ実行
            -- MOVEMENTフェーズや他のフェーズでは修理を一切実行しない
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
            -- 緊急安全帰還処理
            LogInfo("最大イテレーション到達 - 緊急安全帰還を実行中...")
            DisableCombatPlugins()
            yield("/automove off")
            yield("/li inn")
            Wait(2)
            LogInfo("緊急安全帰還処理完了")
            break
        end
        
        Wait(1)
    end
    
    -- スクリプト終了時の安全帰還処理
    LogInfo("スクリプト終了 - 安全帰還処理を実行中...")
    yield("/li inn")
    Wait(2)
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
            -- SEHException時の緊急帰還
            LogInfo("SEHException検出 - 緊急安全帰還を実行中...")
            pcall(function() yield("/li inn") end)
        end
        
        -- lua_pcallkエラー特定対策
        if string.find(errorStr, "lua_pcallk") or string.find(errorStr, "CallDelegate") then
            LogError("NLua CallDelegate/lua_pcallkエラー検出")
            LogError("原因: Luaスタック破損またはメモリアクセス違反")
            LogError("推奨対処: 即座にスクリプト停止・SND再起動")
            -- Lua スタック破損時の緊急帰還
            LogInfo("Luaスタック破損検出 - 緊急安全帰還を実行中...")
            pcall(function() yield("/li inn") end)
        end
        
        -- NLuaMacroEngineエラー特定対策
        if string.find(errorStr, "NLuaMacroEngine") then
            LogError("NLuaMacroEngineエラー検出 - マクロエンジン内部エラー")
            LogError("推奨対処: SomethingNeedDoingプラグイン完全再起動")
            -- マクロエンジンエラー時の緊急帰還
            LogInfo("マクロエンジンエラー検出 - 緊急安全帰還を実行中...")
            pcall(function() yield("/li inn") end)
        end
        
        LogError("スクリプト安全終了を実行します")
        return false
    end
    
    return true
end

-- メイン実行
MainLoop()