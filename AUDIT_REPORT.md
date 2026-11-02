# ed-tools 全站健檢報告（2026-11-02）

範圍：入口頁 `index.html`（er.kiwi-ai.uk／tools.kiwi-ai.uk／xyzkiwi.github.io/ed-tools／kiwi-ed-tools.pages.dev 四個網域）、本 repo 內的 `se/`、`mtbi-ich-discharge.html`、`ed-overload-monitor.html`、`README.md`，以及六個工具 repo 的線上頁面（abx、icd10、peds、heparin、na、calc 與 calc 的 9 個分頁）。

處理原則：非臨床問題（連結、`GH` 表、頁尾格式、版面）在本 repo 內直接修；其他 repo 的問題、Worker 路由與部署、任何臨床內容一律**只報告、不修改**。

---

## 一、已修項目（本 PR）

| # | 檔案 | 問題 | 修正 |
|---|---|---|---|
| 1 | `se/index.html` | 癲癇重積檢核單**完全沒有**免責聲明、資料日期、內容來源（模板三要素皆缺） | 在頁面最下方加標準頁尾：模板免責句＋「內容來源：高醫急診部／神經部『癲癇重積檢核單』院內協定」＋「資料日期：2026-10-23」（日期取自入口卡片）。加 `no-print`，不影響 1:1 紙本列印。未動任何劑量、流程或判讀文字 |
| 2 | `mtbi-ich-discharge.html` | 沒有「回首頁」連結（全站唯一沒有回程的本 repo 頁面） | 頁首加「← 急診臨床小工具」，用相對路徑 `./`：er／pages.dev 回站根，github.io 回 `/ed-tools/`，三站實測皆正確；觸控高度 44px |
| 3 | `mtbi-ich-discharge.html` | 頁尾格式與模板不一致：缺標準免責句、沒有指向資料來源 | 頁尾最上方加模板免責句＋「資料來源：見上方 Reference（連結到 `#refs`）」＋「資料日期：2026-06-01」。**原有的免責聲明文字原封保留** |
| 4 | `ed-overload-monitor.html` | 「← 回上班小工具」點擊高度只有 20px（手機不好點） | 改為 `min-height:44px` |
| 5 | `index.html` | 下載按鈕高約 36px，低於 44px 觸控建議值 | `.btn` 加 `min-height:44px`（外觀不變，只是變高） |
| 6 | `index.html` | 臨床計算機卡片缺 `title`（README 規範每張 `.tile` 都要有） | 補上 `title`（與卡片說明相同文字） |
| 7 | `index.html` | 頁尾「最後更新：2026-10-25」，但 10-30 已改過卡片 | 改為 2026-11-02 |
| 8 | `README.md` | 收錄工具表格中 mtbi、se、note2icd 三列只有 3 欄（表格 4 欄），GitHub 上會錯位 | 補齊欄位；mtbi 補上主網址 `er.kiwi-ai.uk/mtbi-ich-discharge.html`（實測 200） |
| 9 | `README.md` | 「各工具另有短路徑代理（`/icd10`、`/abx`、`/peds`）」漏列 heparin、na、calc | 補齊六條並註明以 `TOOLS` 為準 |
| 10 | `README.md` | 新增工具流程仍寫舊 repo 名 `ed-calc` | 改為「calc（原 ed-calc）」 |

驗證：
- `worker/worker.test.mjs`：17／17 通過（`worker/` 未修改）
- 修改後四頁在 375px 寬皆無水平捲動、無 JS 錯誤；模擬 github.io 網域時卡片會正確換成 GitHub 原址，搜尋功能正常

---

## 二、未修但建議處理

### A. 需要 Kiwi 本人操作（本 repo，但涉及部署，依指示不動）

1. **🔴 pages.dev 備援站 `/na/` 是 404**
   `https://kiwi-ed-tools.pages.dev/na/`、`/hyponatremia`、`/na.html` 都回 404；er 與 tools 正常。代表 10-25 加 `/na` 路由後，`npm run deploy:pages` 沒有跑。院內若改走 pages.dev，入口頁的「低血鈉」卡片會點到 404。
   修法（在 `worker/` 目錄）：

   ```bash
   npm run deploy:pages
   ```

   驗收：`curl -o /dev/null -w "%{http_code}" https://kiwi-ed-tools.pages.dev/na/` 拿到 200。

2. **ICD-10 卡片日期與工具頁不一致**：卡片寫「資料校對 2026-07-10」，icd10 頁面顯示「資料更新 2026-08-27」（健保署更新日）。10-30 的 commit 是刻意移除 ICD-10 的 90 天提醒，所以沒改；請確認卡片要顯示哪個日期。

3. **建議加一個自動檢查**：比對「卡片上的 `er.kiwi-ai.uk` 連結」⊆「`GH` 表」⊆「Worker `TOOLS`＋`DOWNLOADS`」。這次三者一致，但目前完全靠人工記得。可以加在 `worker/worker.test.mjs`（讀 `../index.html`），但因為要動 `worker/`，留給你決定。

