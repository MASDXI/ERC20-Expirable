// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "./ERC20UTXOExpirable.sol";

contract UTXOToken is ERC20UTXOExpirable {

    constructor() 
        ERC20UTXO("ExpireToken","EXPT") 
        ERC20UTXOExpirable(4, 15) { 
    }
}