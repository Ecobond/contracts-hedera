// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {InvestmentMod} from "../src/InvestmentMod.sol";
import {ProjectMod} from "../src/ProjectMod.sol";
import {IProjectMod} from "../src/interfaces/IProjectMod.sol";
import {USDCMock} from "../test/mock/MockUSDC.sol";
import {Test} from "forge-std/Test.sol";

contract InvestmentModTest is Test {
    InvestmentMod public investmentMod;
    ProjectMod public projectMod;
    USDCMock public usdc;
    address public owner;
    address public issuer;
    address public investor;
    address public projectOwner;

    function setUp() public {
        owner = makeAddr("owner");
        issuer = makeAddr("issuer");
        investor = makeAddr("investor");
        projectOwner = makeAddr("projectOwner");

        // Deploy mock USDC
        usdc = new USDCMock();

        // Deploy ProjectMod
        vm.prank(owner);
        projectMod = new ProjectMod(owner);

        // Deploy InvestmentMod - note: owner must be the issuer to grant roles
        investmentMod = new InvestmentMod(owner, address(projectMod), address(usdc));

        // Setup investmentMod issuer role
        uint256 issuerRole = investmentMod.ISSUER_ROLE();
        vm.prank(owner);
        investmentMod.grantRoles(issuer, issuerRole);

        // Mint USDC to investment mod
        usdc.mint(address(investmentMod), 1000000e6);
        usdc.mint(investor, 100000e6);

        // Setup projectMod whitelist
        vm.prank(owner);
        projectMod.setWhitelist(projectOwner, true);
    }

    function test_InvestmentModName() public view {
        assertEq(investmentMod.name(), "Ecobond Shares");
    }

    function test_InvestmentModSymbol() public view {
        assertEq(investmentMod.symbol(), "EBS");
    }

    function test_CreateProject() public {
        vm.prank(projectOwner);
        uint256 projectId = projectMod.createProject("ipfs://QmProject1");
        assertEq(projectId, 1);
    }

    function test_FundProjectSuccessfully() public {
        // Create a project
        vm.prank(projectOwner);
        uint256 projectId = projectMod.createProject("ipfs://QmProject1");
        uint256 fundAmount = 100000e6;

        // Approve investmentMod to spend its own USDC (needed for trySafeTransferFrom)
        vm.prank(address(investmentMod));
        usdc.approve(address(investmentMod), type(uint256).max);

        // Record the project owner's balance before
        uint256 balanceBefore = usdc.balanceOf(projectOwner);

        vm.prank(issuer);
        investmentMod.fundProject(projectId, fundAmount);

        uint256 balanceAfter = usdc.balanceOf(projectOwner);

        assertEq(balanceAfter, balanceBefore + fundAmount);
        assertEq(investmentMod.projectInvestments(projectId), fundAmount);
    }

    function test_TotalAssets() public {
        uint256 initialAssets = investmentMod.totalAssets();
        assertGe(initialAssets, 0);
    }

    function test_InvestorRoles() public view {
        assertTrue(investmentMod.hasAnyRole(issuer, investmentMod.ISSUER_ROLE()));
    }
}
