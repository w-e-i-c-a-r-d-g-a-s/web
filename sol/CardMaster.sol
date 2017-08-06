pragma solidity ^0.4.13;
import "./Card.sol";

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
    function addCard(bytes32 _name, uint _issued, bytes32 _imageHash) {
        Card c = new Card(_name, _issued, _imageHash, msg.sender);
        addressList.push(address(c));
        cards[address(c)] = c;
        // 履歴用にアドレスを返す
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

