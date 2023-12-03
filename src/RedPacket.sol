// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract RedPacket {
    uint256 private total;
    mapping(address => Person) private personMap;
    mapping(address => bool) public personExists;

    mapping(address => Packet) private packetMap;
    mapping(address => bool) public packetExists;

    error LIMIT_ERROR(string);

    // 个人用户信息
    struct Person {
        uint256 deposit;
        bool key;
    }

    // 红包信息
    struct Packet {
        uint256 money;
        bool key;
        uint8 current;
        uint8 limit;
    }

    // 创建一个钱包
    function createPacket(
        uint256 _total,
        uint8 _limit,
        address _user
    ) external returns (bool success) {
        if (_limit != 5 || _limit != 10) {
            revert LIMIT_ERROR("createPacket");
        }

        Packet memory currentPacket = packetMap[_user];

        // 没有现有红包就创建一个新的，如果有则用旧的
        if (!packetExists[_user]) {
            currentPacket = getPacket(_total, _limit);
            packetMap[_user] = currentPacket;
        }
    }

    function getPacket(
        uint256 _total,
        uint8 _limit
    ) private returns (Packet memory packet) {
        packet = Packet(_total, false, 0, _limit);
        return packet;
    }

    function addPacket() external returns (bool success) {}

    function addDeposit() external returns (uint256 currentDeposit) {}

    function withdrawalDeposit() external returns (uint256 currentDeposit) {}
}
