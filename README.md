# NewsSpinner

Claude Code の spinnerVerbs（推論中に表示される「Working…」等のテキスト）を RSS ニュースのヘッドラインに置き換えるツール。

## 依存

- `bash`
- `curl`
- `jq`

## インストール

```bash
git clone https://github.com/Taichi-Ibi/NewsSpinner.git
cd NewsSpinner
bash bin/install.sh
```

インストール後、Claude Code を再起動してください。

## 使い方

```bash
# ニュースを手動で取得
bash ~/.newsspinner/bin/fetch.sh

# スピナーを手動でローテーション
bash ~/.newsspinner/bin/rotate.sh
```

ツール実行のたびに自動でヘッドラインがローテーションします。プールが空になると補充を促すメッセージが表示されます。

## 設定

`~/.newsspinner/config.json` を編集してフィードの追加・削除ができます。

```json
{
  "feeds": [
    {"name": "NHK 主要ニュース", "url": "https://www.nhk.or.jp/rss/news/cat0.xml"},
    {"name": "Hacker News", "url": "https://hnrss.org/frontpage"},
    {"name": "TechCrunch", "url": "https://techcrunch.com/feed/"}
  ],
  "max_pool_size": 50,
  "max_title_length": 40,
  "empty_messages": [
    "📰 ニュース切れ！ fetch して",
    "No news... refresh me",
    "Waiting for fresh headlines"
  ]
}
```

## アンインストール

```bash
bash ~/.newsspinner/bin/uninstall.sh
```

Claude Code を再起動して完了です。
