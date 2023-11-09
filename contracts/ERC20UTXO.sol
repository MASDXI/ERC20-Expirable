// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IERC20UTXO.sol";

/// @TODO doing it more plugin/extension style
/// @TODO adding feature compatible with ERC20 standard
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

/// @NOTE 
// Function
// transfer require utxo id and amount? security concern?
// transferFrom require utxo id and amount? security concern?
// approve require utxo and amount? security concern?

abstract contract ERC20UTXO is Context, ERC20, IERC20UTXO {
    using ECDSA for bytes32;
    
    UTXO[] private _utxos;

    function utxoLength() public override view returns (uint256) {
        return _utxos.length;
    }

    function utxo(uint256 id) public override view returns (UTXO memory) {
        require(id < _utxos.length, "ERC20UTXO: id out of bound");
        return _utxos[id];
    }

    function transfer(uint256 amount, TxInput memory input, TxOutput memory output) public returns (bool) {
        address creator = _msgSender();
        _transfer(amount, input, output, creator);
        return true;
        emit Transfer(creator, output.owner, amount);
    }

    function _transfer(uint256 amount, TxInput memory input, TxOutput memory output, address creator) internal virtual {
        UTXO storage cache = _utxos[input.id];
        require(output.amount <= cache.amount, "ERC20UTXO: transfer amount exceeds utxo amount");
        if (output.amount < cache.amount) {
            uint256 value = cache.amount - output.amount;
            _spend(input, creator);
            unchecked {
                _balances[creator] -= value;   
                _balances[output.owner] += amount;
            }
            _create(output, creator, cache.data);
            _create(TxOutput(value, creator), creator, cache.data);
        } else {
            _spend(input,creator);
            unchecked {
                _balances[creator] -= amount;   
                _balances[output.owner] += amount;
            }
            _create(output, creator, cache.data);
        }
    }

    function _mint(uint256 amount, TxOutput memory output, bytes memory data) internal virtual {
        require(output.amount == amount, "ERC20UTXO: invalid amounts");
        _mint(output.owner, output.amount);
        _create(output, address(0), data);
    }
    
    function _create(TxOutput memory output, address creator, bytes memory data) internal virtual {
        require(output.owner != address(0),"ERC20UTXO: create utxo output to zero address");
        uint256 id = utxoLength()+1;
        UTXO memory utxo = UTXO(output.amount, output.owner, data, false);
        
        _beforeCreate(output.owner,utxo);

        _utxos.push(utxo);
        emit UTXOCreated(id, creator);

        _afterCreate(output.owner,utxo);
    }

    function _spend(TxInput memory inputs, address spender) internal virtual {
        require(inputs.id < _utxos.length, "ERC20UTXO: utxo id out of bound");
        UTXO memory utxo = _utxos[inputs.id];
        require(!utxo.spent, "ERC20UTXO: utxo has been spent");

        _beforeSpend(utxo.owner,utxo);

        require(
            utxo.owner == keccak256(abi.encodePacked(inputs.id))
                          .toEthSignedMessageHash()
                          .recover(inputs.signature),
                          "ERC20UTXO: invalid signature");
        _utxos[inputs.id].spent = true;
        emit UTXOSpent(inputs.id, spender);

        _afterSpend(utxo.owner,utxo);
    }

    function _beforeCreate(address creator, UTXO memory utxo) internal virtual {}

    function _afterCreate(address creator, UTXO memory utxo) internal virtual {}

    function _beforeSpend(address spender, UTXO memory utxo) internal virtual {}

    function _afterSpend(address spender, UTXO memory utxo) internal virtual {}
    
}