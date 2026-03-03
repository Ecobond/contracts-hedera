// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @notice The impact score of a project.
/// @param creditQuality Financial risk score from 0 (highest risk) to 100 (lowest risk).
/// @param greenImpact Environmental integrity score from 0 (lowest impact) to 100 (highest impact).
struct ImpactScore {
    uint8 creditQuality;
    uint8 greenImpact;
}

/// @notice The details of a project used for batch updates.
/// @param impactScore The impact score of the project.
/// @param projectId The ID of the project.
/// @param projectURI The URI pointing to the project's off-chain metadata.
struct ProjectDetails {
    ImpactScore impactScore;
    uint256 projectId;
    string projectURI;
}

/// @title IProjectMod
/// @notice Interface for the Ecobond project registry.
/// @dev Each project is represented as an ERC721 token with associated impact scores and metadata.
interface IProjectMod is IERC721 {
    /// @notice Sets the Chainlink CRE entrypoint address authorized to update projects.
    /// @param _creEndpoint The address of the CRE entrypoint contract.
    function setCreEntrypointAddress(address _creEndpoint) external;

    /// @notice Adds or removes an address from the project creation whitelist.
    /// @param _account The address to whitelist or de-whitelist.
    /// @param _status True to whitelist, false to remove.
    function setWhitelist(address _account, bool _status) external;

    /// @notice Creates a new project and mints an ERC721 token to the caller.
    /// @param projectURI The URI pointing to the project's off-chain metadata.
    /// @return projectId The ID of the newly created project token.
    function createProject(string calldata projectURI) external returns (uint256 projectId);

    /// @notice Batch updates the details of existing projects.
    /// @dev Can only be called by the CRE entrypoint.
    /// @param projectDetails An array of project details to update.
    function updateProjects(ProjectDetails[] calldata projectDetails) external;

    /// @notice Returns the impact score of a specific project.
    /// @param projectId The ID of the project.
    /// @return The impact score containing creditQuality and greenImpact.
    function getProjectScore(uint256 projectId) external view returns (ImpactScore memory);

    /// @notice Returns the total number of projects in the registry.
    /// @return The total supply of project tokens.
    function totalSupply() external view returns (uint256);

    /// @notice Returns the address of the CRE entrypoint contract.
    /// @return The CRE entrypoint address.
    function getCreEntrypointAddress() external view returns (address);

    /// @notice Returns the impact scores for all projects.
    /// @return An array of impact scores indexed by project order (0-indexed).
    function getProjectScores() external view returns (ImpactScore[] memory);
}
