# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要
FFXIVのトレジャーハント（G10/G17地図）を完全自動化するLuaスクリプトです。SomethingNeedDoing (Expanded Edition) v12.0.0+を使用してFFXIV内で実行される自動化システムです。

## アーキテクチャ

### フェーズベース状態管理システム
スクリプトは7段階のフェーズで動作し、各フェーズは独立した関数として実装されています：

```
INIT → MAP_PURCHASE → MOVEMENT → COMBAT → DUNGEON → COMPLETE → (循環またはERROR)
```

- **フェーズ制御**: `ChangePhase(newPhase, reason)`による状態遷移
- **自動検出**: `DetectCurrentState()`で中途実行からの自動復帰
- **エラー処理**: `SafeExecute()`によるpcall()ベースの包括的エラー処理

### モジュール構造
```
CONFIG設定管理 → ログシステム → ユーティリティ関数 → フェーズ実行関数 → メインループ
```

### 主要コンポーネント

#### 1. 設定管理 (CONFIG)
- 地図タイプ別設定（G17/G10）
- タイムアウト値
- デバッグ設定
- オブジェクト距離設定

#### 2. API抽象化レイヤー
新SND v12.0.0+のモジュールベースAPIを統一インターフェースでラップ：
```lua
-- プレイヤー状態: Player.Available/IsBusy/IsMoving
-- インベントリ: Inventory.GetItemCount()
-- アドオン: Addons.GetAddon().Ready/GetNode().Text
-- プラグイン: IPC.IsInstalled()
```

#### 3. ダンジョンシステム（v5.5.0+）
5層構造の階層型ダンジョンを完全自動化：
- **探索**: AutoMoveForward()による前進探索
- **戦闘**: 宝箱インタラクト→戦闘検出→完了待機
- **回収**: CheckForTreasures()による宝箱・皮袋自動回収
- **進行**: CheckForNextFloor()による階層移動
- **ボス戦**: CheckForBoss()による最終層ボス（ブルアポリオン・ゴールデン・モルター）対応
- **脱出**: CheckForExit()による脱出地点検知

## 開発時の重要事項

### SomethingNeedDoing v12.0.0+ API対応
従来の関数ベースAPIからモジュールベースAPIに完全移行済み：
```lua
-- 旧API (使用禁止)
HasPlugin() → IPC.IsInstalled()
IsAddonVisible() → Addons.GetAddon().Ready
GetItemCount() → Inventory.GetItemCount()
```

### エラー処理パターン
すべての外部API呼び出しは`SafeExecute()`でラップ：
```lua
local function SafeExecute(func, errorMessage)
    local success, result = pcall(func)
    if not success then
        LogError(errorMessage, result)
        return false, result
    end
    return true, result
end
```

### ログシステム
構造化ログシステムでフェーズとタイムスタンプを自動付与：
- `LogInfo()` - 一般情報
- `LogDebug()` - デバッグ情報（CONFIG.DEBUG.ENABLED時のみ）
- `LogError()` - エラー情報

### v6.21.0の改善点（2025-07-13）
**ドマ反乱軍の門兵座標ベース精密ターゲティング機能**
- 既知座標 `<276.35608, 3.6584158, -377.5235>` を使用した距離検証
- 10yalm以内の同名NPCのみをターゲット対象とする精密フィルタリング
- 誤ターゲット防止・確実なインタラクト実行

```lua
-- 実装された座標ベース検証ロジック
local domaGuardPos = {X = 276.35608, Y = 3.6584158, Z = -377.5235}
local distance = math.sqrt(
    (targetPos.X - domaGuardPos.X)^2 + 
    (targetPos.Y - domaGuardPos.Y)^2 + 
    (targetPos.Z - domaGuardPos.Z)^2
)
if distance <= 10.0 then  -- 10yalm以内なら正しい門兵
    -- インタラクト処理実行
end
```

### バージョン管理
新機能追加時は必ず以下を更新：
1. ヘッダーコメントのバージョン番号
2. 変更履歴セクション
3. `MainLoop()`内の実行時ログ表示

## よく使用される開発パターン

### フェーズ実行関数の実装
```lua
local function ExecuteNewPhase()
    LogInfo("新フェーズを開始します")
    
    local phaseStartTime = os.clock()
    
    while not SomeCondition() and not IsTimeout(phaseStartTime, CONFIG.TIMEOUTS.SOME_TIMEOUT) do
        -- フェーズ固有の処理
        if SomeEvent() then
            ChangePhase("NEXT_PHASE", "イベント完了")
            return
        end
        Wait(1)
    end
    
    if IsTimeout(phaseStartTime, CONFIG.TIMEOUTS.SOME_TIMEOUT) then
        LogError("フェーズタイムアウト")
        ChangePhase("ERROR", "タイムアウト")
    end
end
```

