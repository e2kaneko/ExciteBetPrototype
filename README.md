# ExciteBetPrototype

Excitebike風の2Dバイクレースプロトタイプです。Godot 4で実装しており、画像アセットを使わず、コード（`Polygon2D`の動的生成）でレトロなドット絵のバイクとコース上のギミックを描画しています。

## 概要

- 3レーンで赤・青・黄の3台のバイクが自動走行し、ゴールラインへ最初に到達したバイクが1着になります。
- スタート/ゴール/リセットの状態管理（`START_WAIT` → `RACING` → `FINISHED` → リセット）により、何度でも繰り返しプレイできます。
- コース上には以下のギミックがランダムに配置されます。
  - **泥（Obstacle）**: 接触すると速度が低下し、泥はねエフェクトが発生します。
  - **ブースト（BoostItem）**: 接触すると一定距離だけ速度が上昇し、走行中はマフラーから火炎エフェクトが出ます。
  - **ジャンプ台（JumpPad）**: 接触すると上方向に飛び上がり、重力で放物線を描いて着地します（離陸・着地時にスクワッシュ＆ストレッチとダストエフェクト）。
  - **坂道（Slope）**: 通過中だけ速度が低下します。
- 画面サイズに応じてスタート/ゴール位置・速度バランスが自動調整されます。

## 技術スタック

- [Godot Engine 4.7](https://godotengine.org/)（GDScript / GL Compatibilityレンダラー）
- HTML5（Web）エクスポートでブラウザ上で動作
- ホスティング: AWS Amplify Hosting

## ディレクトリ構成

```
.
├── project.godot          # Godotプロジェクト設定
├── export_presets.cfg     # Webエクスポート設定（出力先: dist/index.html）
├── scenes/                # .tscnシーンファイル（bike, obstacle, boost_item, jump_pad, slope, main_game）
├── scripts/               # GDScript（各ノードの挙動・ピクセル描画ロジック）
├── dist/                  # Godotでエクスポート済みのWebビルド（直接コミットして配信に使用）
├── amplify.yml            # AWS Amplify Hostingのビルド設定
└── customHttp.yml         # AWS Amplify Hostingのカスタムレスポンスヘッダー設定
```

## ローカルでの実行方法

### Godotエディタで実行

1. [Godot 4.7](https://godotengine.org/download) 以降をインストールします。
2. Godotで本リポジトリ（`project.godot`）を開きます。
3. `F5`（またはエディタの再生ボタン）でメインシーン（`scenes/main_game.tscn`）を実行します。
4. ゲーム画面でスペースキーまたはクリックでレースをスタートします。

### Webビルドをローカルで確認する

`dist/` フォルダには事前にエクスポート済みのWebビルドが含まれています。HTML5エクスポートはCORS制約があるため、`index.html` を直接ブラウザで開くのではなく、簡易HTTPサーバー経由で開いてください。

```bash
cd dist
python -m http.server 8000
# ブラウザで http://localhost:8000 を開く
```

### 変更をWebビルドに反映する

GDScriptやシーンを修正したら、Godotエディタの `Project > Export...` から `Web` プリセットでエクスポートし直してください（出力先は `dist/index.html` に設定済みです）。出力された `dist/` 配下のファイルをコミット・プッシュすると、デプロイ先（Amplify）にも反映されます。

## AWS Amplifyへのデプロイ方法

このリポジトリは「Godotでのビルドはローカルで行い、`dist/` に出力したビルド済みファイルをそのままコミットする」運用を前提としています。そのため、Amplify側のビルドステップは実質的に何も行わず、コミット済みの `dist/` をそのまま配信用アーティファクトとして公開します（`amplify.yml` 参照）。

### 初回セットアップ

1. [AWS Amplifyコンソール](https://console.aws.amazon.com/amplify/) を開き、「New app」→「Host web app」を選択します。
2. GitHubを連携し、本リポジトリと対象ブランチ（`main`）を選択します。
3. ビルド設定は自動検出された `amplify.yml` がそのまま使われます（追加設定は不要です）。
   - `baseDirectory: dist` が公開対象です。
   - `customHttp.yml` はAmplify Hostingが自動的に読み込み、`Cross-Origin-Opener-Policy` / `Cross-Origin-Embedder-Policy` / `Cross-Origin-Resource-Policy` ヘッダーを付与します（GodotのWeb出力が要求するCORS分離ヘッダーです）。
4. 「Save and deploy」をクリックすると、Amplifyが `dist/` の内容をそのままデプロイします。
5. デプロイ完了後、Amplifyが発行するURL（`https://<branch>.<app-id>.amplifyapp.com`）でプレイできます。

### 更新時のデプロイ

1. Godotエディタで変更内容をWebプリセットで再エクスポートし、`dist/` を更新します。
2. `dist/` を含む変更をコミットして `main` ブランチにプッシュします。
3. Amplifyが対象ブランチへのプッシュを検知し、自動的に再デプロイします。

> **注意**: Amplify上にはGodotの実行環境がないため、`.tscn` / `.gd` の変更だけをプッシュしてもサイトの表示は更新されません。必ずローカルでWebエクスポートを実行し、`dist/` の差分を含めてプッシュしてください。

### 独自ドメインの設定（任意）

Amplifyコンソールの「Domain management」から、取得済みドメインやRoute 53で管理しているドメインを追加できます（SSL証明書の発行も自動化されます）。
