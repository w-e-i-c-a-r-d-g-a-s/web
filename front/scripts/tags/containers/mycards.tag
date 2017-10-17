mycards
  .page.container
    .columns.mt-2
      .column.col-12(if="{myCards.length > 0}")
        .my-cards(each="{card in myCards}")
          card(card="{card}")
          .detail
            .columns
              .column.col-6 所有枚数
              .column.col-6
                strong {card.numberOfCard}枚
            .columns
              .column.col-12
                button.btn.btn-primary.btn-block.mt-2(onClick="{showModal}") このカードを配布する
      .column.col-12(if="{myCards.length === 0}")
        .empty
          .empty-icon
            i.icon.icon-photo(style="font-size: 3rem;")
          h4.empty-title 所有しているカードはありません

    .modal(class="{active: isShowDealModal}")
      .modal-overlay
      .modal-container
        .modal-header
          button.btn.btn-clear.float-right(onClick="{closeModal}")
          .modal-title.h5 カードを配布する
        .modal-body
          .content
            card-deal(
              deal="{deal}"
              card="{selectedCard}"
            )
        .modal-footer
    password-modal(
      unlock="{unlock}"
      show="{showPasswordModal}"
      deferred="{deferred}"
      obs="{opts.obs}"
    )

  script.
    import Deferred from 'es6-deferred';
    this.isShowDealModal = false;
    this.selectedCard = {};
    this.showPasswordModal = false;

    this.myCards = [];
    this.on('mount', () => {
      this.myCards = this.web3c.getCards(this.user.etherAccount);
      this.myCards.forEach(async (c) => {
        const cardData = await this.firebase.getCard(c.imageHash);
        if(cardData){
          c.imageUrl = cardData.url;
        }
        this.update();
      });
    });

    showModal(e){
      this.selectedCard = e.item.card;
      this.isShowDealModal = true;
    }

    closeModal(e){
      this.isShowDealModal = false;
    }

    /**
     * カードを配布
     * @param {number} quantity 数量
     * @param {string} receiver 受信者のアドレス
     */
    deal(quantity, receiver){
      const gas = 200000;
      const { address } = this.selectedCard;
      const { etherAccount } = this.user;
      return new Promise(async (resolve, reject) => {
        try {
          await this.inputUnlock();
          try{
            const tx = this.web3c.deal(etherAccount, address, quantity, receiver, gas);
            this.opts.obs.trigger('notifySuccess', {
              text: `transaction send! => ${tx}`
            });
            resolve();
          }catch(e){
            this.opts.obs.trigger('notifyError', { text: e.message });
            reject();
          }
        }catch(e){
          console.log(e);
          reject();
        }
      });
    }

    unlockAccount(){
      // モーダルを表示し、処理を待つ
      this.deferred = new Deferred();
      this.showPasswordModal = true;
      this.update();
      return this.deferred.promise;
    }

    /**
     * パスワード入力モーダルを表示
     * @returns {Promise}
     */
    inputUnlock(){
      return new Promise(async (resolve, reject) => {
        // アンロックダイアログを表示
        const res = await this.unlockAccount();
        if(res){
          // アンロック処理後
          this.showPasswordModal = false;
          this.closeModal();
          this.update();
          resolve();
        }else{
          this.showPasswordModal = false;
          this.update();
          reject(Error('err'));
        }
      });
    }
