// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {CREentrypoint} from "../src/CREentrypoint.sol";
import {InvestmentMod} from "../src/InvestmentMod.sol";
import {ProjectMod} from "../src/ProjectMod.sol";
import {USDCMock} from "../test/mock/MockUSDC.sol";
import {Script} from "forge-std/Script.sol";

contract DeployEcobond is Script {
    address constant FORWARDER_ADDRESS = 0x6E9EE680ef59ef64Aa8C7371279c27E496b5eDc1;
    address constant DEV_ADDRESS = 0x2fd1AFA939eFD359a302D757740d6eC15b820bC2;
    USDCMock usdc;
    ProjectMod projectMod;
    CREentrypoint creEntry;
    InvestmentMod investmentMod;

    function run() public {
        vm.startBroadcast();
        usdc = new USDCMock();
        projectMod = new ProjectMod(msg.sender);
        creEntry = new CREentrypoint(FORWARDER_ADDRESS, address(projectMod));
        investmentMod = new InvestmentMod(msg.sender, address(projectMod), address(usdc));
        projectMod.setCreEntrypointAddress(address(creEntry));
        projectMod.setWhitelist(DEV_ADDRESS, true);
        vm.stopBroadcast();
    }
}
