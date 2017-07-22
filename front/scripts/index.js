import riot from 'riot';
import _ from 'lodash';

import '../styles/app.css';

//tags
import './tags/app.tag';
import './tags/login.tag';
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

// modules
import firebase from './firebase'
import web3c from './modules/web3c'

riot.mixin({web3c});
riot.mixin(firebase);
riot.mount('*');
