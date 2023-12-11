// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import {VRFv2Consumer} from "./ChainLinkVRF.sol";

contract RedPacket is VRFv2Consumer {
    uint256 private total;
    mapping(address => User) private userMap;
    mapping(address => Packet) private packetMap;
    // 随机数ID对应的红包
    mapping(uint256 => address) private requestIdToPacketAddr;
    // 小钱钱

    error LIMIT_ERROR(string); // 红包次数限制异常
    error NO_PACKET(string); // 没有找到对应红包
    error FULL_USER(string); // 用户满了
    error NOT_ENOUGH_USER(string); // 参加的用户不够
    error NO_USER(string); // 没有对应用户

    // 个人用户信息
    struct User {
        uint256 deposit;
        bool lock;
        bool active;
        address pocket; // 正在参加的红包地址
    }

    // 红包信息
    struct Packet {
        uint256 amount;
        bool lock;
        uint8 times;
        uint8 limit;
        uint8 length;
        address[] users;
        address creator;
        bool exist;
        uint256 requestid;
    }

    struct RandomArrayResult {
        uint256[] array;
        uint256 maxIndex;
    }

    constructor(
        uint64 _subscriptionId,
        address _subscriptionAddr
    ) VRFv2Consumer(_subscriptionId, _subscriptionAddr) {}

    // 获取发起人对应的红包
    function getPacket(address _creator) public view returns (Packet memory) {
        Packet memory currentPacket = packetMap[_creator];
        if (!currentPacket.exist) {
            revert NO_PACKET("getPacket");
        }
        return currentPacket;
    }

    // 创建一个新钱包
    function createPacket(
        uint256 _amount,
        uint8 _limit,
        uint8 _length
    ) private returns (Packet memory packet) {
        if (_limit != 5 || _limit != 10) {
            revert LIMIT_ERROR("createPacket");
        }
        address[] memory users = new address[](_limit);
        users[0] = msg.sender;
        packet = Packet(
            _amount,
            false,
            0,
            _limit,
            _length,
            users,
            msg.sender,
            true,
            0
        );
        packetMap[msg.sender] = packet;
        return packet;
    }

    // 参与到红包中
    function attendPacket(address _creator) external returns (bool success) {
        Packet memory packet = packetMap[_creator];
        if (!packet.exist) {
            revert NO_PACKET("attendPacket");
        }
        if (packet.lock) {
            revert FULL_USER("attendPacket");
        }

        packetMap[_creator].users.push(msg.sender);
        // 减少访问packetMap的gas
        if (packet.users.length + 1 == packet.limit) {
            startPacket(packet.creator);
        }
    }

    // 追加押金
    function addDeposit(
        uint256 _deposit
    ) external payable returns (uint256 count) {
        User memory userInfo = userMap[msg.sender];
        userMap[msg.sender].deposit = userInfo.deposit + _deposit;
        return userMap[msg.sender].deposit;
    }

    // 初始化个人信息
    function initUser() public payable returns (uint256 count) {
        userMap[msg.sender] = User(0, false, true, address(0));
        return 0;
    }

    // 开始抢红包
    function startPacket(address _creator) public returns (uint256 requestId) {
        Packet memory packet = getPacket(_creator);
        if (!packet.exist) {
            revert NO_PACKET("startPacket");
        }
        if (packet.users.length != packet.length) {
            revert NOT_ENOUGH_USER("startPacket");
        }
        requestId = requestRandomWords();
        requestIdToPacketAddr[requestId] = _creator;
        return requestId;
    }

    // VRF回调，继续抢红包
    function continuePacket(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal {
        address creator = requestIdToPacketAddr[_requestId];
        delete requestIdToPacketAddr[_requestId];
        Packet memory packet = getPacket(creator);
        // 按照随机数字获取百分比然后获取每个用户分到的amount
        uint256[] memory amounts = getCountByPercent(
            _randomWords,
            packet.amount
        );
    }

    // 合约拥有者可以提取合约余额
    function withdrawContractBalance() public {
        require(
            msg.sender == owner,
            "Only the owner can withdraw contract balance"
        );
        payable(owner).transfer(address(this).balance);
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        setRandomWords(_requestId, _randomWords);
        emit RequestFulfilled(_requestId, _randomWords);

        continuePacket(_requestId, _randomWords);
    }
}
