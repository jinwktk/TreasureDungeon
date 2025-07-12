# TreasureDungeon v3.0+ 実装計画

## 概要
SomethingNeedDoing v12.0.0+対応のトレジャーハント完全自動化スクリプト。  
新しいモジュールベースAPI使用、シンプルで安定した7段階フェーズ管理システム。

## 実装状況（2025-07-12現在）

### ✅ 完了済み
- **v3.0.0-3.0.5**: 基本フレームワーク完成
- **新API対応**: Player.*, Inventory.*, Addons.*, IPC.*
- **フェーズ管理**: 7段階のクリアなフロー制御
- **エラー処理**: SafeExecute関数による堅牢性
- **設定管理**: CONFIG構造体による一元管理

### ⚠️ 現在の課題
- **関数定義順序エラー**: 一部環境で関数が見つからない
- **マーケットボード操作**: APIコールバック値の調整が必要
- **戦闘システム**: RSR/BMRコマンドの検証が必要

## フェーズフロー（v3.0+実装済み）

### 1. 初期化フェーズ (INIT)
```
前提条件チェック → プラグイン確認 → ジョブ確認 → MAP_PURCHASE
```

### 2. 地図購入フェーズ (MAP_PURCHASE)
```
地図所持チェック
├─ 所持あり → ディサイファー → フラグ地点テレポート → MOVEMENT
└─ 所持なし → リムサ・ロミンサテレポート → マーケットボード移動 → 購入 → 再チェック
```

#### 地図購入詳細フロー
```
1. /tp リムサ・ロミンサ でテレポート
2. vnavmeshでマーケットボードに移動（座標: 123.5, 40.2, -38.8）
3. /target マーケットボード でターゲット
4. /interact でマーケットボードを開く
5. 地図名で検索実行
6. 最初の結果を選択・購入
7. SelectYesnoで購入確認
```

### 3. 移動フェーズ (MOVEMENT)
```
vnavmesh移動 → フラグ地点到着 → ディグ実行 → 宝箱発見 → COMBAT
```

### 4. 戦闘フェーズ (COMBAT)
```
戦闘検出 → RSR/BMR起動 → 戦闘終了
├─ ダンジョン転送 → DUNGEON
└─ 転送なし → MOVEMENT（次の宝箱）
```

### 5. ダンジョンフェーズ (DUNGEON)
```
ダンジョン探索 → 宝箱回収 → ミニゲーム処理 → 脱出 → COMPLETE
```

### 6. 完了フェーズ (COMPLETE)
```
次の地図チェック
├─ 地図あり → MAP_PURCHASE（継続）
└─ 地図なし → 終了
```

### 7. エラーフェーズ (ERROR)
```
エラー処理 → 緊急停止 → スクリプト終了
```

## 技術仕様（v3.0+対応済み）

### 新SND v12.0.0+ API使用
```lua
-- プレイヤー状態
Player.Available, Player.IsBusy, Player.IsMoving, Player.Job.Id

-- インベントリ管理
Inventory.GetItemCount(itemId)

-- アドオン制御
Addons.GetAddon("AddonName").Ready
Addons.GetAddon("AddonName").GetNode(nodeId).Text

-- プラグイン検出
IPC.IsInstalled("PluginName")
```

### 設定管理
```lua
CONFIG = {
    MAP_TYPE = "G10", -- G17/G10切り替え
    MAPS = {
        G17 = { itemId = 43557, jobId = 19, searchTerm = "G17" },
        G10 = { itemId = 17836, jobId = 21, searchTerm = "G10" }
    },
    TIMEOUTS = { MOVEMENT = 300, COMBAT = 30, DUNGEON = 600 }
}
```

## 今後の改善計画

### 短期（v3.1）
- [ ] 関数定義順序問題の完全解決
- [ ] マーケットボード操作の安定化
- [ ] 戦闘システム（RSR/BMR）の動作確認
- [ ] テレポートコマンドの最適化

### 中期（v3.2-3.5）
- [ ] ダンジョンタイプ自動判定の実装
- [ ] ルーレットタイプ対応
- [ ] 最終層ボス戦（ゴールデン・モルター・ブルアポリオン）
- [ ] メンテナンス機能（装備修理、チョコボ召喚、食事更新）

### 長期（v4.0）
- [ ] UI設定画面の追加
- [ ] 複数地図タイプの同時対応
- [ ] 詳細統計・ログ機能
- [ ] プロファイル保存機能

## 詳細実装仕様

### ダンジョンタイプ判定（実装予定）
```lua
-- 召喚魔法陣チェックでタイプ判定
if IsTargetable("召喚魔法陣") then
    dungeonType = "ROULETTE"  -- ルーレットタイプ
else
    dungeonType = "DUNGEON"   -- ダンジョンタイプ
end
```

### ダンジョンタイプ処理
```
各階層: オートムーブ → 宝箱ターゲット → 移動 → インタラクト
最終層: ボス戦 → 宝箱/皮袋回収 → 脱出地点 → インタラクト
```

### ルーレットタイプ処理  
```
召喚魔法陣インタラクト → 戦闘 → 宝箱/皮袋回収 → 次の魔法陣
最終層: 脱出地点インタラクト
```

### メンテナンス機能（実装予定）
```lua
-- 装備修理（耐久度30%以下）
-- チョコボ召喚（3分タイマー）
-- 食事更新（効果時間確認）
```

コードを作成する際に以下のソースコードを参考にすると解決するかもしれません。
https://github.com/Jaksuhn/SomethingNeedDoing
https://github.com/WigglyMuffin/SNDScripts/
https://github.com/McVaxius/dhogsbreakfeast
https://github.com/pot0to/pot0to-SND-Scripts/tree/main/New%20SND

特に、以下のコードが一番参考になると思います。
https://github.com/McVaxius/dhogsbreakfeast/blob/main/_functions.lua