### ターゲット検出・インタラクションパターン
```lua
local function CheckForTarget(targetName)
    yield("/target " .. targetName)
    Wait(0.5)
    
    if HasTarget() then
        LogInfo("発見: " .. targetName)
        yield("/interact")
        Wait(2)
        return true
    end
    return false
end
```

### 戦闘制御パターン
```lua
-- 戦闘開始
if HasPlugin("RotationSolverReborn") then
    yield("/rotation auto on")
end
if HasPlugin("BossMod") or HasPlugin("BossModReborn") then
    yield("/bmrai on")
end

-- 戦闘終了時
if HasPlugin("RotationSolverReborn") then
    yield("/rotation auto off")
end
if HasPlugin("BossMod") or HasPlugin("BossModReborn") then
    yield("/bmrai off")
end
```

## 拡張時の注意点

### 新しいボス追加
`CheckForBoss()`関数の`bossTargets`配列に名前を追加するだけで対応可能。

### 新しいダンジョンタイプ対応
`DetectDungeonType()`関数で召喚魔法陣検出ロジックを拡張。

### タイムアウト調整
`CONFIG.TIMEOUTS`で各フェーズのタイムアウト値を調整可能。

## 参考リソース
- SomethingNeedDoing GitHub: https://github.com/Jaksuhn/SomethingNeedDoing
- SNDScripts参考: https://github.com/WigglyMuffin/SNDScripts/
- 関数参考: https://github.com/McVaxius/dhogsbreakfeast/blob/main/_functions.lua

## 重要な開発指示（ユーザー要求事項）

### 今後の作業における必須事項
1. **即座の仕様変更対応**: ユーザーが不要と指摘した機能は即座に削除・修正する
2. **バージョン管理の徹底**: 
   - ヘッダーコメントのバージョン番号更新
   - LogInfo内のバージョン表示更新
   - 変更内容に応じた適切なバージョン説明
3. **CLAUDE.mdへの記録**: 重要な指示や変更要求は都度CLAUDE.mdに記録すること
4. **繰り返し指示の回避**: 一度指摘された事項は二度と繰り返させない

### v6.21.0での対応例
- ユーザー指摘「ドマ反乱軍の門兵インタラクトフラグは不要」→即座に削除実行
- バージョン表示v6.10.0→v6.21.0への一括更新
- 変更内容に応じたログメッセージ更新

### v6.22.0での対応例（2025-07-13）
- Entity.Target nilエラー報告→即座にnilチェック追加修正
- MOVEMENT フェーズでのEntity.Target.Position安全アクセス実装
- GetDistanceToTarget関数のEntity.Target存在チェック強化

### v6.23.0での対応例（2025-07-13）
- ドマ反乱軍の門兵飛行接近無限ループ報告→即座にフラグ再導入修正
- domaGuardInteractedフラグ復活：移動フェーズで1回のみ実行制御
- 無限ループ防止：インタラクト完了後フラグ設定で重複実行回避

### v6.24.0での対応例（2025-07-13）
- ドマ反乱軍の門兵接近方式変更要求→vnav stop + flytarget方式に即座変更
- domaGuardInteractedフラグ削除：座標指定により不要化
- 接近手順最適化：vnav停止→flytarget→インタラクトの確実なフロー

### v6.80.0での対応例（2025-07-13）
- LogDebugログ整理要求→冗長ログを大幅削除（座標・vnavmesh・戦闘状態詳細）
- 重要ログ保持：フェーズ変更詳細・エラー分析用・重要処理フローのみ残留
- パフォーマンス向上：デバッグ出力量大幅削減によりログ負荷軽減

### v1.0.0 安定版リリース（2025-07-13）
- **SEHException完全対策**: IPC危険API無効化・NLua低レベルエラー回避完了
- **無限ループ修正**: ドマ反乱軍の門兵インタラクト後の適切なフラグ管理実装
- **包括的エラー処理**: 多層SafeExecute・システムレベル例外検出・安定性最優先設計
- **本格運用可能**: 長時間連続実行に耐える安定したトレジャーハント自動化システム完成

## 実行環境
- FFXIV + Dalamud + SomethingNeedDoing v12.0.0+
- 必須プラグイン: VNavmesh, RSR, AutoHook, Teleporter
- 推奨ジョブ: G17=ナイト(PLD), G10=戦士(WAR)