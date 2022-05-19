# ARMTest

Windows Server 2022 の仮想マシンとCosmosDBを作成すると同時に、仮想マシンへのPower Automate 及び、 Power BI のインストールを自動化した ARM テンプレート。

- template.bicep
  - テンプレートファイル
- template.json
  - template.bicep から生成した JSON 形式のテンプレートファイル
- parameters.json
  - パラメーターファイル
- installPowerPlatformPackages.ps1
  - Custom Script Extension によって実行される PowerShell スクリプトファイル 

## VS Code の Bicep 拡張機能によるテンプレートビジュアライズ
![image](https://user-images.githubusercontent.com/8349954/169265738-87fc7391-e664-40bd-bd7a-175b370eed89.png)
