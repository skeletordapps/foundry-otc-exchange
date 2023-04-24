// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Exchanger.sol";

contract ExchangerScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        address token0 = vm.envAddress("USDC_CONTRACT_ADDRESS");
        address token1 = vm.envAddress("LEVI_CONTRACT_ADDRESS");
        new Exchanger(token0, token1, 2 ether);
        vm.stopBroadcast();
    }
}