### B. `GH` 對照表／Worker 路由比對結果

| 卡片連結 | `GH` 表 | Worker | 結果 |
|---|---|---|---|
| `/abx/` `/icd10/` `/peds/` `/heparin/` `/na/` `/calc/` | ✅ 6／6 | ✅ `TOOLS` 6／6 | 一致 |
| `/medcloud.zip` `/ed-overload-monitor.zip` | ✅ 2／2 | ✅ `DOWNLOADS` 2／2 | 一致 |
| `se/`、`mtbi-ich-discharge.html`、`ed-overload-monitor.html` | 不需要（相對路徑） | 走 `HUB` | 三站皆 200 |

沒有缺漏，也沒有多餘項目。搜尋用的 `CALC` 清單 72 項，各分頁數量與 calc 線上版逐頁相符（10／12／12／9／8／6／5／5／5）。

小建議：`CALC` 裡「4-2-1」「MAP」「Parkland」「sPESI」等只有英文縮寫，搜「維持輸液」「平均動脈壓」找不到；但清單是照 calc 首頁卡片抽的，要改應從 calc 首頁改。

### C. 其他工具 repo（只報告，未修改）

| repo | 問題 | 嚴重度 |
|---|---|---|
| **abx** | **手機 375px 有水平捲動**：劑量表格（藥物／Route／>50／10–50／<10）寬 399px，整頁被撐寬。建議表格外包 `overflow-x:auto` 容器 | 中 |
| **abx** | 沒有「回首頁」連結 | 低 |
| **peds** | **頁面上沒有可見的免責聲明**：`.disclaimer` 樣式有定義但沒有元素；`DRUG_DATA._meta.disclaimer` 有文字但沒顯示。頁尾只有「資料查核：2026-09-21」，也沒有整體資料來源段落（只有各藥卡內的 📚 來源） | 中 |
| **peds** | 沒有「回首頁」連結 | 低 |
| **icd10** | 沒有「回首頁」連結；頁尾用「使用說明」而非「免責」標題（內容其實有免責意涵） | 低 |
| **icd10** | 外傷小人圖的部位熱區很小（如手腕 9×4px、肩部 9×6px），手機難點 | 低（圖形本質限制，可考慮加放大或清單替代） |
| **calc** | 首頁與 9 個分頁都**沒有回 ed-tools 入口的連結**；分頁之間有導覽列，但沒有回 calc 首頁 | 低 |
| **calc** | 10 個頁面的 README 連結仍指向舊名 `github.com/xyzKIWI/ed-calc#readme`（目前靠 GitHub 自動轉址到 calc 才能用；README 提到不要建舊名 repo，但連結本身最好改成新名） | 低 |
| **heparin** | 頁尾用「臨床安全」標題，不是模板的「免責」；內容完整、有校對日與來源 | 很低（格式差異） |
| **ed-tool-template** | 模板 README 寫 topic `clinical-tools`，ed-tools README 寫 `clinical-tool`（單複數不一致） | 很低 |

各工具頁尾三要素總表（✅ 有／⚠️ 有但格式不同／❌ 沒有）：

| 頁面 | 校對／資料日 | 免責聲明 | 資料來源 | 回首頁 | 375px |
|---|---|---|---|---|---|
| abx | ✅ 2026-06-29／10-30 | ✅ | ✅ | ❌ | ❌ 水平捲動 |
| icd10 | ✅ 資料更新 2026-08-27 | ⚠️「使用說明」 | ✅ 健保署 2023 版 | ❌ | ✅ |
| peds | ✅ 資料查核 2026-09-21 | ❌ | ⚠️ 只在各藥卡 | ❌ | ✅ |
| heparin | ✅ 2026-08-18 | ⚠️「臨床安全」 | ✅ | ✅ | ✅ |
| na | ✅ 2026-10-26 | ✅ | ✅ | ✅ | ✅ |
| calc（10 頁） | ✅ 2026-10-25 | ✅ | ✅ | ❌ | ✅ |
| se（本 repo） | ✅（本 PR 補） | ✅（本 PR 補） | ✅（本 PR 補） | ✅ | ✅ |
| mtbi（本 repo） | ✅ 2026-06-01 | ✅ | ✅（本 PR 補連結） | ✅（本 PR 補） | ✅ |

入口卡片日期與工具頁日期：abx、peds、heparin、na、calc 一致；icd10 不一致（見 A-2）。

### D. 連結檢查摘要

