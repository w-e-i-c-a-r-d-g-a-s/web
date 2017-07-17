pragma solidity ^0.4.11;

// カードマスター
contract CardMaster {
    // CardのContractのリスト
    mapping(address => Card) private cards;
    // アドレスを管理する配列
    address[] private addressList;

    event Debug(address c);

    /**
     * CardのContractを配列とマップに追加
     */
    function addCard(bytes32 _name, uint _issued) {
        Card c = new Card(_name, _issued, msg.sender);
        addressList.push(address(c));
        cards[address(c)] = c;
        Debug(address(c));
    }

    /**
     * カードのアドレスの配列取得
     */
    function getCardAddressList() constant returns (address[] cardAddressList) {
        cardAddressList = addressList;
    }

    /**
     * カードを取得
     */
    function getCard(address cardAddress) constant returns (Card) {
        Card c = cards[cardAddress];
        return c;
    }
}

contract Card {
    // カード属性など
    bytes32 public name;
    address public author;
    uint public issued;

    // 誰が何枚持っているか
    mapping(address => uint) public owns;
    // [Tips]動的配列はpublicで参照できない
    address[] private addressList;

    event Debug(string);
    event Debug_i(uint);
    event Debug(address c);

    function Card(bytes32 _name, uint _issued, address _author){
        name = _name;
        // author = msg.sender; // カードのコントラクトになってしまう
        author = _author;
        issued = _issued;
        addressList.push(author);
        owns[author] = issued;
    }

    /**
    * ownerのアドレスの配列取得
    */
    function getOwnerList() constant returns (address[] ownerAddressList) {
        ownerAddressList = addressList;
    }

    // 売る
    struct SellInfo {
        address from;
        uint quantity;
        uint price; // weiで指定
        bool active;
    }
    SellInfo[] public sellInfos;

    // Sellデータを作成
    function sellOrder(uint quantity, uint price){
        sellInfos.push(SellInfo(msg.sender, quantity, price, true));
    }

    // SellInfosの数を変える
    function sellInfosLength() constant returns (uint){
        return sellInfos.length;
    }

    // 買う
    function buy(uint idx) payable {

        SellInfo s = sellInfos[idx];
        Debug_i(s.quantity);
        Debug_i(s.price);
        Debug_i(msg.value); // wei

        if(msg.value != s.quantity * s.price){
            throw;
        }

        if(!s.active){
            throw;
        }


        address from = s.from;
        address to = msg.sender;
        uint quantity = s.quantity;
        // uint price = s.price;

        bool alreadyOwner = isAlreadyOwner(to);

        if(!alreadyOwner){
            // 初オーナー
            addressList.push(to);
        }
        owns[from] -= quantity;
        owns[to] += quantity;
        s.active = false;
        s.from.transfer(this.balance);
    }

    function isAlreadyOwner(address addr) returns (bool){
        bool isAlready = false;
        // 既にオーナーかどうか（もっといい方法ないかな？）
        for(uint i; i < addressList.length; i++){
            if(addressList[i] == addr){
                isAlready = true;
            }
        }
        return isAlready;
    }

    /**
    * 買い注文リスト
    */
    BuyOrder[] public buyOrders;

    /**
    *  買い注文リストの要素数を返す
    */
    function getBuyOrdersCount() constant returns (uint){
        return buyOrders.length;
    }

    /**
    * 買い注文作成
    */
    function createBuyOrder(uint16 _quantity, uint _etherPrice) payable {
        //TODO:本番ではetherではなくweiを引数に渡す
        uint weiPrice = _etherPrice * 1 ether;
        require(msg.value == _quantity * weiPrice);
        BuyOrder buyOrder = new BuyOrder(msg.sender, _quantity, weiPrice);
        buyOrder.transfer(msg.value);
        buyOrders.push(buyOrder);
    }

    /**
    * 買い注文に対して売る.
    */
    function sell(uint idx, uint16 quantity) payable {
        address seller = msg.sender;
        address buyer = buyOrders[idx].buyer();
        require(owns[seller] >= quantity);
        buyOrders[idx].sell(seller, quantity);
        owns[seller] = owns[seller] - quantity;
        owns[buyer] = owns[buyer] + quantity;
        bool alreadyOwner = isAlreadyOwner(buyer);
        if(!alreadyOwner){
            // 初オーナー
            addressList.push(buyer);
        }
    }
}

/**
 * 買い注文のContract
 */
contract BuyOrder {
    address public buyer;
    uint public value;
    uint16 public quantity;
    uint public price; // weiで指定

    bool public ended;

    event Debug_i(uint);

    function BuyOrder(address _buyer, uint16 _quantity, uint _price) payable {
        buyer = _buyer;
        quantity = _quantity;
        price = _price;
        value = quantity * price;
    }

    /**
    * 販売.
    */
    function sell(address seller, uint16 _quantity) payable {
        require(!ended);
        //提示カード枚数以下
        require(quantity >= _quantity);
        //送付
        seller.transfer(price * _quantity);
        value = value - price * _quantity;
        quantity -= _quantity;

        //TODO:綺麗に割り切れない場合の救済
        if(value == 0){
            ended = true;
        }
    }

    /**
    * オークション終了.
    * 作成者のみ終了可能.
        */
    function close() {
        require(msg.sender == buyer);
        buyer.transfer(value);
        ended = true;
    }

    /**
    * Fallback Function
    */
    function () payable { }
}

// 履歴
contract History {

    address from;
    address to;
    address card;
    uint32 price;
    uint16 quantity;

    function History(
        address _from,
        address _to,
        address _card,
        uint32 _price,
        uint16 _quantity
    ){
        from = _from;
        to = _to;
        card = _card;
        price = _price;
        quantity = _quantity;
    }

}

contract UserMaster {
    mapping (address => User) users;
    function add(){
        User u = new User();
        users[address(u)] = u;
    }
}

// ユーザ
contract User {
    address[] public ownedCard;
    address[] public activity;
    function User(){
    }
}
