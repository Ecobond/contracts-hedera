// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OwnableRoles} from "solady/auth/OwnableRoles.sol";
import {ERC4626} from "solady/tokens/ERC4626.sol";

error ZeroAddress();

contract InvestmentMod is ERC4626, OwnableRoles {
    //*//////////////////////////////////////////////////////////////////////////
    //                                 CONSTANTS
    //////////////////////////////////////////////////////////////////////////*//

    address private constant USDC = address(0x3600000000000000000000000000000000000000);
    uint8 private constant USDC_UNDERLYING_DECIMALS = 6;
    uint8 private constant DECIMALS_OFFSET = 12;
    uint256 private constant MIN_DURATION = 365 days;
    // uint256(keccak256("bond.admin.role"))
    uint256 public constant ADMIN_ROLE = 5990507170922064599851912174407407848819374031555223498714203695820960965153;
    // uint256(keccak256("bond.investor.role"))
    uint256 public constant INVESTOR_ROLE =
        100072418519682715403571630713264651455801416692533675711340257043684521151149;

    //*//////////////////////////////////////////////////////////////////////////
    //                                  STORAGE
    //////////////////////////////////////////////////////////////////////////*//

    //*//////////////////////////////////////////////////////////////////////////
    //                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*//

    constructor(address _owner) {
        _initializeOwner(_owner);
    }

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

    function totalAssets() public view virtual override returns (uint256) {
        return super.totalAssets();
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                              OWNER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    //*//////////////////////////////////////////////////////////////////////////
    //                              ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    //*//////////////////////////////////////////////////////////////////////////
    //                             INVESTOR FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    //*//////////////////////////////////////////////////////////////////////////
    //                             BOND SHARES HOOKS
    //////////////////////////////////////////////////////////////////////////*//

    /// @dev Hook that is called before any withdrawal or redemption.
    function _beforeWithdraw(uint256, uint256) internal virtual override {
        // TODO: implement
    }

    /// @dev Hook that is called after any deposit or mint.
    function _afterDeposit(uint256, uint256) internal virtual override {
        // TODO: implement
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                                 OVERRIDES
    //////////////////////////////////////////////////////////////////////////*//

    function approve(address _spender, uint256 _amount) public virtual override returns (bool) {
        if (_spender == address(0)) revert ZeroAddress();
        return super.approve(_spender, _amount);
    }

    function transfer(address _to, uint256 _amount) public virtual override returns (bool) {
        if (_to == address(0)) revert ZeroAddress();
        return super.transfer(_to, _amount);
    }

    function transferFrom(address _from, address _to, uint256 _amount) public virtual override returns (bool) {
        if (_from == address(0) || _to == address(0)) revert ZeroAddress();
        return super.transferFrom(_from, _to, _amount);
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
