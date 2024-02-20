// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICryptoPunks {
    function balanceOf(address owner) external view returns (uint256);

    function buyPunk(uint256 punkIndex) external payable;

    function punkIndexToAddress(uint256 punkIndex) external view returns (address);

    function transferPunk(address to, uint256 punkIndex) external;
}
