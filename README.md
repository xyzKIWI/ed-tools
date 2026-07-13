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
| 輕微外傷性顱內出血出院準則（內容來源：侯勝文醫師；含點選式快速判定） | 本 repo（`mtbi-ich-discharge.html`） | <https://xyzkiwi.github.io/ed-tools/mtbi-ich-discharge.html> |
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
6. 在 `worker/worker.js` 的 `TOOLS` 加一條短路徑對應（如 `"/xxx": "https://xyzkiwi.github.io/xxx-tool"`），`worker/` 目錄下 `npx wrangler deploy`；卡片連結用 `https://tools.kiwi-ai.uk/xxx/`（院內網擋 `github.io`，直連會失敗）

## 免責聲明

本站所有工具僅供臨床決策輔助參考，不取代臨床判斷、官方仿單與最新指引。劑量與診斷碼請以原始資料來源為準，使用前請自行核對。

## License

MIT
