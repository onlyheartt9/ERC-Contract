// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {RedPacket} from "../src/RedPacket.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        address TOKEN_ADDRESS = vm.envAddress("TOKEN_ADDRESS");
        address SUB_SCRIPTION_ADDRESS = vm.envAddress("SUB_SCRIPTION_ADDRESS");
        uint64 SUB_SCRIPTION_ID = uint64(vm.envUint("SUB_SCRIPTION_ID"));
        bytes32 keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
        vm.startBroadcast();
        new RedPacket(
            SUB_SCRIPTION_ID,
            SUB_SCRIPTION_ADDRESS,
            keyHash,
            TOKEN_ADDRESS
        );
        vm.stopBroadcast();
    }
}
