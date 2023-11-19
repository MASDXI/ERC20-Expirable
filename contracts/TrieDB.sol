// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

contract TrieDBV2 {
    enum TRIE_STATUS { INACTIVE, ACTIVE }

    struct TrieNode {
        bytes32 origin;
        TRIE_STATUS status;
        uint256 balance;
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
            uint256 lastTransaction = trie.balance;
            _createOrUpdateTransaction(trie, data, lastTransaction - amount);
        }
    }

    function _createOrUpdateTransaction(TrieNode storage trie, bytes32 data, uint256 newAmount) internal {
        if (newAmount != 0) {
            trie.balance = newAmount;
        } else {
            trie.balance = 0;
            trie.status = TRIE_STATUS.INACTIVE;
        }
    }

    function _create(address account, uint256 amount, bytes32 origin, bytes32 data) public {
        _modifyTrie(account, amount, origin, data);
    }

    function transfer(address account, uint256 amount) public {
        bytes32 trieHash = _hash(msg.sender, _trieCount[msg.sender] - 1);
        TrieNode storage currentTrie = _trie[trieHash];

        // Ensure the current trie is in an active state and has enough balance
        require(currentTrie.status == TRIE_STATUS.ACTIVE, "Current trie is not active");
        require(currentTrie.balance > 0 && currentTrie.balance >= amount, "Insufficient balance");

        // Calculate the remaining amount needed
        uint256 remainingAmount = amount;

        // Loop through tries until the remaining amount is satisfied
        // @TODO research implementing to loop through only active trie
        for (uint256 i = 0; i < _trieCount[msg.sender] && remainingAmount > 0; i++) {
            // Load struct trie from storage
            TrieNode storage trie = _trie[_hash(msg.sender, i)];

            // Ensure the trie is in an active state before proceeding
            require(trie.status == TRIE_STATUS.ACTIVE, "Trie is not active");

            uint256 lastTransaction = trie.balance > 0 ? trie.balance  : 0;
            // Check if the trie has enough balance
            if (lastTransaction >= remainingAmount) {
                // If yes, modify the trie and exit the loop
                _modifyTrie(account, remainingAmount, trie.origin, "");
                _createOrUpdateTransaction(trie, "", lastTransaction - remainingAmount);
                remainingAmount = 0;
            } else {
                // If no, deduct the remaining balance from the trie and continue to the next trie
                _modifyTrie(account, lastTransaction, trie.origin, "");
                _createOrUpdateTransaction(trie, "", 0);
                remainingAmount -= lastTransaction;
            }
        }
    }
    
    function _spend(address account, uint256 amount, uint256 id, bytes32 data) public {
        bytes32 TrieHashOrigin = _hash(msg.sender, id);
        TrieNode storage originTrie = _trie[TrieHashOrigin];

        uint256 lastTransaction = originTrie.balance;

        _modifyTrie(account, amount, originTrie.origin, "");
        _createOrUpdateTransaction(_trie[_hash(msg.sender, id)], data, lastTransaction - amount);
    }

    function getTrie(bytes32 TrieId) public view returns (TrieNode memory) {
        TrieNode storage trieCache = _trie[TrieId];
        return (trieCache);
    }
}