setting
  .page
    h4 Setting
    button.btn(onclick="{opts.downloadks}") keyStoreをダウンロード
    hr
    div
      p unlockをテスト
      label パスワード
      input(type="password" ref="password")
      a.btn(onclick="{unlock}") unlock

  script.
    unlock(){
      const pw = this.refs.password;
      const _pw = pw.value;
      this.opts.unlock(_pw);
    }

