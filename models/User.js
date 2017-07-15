// const admin = require("firebase-admin");
// const serviceAccount = require("../serviceAccountKey.json");
// admin.initializeApp({
  // credential: admin.credential.cert(serviceAccount),
  // databaseURL: "https://td-demo-5c73d.firebaseio.com"
// });
// const defaultAuth = admin.auth();
// const database = admin.database();

class User {

  // Userを作成
  static create(userId, data) {
    console.log(userId, data);
    database.ref('users/' + userId).set(data);
    console.log('User created');
  }

  // Userを取得
  static get(id){
    console.log('User get', id);
    return new Promise((resolve, reject) => {
      database.ref('users/' + id).once('value')
        .then(function(snapshot) {
          const user = snapshot.val();
          resolve(user);
        });
    });
  }

  // アカウントがあるかどうか
  static has(id){
    return new Promise((resolve, reject) => {
      database.ref('users/' + id).once('value')
        .then(function(snapshot) {
          resolve(snapshot.exists());
        });
    });
  }

  // Etherアカウントがあるかどうか
  static hasEtherAccount(id){
    return new Promise((resolve, reject) => {
      database.ref('users/' + id).once('value')
        .then(function(snapshot) {
          resolve(snapshot.child('etherAccount').exists());
        });
    });
  }

  /**
   * Etherアカウントを登録
   * @static
   * @param {string} id ユーザID
   * @param {string} address Ethereumのアカウント
   * @param {string} fileName EthereumのKeyStoreファイル名
   */
  static setEtherAccount(id, address, fileName){
    return new Promise((resolve, reject) => {
      database.ref('users/' + id).update({
        etherAccount: address,
        etherKeyStoreFile: fileName
      });
    });
  }
}

module.exports = User;
