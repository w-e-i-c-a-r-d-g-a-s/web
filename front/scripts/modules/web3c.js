const CardMasterABI = JSON.parse(require('../../../sol/dist/CardMaster.abi'));
const CardMasterBIN = `0x${require('../../../sol/dist/CardMaster.bin')}`;
const CardABI = JSON.parse(require('../../../sol/dist/Card.abi'));

// 定数
// const CardMasterAddress = '0xbe4d25adf719ba3fedfdbd8ad86dc710b035b21d';
const CardMasterAddress = '0x9199a78d27c9eb38f7ad659ad1bb3e08892e1c77';
const CardMasterContract = web3.eth.contract(CardMasterABI);
const CardMasterInstance = CardMasterContract.at(CardMasterAddress);

const CardContract = web3.eth.contract(CardABI);


const web3c = {
  // アンロック
  unlock: (userName, password, cb = () => {}) => {
    const unlockDurationSec = 0; // 0の場合永続的
    const jsonData = createJSONdata('personal_unlockAccount',
      [
        userName,
        password,
        unlockDurationSec
      ]
    );
    executeJsonRpc(url, jsonData, (data) => {
      // Success
      if(data.error == null){
        console.log('account unlocked! 😀', userName);
      } else {
        console.error(`login error: ${data.error.message}`);
      }
      cb();
    }, (data) => {
      // fail
      console.log('login error');
      cb();
    });
  }

};

const createJSONdata = (method, params) => ({
  jsonrpc: "2.0",
  id: null,
  method: method,
  params: params
});

const executeJsonRpc = (url, json, s, er) => {
  request.post(url)
    .set('Content-Type', 'application/json')
    .send(JSON.stringify(json))
    .then((res) => {
      s(res.body);
    }, (e) => {
      console.log(e);
      er(e);
    });
};

export default web3c;
