// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

contract OrbsDB {
    enum ORBS_STATUS { INACTIVE, ACTIVE }

    struct Orbs {
        bytes32 origin;
        ORBS_STATUS status;
        uint256 balance;
        bytes extraData;
    }
    
    mapping(bytes32 => Orbs) public  _orbs;
    mapping(address => uint256) private _orbsCount;

    function _hash(address account, uint256 Id) public pure returns (bytes32 hash) {
        assembly {
            let data := mload(0x40)
            mstore(add(data, 0x20), account)
            mstore(add(data, 0x40), Id)
            hash := keccak256(add(data, 0x20), 0x40)
        }
    }

    function _getLatestOrbs(address account) private view returns (Orbs storage) {
        uint256 val = _orbsCount[account];
        return _orbs[_hash(account,val)];
    }

    function test(address account) public view returns (Orbs memory orbs) {
        orbs = _getLatestOrbs(account);
        return orbs;
    }

    function _modifyOrbs(address account, uint256 amount, bytes32 origin, bytes memory data) public {
        Orbs storage orbs = _getLatestOrbs(account);
        if (orbs.status == ORBS_STATUS.INACTIVE) {
            orbs.origin = origin;
            orbs.status = ORBS_STATUS.ACTIVE;
            orbs.extraData = data;
            _orbsCount[account]++;
            _updateOrbs(orbs, amount);
        } else {
            _updateOrbs(orbs, orbs.balance - amount);
        }
    }

    function _updateOrbs(Orbs storage orbs, uint256 newAmount) internal {
        if (newAmount != 0) {
            orbs.balance = newAmount;
        } else {
            orbs.balance = 0;
            orbs.status = ORBS_STATUS.INACTIVE;
        }
    }

    function _create(address account, uint256 amount, bytes32 origin, bytes memory data) public {
        _modifyOrbs(account, amount, origin, data);
    }

    function transfer(address account, uint256 amount) public {
        uint256 remainingAmount = amount;
        for (uint256 i = 0; i < _orbsCount[msg.sender] && remainingAmount > 0; i++) {
            // Load struct trie from storage
            Orbs storage tempOrbs = _orbs[_hash(msg.sender, i)];
            // Ensure the trie is in an active state before proceeding
            if (tempOrbs.status == ORBS_STATUS.ACTIVE) {
            uint256 balance = tempOrbs.balance > 0 ? tempOrbs.balance  : 0;
            // Check if the trie has enough balance
                if (balance >= remainingAmount) {
                    // If yes, modify the trie and exit the loop
                    _modifyOrbs(account, remainingAmount, tempOrbs.origin, "");
                    _updateOrbs(tempOrbs, balance - remainingAmount);
                    remainingAmount = 0;
                } else {
                    // If no, deduct the remaining balance from the trie and continue to the next trie
                    _modifyOrbs(account, balance, tempOrbs.origin, "");
                    _updateOrbs(tempOrbs, 0);
                    remainingAmount -= balance;
                }
            }
        }
    }
}