// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// 引入 ERC-20 接口
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MultiTokenReceiver {
    // 存储合约管理者的地址
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // 以太币存款函数
    receive() external payable {}

    // 接收 ERC-20 代币的存款
    function depositToken(address tokenAddress, uint256 amount) public {
        // 确保只有合约管理者可以调用此函数
        require(msg.sender == owner, "Only owner can deposit tokens");

        // 使用 ERC-20 接口转移代币到合约地址
        IERC20 token = IERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
    }

    // 提取 ERC-20 代币
    function withdrawToken(address tokenAddress, uint256 amount) public {
        // 确保只有合约管理者可以调用此函数
        require(msg.sender == owner, "Only owner can withdraw tokens");

        // 使用 ERC-20 接口将代币转移到合约管理者地址
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(owner, amount), "Token transfer failed");
    }

    // 获取合约中指定 ERC-20 代币的余额
    function getTokenBalance(address tokenAddress) public view returns (uint256) {
        IERC20 token = IERC20(tokenAddress);
        return token.balanceOf(address(this));
    }
}