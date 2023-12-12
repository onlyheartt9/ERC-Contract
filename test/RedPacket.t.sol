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
    address[] public users = [
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
        0x70997970C51812dc3A010C7d01b50e0d17dc79C8,
        0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC,
        0x90F79bf6EB2c4f870365E785982E1f101E93b906,
        0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65,
        0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc,
        0x976EA74026E726554dB657fA54763abd0C3a0aa9,
        0x14dC79964da2C08b23698B3D3cc7Ca32193d9955,
        0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f,
        0xa0Ee7A142d267C1f36714E4a8F75612F20a79720
    ];
    uint64 transaction;
    uint256 public depositSingle = 1000000;

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

        // 给用户赋值
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            token.transfer(user, depositSingle * 10);
            vm.prank(from);
            redpacket.addDeposit(depositSingle * 10);
        }
    }

    function test_createPacket() public {
        address from = msg.sender;
        address user0 = users[0];
        vm.prank(user0);
        uint256 packetId = redpacket.createPacket(depositSingle, "ROLL", 5);
    }

    // 合约获取到押金了
    // function testDeposit() public {
    //     address from = msg.sender;
    //     address to = address(redpacket);
    //     uint256 deposit = 1000000;
    //     token.transfer(from, 10000000);
    //     vm.prank(from);
    //     token.approve(to, 10000000);
    //     vm.prank(from);
    //     redpacket.addDeposit(deposit);
    //     vm.prank(from);
    //     uint256 return_deposit = redpacket.getDeposit();
    //     assertEq(deposit, return_deposit);
    // }

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
