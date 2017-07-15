import riot from 'riot';

import '../styles/app.css';

//tags
import './tags/app.tag';
import './tags/navbar.tag';
import './tags/login.tag';
// modules
import firebase from './firebase'
import web3c from './modules/web3c'

riot.mixin({web3c});
riot.mixin(firebase);
riot.mount('*');
