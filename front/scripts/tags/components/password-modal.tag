password-modal
  .modal(class="{active: opts.show}")
    .modal-overlay
    .modal-container(style="width: 40rem" role='document')
      .modal-header
        button.btn.btn-clear.float-right(type='button', aria-label='Close' onclick="{close}")
        .modal-title 取引を実行
      .modal-body
        .content
          form(autocomplete="off" role="presentation" onsubmit="{submit}")
            .form-group
              label.form-label(for='tx-passwd') パスワードを入力してください
              input#tx-passwd.form-input(
                type='password' ref="pw"
                autocomplete="off" name="xxx" placeholder=''
                class="{'is-error': isError, 'is-success': isSuccess }"
              )
              p.form-input-hint {message}
      .modal-footer
        button.btn.btn-link(onclick="{close}") キャンセル
        button.btn.btn-primary(onclick="{submit}") 送信
  script.

    this.message = '';
    this.isError = false;
    this.isSuccess = false;

    async submit(e){
      e.preventDefault();
      if(this.opts.deferred){
        const pw = this.refs.pw.value;
        try {
          // 10分間アンロックする
          await this.web3c.unlock(this.user.etherAccount, pw, 600);
          this.message = `account unlocked => ${this.user.etherAccount}`;
          this.isError = false;
          this.isSuccess = true;
          this.update();
          setTimeout(() => {
            this.opts.deferred.resolve(true);
            this.initForm();
          }, 2000);
        } catch (e) {
          /* handle error */
          this.message = e.message;
          this.isSuccess = false;
          this.isError = true;
          this.update();
        }
      }
    }

    initForm(){
      this.refs.pw.value = '';
      this.message = '';
      this.isError = false;
      this.isSuccess = false;
      this.update();
    }

    close(e){
      e.preventDefault();
      if(this.opts.deferred){
        this.opts.deferred.resolve(false);
      }
    }

