app
  div(if="{isLoggedIn}")
    navbar(user="{user}" logout="{logout}" go="{go}")
    .page.home(if="{page === 'home'}")
      h4 Home
    .page.home(if="{page === 'mypage'}")
      h4 Mypage
    .page.home(if="{page === 'upload'}")
      h4 Upload
    .page.home(if="{page === 'setting'}")
      h4 Setting
      button.btn(onclick="{downloadKS}") keyStoreをダウンロード
      hr
      div
        p unlockをテスト
        label パスワード
        input(type="password" ref="password")
        a.btn(onclick="{unlock}") unlock

  div(if="{!isLoggedIn}")
    a(href="/login") ログイン
    span してください

  script.
    console.log(this);
    this.page = 'home';
    this.user = null;
    this.isLoggedIn = false;

    this.on('mount', () => {
      this.firebase.isLoggedIn().then((user) => {
        this.user = user;
        this.firebase.getUserData(this.user.uid)
          .then((_user) => {
            this.user.etherAccount= _user.etherAccount;
          });
        this.isLoggedIn = true;
        this.update();
      }).catch((e) => {
        // not login
      });
    });

    /**
     * ページ遷移
     */
    go(page){
      this.page = page;
      this.update();
    }

    /**
     * ログアウト処理
     */
    logout(){
      this.firebase.logout().then(() => {
        location.reload();
      });
    }

    /**
     * KeyStoreをダウンロード
     */
    downloadKS(){
      this.firebase.isLoggedIn().then((user) => {
        if(user){
          this.firebase.getUserData(user.uid)
            .then((val) => {
              user.getIdToken().then((idToken) => {
                location.href = `/downloadKS?idToken=${idToken}&etherKeyStoreFile=${val.etherKeyStoreFile}`;
              });
            });
        } else {
          // No user is signed in.
        }
      });
    }

    unlock(){
      const pw = this.refs.password;
      const _pw = pw.value;
      this.web3Controller.unlock(
        this.user.etherAccount,
        _pw,
        () => {
          console.log('done');
        }
      );
    }
