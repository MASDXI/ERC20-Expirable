// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

interface IERC20UTXO {

    struct UTXO {
        uint256 amount;
        address owner;
        bytes data;
        bool spent;
    }

    struct TxInput {
        uint256 id;
        bytes signature;
    }

    struct TxOutput {
        uint256 amount;
        address owner;
    }
    
    function utxo(uint256 id) external view returns (UTXO memory);

    function utxoLength() external view returns (uint256);

    // function listunspent(address account) external view returns (UTXO memory);

    function transfer(address account, uint256 amount, TxInput memory input) external returns (bool);

    // event Transfer(address indexed from, address indexed to, uint256 value);

    event TransactionCreated(uint256 indexed id, address indexed creator);

    event TransactionSpent(uint256 indexed id, address indexed spender);

    // event Approval(address indexed owner, address indexed spender, uint256 id, uint256 value);

}
