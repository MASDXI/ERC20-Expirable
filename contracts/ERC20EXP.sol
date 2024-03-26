// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

/// @TODO refactor code to support custom period

contract ERC20UTXOExpirable {
    // Contract Constant Variables.
    uint8 constant MINIMUM_EXPIRE_PERIOD_SLOT = 1;
    uint8 constant MAXIMUM_EXPIRE_PERIOD_SLOT = 8;
    // uint8 constant SLOT_PER_ERA = 4;
    // uint32 constant YEAR_IN_SECOND = 31_556_926;

    // Contract Configuration Variables.
    uint8 private _expirePeriod;
    uint32 private _blockPerYear;

    mapping(address => mapping(uint256 => mapping(uint8 => uint256)))
        private _balances;

    constructor(uint32 blocks, uint8 period) {
        _updateBlockPerYear(blocks);
        _updateExpirePeriod(period);
    }

    // internal
    function _updateBlockPerYear(uint32 blocks) internal {
        _blockPerYear = blocks;
    }

    function _updateExpirePeriod(uint8 period) internal {
        _expirePeriod = period;
    }

    function _calculateEra(uint256 blockNumber) public view returns (uint256) {
        return blockNumber / _blockPerYear;
    }

    function _calculateSlot(uint256 blockNumber) public view returns (uint8) {
        return uint8((blockNumber % _blockPerYear) / (_blockPerYear / 4));
    }

    function _calculateEraCycleFromExpirePeriodSlot()
        public
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
                totalBalance += _balances[account][era][slot];
            }
        }
        return totalBalance;
    }

    function balanceOf(address account) public view returns (uint256) {
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

    function blockPerEra() public view returns (uint256) {
        return _blockPerYear;
    }

    function blockPerSlot() public view returns (uint256) {
        return _blockPerYear / 4;
    }

    function mint(address account, uint256 amount) public {
        require(account != address(0), "ERC20: mint to the zero address");
        require(amount > 0, "Amount must be greater than zero");
        // Mint tokens to the specified account
        _balances[account][_calculateEra(block.number)][
            _calculateSlot(block.number)
        ] += amount;
        // _totalSupply += amount;

        // emit Transfer(address(0), account, amount);
    }
}
