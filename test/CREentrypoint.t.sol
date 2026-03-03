// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CREentrypoint} from "../src/CREentrypoint.sol";
import {ProjectMod} from "../src/ProjectMod.sol";
import {IProjectMod, ImpactScore, ProjectDetails} from "../src/interfaces/IProjectMod.sol";
import {IReceiver} from "../src/interfaces/IReceiver.sol";
import {Test} from "forge-std/Test.sol";

contract CREentrypointTest is Test {
    CREentrypoint public creEntrypoint;
    ProjectMod public projectMod;
    address public owner;
    address public forwarder;
    address public projectOwner;

    function setUp() public {
        owner = makeAddr("owner");
        forwarder = makeAddr("forwarder");
        projectOwner = makeAddr("projectOwner");

        // Deploy ProjectMod
        vm.prank(owner);
        projectMod = new ProjectMod(owner);

        // Deploy CREentrypoint
        creEntrypoint = new CREentrypoint(forwarder, address(projectMod));

        // Whitelist project owner
        vm.prank(owner);
        projectMod.setWhitelist(projectOwner, true);

        // Set CRE endpoint
        vm.prank(owner);
        projectMod.setCreEntrypointAddress(address(creEntrypoint));
    }

    function test_GetProjectAddress() public {
        assertEq(address(creEntrypoint.getProjectAddress()), address(projectMod));
    }

    function test_ProcessReport() public {
        // Create a project
        vm.prank(projectOwner);
        uint256 projectId = projectMod.createProject("ipfs://QmProject1");

        // Create report data
        ImpactScore memory impactScore = ImpactScore(85, 90);
        ProjectDetails[] memory projectDetails = new ProjectDetails[](1);
        projectDetails[0] = ProjectDetails(impactScore, projectId, "ipfs://QmProject1Updated");

        // Encode the report
        bytes memory reportData = abi.encode(projectDetails);

        // Empty metadata for testing
        bytes memory metadata = "";

        // Call onReport (simulating forwarder call)
        vm.prank(forwarder);
        creEntrypoint.onReport(metadata, reportData);

        // Verify project was updated
        ImpactScore memory score = projectMod.getProjectScore(projectId);
        assertEq(score.creditQuality, 85);
        assertEq(score.greenImpact, 90);
    }

    function test_SupportsInterface() public view {
        bytes4 ireceiverInterface = type(IReceiver).interfaceId;
        assertTrue(creEntrypoint.supportsInterface(ireceiverInterface));
    }
}
