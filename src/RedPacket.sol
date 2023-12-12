// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import {VRFv2Consumer} from "./ChainLinkVRF.sol";
import {Utils} from "./Utils.sol";
import {Transfer} from "./Transfer.sol";

contract RedPacket is VRFv2Consumer, Utils, Transfer {
    uint256 private globalCounter;
    uint256 private total;
    mapping(address => User) private userMap;
    mapping(uint256 => Packet) private packetMap;
    // 随机数ID对应的红包
    mapping(uint256 => uint256) private requestIdToPacketId;
    // 小钱钱

    error LIMIT_ERROR(string); // 红包次数限制异常
    error NOT_ENOUGH_DEPOSIT(string); // 押金不够
    error NO_PACKET(string); // 没有找到对应红包
    error FULL_USER(string); // 用户满了
    error NOT_ENOUGH_USER(string); // 参加的用户不够
    error NO_USER(string); // 没有对应用户
    error ALREADY_ATTEND(string); // 已经参加红包

    // 个人用户信息
    struct User {
        uint256 deposit;
        bool lock;
        bool active;
        bool exist;
        uint256 pocketId; // 正在参加的红包ID
    }

    // 红包信息
    struct Packet {
        uint256 id; // id
        uint256 startTime; // 发起红包时间
        uint256 amount; // 单个红包金额
        string collectType; // 红包类型
        bool lock;  // 红包锁
        uint8 times; // 当前次数
        uint8 limit; // 限制人数
        address[] users; // 当前参加的人数
        address creator; // 发起人
        bool exist; // 是否存在
        uint256 requestid;// 随机数映射id，方便vrf回调
    }

    struct RandomArrayResult {
        uint256[] array;
        uint256 maxIndex;
    }

    constructor(
        uint64 _subscriptionId,
        address _subscriptionAddr,
        address _tokenAddress
    )
        VRFv2Consumer(_subscriptionId, _subscriptionAddr)
        Transfer(_tokenAddress)
    {}

    // 获取发起人对应的红包
    function getPacket(uint256 _id) public view returns (Packet memory) {
        Packet memory currentPacket = packetMap[_id];
        if (!currentPacket.exist) {
            revert NO_PACKET("getPacket");
        }
        return currentPacket;
    }

    // 创建一个新钱包
    function createPacket(
        uint256 _amount,
        string memory collectType,
        uint8 _limit
    ) external returns (uint256 packetId) {
        if (_limit != 5 || _limit != 10) {
            revert LIMIT_ERROR("createPacket");
        }
        uint256 deposit = getDeposit();
        if (deposit < _amount * 10) {
            revert NOT_ENOUGH_DEPOSIT("createPacket");
        }
        address[] memory users = new address[](_limit);
        users[0] = msg.sender;
        uint256 id = generateUniqueID();
        // 创建一个新的钱包
        packet = Packet(
            id,
            block.timestamp,
            _amount,
            collectType,
            false,
            0,
            _limit,
            users,
            msg.sender,
            true,
            0
        );
        packetMap[id] = packet;
        return id;
    }

    // 参与到红包中
    function attendPacket(uint256 _id) external returns (bool success) {
        Packet memory packet = packetMap[_id];
        if (!packet.exist) {
            revert NO_PACKET("attendPacket");
        }
        if (packet.lock) {
            revert FULL_USER("attendPacket");
        }
        if (userMap[msg.sender].lock) {
            revert ALREADY_ATTEND("attendPacket");
        }
        if (deposit < packet.amount * 10) {
            revert NOT_ENOUGH_DEPOSIT("attendPacket");
        }

        packetMap[_id].users.push(msg.sender);
        userMap[msg.sender].packetId = _id;
        userMap[msg.sender].lock = true;
        // 减少访问packetMap的gas
        if (packet.users.length + 1 == packet.limit) {
            startPacket(packet.id);
        }
    }

    // 追加押金
    function addDeposit(uint256 _deposit) external returns (uint256 deposit) {
        initUser();
        User memory userInfo = userMap[msg.sender];
        _receiveTokens(_deposit);
        userMap[msg.sender].deposit = userInfo.deposit + _deposit;

        return userMap[msg.sender].deposit;
    }

    function getDeposit() external view returns (uint256 deposit) {
        return userMap[msg.sender].deposit;
    }

    // 初始化个人信息
    function initUser() public payable returns () {
        if(userMap[msg.sender].exist){
            return
        }
        userMap[msg.sender] = User(0, false, true,true, address(0));
    }

    // 开始抢红包
    function startPacket(uint256 _id) public returns (uint256 requestId) {
        Packet memory packet = getPacket(_id);
        if (!packet.exist) {
            revert NO_PACKET("startPacket");
        }
        if (packet.users.length != packet.limit) {
            revert NOT_ENOUGH_USER("startPacket");
        }
        requestId = requestRandomWords();
        requestIdToPacketId[requestId] = _id;
        return requestId;
    }

    // VRF回调，继续抢红包
    function continuePacket(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal {
        uint256 id = requestIdToPacketId[_requestId];
        Packet memory packet = getPacket(id);
        // 按照随机数字获取百分比然后获取每个用户分到的amount
        uint256[] memory amounts = getCountByPercent(
            _randomWords,
            packet.amount
        );
    }

    function withdrawalDeposit(uint256 deposit) public {
        _extractTokens(deposit);
    }

    // 合约拥有者可以提取合约余额
    function withdrawContractBalance() public {
        // require(
        //     msg.sender == owner,
        //     "Only the owner can withdraw contract balance"
        // );
        // payable(owner).transfer(address(this).balance);
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
