# ed-tools — 急診臨床小工具統一入口

急診第一線速查／速算工具的入口清單頁。

**入口網址：<https://er.kiwi-ai.uk/>**（2026-09-30 起的主網址，給同事用這個）
舊網址：<https://tools.kiwi-ai.uk/>（同一支 Worker，院外照常可用；2026-09-27 起被院內卡巴斯基封鎖，所以改名）
備用：<https://xyzkiwi.github.io/ed-tools/>（GitHub Pages 原址；院內可開，另有「上班小工具」三個 Windows 程式）
備援：<https://kiwi-ed-tools.pages.dev/>（Cloudflare Pages 跑同一支 Worker，網址路徑與主網址相同）

> 首頁 `index.html` 會依開啟的網域自動換連結：github.io 版把短路徑換成 GitHub 原址（腳本內 `GH` 對應表），其他網域（er／tools.kiwi-ai.uk、pages.dev）換成同站路徑；卡片連結一律寫 `https://er.kiwi-ai.uk/…`。「上班小工具」區最上方是雲端藥歷擴充功能（三站都顯示）；其下三個 Windows 程式（`data-gh-only`）**只在 github.io 與 er.kiwi-ai.uk 顯示**（2026-09-30 Kiwi 要求 er 也放；下載檔都在 GitHub，本網域不發檔），tools.kiwi-ai.uk 與 pages.dev 不放。每張下載卡統一兩顆按鈕：［下載檔案］＋［到 GitHub 下載］（Release 頁）。三個程式卡片夾在 `<!-- gh-only:start -->`／`<!-- gh-only:end -->` 之間，Worker 送出首頁時，除 `PROGRAM_HOSTS`（er.kiwi-ai.uk）外整段刪除（原始碼也不留）；新增 github.io 專屬卡片要放在這對標記內。

> 2026-09-27 五個工具 repo 改短名對齊短路徑：`icd10-ed-quickref`→`icd10`、`abx-tool`→`abx`、`peds-dose`→`peds`、`heparin-tool`→`heparin`、`ed-calc`→`calc`。舊 github.io 網址已失效（GitHub repo 網址會自動轉址）；**不要再建立與舊名同名的 repo**，會搶走轉址。回饋表單前綴（`[peds-dose]`、`[ed-calc/頁名]`）刻意沿用舊名以保持 Sheet 資料連續。

> 好記版由 `worker/` 內的 Cloudflare Worker 反向代理 GitHub Pages 而成；`npx wrangler deploy`（在 `worker/` 目錄）即可更新 Worker 本身，頁面內容照常只要 push 本 repo。各工具另有短路徑代理（`/icd10`、`/abx`、`/peds`）——醫院等會封鎖 `github.io` 的內網，一律走 `er.kiwi-ai.uk` 就能用。

## 收錄工具

