---
name: news-fetch
description: >
  Manage Google News RSS feeds for the NewsSpinner spinner.
  Trigger when user wants to add/remove news keywords, fetch headlines,
  or check spinner feed status. Keywords: spinner, news, feed, headline, ニュース, フィード
argument-hint: "[add|remove|list|fetch] [keyword]"
disable-model-invocation: true
allowed-tools: Bash, AskUserQuestion
---

# NewsSpinner — ニュースフィード管理

Claude Code の spinner（推論中テキスト）を Google News ヘッドラインに置き換える。

## 現在の状態

登録済みフィード:
!`bash ~/.newsspinner/bin/fetch.sh list 2>/dev/null || echo "未インストール"`

プール残数:
!`jq 'length' ~/.newsspinner/pool.json 2>/dev/null || echo "0"`

## 前提チェック

スクリプトが `~/.newsspinner/bin/` に存在しない場合、以下を案内して終了:

```
bash ${CLAUDE_SKILL_DIR}/bin/install.sh
```

## 動作

### 引数なし (`$ARGUMENTS` が空)

AskUserQuestion でユーザーに操作を選ばせる:
1. フィードを追加 → キーワードを聞いてから `add` を実行
2. フィードを削除 → 登録済み一覧を見せて選ばせる
3. フィード一覧表示
4. ニュースを取得 (fetch)

### `add <keyword>`

```bash
bash ~/.newsspinner/bin/fetch.sh add "$1"
```

- 登録後「すぐに fetch するか？」を確認
- fetch する場合: `bash ~/.newsspinner/bin/fetch.sh`

### `remove <keyword>`

```bash
bash ~/.newsspinner/bin/fetch.sh remove "$1"
```

### `list`

```bash
bash ~/.newsspinner/bin/fetch.sh list
```

### `fetch`

```bash
bash ~/.newsspinner/bin/fetch.sh
```

## エラー時

- コマンド失敗時はエラー内容を表示し、考えられる原因を伝える
- `jq` / `curl` 未インストール → `install.sh` を案内
- ネットワークエラー → 接続確認を促す
- config.json 破損 → デフォルトで再作成する手順を案内:
  ```bash
  cp ${CLAUDE_SKILL_DIR}/config.json ~/.newsspinner/config.json
  ```
