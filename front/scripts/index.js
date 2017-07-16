import riot from 'riot';

import '../styles/app.css';

//tags
import './tags/app.tag';
import './tags/navbar.tag';
import './tags/login.tag';
import './tags/card.tag';
import './tags/card-detail.tag';
import './tags/containers/home.tag';
import './tags/containers/detail.tag';

// modules
import firebase from './firebase'
import web3c from './modules/web3c'

riot.mixin({web3c});
riot.mixin(firebase);
riot.mount('*');
