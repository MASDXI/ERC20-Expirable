// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC20UTXO.sol";

// @TODO Refactor logic not rely on block timestamp change to block number
// Reference:
// https://eips.ethereum.org/EIPS/eip-100
// https://blog.ethereum.org/2014/07/11/toward-a-12-second-block-time
// https://owasp.org/www-project-smart-contract-top-10/2023/en/src/SC03-timestamp-dependence.html

abstract contract ERC20UTXOExpirable is ERC20UTXO, Ownable {
    // contract rule.
    uint8 constant MINIMUM_EXPIRE_PERIOD_SLOT = 1;
    uint8 constant MAXIMUM_EXPIRE_PERIOD_SLOT = 8;
    uint32 constant YEAR_IN_SECOND = 31_556_926;
    enum SLOT { ZERO, ONE, TWO, TREE, FOUR }

    // contract configuration.
    uint8 private _expirePeriodSlot;
    uint32 private _blockProducePerYear;

    // _balance[address][era][slot] should return uint256 balance
    // mapping(address => mapping(uint8 => mapping(uint8 => [] Trie))) private _balances;
    // mapping(address => mapping(uint8 => mapping(uint8 => uint256))) private _balances;

    constructor(uint64 period_, uint256 _blockPriod) {
        _updateExpirePeriodSlot(period_);
        _blockProducePerYear = YEAR_IN_SECOND / _blockPriod ;
    }

    function _updateExpirePeriodSlot(int8 expirePeriodSlot) private {
        require(
          expirePeriodSlot >= MINIMUM_EXPIRE_PERIOD_SLOT &&
          expirePeriodSlot <= MAXIMUM_EXPIRE_PERIOD_SLOT,
          "Invalid expire period slot");
        _expirePeriodSlot = expirePeriodSlot;
        // emit ExpirePeriodSlotUpdated();
    }

    function _calculateEra(uint256 blockNumber) internal view returns (uint256) {
        if (blockNumber >= _blockProducePerYear) {
            return blockNumber / _blockProducePerYear;
        } else {
            return 0;
        }
    }

    function _calculateSlot(uint256 blockNumber) internal view returns (uint8) {
        uint256 _block = blockPerEra();
        if (_block != 0) {
            if (blockNumber % _block) return uint8(SLOT.ONE) ;
            if (blockNumber % (_block * 2) == 0) return uint8(SLOT.TWO);
            if (blockNumber % (_block * 3) == 0) return uint8(SLOT.THREE);
            if (blockNumber % (_block * 4) == 0) return uint8(SLOT.FOUR);
        } else {
            return uint8(SLOT.ZERO);
        }
    }

    function _lookBackBalanceOf(
      address account,
      uint8 fromEra, 
      uint8 toSlot, 
      uint256 toEra, 
      uint256 toSlot) internal view returns (uint256) {
        uint256 _availableBalancesCache;
        /// @TODO handle fromSlot less than toSlot.
        return _availableBalancesCache;
    }

    function _beforeSpend(
      address spender, 
      address account, 
      Transaction memory transaction) internal override {
        uint256 expireBlock = abi.decode(transaction.extraData, (uint256));
        require(block.blockNumber < expireBlock,"UTXO has been expired");
        // super._beforeCreate(spender, utxo);
    }

    function balanceOf(address account) public view override returns (uint256) {
        uint256 _blockNumberCache = block.number;
        uint256 _eraCache = _calculateEra(_blockNumberCache); // current era.
        uint8 _slotCache = _calculateSlot(_blockNumberCache); // current slot.
        if (_expirePeriodSlot > 1) {
            uint256 fromEra;
            uint8 fromSlot;
            /// @TODO calcuate diff era and diff slot.
            return lookBackBalanceOf(account, fromEra, fromSlot, _eraCache, _slotCache);
        } else {
            return lookBackBalanceOf(account, _eraCache, _slotCache, _eraCache, _slotCache);
        }
    }

    function mint(address account, uint256 amount) public onlyOwner {
        uint256 _block = blockPerSlot() * _expirePeriodSlot;
        _mint(account, amount, abi.encode(block.number + _block));
    }

    function blockPerEra() public view returns (uint256) {
        return blockProducePerYear_;
    }

    function blockPerSlot() public view returns (uint256) {
        return  _blockProducePerYear / 4 ;
    }
}