app
  div(if="{isLoggedIn}")
    navbar(user="{user}" logout="{logout}" go="{go}")
    .page.home(if="{page === 'home'}")
      h4 Home
      card(each="{cards}" go-detail="{goDetail}")

    .page.home(if="{page === 'mypage'}")
      h4 Mypage
    .page.home(if="{page === 'upload'}")
      h4 Upload
      a.btn(onclick="{addCard}") カードを登録
    .page.home(if="{page === 'setting'}")
      h4 Setting
      button.btn(onclick="{deployCardMaster}") Deploy Cardmaster
      button.btn(onclick="{downloadKS}") keyStoreをダウンロード
      hr
      div
        p unlockをテスト
        label パスワード
        input(type="password" ref="password")
        a.btn(onclick="{unlock}") unlock
    detail(
      if="{page === 'detail'}"
      card="{card}"
      sell="{sell}"
      select-sell="{selectSell}"
      refresh-sell-info="{refreshSellInfo}"
    )


  div(if="{!isLoggedIn}")
    a(href="/login") ログイン
    span してください

  script.
    import { assign } from 'lodash';
    this.page = 'home';
    this.user = null;
    this.isLoggedIn = false;

    this.on('mount', () => {
      this.firebase.isLoggedIn().then((user) => {
        this.user = user;
        this.firebase.getUserData(this.user.uid)
          .then((_user) => {
            this.user.etherAccount= _user.etherAccount;
            this.user.wei = this.web3c.web3.eth.getBalance(_user.etherAccount).toString(10);
            this.user.eth = this.web3c.web3.fromWei(this.user.wei, "ether");
            this.update();
          });
        this.isLoggedIn = true;
        this.update();
      }).catch((e) => {
        // not login
      });

      // カードを取得
      this.cards = this.web3c.getCards();
      console.log(this.cards);
    });

    /**
     * ページ遷移
     */
    go(page){
      this.page = page;
      this.update();
    }

    /**
     * カードを登録
     */
    addCard(){
      this.web3c.addCard(this.user.etherAccount, 'Good Morning', 100, 1399659);
    }

    /**
     * ログアウト処理
     */
    logout(){
      this.firebase.logout().then(() => {
        location.reload();
      });
    }

    deployCardMaster(){
      this.web3c.deployCardMaster('0xf5290627291e0dd723741ead15ca20242aeccdd2');
    }

    goDetail(e){
      this.card = this.web3c.getCard(e.item.address);
      this.go('detail');
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

    sell(quantity, wei){
      const gas = 123823;
      this.web3c.sell(
        quantity,
        wei,
        this.card.address,
        this.user.etherAccount,
        gas
      );
    }

    selectSell(e){
      this.sellInfoId = e.item.i;
    }

    refreshSellInfo(){
      this.card = assign({}, this.card, {
        sellInfo: this.web3c.refreshSellInfo(this.card.address)
      });
      this.update();
    }
