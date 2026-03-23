// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {InvestmentMod} from "../src/InvestmentMod.sol";
import {ProjectMod} from "../src/ProjectMod.sol";
import {USDCMock} from "../test/mock/MockUSDC.sol";
import {Script} from "forge-std/Script.sol";

contract DeployEcobond is Script {
    address constant DEV_ADDRESS = 0x2fd1AFA939eFD359a302D757740d6eC15b820bC2;
    address constant ECOBOND_ORACLE_ADDRESS = 0x71ebFf4F22B1c4CeC9c4F1B9d427d165358be101;
    string[12] PROJECTS_URIS = [
        "ipfs://bafkreib3altwckjzo2rbqucli42hes3xn4hyytnfwhxl6unctypxpop4nu",
        "ipfs://bafkreihalgtlyltl5bocf5ngea4yrg2btbd4myqn3uvjdkpd7plbplzukq",
        "ipfs://bafkreicans4wbbbzm436ssi2i5rv72z22bltfktrtdzsklrecb6qidv4wy",
        "ipfs://bafkreicu5cgsnexp4e7zj6tfsf76jbkbfq6j4swhauachpfpmzlsr7fcne",
        "ipfs://bafkreif5ugp2yfhk3mrdyq3bv2yn3v4kg4noahanhjloemyhgjroafriri",
        "ipfs://bafkreihim6obgqd6armigw6w4jpdedjpge5umdo5beaxji4j4aog4afxze",
        "ipfs://bafkreieufotunwezuibzem7xjuuphdndi6n55rukxhhhurjglgudllxbj4",
        "ipfs://bafkreie54vulgbbpkosfktf3ufisjl6tmcm34rexr4fn7j7kizzeble26e",
        "ipfs://bafkreid4kt25ynpy4bfwptyj32chionaualpbzmte7ybfcr7pbrvgix3ay",
        "ipfs://bafkreigin36zohwcr3a4xnpbk7o4iywfdp5tg3lskv7sclwq7doo2vknlm",
        "ipfs://bafkreihshcmpdsczwnkhsb2ugly4gkyfk76htqumavpniyovqh4ox6njei",
        "ipfs://bafkreiexsp3vkhi2hy4abwgtlln3peni6licalltwksqdtcepy3uig5gwy"
    ];

    USDCMock usdc;
    ProjectMod projectMod;
    InvestmentMod investmentMod;

    function run() public {
        vm.startBroadcast();

        // Deploy contracts
        projectMod = new ProjectMod(msg.sender);
        usdc = new USDCMock();
        investmentMod = new InvestmentMod(msg.sender, address(projectMod), address(usdc));

        // Set roles
        investmentMod.grantRoles(msg.sender, investmentMod.ISSUER_ROLE());

        // Set oracle address
        projectMod.setEcobondOracleAddress(ECOBOND_ORACLE_ADDRESS);

        // Set whitelist
        projectMod.setWhitelist(DEV_ADDRESS, true);
        projectMod.setWhitelist(ECOBOND_ORACLE_ADDRESS, true);
        projectMod.setWhitelist(msg.sender, true);

        // Mint tokens
        usdc.mint(msg.sender, 1_000_000_000e18);
        usdc.mint(DEV_ADDRESS, 1_000_000_000e18);
        usdc.mint(0x7D413F244A0e9A0b9C8D7F9AFA1177eE3a2837fa, 1_000_000_000e18);

        // Create projects
        uint8 projectsCount = uint8(PROJECTS_URIS.length);
        for (uint8 i; i < projectsCount; ++i) {
            projectMod.createProject(PROJECTS_URIS[i]);
        }

        vm.stopBroadcast();
    }
}
