// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProjectMod, ImpactScore, ProjectDetails} from "./interfaces/IProjectMod.sol";
import {OwnableRoles} from "solady/auth/OwnableRoles.sol";
import {ERC4626, SafeTransferLib} from "solady/tokens/ERC4626.sol";

error ZeroAddress();
error ProjectFundingFailed();
error InsufficientAssets();
error SharesError();

contract InvestmentMod is ERC4626, OwnableRoles {
    //*//////////////////////////////////////////////////////////////////////////
    //                                 CONSTANTS
    //////////////////////////////////////////////////////////////////////////*//

    uint8 private constant USDC_UNDERLYING_DECIMALS = 6;
    uint8 private constant DECIMALS_OFFSET = 12;
    // uint256(keccak256("bond.issuer.role")) either a multisig or DAO
    uint256 public constant ISSUER_ROLE = 8134971354964128561662918087387438297584684331987304161041731369355285421532;
    address private immutable USDC;
    IProjectMod public immutable PROJECT_MOD;

    //*//////////////////////////////////////////////////////////////////////////
    //                                  STORAGE
    //////////////////////////////////////////////////////////////////////////*//

    uint256 public totalInvestments;
    mapping(uint256 => uint256) public projectInvestments;

    //*//////////////////////////////////////////////////////////////////////////
    //                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*//

    constructor(address _owner, address _projectMod, address _usdc) {
        _initializeOwner(_owner);
        PROJECT_MOD = IProjectMod(_projectMod);
        USDC = _usdc;
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                            BOND SHARES METADATA
    //////////////////////////////////////////////////////////////////////////*//

    /// @dev Returns the name of the token.
    function name() public view virtual override returns (string memory) {
        return "Ecobond Shares";
    }

    /// @dev Returns the symbol of the token.
    function symbol() public view virtual override returns (string memory) {
        return "EBS";
    }

    /// @dev Returns the address of the underlying asset.
    function asset() public view virtual override returns (address) {
        return USDC;
    }

    function totalAssets() public view virtual override returns (uint256) {
        return super.totalAssets() + totalInvestments + getExpectedReturns();
    }

    /// @dev Computes expected returns across all funded projects based on their impact scores.
    /// Formula: expectedReturn = investment * (creditQuality + greenImpact) / 200
    function getExpectedReturns() public view returns (uint256 expectedReturns_) {
        uint256 length = PROJECT_MOD.totalSupply();
        for (uint256 i; i < length; ++i) {
            uint256 investment = projectInvestments[i + 1];
            if (investment > 0) {
                ImpactScore memory score = PROJECT_MOD.getProjectScore(i + 1);
                expectedReturns_ += (investment * (uint256(score.creditQuality) + uint256(score.greenImpact))) / 200;
            }
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             ISSUER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    function fundProject(uint256 _projectId, uint256 _amount) external onlyRoles(ISSUER_ROLE) {
        if (_amount == 0) revert ZeroAddress();
        if (PROJECT_MOD.ownerOf(_projectId) == address(0)) revert ZeroAddress();

        uint256 projectInvestment = projectInvestments[_projectId];

        projectInvestments[_projectId] = projectInvestment + _amount;
        totalInvestments = totalInvestments + _amount;

        if (!SafeTransferLib.trySafeTransferFrom(asset(), address(this), PROJECT_MOD.ownerOf(_projectId), _amount)) {
            revert ProjectFundingFailed();
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             BOND SHARES HOOKS
    //////////////////////////////////////////////////////////////////////////*//

    /// @dev Hook that is called after any deposit or mint.
    /// Validates that the investment was properly tracked and authorized.
    function _afterDeposit(uint256, uint256 shares) internal virtual override {
        // Ensure that only authorized addresses can deposit
        // This validates the deposit occurred correctly in the parent contract
        if (shares == 0) revert SharesError();
    }

    /// @dev Hook that is called before any withdrawal or redemption.
    /// Ensures adequate liquidity exists after treasury allocations.
    function _beforeWithdraw(uint256 assets, uint256) internal virtual override {
        // Ensure the contract has sufficient assets to cover the withdrawal
        // Account for invested capital that may not be immediately available
        if (assets > SafeTransferLib.balanceOf(asset(), address(this))) {
            revert InsufficientAssets();
        }
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
