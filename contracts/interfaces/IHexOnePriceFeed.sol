// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

interface IHexOnePriceFeed {

    function setPriceFeed(address _baseToken, address _priceFeed) external;

    function getBaseTokenPrice(address _baseToken, uint256 _amount) external view returns (uint256);
}