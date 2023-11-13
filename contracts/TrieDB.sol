// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

contract TrieDB {

    enum TRIE_STATUS { INACTIVE, ACTIVE }

    struct TrieNode {
        bytes32 origin;
        TRIE_STATUS status;
        Transaction[] txChange;
    }

    struct Transaction {
        uint256 amount;
        bytes32 extraData;
    }

    mapping(bytes32 => TrieNode) public _trie;
    mapping(address => uint256) public _trieCount;

    function _hash(address account, uint256 Id) public pure returns (bytes32) {
        return bytes32(abi.encode(keccak256(abi.encode(account, Id))));
    }

    function _modifyTrie(address account, uint256 amount, bytes32 origin, bytes32 data) internal {
        // require validation input
        bytes32 TrieHash = _hash(account, _trieCount[account]);
        TrieNode storage trie = _trie[TrieHash];

        if (trie.status == TRIE_STATUS.INACTIVE) {
            trie.origin = origin;
            trie.status = TRIE_STATUS.ACTIVE;
            _trieCount[account]++;
            _createOrUpdateTransaction(trie, data, amount);
        } else {
            Transaction storage lastTransaction = trie.txChange[trie.txChange.length - 1];
            _createOrUpdateTransaction(trie, data, lastTransaction.amount - amount);
        }
    }

    function _createOrUpdateTransaction(TrieNode storage trie, bytes32 data, uint256 newAmount) internal {
        if (newAmount != 0) {
            trie.txChange.push(Transaction(newAmount, data));
        } else {
            trie.txChange.push(Transaction(newAmount, data));
            trie.status = TRIE_STATUS.INACTIVE;
        }
    }

    function _create(address account, uint256 amount, bytes32 origin, bytes32 data) public {
        _modifyTrie(account, amount, origin, data);
    }

    function transfer(address account, uint256 amount) public {
        bytes32 TrieHash = _hash(msg.sender, _trieCount[msg.sender]);
        TrieNode storage trie = _trie[TrieHash];
        Transaction memory lastTransaction = trie.txChange.length > 0 ? trie.txChange[trie.txChange.length - 1] : Transaction(0, "");

        _modifyTrie(account, amount, trie.origin, "");
        _createOrUpdateTransaction(_trie[TrieHash], "", lastTransaction.amount - amount);
    }
    
    function _spend(address account, uint256 amount, uint256 id, bytes32 data) public {
        bytes32 TrieHashOrigin = _hash(msg.sender, id);
        TrieNode storage originTrie = _trie[TrieHashOrigin];
        Transaction storage lastTransaction = originTrie.txChange[originTrie.txChange.length - 1];

        _modifyTrie(account, amount, originTrie.origin, "");
        _createOrUpdateTransaction(_trie[_hash(msg.sender, id)], data, lastTransaction.amount - amount);
    }

    function getTrie(bytes32 TrieId) public view returns (TrieNode memory, Transaction memory) {
        TrieNode storage trieCache = _trie[TrieId];
        return (trieCache, trieCache.txChange[trieCache.txChange.length - 1]);
    }

    function getTx(bytes32 TrieId) public view returns (Transaction[] memory) {
        TrieNode storage trieCache = _trie[TrieId];
        return trieCache.txChange;
    }
}