// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProjectMod, ImpactScore, ProjectDetails} from "./interfaces/IProjectMod.sol";
import {OwnableRoles} from "solady/auth/OwnableRoles.sol";
import {ERC4626, SafeTransferLib} from "solady/tokens/ERC4626.sol";

/// @notice Thrown when a zero address is provided where a valid address is required.
error ZeroAddress();
/// @notice Thrown when the USDC transfer to the project owner fails during funding.
error ProjectFundingFailed();
/// @notice Thrown when a withdrawal is attempted but the contract lacks sufficient liquid assets.
error InsufficientAssets();
/// @notice Thrown when a deposit results in zero shares being minted.
error SharesError();

/// @title InvestmentMod
/// @notice ERC4626 tokenized vault for Ecobond investments, backed by USDC.
/// @dev Investors deposit USDC and receive vault shares. The issuer (multisig/DAO) can fund
///      approved projects from the vault's USDC reserves. Total assets includes the USDC balance,
///      cumulative investments, and expected returns derived from project impact scores.
contract InvestmentMod is ERC4626, OwnableRoles {
    //*//////////////////////////////////////////////////////////////////////////
    //                                 CONSTANTS
    //////////////////////////////////////////////////////////////////////////*//

    /// @notice The number of decimals of the underlying USDC token.
    uint8 private constant USDC_UNDERLYING_DECIMALS = 6;

    /// @notice The decimals offset between vault shares and the underlying asset.
    uint8 private constant DECIMALS_OFFSET = 12;

    /// @notice The role identifier for the issuer (multisig or DAO).
    /// @dev Computed as uint256(keccak256("bond.issuer.role")).
    uint256 public constant ISSUER_ROLE = 8134971354964128561662918087387438297584684331987304161041731369355285421532;

    /// @notice The address of the USDC token used as the vault's underlying asset.
    address private immutable USDC;

    /// @notice The ProjectMod contract used for querying project data.
    IProjectMod public immutable PROJECT_MOD;

    //*//////////////////////////////////////////////////////////////////////////
    //                                  STORAGE
    //////////////////////////////////////////////////////////////////////////*//

    /// @notice The cumulative amount of USDC invested across all projects.
    uint256 public totalInvestments;

    /// @notice The amount of USDC invested into each project, keyed by project ID.
    mapping(uint256 => uint256) public projectInvestments;

    //*//////////////////////////////////////////////////////////////////////////
    //                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*//

    /// @notice Deploys the InvestmentMod vault.
    /// @param _owner The address that will be set as the contract owner (can grant roles).
    /// @param _projectMod The address of the ProjectMod contract.
    /// @param _usdc The address of the USDC token.
    constructor(address _owner, address _projectMod, address _usdc) {
        _initializeOwner(_owner);
        PROJECT_MOD = IProjectMod(_projectMod);
        USDC = _usdc;
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                            BOND SHARES METADATA
    //////////////////////////////////////////////////////////////////////////*//

    /// @notice Returns the name of the vault token.
    /// @return The string "Ecobond Shares".
    function name() public view virtual override returns (string memory) {
        return "Ecobond Shares";
    }

    /// @notice Returns the symbol of the vault token.
    /// @return The string "EBS".
    function symbol() public view virtual override returns (string memory) {
        return "EBS";
    }

    /// @notice Returns the address of the underlying asset (USDC).
    /// @return The USDC token address.
    function asset() public view virtual override returns (address) {
        return USDC;
    }

    /// @notice Returns the total assets managed by the vault.
    /// @dev Accounts for the USDC balance held, cumulative project investments,
    ///      and expected returns derived from project impact scores.
    /// @return The total asset value in USDC terms.
    function totalAssets() public view virtual override returns (uint256) {
        return super.totalAssets() + totalInvestments + getExpectedReturns();
    }

    /// @notice Computes expected returns across all funded projects based on their impact scores.
    /// @dev For each project with a non-zero investment, the expected return is calculated as:
    ///      `expectedReturn = investment * (creditQuality + greenImpact) / 200`
    ///      The average of both scores (0-100) is treated as a yield percentage.
    /// @return expectedReturns_ The aggregate expected returns across all projects.
    function getExpectedReturns() public view returns (uint256 expectedReturns_) {
        uint256 length = PROJECT_MOD.totalSupply();
        for (uint256 i = 1; i <= length; ++i) {
            uint256 investment = projectInvestments[i];
            if (investment > 0) {
                ImpactScore memory score = PROJECT_MOD.getProjectScore(i);
                expectedReturns_ += (investment * (uint256(score.creditQuality) + uint256(score.greenImpact))) / 200;
            }
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             ISSUER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @notice Funds a project by transferring USDC from the vault to the project owner.
    /// @dev Only callable by addresses with the ISSUER_ROLE. Updates investment tracking
    ///      before executing the transfer. Reverts if the transfer fails.
    /// @param _projectId The ID of the project to fund.
    /// @param _amount The amount of USDC to transfer to the project owner.
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

    /// @dev Hook called after any deposit or mint. Reverts if zero shares were minted.
    /// @param shares The number of shares minted.
    function _afterDeposit(uint256, uint256 shares) internal virtual override {
        if (shares == 0) revert SharesError();
    }

    /// @dev Hook called before any withdrawal or redemption.
    ///      Ensures the vault has sufficient liquid USDC to cover the withdrawal,
    ///      since some assets may be locked in project investments.
    /// @param assets The amount of USDC being withdrawn.
    function _beforeWithdraw(uint256 assets, uint256) internal virtual override {
        if (assets > SafeTransferLib.balanceOf(asset(), address(this))) {
            revert InsufficientAssets();
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                                 OVERRIDES
    //////////////////////////////////////////////////////////////////////////*//

    /// @notice Approves a spender to transfer vault shares. Reverts on zero address.
    /// @param _spender The address to approve.
    /// @param _amount The amount of shares to approve.
    /// @return True if the approval succeeded.
    function approve(address _spender, uint256 _amount) public virtual override returns (bool) {
        if (_spender == address(0)) revert ZeroAddress();
        return super.approve(_spender, _amount);
    }

    /// @notice Transfers vault shares to a recipient. Reverts on zero address.
    /// @param _to The recipient address.
    /// @param _amount The amount of shares to transfer.
    /// @return True if the transfer succeeded.
    function transfer(address _to, uint256 _amount) public virtual override returns (bool) {
        if (_to == address(0)) revert ZeroAddress();
        return super.transfer(_to, _amount);
    }

    /// @notice Transfers vault shares between addresses. Reverts on zero address.
    /// @param _from The sender address.
    /// @param _to The recipient address.
    /// @param _amount The amount of shares to transfer.
    /// @return True if the transfer succeeded.
    function transferFrom(address _from, address _to, uint256 _amount) public virtual override returns (bool) {
        if (_from == address(0) || _to == address(0)) revert ZeroAddress();
        return super.transferFrom(_from, _to, _amount);
    }

    /// @dev Returns the number of decimals of the underlying USDC asset.
    function _underlyingDecimals() internal view virtual override returns (uint8) {
        return USDC_UNDERLYING_DECIMALS;
    }

    /// @dev Returns the decimals offset between shares and the underlying asset.
    function _decimalsOffset() internal view virtual override returns (uint8) {
        return DECIMALS_OFFSET;
    }
}
