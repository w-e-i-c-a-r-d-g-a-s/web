## Requirements

* Node.js v8+

#### パッケージをインストール

`truffle`, `yarn`,`nodemon`が入ってない場合はインストール

```
npm install -g nodemon yarn truffle
```

## Ethereum RPCの起動

#### RPCをgethで実行する場合

```
$ geth --port 30001 --networkid "3981" \
  --rpc --rpcaddr localhost --rpcport 8545 --rpccorsdomain "*" --rpcapi eth,web3,personal \
  --datadir . console
```

のようなコマンドで、gethを起動する

## Installation

submoduleを追加・更新

```
$ git submodule update -i
```


### パッケージをインストール

```
$ yarn install
```

### 設定ファイルを配置

必要なファイルを
https://drive.google.com/drive/folders/0B-k36n5IvAUKNTlLb3RQZ09XNVk
からダウンロードし、配置します。

* firebase.config.js → /front/scripts/ 直下
* etherSetting.json → プロジェクトのルート
* serviceAccountKey.json → プロジェクトのルート

etherSetteingの中身はgethの設定により適宜書き換えるようにしてください。

### solidityのコンパイル実行

```
$ cd contracts
$ truffle compile
```

`./contracts/build/contracts`にコンパイルされたsolidityファイルが生成される

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

## Production

ディレクトリ構成

* `~/td-demo/` アプリの本体
* `~/ethereum-td/` gethのディレクトリ

pullし、solc・フロントエンドをビルドする

```
$ cd td-demo
$ git pull
$ yarn install
$ npm run solc
$ npm run build
```

`public`にjs, cssが作成されます。


#### gethの起動

```
vim ~/geth.sh

sh ~/geth.sh
```

```
$ NODE_ENV=production pm2 start td-demo/bin/www
# 8080ポートになる
# リスタートしたい場合は
$ pm2 restart www
```
で本番サーバを立てます。


監視アプリ(β）の起動

```
NODE_ENV=production pm2 start guard.js
```


