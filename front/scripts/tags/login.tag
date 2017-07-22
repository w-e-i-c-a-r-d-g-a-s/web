login
  .loading(if="{isInitialLoading}")

  .container(if="{!isInitialLoading}")
    h5.text-center Login
    .columns(if="{!isLoggedIn}")
      .column.col-sm-1.col-lg-3
      .column.col-sm-10.col-lg-6
        a.btn.btn-block(href="#" onclick="{authTwitter}") Sign in with Twitter
        .divider.text-center(data-content="OR")
        a.btn.btn-block(href="#" onclick="{authFacebook}") Sign in with Facebook
      .column.col-sm-1.col-lg-3
    .columns(if="{isLoggedIn && !hasEthAccount}")
      .column.col-6
        form
          .form-group
            label.form-label(for="") Ethereumのパスワードを入力
            input.form-input(type="password" ref="pw" disabled="{loading}" oninput="{updatePassword}" autocomplete="off" name="password" placeholder="必ず保存してください！")
          a.btn(disabled="{disabled}" onclick="{create}" class="{loading: loading}") 作成

    .columns(if="{isLoggedIn && hasEthAccount}")
      h2 アカウント情報
      ul
        li {this.etherInfo.address}
        li {this.etherInfo.mnemonic}
        li {this.etherInfo.privatekey}
      br
      a(href="/") トップへ


  script.
    import request from 'superagent';
    this.disabled = true;
    this.isInitialLoading = true;
    this.hasEthAccount = false;
    this.isLoggedIn = false;
    this.user = {};
    this.etherInfo = null;

    this.on('mount', () => {
      this.firebase.isLoggedIn().then((user) => {
        this.user = user;
        // has account?
        this.isLoggedIn = true;
        this.firebase.hasEthAccount(user.uid).then((res) => {
          if(res){
            location.href = '/';
          }else{
            // input password
            this.isInitialLoading = false;
            this.update();
          }
        });
      }).catch((e) => {
        // not loggedin
        this.isInitialLoading = false;
        this.update();
      });
    });


    // Twitter認証
    authTwitter(e) {
      e.preventDefault();
      this.firebase.authTwitter();
    }

    // Facebook 認証
    authFacebook(e) {
      e.preventDefault();
      this.firebase.authFacebook();
    }

    updatePassword(e){
      const v = e.target.value;
      if(v.length > 0){
        this.disabled = false;
      }
    }

    create() {
      const { pw } = this.refs;
      this.loading = true;
      request.post('/newWallet')
        .set('Content-Type', 'application/json')
        .send(JSON.stringify({
          password: pw.value
        }))
        .then((res) => {
          this.firebase.updateEthAccount(this.user.uid, {
            address: res.body.address,
            fileName: res.body.fileName
          }).then(() => {
            this.etherInfo = res.body;
            console.log(this.etherInfo);
            this.loading = false;
            this.hasEthAccount = true;
            this.update();
          }, () => {
            this.loading = false;
            throw new Error("request fail")
          });
        }, (e) => {
          this.loading = false;
          throw new Error("request fail")
        });
    }
