// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProjectMod, ImpactScore, ProjectDetails} from "./interfaces/IProjectMod.sol";
import {ERC721, ERC721Enumerable, IERC165} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "solady/auth/Ownable.sol";

/// @notice Emitted when a project's metadata or impact score is updated.
/// @param projectId The ID of the project.
/// @param projectURI The updated URI for the project's off-chain metadata.
/// @param impactScore The updated impact score of the project.
event ProjectUpdated(uint256 indexed projectId, string projectURI, ImpactScore impactScore);

/// @notice Emitted when the Ecobond Oracle address is changed.
/// @param ecobondOracle The new Ecobond Oracle address.
event EcobondOracleSet(address indexed ecobondOracle);

/// @notice Emitted when an address is added to or removed from the whitelist.
/// @param account The affected address.
/// @param status True if whitelisted, false if removed.
event Whitelisted(address indexed account, bool status);

/// @notice Thrown when a function restricted to the Ecobond Oracle is called by another address.
error NotEcobondOracle();

/// @notice Thrown when a non-whitelisted address attempts to create a project.
error NotWhitelisted();

/// @title ProjectMod
/// @notice ERC721-based project registry for Ecobond. Each project is an NFT with
///         associated impact scores (creditQuality, greenImpact) and off-chain metadata.
/// @dev Projects are created by whitelisted addresses and updated by the CRE entrypoint.
///      Impact scores are used by InvestmentMod to compute expected returns.
contract ProjectMod is ERC721Enumerable, ERC721URIStorage, Ownable, IProjectMod {
    //*//////////////////////////////////////////////////////////////////////////
    //                                  STORAGE
    //////////////////////////////////////////////////////////////////////////*//

    /// @notice The address of the CRE entrypoint authorized to update project scores.
    address private ecobondOracle;

    /// @notice Mapping from project ID to its impact score.
    mapping(uint256 => ImpactScore) private projectScores;

    /// @notice Mapping from address to whitelist status for project creation.
    mapping(address => bool) private whitelist;

    //*//////////////////////////////////////////////////////////////////////////
    //                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*//

    /// @notice Deploys the ProjectMod contract.
    /// @param _owner The address that will be set as the contract owner.
    constructor(address _owner) ERC721("", "") {
        _initializeOwner(_owner);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                                 MODIFIERS
    //////////////////////////////////////////////////////////////////////////*//

    /// @dev Restricts access to the Ecobond Oracle address.
    modifier onlyEcobondOracle() {
        if (_msgSender() != ecobondOracle) revert NotEcobondOracle();
        _;
    }

    /// @dev Restricts access to whitelisted addresses.
    modifier onlyWhitelisted() {
        if (!whitelist[_msgSender()]) revert NotWhitelisted();
        _;
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @notice Sets the Ecobond Oracle address authorized to update projects.
    /// @dev Only callable by the contract owner.
    /// @param _ecobondOracle The address of the Ecobond Oracle contract.
    function setEcobondOracleAddress(address _ecobondOracle) external onlyOwner {
        ecobondOracle = _ecobondOracle;
        emit EcobondOracleSet(_ecobondOracle);
    }

    /// @notice Adds or removes an address from the project creation whitelist.
    /// @dev Only callable by the contract owner.
    /// @param _account The address to whitelist or de-whitelist.
    /// @param _status True to whitelist, false to remove.
    function setWhitelist(address _account, bool _status) external onlyOwner {
        whitelist[_account] = _status;
        emit Whitelisted(_account, _status);
    }

    /// @notice Creates a new project and mints an ERC721 token to the caller.
    /// @dev Only callable by whitelisted addresses. Project IDs are sequential starting from 1.
    /// @param _projectURI The URI pointing to the project's off-chain metadata.
    /// @return projectId_ The ID of the newly created project token.
    function createProject(string calldata _projectURI) external onlyWhitelisted returns (uint256 projectId_) {
        projectId_ = totalSupply() + 1;
        _mint(_msgSender(), projectId_);
        _setTokenURI(projectId_, _projectURI);
        emit ProjectUpdated(projectId_, _projectURI, ImpactScore(0, 0));
    }

    /// @notice Batch updates the impact scores and metadata of existing projects.
    /// @dev Only callable by the CRE entrypoint.
    /// @param _projectDetails An array of ProjectDetails containing new scores and URIs.
    function updateProjects(ProjectDetails[] calldata _projectDetails) external onlyEcobondOracle {
        uint256 length = _projectDetails.length;
        for (uint256 i; i < length; ++i) {
            _updateProject(_projectDetails[i].projectId, _projectDetails[i].projectURI, _projectDetails[i].impactScore);
        }
    }

    /// @notice Returns the address of the Ecobond Oracle contract.
    /// @return The Ecobond Oracle address.
    function getEcobondOracleAddress() external view returns (address) {
        return ecobondOracle;
    }

    /// @notice Returns the impact score of a specific project.
    /// @dev Reverts if the project ID does not exist.
    /// @param _projectId The ID of the project.
    /// @return The impact score containing creditQuality and greenImpact.
    function getProjectScore(uint256 _projectId) external view returns (ImpactScore memory) {
        _requireOwned(_projectId);
        return projectScores[_projectId];
    }

    /// @notice Returns the impact scores for all projects.
    /// @dev Iterates over all project token IDs (1-indexed) and returns a 0-indexed array.
    /// @return projectScores_ An array of impact scores for all projects.
    function getProjectScores() external view returns (ImpactScore[] memory projectScores_) {
        uint256 length = totalSupply();
        projectScores_ = new ImpactScore[](length);
        for (uint256 i; i < length; ++i) {
            projectScores_[i] = projectScores[i + 1];
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                              PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @notice Returns the token collection name.
    /// @return The string "Ecobond Projects".
    function name() public view virtual override returns (string memory) {
        return "Ecobond Projects";
    }

    /// @notice Returns the token collection symbol.
    /// @return The string "EBP".
    function symbol() public view virtual override returns (string memory) {
        return "EBP";
    }

    /// @notice Returns the URI for a given token ID.
    /// @param _tokenId The ID of the token.
    /// @return The token's metadata URI.
    function tokenURI(uint256 _tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return ERC721URIStorage.tokenURI(_tokenId);
    }

    /// @notice Checks if the contract supports a given interface.
    /// @param _interfaceId The interface identifier to check.
    /// @return True if the interface is supported.
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    /// @notice Returns the total number of project tokens in circulation.
    /// @return The total supply of project NFTs.
    function totalSupply() public view virtual override(ERC721Enumerable, IProjectMod) returns (uint256) {
        return ERC721Enumerable.totalSupply();
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @dev Overrides ERC721 and ERC721Enumerable _update to maintain enumeration.
    function _update(address _to, uint256 _tokenId, address _auth)
        internal
        virtual
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return ERC721Enumerable._update(_to, _tokenId, _auth);
    }

    /// @dev Overrides ERC721 and ERC721Enumerable _increaseBalance to maintain enumeration.
    function _increaseBalance(address _account, uint128 _amount) internal virtual override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._increaseBalance(_account, _amount);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @dev Updates a project's impact score and metadata URI.
    /// @param _projectId The ID of the project to update.
    /// @param _projectURI The new metadata URI.
    /// @param _impactScore The new impact score.
    function _updateProject(uint256 _projectId, string calldata _projectURI, ImpactScore calldata _impactScore)
        private
    {
        projectScores[_projectId] = _impactScore;
        if (bytes(_projectURI).length > 0) {
            _setTokenURI(_projectId, _projectURI);
        }
        emit ProjectUpdated(_projectId, _projectURI, _impactScore);
    }
}
