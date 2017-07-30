upload
  .page.container
    .columns
      .column.col-2.col-xs-12.col-sm-12.hide-md.hide-lg
      .column.col-4.col-xs-12.col-sm-12.col-md-6.col-lg-6
        h5.preview-title プレビュー
        card(card="{card}" single="{true}")
        img(ref="prev")
      .column.col-4.col-xs-12.col-sm-12.col-md-6.col-lg-6
        form
          .form-group
            label.form-label カード画像
            input.form-input(
              type="file"
              id="file"
              ref="file"
              accept="image/x-png,image/gif,image/jpeg"
              onchange="{selectFile}"
            )
          .form-group
            label.form-label(for="card-name") カード名
            input#card-name.form-input(
              type="text"
              ref="cardName"
              placeholder="New Card Name"
              oninput="{changeName}"
            )
          .form-group
            label.form-label(for="total-supply") 発行枚数
            input#total-supply.form-input(
              type="number"
              ref="totalSupply"
              placeholder="10"
              oninput="{changeTs}"
            )
          .form-group
            button.btn.btn-primary(
              onclick="{addCard}"
              disabled="{!enableForm}"
              class="{loading: loading}"
            ) カードを発行
      .column.col-2.col-xs-12.col-sm-12.hide-md.hide-lg

  password-modal(
    unlock="{unlock}"
    show="{showPasswordModal}"
    deferred="{deferred}"
    obs="{opts.obs}"
  )

  script.
    import Deferred from 'es6-deferred';
    import SparkMD5 from 'spark-md5';

    const PH_NAME = 'New Card Name';
    const PH_TS = 10;
    const PH_IMAGE_URL = 'https://www.ethereum.org/images/logos/ETHEREUM-LOGO_PORTRAIT_Black_small.png';

    this.showPasswordModal = false;
    this.loading = false;
    this.enableForm = false;
    this.file = null;
    this.fileHash = '';
    this.card = {
      name: PH_NAME,
      address: '0x999999999999999999999999999999999',
      imageUrl: 'https://www.ethereum.org/images/logos/ETHEREUM-LOGO_PORTRAIT_Black_small.png',
      issued: PH_TS
    };

    this.on('mount', () => {
      this.card.author = this.user.etherAccount;
      this.update();
    });

    async addCard(e){
      e.preventDefault();
      const { cardName, totalSupply } = this.refs;
      if(cardName.value && totalSupply.value){
        this.loading = true;
        this.update();
        // パスワード入力
        try {
          await this.inputUnlock();
        } catch (e) {
          // キャンセル
          this.loading = false;
          this.update();
          return ;
        }
        // 画像データアップロード
        const url = await this.firebase.uploadImage(this.file, this.fileHash);
        // console.log(url, this.card);
        // FBにカードデータを作成
        this.firebase.createCard(this.fileHash, {
          name: cardName.value,
          issued: +totalSupply.value,
          url
        });
        await this._addCard(cardName.value, totalSupply.value, this.fileHash);
        this.loading = false;
        this.resetForm();
        this.update();
      }
    }

    {
    /**
     * カードを登録
     */
    async _addCard(name, totalSupply, imageHash){
      console.log(name, totalSupply, imageHash);
      const gas = 1599659;
      return new Promise((resolve, reject) => {
        try {
          const tx = this.web3c.addCard(this.user.etherAccount, name, totalSupply, imageHash.toString(), gas);
          this.opts.obs.trigger('notifySuccess', {
            text: `transaction send! => ${tx}`
          });
          resolve();
        }catch(e){
          // if(e.message === 'authentication needed: password or unlock'){
          // }
          this.opts.obs.trigger('notifyError', {
            text: e.message
          });
          reject(Error('err'));
        }
      });
    }

    }

    resetForm(){
      const { cardName, totalSupply, file} = this.refs;
      cardName.value = '';
      totalSupply.value = '';
      file.value = '';
      this.card.name = PH_NAME;
      this.card.issued = PH_TS;
      this.card.imageUrl = PH_IMAGE_URL;
      this.checkForm();
    }

    changeName(e){
      this.card.name = e.target.value;
      if(this.card.name.length === 0){
        this.card.name = PH_NAME;
      }
      this.checkForm();
    }

    changeTs(e){
      this.card.issued = e.target.value;
      if(e.target.value.length === 0){
        this.card.name = TS_PH;
      }
      this.checkForm();
    }

    checkForm(){
      const { cardName, totalSupply, file } = this.refs;
      this.enableForm = cardName.value && totalSupply.value && file.value;
      this.update();
    }

    selectFile(e){
      e.preventDefault();
      this.file = e.target.files[0];
      const blobSlice = File.prototype.slice || File.prototype.mozSlice || File.prototype.webkitSlice;
      const chunkSize = 2097152; // Read in chunks of 2MB
      const chunks = Math.ceil(this.file.size / chunkSize);
      let currentChunk = 0;
      const spark = new SparkMD5.ArrayBuffer();
      const reader = new FileReader();

      const loadNext = () => {
        const start = currentChunk * chunkSize;
        const end = ((start + chunkSize) >= this.file.size) ? this.file.size : start + chunkSize;
        reader.readAsArrayBuffer(blobSlice.call(this.file, start, end));
      };

      reader.onload = (e) => {
        // md5を計算
        // console.log('read chunk nr', currentChunk + 1, 'of', chunks);
        spark.append(e.target.result); // Append array buffer
        currentChunk++;
        if (currentChunk < chunks) {
          loadNext();
        } else {
          // finished loading
          // md5を返す
          const hash = spark.end();
          this.fileHash = hash;
          this.setImageToPreview();
          this.checkForm();
        }
      };

      reader.onerror = function () {
        throw new Error("Something bad happened.")
      };

      loadNext();
      this.checkForm();
    }

    // preview
    setImageToPreview(){
      const reader = new FileReader();
      reader.onload = (e) => {
        this.card.imageUrl = e.target.result;
        this.update();
      };

      reader.onerror = function () {
        throw new Error("Something bad happened.")
      };
      reader.readAsDataURL(this.file);
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
          console.log('unlocked!');
          this.showPasswordModal = false;
          this.update();
          resolve();
        }else{
          this.showPasswordModal = false;
          this.update();
          reject(Error('err'));
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
