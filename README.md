# average-handwriting-hid

WacomHID で筆圧・傾き付きの手書きを収集し、フーリエ係数の平均化で「平均手書き文字」を生成する Processing システム。

[average-figure-processing](https://github.com/nkmr-lab/average-figure-processing) を WacomHID 対応に再構築したもの。

## 機能

### 収集モード
- Wacom ペンで文字を書き、JSON に保存
- 筆圧・傾き・距離も記録
- `save/` フォルダに自動保存

### 可視化モード
- 保存した JSON をドラッグ＆ドロップ
- フーリエ級数展開 → 係数平均 → 平均手書き文字を生成
- 筆圧も平均化して太さに反映

## スケッチ一覧

### averageHandwritingHID (メイン)
WacomHID でペン入力し、手書きを収集 + 可視化する統合ツール。

| キー | 動作 |
|---|---|
| Tab | 収集モード ↔ 可視化モード 切替 |
| C | 可視化モードでデータをクリア |

### batchAverager
フォルダ内の JSON を正規表現でグルーピングし、一括で平均化。画像 + JSON を出力。
- `DATA_PATH` に手書き JSON のフォルダを指定して実行
- 年齢層別などのグループ定義を `GROUPS` で設定

### morphingVisualizer
2つ以上の平均化済み JSON をドロップすると、フーリエ係数の補間でモーフィングアニメーションを生成。

| キー | 動作 |
|---|---|
| Space | モーフィング開始 |
| C | データクリア |

## ファイル構成

```
average-handwriting-hid/
├── README.md
├── averageHandwritingHID/    ← メイン (収集 + D&D可視化)
│   ├── averageHandwritingHID.pde
│   ├── WacomHID.pde, WacomHIDConfig.pde
│   ├── HWPoint.pde, HWStroke.pde, HWCanvas.pde
│   ├── HWFormat.pde
│   ├── Fourier.pde, Spline.pde, AverageEngine.pde
│   ├── Button.pde, DragAndDrop.pde, PointF.pde
│   └── code/ (jar files)
├── batchAverager/            ← 一括平均化
│   ├── batchAverager.pde
│   ├── (共通 .pde ファイル)
│   └── code/
└── morphingVisualizer/       ← モーフィング
    ├── morphingVisualizer.pde
    ├── DragAndDrop.pde
    ├── (共通 .pde ファイル)
    └── code/
```

## JSON フォーマット

```json
{
  "character": "あ",
  "strokeLength": 3,
  "strokes": [
    {
      "points": [
        {"x": 150.0, "y": 200.0, "pressure": 3200, "tiltX": 15.0, "tiltY": 10.0, "distance": 6400},
        ...
      ]
    },
    ...
  ]
}
```

従来の `{x, y}` のみの JSON も読み込み可能（筆圧等は 0 として扱う）。

## セットアップ

1. Processing をインストール
2. このリポジトリをクローン
3. `averageHandwritingHID/` フォルダを Processing で開く
4. `WacomHIDConfig.pde` でデバイスを選択
5. 実行

## 依存

- `code/` フォルダ内:
  - hid4java-0.8.0.jar
  - jna-5.13.0.jar

## 平均化のアルゴリズム

1. 各手書きの各ストロークをスプライン補間
2. 往復化（DoubleBack）してフーリエ級数展開
3. 全サンプルのフーリエ係数を平均
4. 平均係数から点列を復元
5. 筆圧はリサンプリング後に各点で平均
