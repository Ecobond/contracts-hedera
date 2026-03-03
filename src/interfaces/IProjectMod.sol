// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @notice The impact score of a project.
struct ImpactScore {
    uint8 creditQuality; // 0 - 100 (financial risk)
    uint8 greenImpact; // 0 - 100 (environmental integrity)
}

/// @notice The details of a project.
struct ProjectDetails {
    /// @notice The impact score of the project.
    ImpactScore impactScore;
    /// @notice The ID of the project.
    uint256 projectId;
    /// @notice The URI of the project.
    string projectURI;
}

interface IProjectMod is IERC721 {
    function setCreEntrypointAddress(address _creEndpoint) external;
    function setWhitelist(address _account, bool _status) external;
    /// @notice Creates a new project.
    /// @param projectURI The URI of the project.
    /// @return projectId The ID of the created project.
    function createProject(string calldata projectURI) external returns (uint256 projectId);

    /// @notice Updates the details of existing projects.
    /// @param projectDetails The details of the projects to update.
    function updateProjects(ProjectDetails[] calldata projectDetails) external;

    /// @notice Returns the impact score of a project.
    /// @param projectId The ID of the project.
    /// @return The impact score of the project.
    function getProjectScore(uint256 projectId) external view returns (ImpactScore memory);

    /// @notice Returns the total number of projects.
    /// @return The total supply of project tokens.
    function totalSupply() external view returns (uint256);
    function getCreEntrypointAddress() external view returns (address);
    function getProjectScores() external view returns (ImpactScore[] memory);
}
