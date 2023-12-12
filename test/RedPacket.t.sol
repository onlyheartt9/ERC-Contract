// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2, console} from "forge-std/Test.sol";
import "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {RedPacket} from "../src/RedPacket.sol";
import "./mock/MockErc20.sol";

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RedPockTest is Test {
    RedPacket public redpacket;
    VRFCoordinatorV2Mock public mock;
    IERC20 public token; // 代币合约
    address public user = 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955;
    uint64 transaction;

    function setUp() public {
        uint96 fee = 100000000000000000;
        uint96 link = 1000000000;
        mock = new VRFCoordinatorV2Mock(fee, link);
        uint96 fundAmount = 1000000000000000000;
        transaction = mock.createSubscription();
        emit log_uint(transaction);
        mock.fundSubscription(transaction, fundAmount);
        token = new MockErc20();
        // token = IERC20(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        redpacket = new RedPacket(transaction, address(mock), address(token));
        mock.addConsumer(transaction, address(redpacket));
    }

    function testDeposit() public {
        uint256 deposit = 10000;
        token.approve(user, 100000000);
        token.approve(address(redpacket), 100000000);
        token.allowance(address(redpacket),msg.sender);
        token.allowance(user,msg.sender);
        token.transferFrom(user, address(redpacket), deposit);
        // redpacket.addDeposit(deposit);
        uint256 return_deposit = token.balanceOf(address(redpacket));
        assertEq(deposit, return_deposit);
    }

    // function test_random() public {
    //     uint256 requestId = redpacket.requestRandomWords();
    //     emit log_uint(requestId);
    //     mock.fulfillRandomWords(requestId, address(redpacket));
    //     (bool fulfilled, uint256[] memory randomWords) = redpacket.getRequestStatus(
    //         requestId
    //     );
    //     emit log_array(randomWords);
    //     assertTrue(fulfilled);
    // }
}