- **入口頁（四個網域）**：所有卡片、按鈕、頁尾連結都是 200；錨點 `#work-tools`、`#ed-overload-monitor` 存在。
- **下載**：`medcloud.zip`、`ed-overload-monitor.zip`（er 與 github.io 兩份位元組相同）、`ChromeDarkMode.bat`、`MouseJiggle.zip`、`Clean.bat` 都能下載。
- **README**：所有實際網址都是 200；`github.com/xyzKIWI/<repo>` 用 `git ls-remote` 確認 repo 都存在。
- **工具頁內部錨點**：全部存在，沒有找到斷掉的 `#` 錨點。
- **期刊網站回 403 的連結**（tandfonline、journals.lww.com、ahajournals、academic.oup.com、jamanetwork、sagepub、thejns.org、MDCalc 短時間內大量請求時）：用真的 Chromium 開，都是 Cloudflare「Just a moment...」機器人驗證頁，**不是死連結**；同事用一般瀏覽器開不受影響。MDCalc 用瀏覽器開是 200。
- **PubMed 連結**：自動檢查被限速（429／403），改用 PubMed 資料庫查 PMID 25423541、39418684、27838043、24074529、30881551：5 個 PMID 都存在，且與頁面引用的標題相符。
- 限制：這次工作階段的網路政策擋住了 `github.com/xyzKIWI/<其他 repo>/releases/latest` 網頁（403 來自工作階段代理，不是 GitHub）。改用旁證確認：同一 repo 的 `releases/latest/download/<檔名>` 都能下載，表示 latest release 存在，Release 頁不會是死連結。

---

## 三、疑似臨床內容問題（只列出，未修改）

> 以下都是「看起來可能有問題、請原作者／協定負責人確認」，不代表一定錯。所有臨床文字、劑量、閾值這次都**沒有更動**。

### se／癲癇重積檢核單（本 repo）

1. **EMR 病歷在未填體重時會用假設體重算劑量**（`se/index.html` 的 `updateEMR()`）：
   - 勾選「Lorazepam < 40 kg」但體重欄空白時，EMR 寫入 `Lorazepam 3.5mg IV`（程式預設 35 kg）
   - 勾選「Keppra < 50 kg」但體重欄空白時，寫入 `Keppra 2700mg ST IVD`（預設 45 kg）

   畫面上的劑量徽章在沒體重時會顯示「請先輸入體重」，但 EMR 文字卻出現具體劑量，兩者不一致。建議：體重空白時 EMR 改寫「體重未填，劑量未計算」。
2. **Midazolam 第三線 loading 0.2 mg/kg 沒有上限**：體重 100 kg 會顯示 20 mg IV push。若院內協定有單次上限，建議加上。
3. **Midazolam pump 換算假設「1 mg/mL 配方」**：徽章寫「1mg/mL 配方即 X mL/h」，請確認與院內實際泡法相同，否則 mL/h 會錯。
4. **體重分級的自動勾選只在「尚未勾選」時觸發**：先輸入 35 kg（自動勾 < 40 kg）再改成 70 kg，勾選不會跟著換。因為有上限（4 mg、3000 mg），目前算出的數字剛好一樣，但病歷會記錄成「< 40 kg」選項。
5. 指引對照表 Lorazepam 欄「單次總累積上限 8 mg」用詞容易誤讀（「單次」與「累積」並列），建議改成「兩劑合計上限 8 mg」之類的寫法。

### mtbi／輕微外傷性顱內出血出院準則（本 repo）

6. **抗血小板定義前後不一致**：
   - 頁首「一句話總結」寫「無抗凝／抗血小板藥」為前提，並寫「**任何**抗凝／抗血小板者…均屬高風險（mBIG 3）」
   - 但第 5 節表格與互動快速判定寫「mBIG 修正：**單獨 aspirin 不算**」

   單獨吃 aspirin 的病人，看總結會判 mBIG 3，用互動判定則可能走到 mBIG 1。建議請侯醫師確認後統一。
7. Tintinalli 章節號不一致：文末參考文獻寫「Ch.257 Head Trauma」，KB 來源頁面框寫「Tintinalli Ch258｜Head Trauma」。

### 其他 repo

8. 這次只抽查頁尾與連結，沒有對 abx、icd10、peds、heparin、na、calc 做完整臨床驗算（calc、na 上一輪已補驗算測試）。抽查範圍內沒有發現明顯的臨床數值問題。

---

## 附：檢查方法

- 連結：Python 抓取各頁 HTML、解析所有 `<a href>`，逐一 GET（跟隨轉址）並檢查目標頁是否有對應的 `id`／`name` 錨點；403 的部分再用 Playwright Chromium 複驗。
- `GH` 表：從 `index.html` 抽卡片 `href` 與 `GH` 物件，和 `worker/worker.js` 的 `TOOLS`／`DOWNLOADS` 比對；四個網域實際請求每條短路徑。
- 頁尾：Playwright 渲染後抓頁面文字（icd10、peds 的頁尾由 JS 產生），對照 `ed-tool-template/index.html` 的標準段落。
- 手機版：Playwright 375×740、iPhone UA，量測 `scrollWidth`、超出視窗的元素、小於 24px 的點擊目標（radio／checkbox 若包在 `<label>` 內則以 label 尺寸計）、被 `overflow:hidden` 截掉的文字，並人工檢視截圖。
