// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OwnableRoles} from "solady/auth/OwnableRoles.sol";
import {ERC4626} from "solady/tokens/ERC4626.sol";

error ZeroAddress();

contract InvestmentMod is ERC4626, OwnableRoles {
    address private constant USDC = address(0x3600000000000000000000000000000000000000);
    uint8 private constant USDC_UNDERLYING_DECIMALS = 6;
    uint8 private constant DECIMALS_OFFSET = 12;
    uint256 private constant MIN_DURATION = 365 days;
    uint256 public constant ADMIN_ROLE = 1;
    uint256 public constant INVESTOR_ROLE = 2;

    //*//////////////////////////////////////////////////////////////////////////
    //                            BOND SHARES METADATA
    ///////////////////////////////////////////////////////////////////////////*/

    /// @dev Returns the name of the token.
    function name() public view virtual override returns (string memory) {
        return "Green Bond Shares";
    }

    /// @dev Returns the symbol of the token.
    function symbol() public view virtual override returns (string memory) {
        return "GBS";
    }

    /// @dev Returns the address of the underlying asset.
    function asset() public view virtual override returns (address) {
        return USDC;
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             BOND SHARES HOOKS
    //////////////////////////////////////////////////////////////////////////*//

    /// @dev Hook that is called before any withdrawal or redemption.
    function _beforeWithdraw(uint256, uint256) internal virtual override {
        if (block.timestamp < MIN_DURATION) revert();
    }

    /// @dev Hook that is called after any deposit or mint.
    function _afterDeposit(uint256 assets, uint256 shares) internal virtual override {}

    //*//////////////////////////////////////////////////////////////////////////
    //                                 OVERRIDES
    //////////////////////////////////////////////////////////////////////////*//

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        if (spender == address(0)) revert ZeroAddress();
        return super.approve(spender, amount);
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        if (to == address(0)) revert ZeroAddress();
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        if (from == address(0) || to == address(0)) revert ZeroAddress();
        return super.transferFrom(from, to, amount);
    }

    /// @dev Returns the number of decimals of the underlying asset.
    function _underlyingDecimals() internal view virtual override returns (uint8) {
        return USDC_UNDERLYING_DECIMALS;
    }

    /// @dev Returns the decimals offset.
    function _decimalsOffset() internal view virtual override returns (uint8) {
        return DECIMALS_OFFSET;
    }
}
