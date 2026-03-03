// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProjectMod, ProjectDetails} from "./interfaces/IProjectMod.sol";
import {ReceiverTemplate} from "./libraries/ReceiverTemplate.sol";

/// @title CREentrypoint
/// @notice Chainlink CRE (Compute, Read, Execute) entrypoint that receives off-chain reports
///         and forwards decoded project updates to the ProjectMod contract.
/// @dev Extends ReceiverTemplate to handle report forwarding from the Chainlink forwarder.
contract CREentrypoint is ReceiverTemplate {
    /// @notice The ProjectMod contract that this entrypoint forwards updates to.
    IProjectMod private project;

    /// @notice Deploys the CRE entrypoint with a forwarder and project contract.
    /// @param _forwarderAddress The address of the Chainlink forwarder contract.
    /// @param _projectAddress The address of the ProjectMod contract.
    constructor(address _forwarderAddress, address _projectAddress) ReceiverTemplate(_forwarderAddress) {
        project = IProjectMod(_projectAddress);
    }

    /// @notice Returns the address of the ProjectMod contract.
    /// @return The IProjectMod interface reference for the project contract.
    function getProjectAddress() external view returns (IProjectMod) {
        return project;
    }

    /// @notice Processes an incoming report by decoding it and forwarding project updates.
    /// @dev Called internally by the ReceiverTemplate when a valid report is received.
    /// @param _report The ABI-encoded report data containing ProjectDetails[].
    function _processReport(bytes calldata _report) internal virtual override {
        project.updateProjects(_decodeReport(_report));
    }

    /// @notice Decodes a raw report into an array of ProjectDetails.
    /// @param _report The ABI-encoded report bytes.
    /// @return The decoded array of ProjectDetails structs.
    function _decodeReport(bytes calldata _report) internal pure returns (ProjectDetails[] memory) {
        return abi.decode(_report, (ProjectDetails[]));
    }
}
