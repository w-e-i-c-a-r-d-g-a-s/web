import '../styles/app.css';

//tags
import './tags/app.tag';
import './tags/components/card.tag';
import './tags/components/navbar.tag';
import './tags/components/card-detail.tag';
import './tags/components/card-owners.tag';
import './tags/components/card-bid.tag';
import './tags/components/card-ask.tag';
import './tags/containers/home.tag';
import './tags/containers/mycards.tag';
import './tags/containers/upload.tag';
import './tags/containers/detail.tag';
import './tags/containers/admin.tag';
import './tags/containers/setting.tag';
import './tags/containers/toast-box.tag';
import './tags/components/password-modal.tag';

import route from 'riot-route';
// modules
import firebase from './firebase'
import web3c from './modules/web3c'


firebase.firebase.isLoggedIn().then((_user) => {
  const user = _user;
  firebase.firebase.getUserData(user.uid).then((_user) => {
    user.etherAccount= _user.etherAccount;
    user.wei = web3c.web3.eth.getBalance(_user.etherAccount).toString(10);
    user.eth = web3c.web3.fromWei(user.wei, "ether");
    // オブザーバーオブジェクト
    const obs = riot.observable();

    // filterの監視
    web3c.watch((res) => {
      console.log(res);
      const { tx, receipt, isError, txIndex } = res;
      // 自分が発行したtxの場合は通知
      if(user.etherAccount === tx.from){
        let text = '';
        if(isError){
          text = res.errorMsg;
          obs.trigger('notifyError', {
            text
          });
        } else {
          text = `🔨mined! (${txIndex}) => blockNumber: ${tx.blockNumber},
                    value: ${tx.value.toString(10)},
                    gasUsed: ${receipt.gasUsed},
                    gas: ${tx.gas}`;
          obs.trigger('notifySuccess', {
            text
          });
        }
      }
    });


    riot.mixin({user});
    riot.mixin({web3c});
    riot.mixin(firebase);
    riot.mount('navbar');
    riot.mount('toast-box', { obs });
    // riot.mount('app');

    route(function(collection, id, action) {
      console.log(collection, id, action);
    });

    route('/', function(collection, id, action) {
      console.log('route is home');
      riot.mount('app', 'home');
    });

    route('/cards/*', function(cardAddress) {
      console.log('route is card detail', cardAddress);
      riot.mount('app', 'detail', {
        cardAddress
      });
    });

    route('mycards', () => {
      console.log('route is mycards');
      riot.mount('app', 'mycards');
    });

    route('upload', () => {
      console.log('route is upload');
      riot.mount('app', 'upload', {obs});
    });

    route('admin', () => {
      console.log('route is admin');
      riot.mount('app', 'admin', {obs});
    });

    route('setting', () => {
      console.log('route is setting');
      riot.mount('app', 'setting', {obs});
    });

    route.start(true);
  });
  // this.isLoggedIn = true;
  // this.update();
}).catch((e) => {
  // not login
  location.href = '/login';
});



