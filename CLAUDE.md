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

### v1.0.0 MetaData設定システム実装完了（2025-07-13）

#### 🔧 MetaData設定システム実装
ユーザー要求に基づき、pot0to参考スクリプトに準拠したSND MetaDataベース設定管理システムを実装しました。
- **YAMLライク形式**: `--[=====[ ]=====]` デリミタによる標準的なSND MetaData形式
- **GetConfigValue()関数**: MetaDataから設定値を取得する統一インターフェース実装
- **設定値外部化**: MAP_TYPE、TIMEOUTS、DEBUGをMetaDataベースに変更
- **変更履歴削減**: 最新3件（v1.0.0、v6.89、v6.83）のみに整理
- **将来的な拡張性**: SNDの設定システム連携に対応した設計

#### 🎯 プロジェクト完成概要
FFXIVトレジャーハント（G10/G17地図）完全自動化システムの安定版が完成しました。
長時間連続実行に耐える堅牢な設計により、本格運用が可能な状態に到達。

#### 🛡️ 主要技術的成果
- **SEHException完全対策**: IPC危険API無効化・NLua低レベルエラー回避完了
- **無限ループ修正**: ドマ反乱軍の門兵インタラクト後の適切なフラグ管理実装
- **包括的エラー処理**: 多層SafeExecute・システムレベル例外検出・安定性最優先設計
- **Y座標補正システム**: 既知問題座標での自動修正・移動精度向上

#### 📋 最終必須プラグインリスト
1. **Something Need Doing [Expanded Edition]** v12.0.0.0+ - Luaスクリプト実行
2. **vnavmesh** - 自動ナビゲーション・移動
3. **RotationSolverReborn** - 自動戦闘
4. **BossModReborn** - 戦闘支援・回避支援
5. **Teleporter** - テレポート機能
6. **[Globetrotter](https://github.com/chirpxiv/Globetrotter)** - 地図・座標管理
7. **[YesAlready](https://github.com/PunishXIV/YesAlready)** - 自動確認ダイアログ処理

#### 🏗️ アーキテクチャ設計原則
- **安全性最優先**: 危険API回避・多層エラー処理・システム例外対策
- **安定性重視**: 無限ループ防止・フラグ管理・適切な状態遷移
- **保守性確保**: 構造化ログ・モジュラー設計・コメント充実

#### 💾 ファイル構成（v1.0.0）
```
TreasureDungeonLegacy/
├── TreasureDungeon.lua     # メインスクリプト（157KB、約3600行）
├── README.md               # ユーザー向けドキュメント
├── CLAUDE.md              # 開発者向けドキュメント・作業履歴
└── .git/                  # Gitリポジトリ
```

#### 🎯 完成時点でのスクリプト特徴
- **7段階フェーズ管理**: INIT→MAP_PURCHASE→MOVEMENT→COMBAT→DUNGEON→COMPLETE→ERROR
- **配置座標補正**: X=525.47,Z=-799.65(Y=22.0)・X=219.05,Z=-66.08(Y=95.224)
- **タイムアウト最適化**: 戦闘30分・ダンジョン無制限・移動5分
- **CONFIG完全対応**: G10/G17地図対応・SEHException対策設定

#### 📈 開発統計（v6.47.0→v1.0.0）
- **総開発期間**: 2025-07-13 1日間集中開発
- **バージョン進化**: v6.47.0→v6.89→v1.0.0（42バージョンアップ）
- **主要問題解決**: SEHException・無限ループ・Y座標問題・時間計算オーバーフロー
- **最終コード量**: 約3600行（コメント・変更履歴含む）

#### 🏆 品質保証完了項目
✅ SEHException完全対策  
✅ 無限ループ修正完了  
✅ 包括的エラー処理実装  
✅ Y座標補正システム  
✅ 必須プラグイン最適化  
✅ ドキュメント整備完了  
✅ Git管理・タグ付け完了  

**結論**: v1.0.0により、実用的で安定したFFXIVトレジャーハント自動化システムが完成。

### v1.0.5での対応例（2025-07-14）
- **戦闘中冗長ログ削減完了**: combatPluginsEnabledフラグによる重複検出ログ抑制
- **宝箱インタラクト改善**: 移動前マウント自動召喚システム実装
- **フラッグ座標ログ重複防止**: flagCoordinatesLoggedフラグでVector2+Y座標ログ最適化
- **Y座標フォールバック最適化**: 移動中の「Y=150.0適用」ログ重復削減
- **ユーザー要求即座対応**: 「戦闘中うるさいかも」「マウント乗ってよってから」への即座修正

### v1.2.0での対応例（2025-07-14）
- **CBTプラグイン/tpflag対応**: ユーザー要求に基づくCBTプラグインの/tpflagコマンド実装
- **テレポート処理統一**: 複雑なExcel API処理を/tpflagに置き換えてシンプル化
- **フォールバック機能**: CBT未使用時の従来処理維持・安全性確保
- **推奨プラグイン追加**: ChatCoordinatesプラグインを推奨リストに追加

### v1.1.4 重要なログ出力パターン（常に更新）
**価格取得成功ログの確認事項:**
```
[02:39:44][DEBUG][MAP_PURCHASE] 価格テキスト取得: 24,000
[02:39:44][WARN][MAP_PURCHASE] 価格情報を取得できませんでした - 購入を続行します
```
- 価格取得は成功している（24,000取得）が判定ロジックでエラー扱いになっている
- GetNode(1,26,4,5)で正しく価格を取得しているが、戻り値の処理に問題がある

**価格制限機能の実際の動作:**
- CONFIG.PRICE_LIMITS.ENABLED = true（有効）
- MAX_PRICE = 40000ギル設定
- 実際の価格: 24,000ギル（制限内）
- 期待される動作: 購入続行、制限内ログ表示

## 実行環境
- FFXIV + Dalamud + SomethingNeedDoing v12.0.0+
- 必須プラグイン: VNavmesh, RSR, BossModReborn, Teleporter, Globetrotter, YesAlready
- 推奨ジョブ: G17=ナイト(PLD), G10=戦士(WAR)

## 追加ルール
先頭のコメントにある変更履歴は最新２件のみ
Lua実行時にバージョンと変更点がわかるようにすること
