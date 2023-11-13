// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IERC20UTXO.sol";

// @TODO doing it more plugin/extension style
// @TODO adding feature compatible with ERC20 standard
// Function
// function transfer(address _to, uint256 _value) public returns (bool success) [DONE_WITH_CONDITION]
// function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) [TODO]
// function approve(address _spender, uint256 _value) public returns (bool success) [TODO]
// function allowance(address _owner, address _spender) public view returns (uint256 remaining) [TODO]
// Event
// event Transfer(address indexed _from, address indexed _to, uint256 _value) [DONE]
// event Approval(address indexed _owner, address indexed _spender, uint256 _value) [DONE]
// event TransactionSpent(bytes32 indexed _id) [TODO]
// event TransactionCreated(bytes32 indexed _id) [TODO]

// Function
// transfer require utxo id and amount? security concern?
// transferFrom require utxo id and amount? security concern?
// approve require utxo and amount? security concern?

abstract contract ERC20UTXO is Context, ERC20, IERC20UTXO {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}


    function transfer(address account, uint256 value) public override returns (bool) {
        // TxOutput memory cacheTxOutput = TxOutput({amount: value, owner: account});
        // address creator = _msgSender();
        // _transfer(value, input, cacheTxOutput, creator);
        // return true;
        _transferSet(account,value,msg.sender);
        return true;
    }

    function _mint(address account, uint256 amount, bytes memory data) internal virtual {
        _mint(account, amount);
        _create(account, amount, bytes32(0), data);
    }

    mapping(bytes32 => TrieNode) public _trie;
    mapping(address => uint256) public _trieCount;

    function _hash(address account, uint256 Id) public pure returns (bytes32) {
        return bytes32(abi.encode(keccak256(abi.encode(account, Id))));
    }

    function _modifyTrie(address account, uint256 amount, bytes32 origin, bytes memory data) internal {
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

    function _createOrUpdateTransaction(TrieNode storage trie, bytes memory data, uint256 newAmount) internal {
        if (newAmount != 0) {
            trie.txChange.push(Transaction(newAmount, data));
        } else {
            trie.txChange.push(Transaction(newAmount, data));
            trie.status = TRIE_STATUS.INACTIVE;
        }
    }

    function _create(address account, uint256 amount, bytes32 origin, bytes memory data) public {
        _modifyTrie(account, amount, origin, data);
    }

    function _transferSet(address account, uint256 amount, address sender) internal {
        bytes32 trieHash = _hash(sender, _trieCount[sender] - 1);
        TrieNode storage currentTrie = _trie[trieHash];

        // Ensure the current trie is in an active state and has enough balance
        // require(currentTrie.status == TRIE_STATUS.ACTIVE, "Current trie is not active");
        // require(currentTrie.txChange.length > 0 && currentTrie.txChange[currentTrie.txChange.length - 1].amount >= amount, "Insufficient balance");

        // Calculate the remaining amount needed
        uint256 remainingAmount = amount;

        // Loop through tries until the remaining amount is satisfied
        // @TODO research implementing to loop through only active trie
        for (uint256 i = 0; i < _trieCount[sender] && remainingAmount > 0; i++) {
            // Load struct trie from storage
            TrieNode storage trie = _trie[_hash(sender, i)];

            Transaction memory lastTransaction = trie.txChange.length > 0 ? trie.txChange[trie.txChange.length - 1] : Transaction(0, "");
            // Check if the trie has enough balance
            if (lastTransaction.amount >= remainingAmount) {
                _beforeSpend(sender, account, lastTransaction);
                // If yes, modify the trie and exit the loop
                _modifyTrie(account, remainingAmount, trie.origin, lastTransaction.extraData);
                _createOrUpdateTransaction(trie, lastTransaction.extraData, lastTransaction.amount - remainingAmount);
                remainingAmount = 0;
                _afterSpend(sender, account, lastTransaction);
            } else {
                // If no, deduct the remaining balance from the trie and continue to the next trie
                _beforeSpend(sender, account, lastTransaction);
                _modifyTrie(account, lastTransaction.amount, trie.origin, lastTransaction.extraData);
                _createOrUpdateTransaction(trie, lastTransaction.extraData, 0);
                remainingAmount -= lastTransaction.amount;
                _afterSpend(sender, account, lastTransaction);
            }
        }
        _transfer(msg.sender, account, amount);
    }
    
    function _spend(address account, uint256 amount, uint256 id, bytes memory data) public {
        bytes32 TrieHashOrigin = _hash(msg.sender, id);
        TrieNode storage originTrie = _trie[TrieHashOrigin];
        Transaction storage lastTransaction = originTrie.txChange[originTrie.txChange.length - 1];

        _beforeSpend(msg.sender, account, lastTransaction);
        _modifyTrie(account, amount, originTrie.origin, bytes(""));
        _createOrUpdateTransaction(_trie[_hash(msg.sender, id)], data, lastTransaction.amount - amount);
        _afterSpend(msg.sender, account, lastTransaction);
    }

    function getTrie(bytes32 TrieId) public view returns (TrieNode memory, Transaction memory) {
        TrieNode storage trieCache = _trie[TrieId];
        return (trieCache, trieCache.txChange[trieCache.txChange.length - 1]);
    }

    function getTx(bytes32 TrieId) public view returns (Transaction[] memory) {
        TrieNode storage trieCache = _trie[TrieId];
        return trieCache.txChange;
    }

    function _beforeSpend(address spender, address account, Transaction memory transaction) internal virtual {}
    
    function _afterSpend(address spender, address account, Transaction memory transaction) internal virtual {}
}