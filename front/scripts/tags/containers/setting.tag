setting
  .page
    h4 Setting
    button.btn(onclick="{downloadKS}") keyStoreをダウンロード
    hr
    div
      p unlockをテスト
      label パスワード
      input(type="password" ref="password")
      a.btn(onclick="{unlock}") unlock

