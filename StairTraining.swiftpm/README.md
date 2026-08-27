# StairTraining

私人用的爬樓梯 + Cindy 訓練進度追蹤 App。每次按「完成一次」會立刻透過 LINE Messaging API 傳訊息給老婆,不需要任何後端伺服器。

## 這個 App 做什麼

- **爬樓梯**:記錄今天完成第幾趟(每趟 = 爬 13 層樓梯 + 搭電梯下樓)。目標趟數每過一個日曆天會自動 +1(今天 4 趟,明天自動變 5 趟目標),完全對應你目前的訓練菜單。
- **Cindy**:記錄今天完成第幾組,目標組數預設沿用前一天(可自行調整)。
- 每按一次「完成一次」,立刻呼叫 LINE 官方帳號的 push API,把進度訊息送到老婆的 LINE。
- 全部完成時會多送一則「🏆 全部完成」的訊息。
- 右上角「設定」可以填 Channel Access Token 與老婆的 userId,並且可以先發一則測試訊息確認有沒有接對。
- 左上角「鉛筆」可以手動校正今天的天數/趟數/組數(第一次安裝、或跟現實進度對不上時用)。

## 為什麼不是用 LINE Notify?

LINE Notify 服務已經在 2025/3/31 終止,官方不再開放新綁定。這個 App 改用「LINE 官方帳號(免費)+ Messaging API push message」的方式,直接把訊息推給你老婆的 userId,原理上等同你原本想要的效果,而且完全不需要架設任何伺服器。

## 開啟這個專案

這個資料夾是標準的 Swift Playgrounds App 專案格式(`.swiftpm`),兩種裝置都能直接開:

**A. 有 Mac(用 Xcode)**
1. 直接在 Finder 雙擊 `StairTraining.swiftpm`,或在終端機 `xed StairTraining.swiftpm`,Xcode 會把它當一般 App 專案開啟。
2. 把 iPhone 接上 Mac(或選模擬器),在專案設定的 Signing & Capabilities 選你自己的 Apple ID 當 Team(用免費帳號簽署即可,App 只是裝在自己手機上)。
3. 按 Run 就會直接裝到手機上。

**B. 只有 iPad / iPhone(用 App Store 的「Swift Playgrounds」App)**
1. 把整個 `StairTraining.swiftpm` 資料夾透過 AirDrop 或 iCloud 雲端硬碟傳到 iPad。
2. 用 Swift Playgrounds 打開這個資料夾,按左上角執行鍵測試。
3. 完成後選「分享我的 App」→ 用你的 Apple ID 直接安裝到手機主畫面。免費 Apple ID 裝的 App 大約 7 天後系統會要求重新簽署,只要偶爾重新打開 Playgrounds 點一次「執行/安裝」即可(這個 App 不需要背景執行,平常關掉也沒關係,只有你打開 App 按按鈕時才會送訊息)。

> 如果 Xcode 對 `Package.swift` 裡的 `appIcon: .placeholder(icon: .bird)` 顯示找不到 `.bird`,代表你的 Xcode 版本內建圖示清單不同,直接依 Xcode 自動完成建議換一個內建圖示即可,不影響其他功能。

## 使用前準備

你已經有 LINE 官方帳號的 **Channel Access Token** 和老婆的 **userId**,打開 App 後:

1. 按右上角齒輪圖示進入「設定」。
2. 貼上 Channel Access Token、老婆的 userId。
3. 按「發送測試訊息」確認老婆的 LINE 有收到。
4. 按「完成」關閉設定。
5. (第一次用)按左上角鉛筆,把今天實際的天數/已完成趟數/組數填正確,存檔。

之後每天訓練時打開 App,爬完一趟、搭電梯下樓後按一次「完成一次」,老婆就會馬上收到 LINE。

## 資料存在哪裡

- 每天的進度(天數、趟數、組數)存在裝置的 `UserDefaults`。
- LINE Token 與 userId 存在裝置的 Keychain,不會上傳到任何地方,只有送訊息時直接呼叫 `api.line.me`。
