admin
  .container.page
    h4 Admin
    button.btn(onclick="{opts.deployCardMaster}") Deploy Cardmaster
    hr
    h5 送金
    .columns
      .column.col-5
        .form-group
          label.form-label From
          select.form-select.select-sm(onchange="{changeAccount}")
            option(each="{ac in accounts}", value="{ac.account}")
              | {ac.account}
              | ({ac.eth + ' Eth'})
              // | ({parent.opts.unit === 'wei' ? ac.wei + ' Wei' : ac.eth + ' Eth'})
        .form-group
          label.form-label To
          input.form-input(type="text" placeholder="0x..." ref="receiver")
        .form-group
          .input-group
            input.form-input(type="text" placeholder="0" ref="eth")
            span.input-group-addon Eth
        .form-group
          button.btn.btn-sm(onclick="{send}") 送る

  script.
    this.account = '';
    this.accounts = [];

    this.on('mount', () => {
      this.accounts = this.updateAccounts();
      this.account = this.accounts[0].account;
      this.update();
    })

    updateAccounts(){
      const { web3 }  = this.web3c;
      return web3.eth.accounts.map((account) => {
        const wei = web3.eth.getBalance(account).toString(10);
        const eth = web3.fromWei(wei, "ether");
        return { account, wei, eth };
      });
    }

    changeAccount(){
      this.account = e.target.value;
    }

    send(){
      if(this.refs.receiver.value && this.refs.eth.value) {
        const { web3 }  = this.web3c;
        const sender = this.account;
        const receiver = this.refs.receiver.value;
        const amount = web3.toWei(this.refs.eth.value, "ether");
        const tx = web3.eth.sendTransaction({from:sender, to:receiver, value: amount})
        console.log(tx);
      }
    }
