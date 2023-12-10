// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2, console} from "forge-std/Test.sol";
import {VRFv2Consumer} from "../src/ChainLinkVRF.sol";

contract CounterTest is Test {
    VRFv2Consumer public vrf;
    uint64 sub = 7682;

    function setUp() public {
        vrf = new VRFv2Consumer(sub);
        console(6666);
        console2(address(vrf));
        // counter.setNumber(0);
    }

    // function testRandom (){
    //     vrf.requestRandomWords();
    //     vrf.RequestFulfilled();
    // }
}
