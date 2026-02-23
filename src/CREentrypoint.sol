// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProjectMod, ProjectDetails} from "./interfaces/IProjectMod.sol";
import {ReceiverTemplate} from "./libraries/ReceiverTemplate.sol";

contract CREentrypoint is ReceiverTemplate {
    IProjectMod private project;

    constructor(address _forwarderAddress, address _projectAddress) ReceiverTemplate(_forwarderAddress) {
        project = IProjectMod(_projectAddress);
    }

    function getProjectAddress() external view returns (IProjectMod) {
        return project;
    }

    function _processReport(bytes calldata _report) internal virtual override {
        project.updateProjects(_decodeReport(_report));
    }

    function _decodeReport(bytes calldata _report) internal pure returns (ProjectDetails[] memory) {
        return abi.decode(_report, (ProjectDetails[]));
    }
}
