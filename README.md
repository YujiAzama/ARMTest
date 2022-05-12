# ARMTest

Windows Server 2022 の仮想マシンを起動すると同時に、Power Automate 及び、 Power BI をインストールするまでを自動化した ARM テンプレート。

- template.bicep
  - テンプレートファイル
- template.json
  - template.bicep から生成した JSON 形式のテンプレートファイル
- parameters.json
  - パラメーターファイル
- installPowerPlatformPackages.ps1
  - Custom Script Extension によって実行される PowerShell スクリプトファイル 

## VS Code の Bicep 拡張機能によるテンプレートビジュアライズ
<img width="608" alt="image" src="https://user-images.githubusercontent.com/8349954/168033959-2b7810be-654a-4176-8288-bc2257e2f181.png">
