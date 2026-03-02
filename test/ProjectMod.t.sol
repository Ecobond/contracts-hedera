// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ProjectMod} from "../src/ProjectMod.sol";
import {IProjectMod, ImpactScore, ProjectDetails} from "../src/interfaces/IProjectMod.sol";
import {Test} from "forge-std/Test.sol";

contract ProjectModTest is Test {
    ProjectMod public projectMod;
    address public owner;
    address public user1;
    address public user2;
    address public creEndpoint;

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        creEndpoint = makeAddr("creEndpoint");

        vm.prank(owner);
        projectMod = new ProjectMod(owner);

        // Set up CRE endpoint
        vm.prank(owner);
        projectMod.setCreEntrypointAddress(creEndpoint);

        // Whitelist users
        vm.prank(owner);
        projectMod.setWhitelist(user1, true);
        vm.prank(owner);
        projectMod.setWhitelist(user2, true);
    }

    function test_CreateProject() public {
        vm.prank(user1);
        uint256 projectId = projectMod.createProject("ipfs://QmProject1");

        assertEq(projectId, 1);
        assertEq(projectMod.ownerOf(projectId), user1);
    }

    function test_CreateMultipleProjects() public {
        vm.prank(user1);
        uint256 projectId1 = projectMod.createProject("ipfs://QmProject1");

        vm.prank(user2);
        uint256 projectId2 = projectMod.createProject("ipfs://QmProject2");

        assertEq(projectId1, 1);
        assertEq(projectId2, 2);
        assertEq(projectMod.totalSupply(), 2);
    }

    function test_ProjectCreationNotWhitelisted() public {
        address notWhitelisted = makeAddr("notWhitelisted");

        vm.prank(notWhitelisted);
        vm.expectRevert();
        projectMod.createProject("ipfs://QmProject1");
    }

    function test_UpdateProject() public {
        vm.prank(user1);
        uint256 projectId = projectMod.createProject("ipfs://QmProject1");

        ImpactScore memory newScore = ImpactScore(85, 90);
        ProjectDetails[] memory projectDetails = new ProjectDetails[](1);
        projectDetails[0] = ProjectDetails(newScore, projectId, "ipfs://QmProject1Updated");

        vm.prank(creEndpoint);
        projectMod.updateProjects(projectDetails);

        ImpactScore memory score = projectMod.getProjectScore(projectId);
        assertEq(score.creditQuality, 85);
        assertEq(score.greenImpact, 90);
    }

    function test_GetProjectScores() public {
        vm.prank(user1);
        uint256 projectId1 = projectMod.createProject("ipfs://QmProject1");

        vm.prank(user2);
        uint256 projectId2 = projectMod.createProject("ipfs://QmProject2");

        ImpactScore memory newScore1 = ImpactScore(80, 85);
        ImpactScore memory newScore2 = ImpactScore(75, 90);

        ProjectDetails[] memory projectDetails = new ProjectDetails[](2);
        projectDetails[0] = ProjectDetails(newScore1, projectId1, "ipfs://QmProject1Updated");
        projectDetails[1] = ProjectDetails(newScore2, projectId2, "ipfs://QmProject2Updated");

        vm.prank(creEndpoint);
        projectMod.updateProjects(projectDetails);

        ImpactScore[] memory scores = projectMod.getProjectScores();
        assertEq(scores.length, 2);
        // Check first project (ID 1) should be at index 0
        assertEq(scores[0].creditQuality, 80);
        assertEq(scores[0].greenImpact, 85);
        // Check second project (ID 2) should be at index 1
        assertEq(scores[1].creditQuality, 75);
        assertEq(scores[1].greenImpact, 90);
    }

    function test_SetWhitelist() public {
        address newUser = makeAddr("newUser");

        vm.prank(owner);
        projectMod.setWhitelist(newUser, true);

        vm.prank(newUser);
        uint256 projectId = projectMod.createProject("ipfs://QmProject");
        assertEq(projectMod.ownerOf(projectId), newUser);
    }

    function test_RemoveFromWhitelist() public {
        vm.prank(owner);
        projectMod.setWhitelist(user1, false);

        vm.prank(user1);
        vm.expectRevert();
        projectMod.createProject("ipfs://QmProject");
    }

    function test_ProjectName() public {
        assertEq(projectMod.name(), "Ecobond Projects");
    }

    function test_ProjectSymbol() public {
        assertEq(projectMod.symbol(), "EBP");
    }
}
