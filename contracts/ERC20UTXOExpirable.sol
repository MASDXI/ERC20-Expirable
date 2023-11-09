// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC20UTXO.sol";

// @TODO Eefactor logic not rely on block timestamp change to block number
// Reference:
// https://eips.ethereum.org/EIPS/eip-100
// https://blog.ethereum.org/2014/07/11/toward-a-12-second-block-time
// https://owasp.org/www-project-smart-contract-top-10/2023/en/src/SC03-timestamp-dependence.html

abstract contract ERC20UTXOExpirable is ERC20UTXO, Ownable {

    uint64 private immutable _period;

    constructor(uint64 period_) {
        _period = period_ ;
    }

    function mint(uint256 amount, TxOutput memory outputs) public onlyOwner { 
        _mint(amount, outputs, abi.encode(block.timestamp + _period));
    }

    function _beforeSpend(address spender, UTXO memory utxo) internal override {
        uint256 expireDate = abi.decode(utxo.data, (uint256));
        require(block.timestamp < expireDate,"UTXO has been expired");
        super._beforeCreate(spender, utxo);
    }
}