
## install

### Ethereum RPCの起動

#### a. RPCをgethで実行する場合

```
$ geth --port 30001 --networkid "3981" \
  --rpc --rpcaddr localhost --rpcport 8545 --rpccorsdomain "*" --rpcapi eth,web3,personal \
  --datadir . console
```

のようなコマンドで、gethを起動する

#### b. RPCをtestrpcで実行する場合

<!--
[eth-testrpc](https://github.com/pipermerriam/eth-testrpc) をpipでインストール
(pythonは2, 3どっちでも良さそう)

```sh
$ pip install eth-testrpc
```

うまくいかない場合はこっちを試す

```sh
sudo -H pip install eth-testrpc
```



`command not found: testrpc`といわれる場合は
-->

[ethereumjs-testrpc](https://github.com/ethereumjs/testrpc)をインストールします。

```
$ npm uninstall -g ethereumjs-testrpc
$ npm install -g ethereumjs-testrpc
```

インストールができたら`testrpc`で起動する。

```sh
$ testrpc
```

（一度接続した後の止め方が分からない・・・）

---

### パッケージをインストール

`yarn`,`nodemon`が入ってない場合はインストール

```
npm install -g nodemon yarn
```

インストールを実行

```
$ yarn install
```

## 設定ファイルを配置

必要なファイルを
https://drive.google.com/drive/folders/0B-k36n5IvAUKNTlLb3RQZ09XNVk
からダウンロードし、配置します。

* firebase.config.js → /front/scripts/ 直下
* etherSetting.json → プロジェクトのルート
* serviceAccountKey.json → プロジェクトのルート

etherSetteingの中身はgethの設定により適宜書き換えるようにしてください。

## solc実行
```
$ npm run solc
```

## Development

フロント側のビルドシステムを起動

```
$ npm run front
```

（別のターミナルウィンドウで）  
サーバ側のビルドシステムを起動

```
$ DEBUG=td:* nodemon bin/www
```

`localhost:3000`にアクセスします。
