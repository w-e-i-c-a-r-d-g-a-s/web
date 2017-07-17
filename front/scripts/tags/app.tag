app
  div(if="{isLoggedIn}")
    navbar(user="{user}" logout="{logout}" go="{go}")
    home(
      if="{page === 'home'}"
      cards="{cards}"
      go-detail="{goDetail}"
    )
    mypage(if="{page === 'mypage'}")
    upload(
      if="{page === 'upload'}"
      add-card="{addCard}"
    )
    admin(if="{page === 'admin'}" deploy-card-master="{deployCardMaster}")
    setting(if="{page === 'setting'}")
    detail(
      if="{page === 'detail'}"
      card="{card}"
      sell="{sell}"
      select-sell="{selectSell}"
      select-buyorder= "{selectBuyOrder}"
      refresh-sell-info="{refreshSellInfo}"
      buy="{buy}"
      buy-order="{buyOrder}"
      refresh-buyorder-info="{refreshBuyOrderInfo}"
      accept-bid="{acceptBid}"
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
    addCard(name, totalSupply){
      const gas = 1399659;
      this.web3c.addCard(this.user.etherAccount, name, totalSupply, gas);
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
      this.web3c.unlock(
        this.user.etherAccount,
        _pw,
        () => {
          console.log('done');
        }
      );
    }

    sell(quantity, wei){
      const gas = 223823;
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

    selectBuyOrder(e){
      this.buyOrderId = e.item.i;
    }

    refreshSellInfo(){
      this.card = assign({}, this.card, {
        sellInfo: this.web3c.refreshSellInfo(this.card.address)
      });
      this.update();
    }

    refreshBuyOrderInfo(){
      this.card = assign({}, this.card, {
        buyOrderInfo: this.web3c.refreshBuyOrderInfo(this.card.address)
      });
      this.update();
    }

    buy(){
      const selectedSellOrder = this.card.sellInfo[this.sellInfoId];
      const gas = 77911;
      this.web3c.buy(
        this.user.etherAccount,
        this.card.address,
        this.sellInfoId,
        gas,
        selectedSellOrder.totalPriceEth
      );
    }

    // TODO priceはEtherが入っている（本当はwei)
    buyOrder(quantity, price){
      // console.log(quantity, price);
      const gas = 400000;
      this.web3c.buyOrder(
        this.user.etherAccount,
        this.card.address,
        quantity,
        price,
        gas
      );
    }

    acceptBid(quantity){
      console.log('accept', quantity);
      const gas = 223823;
      this.web3c.acceptBid(
        this.user.etherAccount,
        this.card.address,
        this.buyOrderId,
        quantity,
        gas
      );
    }
