// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract RedPacket {
    uint256 private total;
    mapping(address => User) private userMap;
    mapping(address => Packet) private packetMap;

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
    }

    struct RandomArrayResult {
        uint256[] array;
        uint256 maxIndex;
    }

    // 获取发起人对应的钱包
    function getPacket(address _creator) public view returns (Packet memory) {
        Packet memory currentPacket = packetMap[_creator];
        if (currentPacket.amount <= 0) {
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
        packet = Packet(_amount, false, 0, _limit, _length, users, msg.sender);
        packetMap[msg.sender] = packet;
        return packet;
    }

    // 参与到红包中
    function attendPacket(address _creator) external returns (bool success) {
        Packet memory packet = packetMap[_creator];
        if (packet.amount <= 0) {
            revert NO_PACKET("attendPacket");
        }

        packetMap[_creator].users.push(msg.sender);
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
    function initUser(uint256 _deposit) public payable returns (uint256 count) {
        userMap[msg.sender] = User(_deposit, false, true);
        return _deposit;
    }

    function startPacket(
        address _creator
    ) public payable returns (uint256 count) {
        Packet memory packet = getPacket(_creator);
        if (packet.amount <= 0) {
            revert NO_PACKET("startPacket");
        }
        if (packet.users.length != packet.length) {
            revert NOT_ENOUGH_USER("startPacket");
        }
        (uint256[] memory numbers, uint256 index) = generateFairRandomArray(
            packet.length,
            packet.amount
        );

        // 
        for (uint256 i = 0; i < numbers.length; i++) {
            uint256 number = numbers[i];
            address userAddress = packet.users[i];
            User memory user = userMap[userAddress];
            if (!user.active) {
                revert NO_USER("startPacket");
            }
            // 将红包的钱分给用户账户中
            userMap[userAddress].deposit =
                userMap[userAddress].deposit +
                number;
                
        }

        return 8;
    }

    function withdrawalDeposit() external returns (uint256 currentDeposit) {}

    function generateFairRandomArray(
        uint256 length,
        uint256 totalSum
    ) public view returns (uint256[] memory, uint256) {
        require(length > 0, "Length must be greater than 0");
        require(
            totalSum >= length,
            "Total sum must be greater than or equal to length"
        );

        uint256[] memory fairRandomArray = new uint256[](length);

        // 初始化数组，填充从 1 到 length-1 的整数
        uint256 sum = 0;
        for (uint256 i = 0; i < length - 1; i++) {
            fairRandomArray[i] = i + 1;
            sum += i + 1;
        }

        // 最后一个元素的值设置为总和减去当前总和
        fairRandomArray[length - 1] = totalSum - sum;

        // 使用 Fisher-Yates 洗牌算法对数组进行随机化
        for (uint256 i = length - 1; i > 0; i--) {
            uint256 j = uint256(
                keccak256(abi.encodePacked(block.timestamp, i))
            ) % (i + 1);
            (fairRandomArray[i], fairRandomArray[j]) = (
                fairRandomArray[j],
                fairRandomArray[i]
            );
        }

        // 查找最大数的索引
        uint256 maxIndex = 0;
        for (uint256 i = 1; i < length; i++) {
            if (fairRandomArray[i] > fairRandomArray[maxIndex]) {
                maxIndex = i;
            }
        }

        return (fairRandomArray, maxIndex);
    }
}
