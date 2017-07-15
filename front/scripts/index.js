import riot from 'riot';

import '../styles/app.css';

//tags
import './tags/app.tag';
import './tags/navbar.tag';
import './tags/login.tag';
// modules
import firebase from './firebase'
import web3c from './modules/web3c'

const url = 'http://localhost:8545';
let web3;
if (typeof web3 !== 'undefined') {
  web3 = new Web3(web3.currentProvider);
} else {
  // set the provider you want from Web3.providers
  web3 = new Web3(new Web3.providers.HttpProvider(url));
}

riot.mixin({web3});
riot.mixin({web3c});
riot.mixin(firebase);
riot.mount('*');
