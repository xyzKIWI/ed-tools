# ed-tools — 急診臨床小工具統一入口

急診第一線速查／速算工具的入口清單頁。

**入口網址：<https://tools.kiwi-ai.uk/>**（好記版，給同事用這個）
備用：<https://xyzkiwi.github.io/ed-tools/>（GitHub Pages 原址，內容相同）

> 好記版由 `worker/` 內的 Cloudflare Worker 反向代理 GitHub Pages 而成；`npx wrangler deploy`（在 `worker/` 目錄）即可更新 Worker 本身，頁面內容照常只要 push 本 repo。各工具另有短路徑代理（`/icd10`、`/abx`、`/peds`）——醫院等會封鎖 `github.io` 的內網，一律走 `tools.kiwi-ai.uk` 就能用。

## 收錄工具

| 工具 | Repo | 上線網址 | GitHub Pages 原址 |
|---|---|---|---|
| 抗微生物藥腎功能劑量速查 | [abx-tool](https://github.com/xyzKIWI/abx-tool) | <https://tools.kiwi-ai.uk/abx/> | <https://xyzkiwi.github.io/abx-tool/> |
| 急診 ICD-10-CM 診斷碼速查 | [icd10-ed-quickref](https://github.com/xyzKIWI/icd10-ed-quickref) | <https://tools.kiwi-ai.uk/icd10/> | <https://xyzkiwi.github.io/icd10-ed-quickref/> |
| 兒科藥物劑量速算 | [peds-dose](https://github.com/xyzKIWI/peds-dose) | <https://tools.kiwi-ai.uk/peds/> | <https://xyzkiwi.github.io/peds-dose/> |
| Heparin dose 調整計算 | [heparin-tool](https://github.com/xyzKIWI/heparin-tool) | <https://tools.kiwi-ai.uk/heparin/> | <https://xyzkiwi.github.io/heparin-tool/> |
| 急診臨床計算機（72 個評分／公式／決策規則，9 頁） | [ed-calc](https://github.com/xyzKIWI/ed-calc) | <https://tools.kiwi-ai.uk/calc/> | <https://xyzkiwi.github.io/ed-calc/> |
| 雲端藥歷整理小幫手 v1.5.0（瀏覽器擴充功能，需下載安裝） | [CloudMedicationHelper](https://github.com/xyzKIWI/CloudMedicationHelper) | <https://tools.kiwi-ai.uk/medcloud.zip>（直接下載） | [Releases](https://github.com/xyzKIWI/CloudMedicationHelper/releases/latest) |
| 輕微外傷性顱內出血出院準則（內容來源：侯勝文醫師；含點選式快速判定） | 本 repo（`mtbi-ich-discharge.html`） | <https://xyzkiwi.github.io/ed-tools/mtbi-ich-discharge.html> |
| Chrome 深色模式切換（Windows 批次檔，上班小工具） | [chrome-dark-mode](https://github.com/xyzKIWI/chrome-dark-mode)（私人，副本放本 repo `downloads/`） | <https://tools.kiwi-ai.uk/downloads/ChromeDarkMode.zip>（另有 `.bat`） | — |
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
6. 在 `worker/worker.js` 的 `TOOLS` 加一條短路徑對應（如 `"/xxx": "https://xyzkiwi.github.io/xxx-tool"`），`worker/` 目錄下 `npx wrangler deploy`；卡片連結用 `https://tools.kiwi-ai.uk/xxx/`（院內網擋 `github.io`，直連會失敗）

⚠️ **第 6 步不做等於沒上線**：程式碼推上 GitHub、Pages 也建好了，`tools.kiwi-ai.uk/xxx/` 還是會 404 —— Worker 跑的是上次 deploy 的版本，`worker.js` 進 repo 不會自動生效。驗收句是 `curl -o /dev/null -w "%{http_code}" https://tools.kiwi-ai.uk/xxx/` 拿到 200，不是「GitHub 上有檔案」。

### 下載型工具（瀏覽器擴充功能等）

不是網頁、要下載安裝的工具，走 `worker.js` 的 `DOWNLOADS` 對應表，代理到 GitHub Release 資產：

- 對應目標用 `releases/latest/download/<固定檔名>.zip` 永久連結，發新版不必改 Worker
- **但每次發 release 都要附一份「不帶版號」的固定檔名 zip**，否則這條路由會 404。帶版號的那份照發，兩份內容相同
- 卡片放在「瀏覽器擴充功能（需下載安裝）」區，名稱後加 `<span class="tag">下載 zip</span>` 讓人知道點下去是下載不是開頁面

### 上班小工具（Windows 批次檔等）

來源 repo 是私人的，所以不走 Release 代理，直接把檔案**複製**進本 repo 的 `downloads/`，經 Worker 預設路徑提供（不用改 `worker.js`、不用 wrangler deploy）：

- 來源更新後要手動重新複製 `.bat` 並重包 zip（zip 內含 `.bat`＋`README.txt`），推上去後比對 md5
- `.gitattributes` 設 `*.bat binary`：批次檔必須保持 CRLF 換行，不能讓 git 轉換
- 卡片放頁面最下方「上班小工具」區，用 `.row.dl` 版型（右側下載按鈕）

## 免責聲明

本站所有工具僅供臨床決策輔助參考，不取代臨床判斷、官方仿單與最新指引。劑量與診斷碼請以原始資料來源為準，使用前請自行核對。

## License

MIT
