# StairTraining

私人用的爬樓梯 + Cindy 訓練進度追蹤 App。你們兩人各自在自己手機上記錄進度,App 會自動把資料同步到 Firebase,兩邊都能即時看到對方目前練到哪裡,不需要另外傳訊息。

## 這個 App 做什麼

- **爬樓梯**:記錄今天完成第幾趟(每趟 = 爬 13 層樓梯 + 搭電梯下樓)。目標趟數每過一個日曆天會自動 +1(今天 4 趟,明天自動變 5 趟目標)。
- **Cindy**:記錄今天完成第幾組,目標組數預設沿用前一天(可自行調整)。
- 每按一次「完成一次」,馬上把你的進度上傳到共用的 Firebase 資料庫。
- 畫面下半部會顯示「另一半的進度」,每 15 秒自動更新一次,也可以下拉重新整理。
- 右上角「設定」:選擇自己是「老公」還是「老婆」,並填入雙方共用的 Firebase 位址。
- 左上角「鉛筆」:手動校正今天的天數/趟數/組數(第一次安裝、或跟現實進度對不上時用)。

## 為什麼是 Firebase,不是 LINE?

原本想法是完成一趟就傳 LINE 通知,但 LINE Notify 已在 2025/3/31 停用。討論後決定改成「兩人都在同一個 App 裡互看進度」,不需要另外收發訊息。用 Firebase Realtime Database 的原因:免費、不用架伺服器、App 直接用一般的網路請求(REST API)讀寫資料就好,不需要額外安裝任何 SDK。

## 第一步:建立共用的 Firebase 資料庫(只要做一次,由你們其中一人操作)

1. 瀏覽器打開 https://console.firebase.google.com ,用 Google 帳號登入,建立一個新專案(免費方案即可,不需要信用卡)。
2. 進到專案後,左側選單「Build」→「Realtime Database」→「建立資料庫」。地區隨意選,規則先選「測試模式」也可以,之後我們會換成下面這組規則。
3. 進到「規則(Rules)」分頁,貼上:

   ```json
   {
     "rules": {
       "couples": {
         "$room": {
           ".read": true,
           ".write": true
         }
       }
     }
   }
   ```

   **這代表**:只要知道完整的資料庫網址「加上」房間代碼這兩樣東西的人就能讀寫資料。因為只有訓練組數、趟數這種低敏感度資料,用一組長一點、不會被猜到的房間代碼(例如 `willie-jane-2026-9f3a`)當密碼即可,不需要更複雜的帳號驗證機制。**不要把房間代碼公開分享出去。**
4. 在 Realtime Database 頁面上方會看到資料庫網址,長得像:
   `https://你的專案id-default-rtdb.firebaseio.com`
   把這個網址記下來。

## 第二步:兩支手機分別設定 App

1. 打開 App,按右上角齒輪進入「設定」。
2. 「我是誰」選自己是「老公」還是「老婆」(兩支手機要選不同的)。
3. 貼上第一步拿到的 Database URL,以及你們一起決定的「房間代碼」——**兩支手機這兩欄要填一模一樣**。
4. 按「測試連線並上傳一次我的進度」,顯示「✅ 已成功上傳」代表設定成功。
5. 按「完成」關閉設定。
6. (第一次用)按左上角鉛筆,把今天實際的天數/已完成趟數/組數填正確,存檔。

之後每天打開 App,爬完一趟、搭電梯下樓後按一次「完成一次」,對方打開 App 就能看到最新進度(或最多等 15 秒自動更新)。

## 開啟這個專案

這個資料夾是標準的 Swift Playgrounds App 專案格式(`.swiftpm`),兩種裝置都能直接開:

**A. 有 Mac(用 Xcode)**
1. 直接在 Finder 雙擊 `StairTraining.swiftpm`,或在終端機 `xed StairTraining.swiftpm`,Xcode 會把它當一般 App 專案開啟。
2. 把 iPhone 接上 Mac(或選模擬器),在專案設定的 Signing & Capabilities 選你自己的 Apple ID 當 Team(用免費帳號簽署即可,App 只是裝在自己手機上)。
3. 按 Run 就會直接裝到手機上。你老婆的手機上也要跑同一份專案(可以直接把整個資料夾傳給她,或用同一台 Mac 接她的手機各 Run 一次)。

**B. 只有 iPad / iPhone(用 App Store 的「Swift Playgrounds」App)**
1. 把整個 `StairTraining.swiftpm` 資料夾透過 AirDrop 或 iCloud 雲端硬碟傳到 iPad。
2. 用 Swift Playgrounds 打開這個資料夾,按左上角執行鍵測試。
3. 完成後選「分享我的 App」→ 用你的 Apple ID 直接安裝到手機主畫面。免費 Apple ID 裝的 App 大約 7 天後系統會要求重新簽署,只要偶爾重新打開 Playgrounds 點一次「執行/安裝」即可。
4. 老婆那邊也要重複一次同樣的步驟,把 App 裝到她自己的手機上。

> 如果 Xcode 對 `Package.swift` 裡的 `appIcon: .placeholder(icon: .bird)` 顯示找不到 `.bird`,代表你的 Xcode 版本內建圖示清單不同,直接依 Xcode 自動完成建議換一個內建圖示即可,不影響其他功能。

## 資料存在哪裡

- 每天的進度(天數、趟數、組數)存在裝置本機的 `UserDefaults`,離線也能記錄。
- 一有變動就會嘗試上傳到你們設定的 Firebase Realtime Database,讓對方看得到;上傳失敗(例如沒網路)畫面上會顯示錯誤訊息,之後有網路時再按一次「完成一次」或下拉重新整理即可。
- Firebase 位址、房間代碼、身分選擇都只存在自己手機的 `UserDefaults` 裡。
