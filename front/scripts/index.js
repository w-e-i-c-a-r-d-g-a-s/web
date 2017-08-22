import request from 'superagent';
import route from 'riot-route';

import '../styles/app.css';

//tags
import './tags/app.tag';
import './tags/components/card.tag';
import './tags/components/navbar.tag';
import './tags/components/card-owners.tag';
import './tags/components/card-bid.tag';
import './tags/components/card-deal.tag';
import './tags/components/card-ask.tag';
import './tags/components/card-activity.tag';
import './tags/components/card-tags.tag';
import './tags/components/card-prices.tag';
import './tags/containers/home.tag';
import './tags/containers/mycards.tag';
import './tags/containers/activity.tag';
import './tags/containers/upload.tag';
import './tags/containers/detail.tag';
import './tags/containers/admin.tag';
import './tags/containers/setting.tag';
import './tags/containers/tagpage.tag';
import './tags/containers/toast-box.tag';
import './tags/containers/notfound.tag';
import './tags/components/password-modal.tag';

// modules
import firebase from './modules/firebase';
import web3c from './modules/web3c';
import { EVENT, MENUS } from './constants';

// オブザーバーオブジェクト
const obs = riot.observable();

const setEtherPriceAPI = () => {
  // Eth -> JPY 変換API
  let ethAPI = ''
  if(process.env.NODE_ENV === 'production'){
    ethAPI = 'https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=JPY';
  }else{
    ethAPI = '/dummyprice';
  }

  const updateEthPrice = () => {
    request('GET', ethAPI).then((data) => {
      obs.trigger('updateEthPrice', {
        etherJPY: data.body.JPY
      });
    }).catch(() => {
      console.error('cant get etherAPI');
    })
  };

  // 1分に1回くらいリクエストする
  setInterval(() => {
    updateEthPrice();
  }, 60 * 1000);
  updateEthPrice();
};

(async () => {
  let _authUser = null;
  try {
    _authUser = await firebase.firebase.isLoggedIn();
  } catch (e) {
    // not login
    location.href = '/login';
    return;
  }

  // Create user data
  const _user = await firebase.firebase.getUserData(_authUser.uid);
  const user = _authUser;
  user.link = _user.link;
  user.etherAccount= _user.etherAccount;
  user.wei = web3c.web3.eth.getBalance(_user.etherAccount).toString(10);
  user.eth = web3c.web3.fromWei(user.wei, "ether");

  setEtherPriceAPI();

  riot.mixin({user});
  riot.mixin({web3c});
  riot.mixin(firebase);
  riot.mount('navbar', { obs });
  riot.mount('toast-box', { obs });

  route('/', (collection, id, action) => {
    console.log('route is home');
    obs.trigger(EVENT.UPDATE_MENU, { selectedMenu: MENUS.HOME });
    riot.mount('app', 'home');
  });

  route('/cards/*', (cardAddress) => {
    riot.mount('app', 'detail', { cardAddress, obs });
  });

  route('/tags/*', (tag) => {
    riot.mount('app', 'tagpage', { tag });
  });

  route('mycards', () => {
    obs.trigger(EVENT.UPDATE_MENU, { selectedMenu: MENUS.MYCARDS });
    riot.mount('app', 'mycards');
  });

  route('upload', () => {
    obs.trigger(EVENT.UPDATE_MENU, { selectedMenu: MENUS.UPLOAD });
    riot.mount('app', 'upload', {obs});
  });

  route('activity', () => {
    obs.trigger(EVENT.UPDATE_MENU, { selectedMenu: MENUS.ACTIVITY });
    riot.mount('app', 'activity', {obs});
  });

  route('admin', () => {
    obs.trigger(EVENT.UPDATE_MENU, { selectedMenu: MENUS.ADMIN });
    riot.mount('app', 'admin', {obs});
  });

  route('setting', () => {
    obs.trigger(EVENT.UPDATE_MENU, { selectedMenu: MENUS.SETTING });
    riot.mount('app', 'setting', {obs});
  });

  route((collection, id, action) => {
    console.log('not found', collection, id, action);
    riot.mount('app', 'notfound');
  });

  route.start(true);
})();

