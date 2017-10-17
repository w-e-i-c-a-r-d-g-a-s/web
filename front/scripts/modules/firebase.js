import firebase from 'firebase';
import config from '../firebase.config';

firebase.initializeApp(config);

const storage = firebase.storage();
const storageRef = storage.ref();

firebase.auth().getRedirectResult().then(function(result) {
  const { user } = result;

  if(user){
    const { providerId, profile } = result.additionalUserInfo;

    // ユーザページへのリンクを生成
    let link = '';
    if(providerId === 'facebook.com'){
      link = profile.link;
    }

    if(providerId === 'twitter.com'){
      const { username } = result.additionalUserInfo;
      link = `https://twitter.com/${username}`;
    }

    // ユーザ登録
    // ユーザがすでにいる場合は作成しない
    firebase.database().ref('users/' + user.uid)
      .once('value')
      .then((snapshot) => {
        if(!snapshot.exists()){
          firebase.database().ref('users/' + user.uid).set({
            providerId, // twiiter or facebook
            link,       // user page link
            displayName: user.displayName,
            email: user.email,
            photoURL: user.photoURL
          });
        }
      });
  }
}).catch(function(error) {
  console.log(error);
});

// TODO アドレスと画像の紐付け
const addressToPhotoUrl = {};
const res = firebase.database().ref('users').limitToLast(100);
res.once('value', (ss) => {
  ss.forEach((s) => {
    const val = s.val();
    addressToPhotoUrl[val.etherAccount] = val.photoURL;
  });
});

export default {
  firebase: {
    _firebase: firebase,
    addressToPhotoUrl,
    // ログインしているかどうか
    isLoggedIn(){
      return new Promise((resolve, reject) => {
        firebase.auth().onAuthStateChanged((user) => {
          if (user) {
            resolve(user);
          } else {
            reject();
          }
        });
      });
    },

    // DBからユーザデータを取得
    getUserData(userUID){
      return new Promise((resolve, reject) => {
        firebase.database()
          .ref(`users/${userUID}`)
          .on('value', (snapshot) => {
            resolve(snapshot.val());
          });
      });
    },

    // etherのアドレスからユーザを検索
    findByUser(address){
      const ref = firebase.database().ref('users');
      return new Promise((resolve, reject) => {
        ref.orderByChild('etherAccount').equalTo(address)
          .on('child_added', (snapshot) => {
            resolve(snapshot.val().photoURL);
          });
      });
    },

    // Twitter認証
    authTwitter() {
      const provider = new firebase.auth.TwitterAuthProvider();
      firebase.auth().signInWithRedirect(provider);
    },

    // Facebook 認証
    authFacebook() {
      const provider = new firebase.auth.FacebookAuthProvider();
      firebase.auth().signInWithRedirect(provider);
    },

    logout(){
      return new Promise((resolve, reject) => {
        firebase.auth().signOut().then(() => {
          resolve();
        }, (error) => {
          reject(Error('err'));
        });
      });
    },

    // has eth account
    hasEthAccount(id){
      return new Promise((resolve, reject) => {
        firebase.database().ref('users/' + id).once('value')
          .then(function(snapshot) {
            resolve(snapshot.child('etherAccount').exists());
          });
      });
    },

    // update eth account
    updateEthAccount(id, {address, fileName}){
      return firebase.database().ref('users/' + id).update({
        etherAccount: address.toLowerCase(),
        etherKeyStoreFile: fileName
      });
    },

    /**
     * カードデータを作成
     * @param {object} card カードデータ
     */
    createCard(id, card){
      firebase.database().ref('cards/' + id ).set(card);
      this.setTags(card.tags, id);
    },

    /**
     * タグの一覧を取得
     * TODO 全件取得するのでそのうち遅くなるのでは？
     * @returns {Promise}
     */
    getTags(){
      const ref = firebase.database().ref('tags').orderByValue();
      return new Promise((resolve, reject) => {
        ref.once('value', (data) => {
          const tags = [];
          data.forEach((ss) => {
            tags.push(ss.key);
          });
          resolve(tags);
        });
      });
    },

    /**
     * タグをセット
     * @param {array} tagList タグデータの配列
     * @param {string} cardId カードID
     */
    setTags(tagList, cardId){
      tagList.forEach((tag) => {
        const ref = firebase.database().ref(`tags/${tag}`);
        ref.once('value').then((snapshot) => {
          if(snapshot.exists()){
            // カードを追加
            const v = snapshot.val();
            v.push(cardId);
            ref.set(v);
          } else {
            // 新規
            ref.set([cardId]);
          }
        });
      });
    },

    getCard(id){
      return new Promise((resolve, reject) => {
        firebase.database().ref('cards/' + id ).once('value')
          .then((ss) => {
            resolve(ss.val());
          });
      });
    },

    // 直近の取引5件分を取得
    getLatestTradeCards(){
      return new Promise((resolve, reject) => {
        firebase.database().ref('latestTradeCards')
          .orderByChild('time')
          .limitToLast(5)
          .once('value')
          .then((ss) => {
            resolve(ss.val());
          });
      });
    },

    /**
     * 画像をアップロード
     * @param {File} file ファイルオブジェクト
     * @param {string} fileName ファイル名
     */
    uploadImage(file, fileName){
      const metadata = {
        'contentType': file.type
      };
      // 拡張子を取得
      const _f = file.name.split('.');
      const ext = _f[_f.length - 1];
      return new Promise((resolve, reject) => {
        storageRef.child(`images/${fileName}.${ext}`)
          .put(file, metadata)
          .then((snapshot) => {
            // console.log('Uploaded', snapshot.totalBytes, 'bytes.');
            // console.log(snapshot.metadata);
            const url = snapshot.downloadURL;
            resolve(url);
            // console.log('File available at', url);
          }).catch((err) => {;
            reject(Error(err.message));
          });
      });
    },

    /**
     * ユーザに紐づく履歴情報を取得
     * @param {string} etherAccount 履歴を取得したいアカウント
     * @param {number} latestSortKey 最後のソートキーの値
     * @returns {object} ref
     */
    getUserTransactionsRef(etherAccount, latestSortKey){
      let ref = firebase.database()
        .ref(`accountActivities/${etherAccount}/txs`)
        .orderByChild("sortKey")
        .limitToFirst(5);
      // 次のデータを所得する場合
      if(latestSortKey){
        ref = ref.startAt(latestSortKey + 1)
      }
      return ref;
    },

    /**
     * カードに紐づく履歴情報を取得
     * @param {string} cardAddress 履歴を取得したいカードアドレス
     * @returns {object} ref
     */
    getCardTransactions(cardAddress, latestSortKey){
      let ref = firebase.database()
        .ref(`cardActivities/${cardAddress}/txs`)
        .orderByChild("sortKey")
        .limitToFirst(5);
      // 次のデータを所得する場合
      if(latestSortKey){
        ref = ref.startAt(latestSortKey + 1)
      }
      return ref;
    }
  }
};
