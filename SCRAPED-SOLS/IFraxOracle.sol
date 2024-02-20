// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

interface IFraxOracle {
    function BASE_TOKEN() external view returns (address);

    function QUOTE_TOKEN() external view returns (address);

    function acceptTransferTimelock() external;

    function addRoundData(bool _isBadData, uint104 _priceLow, uint104 _priceHigh, uint40 _timestamp) external;

    function decimals() external pure returns (uint8 _decimals);

    function description() external view returns (string memory);

    function getPrices() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function lastCorrectRoundId() external view returns (uint80);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function maximumDeviation() external view returns (uint256);

    function maximumOracleDelay() external view returns (uint256);

    function pendingTimelockAddress() external view returns (address);

    function priceSource() external view returns (address);

    function renounceTimelock() external;

    function rounds(
        uint256
    ) external view returns (uint104 priceLow, uint104 priceHigh, uint40 timestamp, bool isBadData);

    function setMaximumDeviation(uint256 _newMaxDeviation) external;

    function setMaximumOracleDelay(uint256 _newMaxOracleDelay) external;

    function setPriceSource(address _newPriceSource) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function timelockAddress() external view returns (address);

    function transferTimelock(address _newTimelock) external;

    function version() external view returns (uint256 _version);
}
