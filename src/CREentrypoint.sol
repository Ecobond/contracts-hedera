// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProject} from "./interfaces/IProject.sol";
import {ReceiverTemplate} from "./libraries/ReceiverTemplate.sol";

contract CREentrypoint is ReceiverTemplate {
    IProject private project;

    constructor(address _forwarderAddress, address _projectAddress) ReceiverTemplate(_forwarderAddress) {
        project = IProject(_projectAddress);
    }

    function getProjectAddress() external view returns (IProject) {
        return project;
    }

    function _processReport(bytes calldata report) internal virtual override {
        (uint256[] memory projectIds, string[] memory projectURIs) = abi.decode(report, (uint256[], string[]));
        project.updateProjects(projectIds, projectURIs);
    }
}
