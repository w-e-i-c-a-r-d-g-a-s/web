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
    admin(
      if="{page === 'admin'}"
      send="{send}"
      deploy-card-master="{deployCardMaster}"
    )
    setting(
      if="{page === 'setting'}"
      downloadks="{downloadKS}"
      unlock="{unlock}"
    )
    detail(
      if="{page === 'detail'}"
      user="{user}"
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

  toast-box(queue="{queue}")

  div(if="{!isLoggedIn}")
    a(href="/login") ログイン
    span してください

  script.
    import { assign } from 'lodash';
    this.page = 'home';
    this.user = null;
    this.isLoggedIn = false;
    this.queue = [];

    this.on('mount', () => {

      this.firebase.isLoggedIn().then((user) => {
        this.user = user;
        // filterの監視
        this.web3c.watch(this.user.etherAccount, (text, type='') => {
          this.queue.push({ text, type });
          this.update();
        });
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

    unlock(_pw){
      const success = () => {
        this.notify(`account unlocked => ${this.user.etherAccount}`, 'success');
      };
      const err = (errorText) => {
        this.notify(errorText, 'error');
      };

      this.web3c.unlock(
        this.user.etherAccount,
        _pw,
        success,
        err
      );
    }

    sell(quantity, wei){
      const gas = 423823;
      try {
        const tx = this.web3c.sell(
          quantity,
          wei,
          this.card.address,
          this.user.etherAccount,
          gas
        );
        this.notify(`transaction send! => ${tx}`);
      }catch(e){
        this.notify(e.message, 'error');
      }
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
      console.log(selectedSellOrder);
      const gas = 208055;
      try {
        const tx = this.web3c.buy(
          this.user.etherAccount,
          this.card.address,
          selectedSellOrder.id,
          gas,
          selectedSellOrder.totalPriceEth
        );
        this.notify(`transaction send! => ${tx}`);
      }catch(e){
        this.notify(e.message, 'error');
      }
    }

    // TODO priceはEtherが入っている（本当はwei)
    buyOrder(quantity, price){
      // console.log(quantity, price);
      const gas = 800000;
      try{
        const tx = this.web3c.buyOrder(
          this.user.etherAccount,
          this.card.address,
          quantity,
          price,
          gas
        );
        this.notify(`transaction send! => ${tx}`);
      }catch(e){
        this.notify(e.message, 'error');
      }
    }

    acceptBid(quantity){
      const selectedBuyOrder = this.card.buyOrderInfo[this.buyOrderId];
      console.log(selectedBuyOrder.id);
      const gas = 1523823;
      try{
        const tx = this.web3c.acceptBid(
          this.user.etherAccount,
          this.card.address,
          selectedBuyOrder.id,
          quantity,
          gas
        );
        this.notify(`transaction send! => ${tx}`);
      }catch(e){
        this.notify(e.message, 'error');
      }
    }

    /**
     * 通知
     * @param {string} text テキスト
     * @param {string} type 表示タイプ
     */
    notify(text, type=''){
      this.queue.push({ text, type });
      this.update();
    }

    send(sender, receiver, value){
      const { web3 }  = this.web3c;
      const amount = web3.toWei(value, "ether");
      try{
        const tx = web3.eth.sendTransaction({
          from:sender,
          to:receiver,
          value: amount
        })
        this.notify(`transaction send! => ${tx}`);
      }catch(e){
        this.notify(e.message, 'error');
      }
    }


