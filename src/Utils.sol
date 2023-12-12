// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

abstract contract Utils {
    // 设置percent的精确度，越大越精确
    uint64 private decimal = 10000;

    // 计算随机数的百分比
    function calculatePercentages(
        uint256[] memory _randomWords
    ) public view returns (uint256[] memory) {
        uint256[] memory percentages = new uint256[](_randomWords.length);
        uint256 total = 0;

        // 计算总和
        for (uint256 i = 0; i < _randomWords.length; i++) {
            total += _randomWords[i] / decimal;
        }

        // 计算百分比
        for (uint256 i = 0; i < _randomWords.length; i++) {
            percentages[i] = (_randomWords[i]) / total;
        }

        return percentages;
    }

    function getCountByPercent(
        uint256[] memory _randomWords,
        uint256 _amount
    ) public view returns (uint256[] memory) {
        uint256[] memory percentages = calculatePercentages(_randomWords);
        uint256[] memory amounts = new uint256[](percentages.length);
        // 计算总和
        for (uint256 i = 0; i < percentages.length; i++) {
            uint256 percentage = percentages[i];
            amounts[i] = (_amount * percentage) / decimal;
        }
        return amounts;
    }

    // 生成唯一id
    function generateUniqueID() public view returns (uint256) {
        return
            uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
    }
}
