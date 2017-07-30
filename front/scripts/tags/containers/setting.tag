setting
  .page
    h4 Setting
    button.btn(onclick="{downloadKS}") keyStoreをダウンロード
    hr
    div
      p unlockをテスト
      label パスワード
      input(type="password" ref="password")
      a.btn.btn-sm(onclick="{unlock}") unlock

  script.

    /**
     * KeyStoreをダウンロード
     */
    downloadKS(){
      this.firebase.isLoggedIn().then((user) => {
        if(user){
          this.firebase.getUserData(user.uid).then((val) => {
            user.getIdToken().then((idToken) => {
              location.href = `/downloadKS?idToken=${idToken}&etherKeyStoreFile=${val.etherKeyStoreFile}`;
            });
          });
        } else {
          // No user is signed in.
        }
      });
    }

    async unlock(){
      const pw = this.refs.password;
      const _pw = pw.value;
      if(!_pw){
        return;
      }
      try {
        await this.web3c.unlock(this.user.etherAccount, _pw);
        opts.obs.trigger('notifySuccess', {
          text: `account unlocked => ${this.user.etherAccount}`
        });
      } catch (e) {
        /* handle error */
        opts.obs.trigger('notifyError', {
          text: `login error: ${e.message}`
        });
      }
    }

