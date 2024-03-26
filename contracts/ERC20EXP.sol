// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

/// @TODO refactor code to support custom period.
// _mint that inherit from @openzeppelin/contracts SHOULD NOT BE USE.
// _burn that inherit from @openzeppelin/contracts SHOULD NOT BE USE.

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./TrieDB.sol";

abstract contract ERC20Expirable is ERC20, TrieDB, {
    // contract constant variables.
    uint8 constant MINIMUM_EXPIRE_PERIOD_SLOT = 1;
    uint8 constant MAXIMUM_EXPIRE_PERIOD_SLOT = 8;
    // uint8 constant SLOT_PER_ERA = 4;
    // uint32 constant YEAR_IN_SECOND = 31_556_926;

    // contract configuration variables.
    uint8 private _expirePeriod;
    uint32 private _blockPerYear;

    /// @TODO change to trieDB to store tire node.
    // each ERA contain 'n' SLOT 
    // each SLOT can contain trie node inside
    mapping(address => mapping(uint256 => mapping(uint8 => uint256)))
        private _balances;

    constructor(uint32 blocks, uint8 period) {
        _updateBlockPerYear(blocks);
        _updateExpirePeriod(period);
    }

    // private function
    function _updateBlockPerYear(uint32 blocks) private {
        // @TODO require check
        uint256 _blockPerYearCache = _blockPerYear;
        _blockPerYear = blocks;
        emit BlockProducedPerYearUpdated(uint256 _blockPerYearCache, uint256 blocks);
    }

    function _updateExpirePeriod(uint8 period) private {
        // @TODO require check
        uint8 _expirePeriodCache = _expirePeriod;
        _expirePeriod = period;
        emit TokenExpiryPeriodUpdated(uint8 _periodCache, uint8 period);
    }

    // internal function
    function _calculateEra(uint256 blockNumber) public virtual view returns (uint256) {
        return blockNumber / _blockPerYear;
    }

    function _calculateSlot(uint256 blockNumber) public virtual view returns (uint8) {
        return uint8((blockNumber % _blockPerYear) / (_blockPerYear / 4));
    }

    function _calculateEraCycleFromExpirePeriodSlot()
        public
        virtual
        view
        returns (uint8)
    {
        if (_expirePeriod < 4) {
            return 1;
        }
        uint8 eraCycle = _expirePeriod / 4;
        if (_expirePeriod % 4 > 0) {
            eraCycle++;
        }
        return eraCycle;
    }

    function _lookBack(
        address account,
        uint256 fromEra,
        uint8 fromSlot,
        uint256 toEra,
        uint8 toSlot
    ) public view returns (uint256) {
        uint256 totalBalance = 0;
        for (uint256 era = fromEra; era <= toEra; era++) {
            uint8 startSlot = (era == fromEra) ? fromSlot : 0;
            uint8 endSlot = (era == toEra) ? toSlot : 3;
            for (uint8 slot = startSlot; slot <= endSlot; slot++) {
                // @TODO sumarize only available balance
                totalBalance += _balances[account][era][slot];
            }
        }
        return totalBalance;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        require(amount > 0, "Amount must be greater than zero");
        _balances[account][_calculateEra(block.number)][
            _calculateSlot(block.number)
        ] += amount;
        // @TODO built-in encode data to trieDB
        // _create(account, amount, null /*origin*/, null /*data*/);
        emit Transfer(address(0), account, amount);
    }

    // public function
    function balanceOf(address account) public override view returns (uint256) {
        uint256 blockNumber = block.number;
        uint256 era = _calculateEra(blockNumber);
        uint8 slot = _calculateSlot(blockNumber);
        uint256 fromEra = (era != 0)
            ? (era - _calculateEraCycleFromExpirePeriodSlot())
            : 0;
        uint8 fromSlot = (slot < _expirePeriod)
            ? (4 - _expirePeriod + slot) % 4
            : (slot == 0)
                ? 0
                : slot - (slot % 4);
        return _lookBack(account, fromEra, fromSlot, era, slot);
    }

    function transfer(address account, uint256 amount) public virtual override returns (bool) {
        // @TODO research
        // Datetime need to be built-in
        // beforetransfer hook function style conditioned transfer.
        // aftertransfer hook function style conditioned transfer.
        // create trie when transfer how to know the trie id?
    }

    function blockPerEra() public override view returns (uint256) {
        return _blockPerYear;
    }

    function blockPerSlot() public override view returns (uint256) {
        return _blockPerYear / 4;
    }
}