| 工具 | Repo | 上線網址 | GitHub Pages 原址 |
|---|---|---|---|
| 抗微生物藥腎功能劑量速查 | [abx](https://github.com/xyzKIWI/abx) | <https://er.kiwi-ai.uk/abx/> | <https://xyzkiwi.github.io/abx/> |
| 急診 ICD-10-CM 診斷碼速查 | [icd10](https://github.com/xyzKIWI/icd10)（2026-09-27 由 icd10-ed-quickref 改名） | <https://er.kiwi-ai.uk/icd10/> | <https://xyzkiwi.github.io/icd10/> |
| 兒科藥物劑量速算 | [peds](https://github.com/xyzKIWI/peds) | <https://er.kiwi-ai.uk/peds/> | <https://xyzkiwi.github.io/peds/> |
| Heparin dose 調整計算 | [heparin](https://github.com/xyzKIWI/heparin) | <https://er.kiwi-ai.uk/heparin/> | <https://xyzkiwi.github.io/heparin/> |
| 急診臨床計算機（72 個評分／公式／決策規則，9 頁） | [calc](https://github.com/xyzKIWI/calc) | <https://er.kiwi-ai.uk/calc/> | <https://xyzkiwi.github.io/calc/> |
| 雲端藥歷整理小幫手 v1.5.0（瀏覽器擴充功能，需下載安裝） | [CloudMedicationHelper](https://github.com/xyzKIWI/CloudMedicationHelper) | <https://er.kiwi-ai.uk/medcloud.zip>（直接下載） | [Releases](https://github.com/xyzKIWI/CloudMedicationHelper/releases/latest) |
| 輕微外傷性顱內出血出院準則（內容來源：侯勝文醫師；含點選式快速判定） | 本 repo（`mtbi-ich-discharge.html`） | <https://xyzkiwi.github.io/ed-tools/mtbi-ich-discharge.html> |
| 多瀏覽器深色模式切換（Chrome／Comet／Edge／IE，Windows 批次檔） | [chrome-dark-mode](https://github.com/xyzKIWI/chrome-dark-mode)（公開） | [ChromeDarkMode.bat](https://github.com/xyzKIWI/chrome-dark-mode/releases/latest/download/ChromeDarkMode.bat)（主要下載，GitHub Release；exe 版同一 Release 仍在） | [Releases](https://github.com/xyzKIWI/chrome-dark-mode/releases/latest) |
| MouseJiggle 滑鼠防閒置工具（Normal／Zen，Windows 可攜式程式） | [MouseJiggle](https://github.com/xyzKIWI/MouseJiggle)（公開） | [GitHub Release 頁](https://github.com/xyzKIWI/MouseJiggle/releases/latest)（EXE／可攜版 zip） | [Releases](https://github.com/xyzKIWI/MouseJiggle/releases/latest) |
| Windows 暫存與快取清理（Clean.bat 批次檔） | [windows-clean](https://github.com/xyzKIWI/windows-clean)（公開） | [GitHub Release 頁](https://github.com/xyzKIWI/windows-clean/releases/latest) | [Releases](https://github.com/xyzKIWI/windows-clean/releases/latest) |
| note2icd 病歷自動抽 ICD 碼 | 規劃中 | — |

### 外部工具（ [highker21](https://highker21.github.io/) 製作，內容與校對由原作者維護）

| 工具 | 上線網址 |
|---|---|
| Vancomycin / Teicoplanin 劑量計算機（高醫藥典） | <https://highker21.github.io/tools/vanco-teico-calculator.html> |
| 類鴉片劑量換算（OME） | <https://highker21.github.io/tools/opioid-converter.html> |
| 健保碼查詢（處置／藥品） | <https://highker21.github.io/tools/nhi-code-finder.html> |

## 新增工具的標準流程

0. 從模板開新 repo：[ed-tool-template](https://github.com/xyzKIWI/ed-tool-template) 按 **Use this template**（骨架含頁面、校對日頁尾、免責、README 段落，照模板 README 的 checklist 走）
1. 一工具一 repo，名稱用 kebab-case，本地資料夾名 = repo 名
2. Repo 必備：`README.md`（用途、資料來源、更新方法、免責聲明）、`LICENSE`（MIT）、topics（`emergency-medicine`、`clinical-tool`）、homepage 填 Pages 網址
3. 工具頁面內必有：版本或資料最後校對日、免責聲明
4. 部署：main 分支根目錄 → GitHub Pages（Settings → Pages → Deploy from a branch）
5. 上線後回到本 repo：`index.html` 加一張卡片（名稱、一句話、資料校對日、連結），README 表格加一列
   - 「速查／速算」區用 `.tile` 格子：`data-reviewed="YYYY-MM-DD"`（超過 90 天自動標琥珀色提醒）、`data-kw`（搜尋關鍵字，中英同義詞都放）、`title`（完整名稱與說明）；其他區用 `.row`
   - ⚠️ 主頁搜尋框內建 ed-calc 的 72 項清單（`index.html` 底部 `const CALC`，由 ed-calc `index.html` 的分類卡片抽出）。**ed-calc 增刪項目時要同步重抽**，否則搜尋找不到新項目
6. 在 `worker/worker.js` 的 `TOOLS` 加一條短路徑對應（如 `"/xxx": "https://xyzkiwi.github.io/xxx-tool"`），`worker/` 目錄下 `npx wrangler deploy` **＋** `npm run deploy:pages`（pages.dev 備援站）；卡片連結用 `https://er.kiwi-ai.uk/xxx/`，並在 `index.html` 腳本的 `GH` 對應表加一列 GitHub 原址（github.io 版靠它換連結）

⚠️ **第 6 步不做等於沒上線**：程式碼推上 GitHub、Pages 也建好了，`er.kiwi-ai.uk/xxx/` 還是會 404 —— Worker 跑的是上次 deploy 的版本，`worker.js` 進 repo 不會自動生效。驗收句是 `curl -o /dev/null -w "%{http_code}" https://tools.kiwi-ai.uk/xxx/` 拿到 200，不是「GitHub 上有檔案」。

### 下載型工具（瀏覽器擴充功能等）

不是網頁、要下載安裝的工具，走 `worker.js` 的 `DOWNLOADS` 對應表，代理到 GitHub Release 資產：

- 對應目標用 `releases/latest/download/<固定檔名>.zip` 永久連結，發新版不必改 Worker
- **但每次發 release 都要附一份「不帶版號」的固定檔名 zip**，否則這條路由會 404。帶版號的那份照發，兩份內容相同
- 卡片放在「瀏覽器擴充功能（需下載安裝）」區，名稱後加 `<span class="tag">下載 zip</span>` 讓人知道點下去是下載不是開頁面

### 上班小工具（Windows 可攜式程式）

**.exe 不經本網域發送**（2026-09-27：院內卡巴斯基封鎖 tools.kiwi-ai.uk，疑因本網域代理未簽章 exe）：公開來源 repo 的卡片按鈕一律連到 GitHub 的 `releases/latest` 頁面，讓使用者在 GitHub 上下載，不要再加進 `worker.js` 的 `DOWNLOADS`。

- 按鈕連 `https://github.com/xyzKIWI/<repo>/releases/latest`；更新 latest release 後不必修改卡片
- 深色模式按鈕直接下載 GitHub Release 的 `ChromeDarkMode.bat`（2026-09-27 改回 bat；exe 只是把同一份 bat 包進 .NET 殼、解到暫存再跑）；**發新版時 Release 要附 `ChromeDarkMode.bat`**，否則按鈕 404。入口站 repo 不再放任何程式檔（原 `downloads/` 副本 2026-09-27 刪除）
- 卡片放頁面最下方「上班小工具」區，用 `.row.dl` 版型（右側下載按鈕）
- Windows 清理改為直接發佈 `.bat`（repo `windows-clean`）；原 `Clean.exe` 只是把舊版 bat 包進 .NET 殼、執行時解到暫存再跑，已停用

## 免責聲明

本站所有工具僅供臨床決策輔助參考，不取代臨床判斷、官方仿單與最新指引。劑量與診斷碼請以原始資料來源為準，使用前請自行核對。

## License

MIT

## pages.dev 備援站

`kiwi-ed-tools.pages.dev` 是 Cloudflare Pages 專案，內容只有一支 `_worker.js`（＝`worker/worker.js` 原封不動），所以行為與主網址相同。改過 `worker.js` 後兩邊都要部署：

```bash
cd worker
npx wrangler deploy        # er.kiwi-ai.uk＋tools.kiwi-ai.uk
npm run deploy:pages       # kiwi-ed-tools.pages.dev（在暫存資料夾部署，不會讀到 wrangler.jsonc）
```

⚠️ **不要在 `worker/` 目錄裡跑 `wrangler pages project create` 或 `wrangler pages deploy`**：新版 wrangler 會讀到本目錄的 `wrangler.jsonc`，改成部署一支新 Worker 並把 tools.kiwi-ai.uk 綁過去（2026-09-27 發生過，已復原）。
