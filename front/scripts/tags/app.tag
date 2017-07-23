app
  div(if="{isLoggedIn}")
    navbar(user="{user}" logout="{logout}" go="{go}")
    home(
      if="{page === 'home'}"
      go-detail="{goDetail}"
    )
    mycards(
      if="{page === 'mycards'}"
      user="{user}"
      go-detail="{goDetail}"
    )
    upload(
      if="{page === 'upload'}"
      user="{user}"
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
      bid="{bid}"
      ask="{ask}"
      bid-id="{bidId}"
      ask-id="{this.askId}"
      accept-bid="{acceptBid}"
      select-bid="{selectBid}"
      select-ask= "{selectAsk}"
      refresh-bid-info="{refreshBidInfo}"
      refresh-ask-info="{refreshAskInfo}"
      accept-ask="{acceptAsk}"
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
        this.firebase.getUserData(this.user.uid)
          .then((_user) => {
            this.user.etherAccount= _user.etherAccount;
            this.user.wei = this.web3c.web3.eth.getBalance(_user.etherAccount).toString(10);
            this.user.eth = this.web3c.web3.fromWei(this.user.wei, "ether");
            this.update();
            // filterの監視
            this.web3c.watch((res) => {
              const { tx, receipt, isError, txIndex } = res;
              // 自分が発行したtxの場合は通知
              if(this.user.etherAccount === tx.from){
                let text = '';
                if(isError){
                  text = res.errorMsg;
                } else {
                  text = `🔨mined! (${txIndex}) => blockNumber: ${tx.blockNumber},
                    value: ${tx.value.toString(10)},
                    gasUsed: ${receipt.gasUsed},
                    gas: ${tx.gas}`;
                }
                this.queue.push({
                  text,
                  type: isError ? 'error' : 'success'
                });
                this.update();
              }
            });
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
     * カードを登録
     */
    addCard(name, totalSupply, imageHash){
      console.log(name, totalSupply, imageHash);
      const gas = 1399659;
      return new Promise((resolve, reject) => {
        try {
          const tx = this.web3c.addCard(this.user.etherAccount, name, totalSupply, imageHash.toString(), gas);
          this.notify(`transaction send! => ${tx}`);
          resolve();
        }catch(e){
          this.notify(e.message, 'error');
          reject(Error('err'));
        }
      });
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

    goDetail(cardAddress){
      this.card = this.web3c.getCard(cardAddress);
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

    /**
     * 売り注文(bid)を発行
     *
     * @param {number} quantity 数量
     * @param {number} wei 一枚あたりの価格(wei)
     */
    bid(quantity, wei){
      const gas = 200000;
      try {
        const tx = this.web3c.bid(
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

    selectBid(e){
      this.bidId = e ? e.item.i : null;
      console.log(this.bidId);
      this.update();
    }

    selectAsk(e){
      this.askId =  e ? e.item.i : null;
      this.update();
    }

    refreshBidInfo(){
      this.card = assign({}, this.card, {
        bidInfo: this.web3c.refreshBidInfo(this.card.address)
      });
      this.update();
    }

    refreshAskInfo(){
      this.card = assign({}, this.card, {
        askInfo: this.web3c.refreshAskInfo(this.card.address)
      });
      this.update();
    }

    acceptBid(){
      const selectedBid = this.card.bidInfo[this.bidId];
      const gas = 208055;
      try {
        const tx = this.web3c.acceptBid(
          this.user.etherAccount,
          this.card.address,
          selectedBid.id,
          gas,
          selectedBid.totalPriceEth
        );
        this.notify(`transaction send! => ${tx}`);
      }catch(e){
        this.notify(e.message, 'error');
      }
    }

    /**
     * 買い注文を発行
     *
     * @param {number} quantity 数量
     * @param {number} wei 1枚あたりの価格(wei)
     */
    ask(quantity, wei){
      // TODO ここで単位をetherに変換
      const price = this.web3c.web3.fromWei(wei, 'ether');
      const gas = 800000;
      try{
        const tx = this.web3c.ask(
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

    acceptAsk(quantity){
      const selectedAsk = this.card.askInfo[this.askId];
      const gas = 1523823;
      try{
        const tx = this.web3c.acceptAsk(
          this.user.etherAccount,
          this.card.address,
          selectedAsk.id,
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


