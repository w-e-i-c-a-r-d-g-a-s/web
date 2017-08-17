const fs = require('fs');
const express = require('express');
const router = express.Router();
const ethers = require('ethers');
const etherSetting = require('../etherSetting.json');

router.post('/', (req, res) => {
  const pw = req.body.password;
  // console.log(pw);
  const Wallet = ethers.Wallet;
  const providers = ethers.providers;
  // console.log(providers);
  const _wallet = Wallet.createRandom();
  _wallet.encrypt(pw).then(function(json) {
    // keyStoreを保存
    const keyStore = json;
    const fileName = `UTC--${new Date().toISOString()}--${_wallet.address.slice(2)}`;
    fs.writeFile(`${etherSetting.etherPath}/keystore/${fileName}`, keyStore, (err) => {
      if(err){
        throw err;
      }
      // アドレスを登録
      res.json({
        address: _wallet.address,
        mnemonic: _wallet.mnemonic,
        privatekey: _wallet.privateKey,
        address: _wallet.address,
        fileName: fileName
      });
    });
  });
});

module.exports = router;

