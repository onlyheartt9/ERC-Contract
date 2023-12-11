// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2, console} from "forge-std/Test.sol";
import "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {RedPacket} from "../src/RedPacket.sol";

contract RedPockTest is Test {
    RedPacket public vrf;
    VRFCoordinatorV2Mock public mock;
    uint64 transaction;

    function setUp() public {
        uint96 fee = 100000000000000000;
        uint96 link = 1000000000;
        mock = new VRFCoordinatorV2Mock(fee, link);
        uint96 fundAmount = 1000000000000000000;
        transaction = mock.createSubscription();
        emit log_uint(transaction);
        mock.fundSubscription(transaction, fundAmount);
        vrf = new RedPacket(transaction, address(mock));
        mock.addConsumer(transaction, address(vrf));
    }

    function test_random() public {
        uint256 requestId = vrf.requestRandomWords();
        emit log_uint(requestId);
        mock.fulfillRandomWords(requestId, address(vrf));
        (bool fulfilled, uint256[] memory randomWords) = vrf.getRequestStatus(
            requestId
        );
        emit log_array(randomWords);
        assertTrue(fulfilled);
    }
}
