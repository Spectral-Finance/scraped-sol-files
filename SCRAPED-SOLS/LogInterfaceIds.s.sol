// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "frax-std/BaseScript.sol";
import "frax-std/FraxTest.sol";
import "src/interfaces/oracles/abstracts/IUniswapV3SingleTwapOracle.sol";
import "src/interfaces/oracles/abstracts/ICurvePoolVirtualPriceOracleWithMinMax.sol";
import "src/interfaces/oracles/abstracts/ICurvePoolEmaPriceOracleWithMinMax.sol";
import "src/interfaces/oracles/abstracts/IChainlinkOracleWithMaxDelay.sol";
import "src/interfaces/oracles/abstracts/IEthUsdChainlinkOracleWithMaxDelay.sol";

contract LogInterfaceIds is BaseScript {
    function run() public {
        console.log("IUniswapV3SingleTwapOracle: ");
        console.logBytes4(type(IUniswapV3SingleTwapOracle).interfaceId);
        console.log("ICurvePoolVirtualPriceOracleWithMinMax: ");
        console.logBytes4(type(ICurvePoolVirtualPriceOracleWithMinMax).interfaceId);
        console.log("ICurvePoolEmaPriceOracleWithMinMax: ");
        console.logBytes4(type(ICurvePoolEmaPriceOracleWithMinMax).interfaceId);
        console.log("IChainlinkOracleWithMinMaxDelay: ");
        console.logBytes4(type(IChainlinkOracleWithMaxDelay).interfaceId);
        console.log("IChainlinkOracleWithMinMaxDelay: ");
        console.logBytes4(type(IEthUsdChainlinkOracleWithMaxDelay).interfaceId);
    }
}
