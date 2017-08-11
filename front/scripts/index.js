import request from 'superagent';
import route from 'riot-route';

import '../styles/app.css';

//tags
import './tags/app.tag';
import './tags/components/card.tag';
import './tags/components/navbar.tag';
import './tags/components/card-detail.tag';
import './tags/components/card-owners.tag';
import './tags/components/card-bid.tag';
import './tags/components/card-send.tag';
import './tags/components/card-ask.tag';
import './tags/containers/home.tag';
import './tags/containers/mycards.tag';
import './tags/containers/activity.tag';
import './tags/containers/upload.tag';
import './tags/containers/detail.tag';
import './tags/containers/admin.tag';
import './tags/containers/setting.tag';
import './tags/containers/toast-box.tag';
import './tags/components/password-modal.tag';

// modules
import firebase from './firebase'
import web3c from './modules/web3c'


firebase.firebase.isLoggedIn().then((_user) => {
  const user = _user;
  firebase.firebase.getUserData(user.uid).then((_user) => {
    user.link = _user.link;
    user.etherAccount= _user.etherAccount;
    user.wei = web3c.web3.eth.getBalance(_user.etherAccount).toString(10);
    user.eth = web3c.web3.fromWei(user.wei, "ether");
    // オブザーバーオブジェクト
    const obs = riot.observable();

    // Eth -> JPY 変換API
    const ethAPI = 'https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=JPY'
    const updateEthPrice = () => {
      request('GET', ethAPI).then((data) => {
        obs.trigger('updateEthPrice', {
          etherJPY: data.body.JPY
        });
      }).catch(() => {
        console.alert('cant get ethAPI');
      })
    };

    // 1分に1回くらいリクエストする
    setInterval(() => {
      updateEthPrice();
    }, 60 * 1000);
    updateEthPrice();

    riot.mixin({user});
    riot.mixin({web3c});
    riot.mixin(firebase);
    riot.mount('navbar', { obs });
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
        cardAddress,
        obs
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

    route('activity', () => {
      console.log('route is activity');
      riot.mount('app', 'activity', {obs});
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



