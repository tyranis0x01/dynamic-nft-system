// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/onchain/TestDynamicNFT.sol";

contract DeployTestDynamicNFT is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the TestDynamicNFT contract
        TestDynamicNFT nft = new TestDynamicNFT();

        vm.stopBroadcast();

        console.log("TestDynamicNFT deployed to:", address(nft));

        // Log some useful information
        console.log("Contract name:", nft.name());
        console.log("Contract symbol:", nft.symbol());
        console.log("Total supply:", nft.totalSupply());
    }
}