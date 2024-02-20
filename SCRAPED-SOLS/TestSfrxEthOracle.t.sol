// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "src/_v1/SfrxEthOracle.sol";
import "src/interfaces/IFrxEthStableSwap.sol";
import "./BaseOracleTest.t.sol";
import { Mainnet as Constants_Mainnet, Arbitrum as Constants_Arbitrum } from "src/Constants.sol";

contract SfrxEthOracleTest is TestHelper {
    //Test oracle returns correct price
    SfrxEthOracle sfraxEthOracle;

    // These represent the true values for expected Price calculations
    uint256 chainlinkPrice;
    uint256 emaPrice;
    uint256 stakerPrice;

    // these are values from storage mostly immutables
    ISfrxEth public staker;
    uint256 public stakingPricePrecision;
    IFrxEthStableSwap public pool;
    AggregatorV3Interface public chainlinkFeed;
    uint8 public chainlinkFeedDecimals;
    uint256 public emaPrecision;
    uint256 public emaMax;
    string public description;
    uint8 public decimals;
    string public name;
    uint256 public version;

    function setUp() public {
        string memory _envKey = vm.envString("MAINNET_URL");
        vm.createSelectFork(_envKey, 16_451_985);

        // deploy new pair, once deployed replace with actual address
        sfraxEthOracle = new SfrxEthOracle(Constants_Mainnet.TIMELOCK_ADDRESS, 9e17);
        (, int256 _chainlinkPrice, , , ) = AggregatorV3Interface(sfraxEthOracle.chainlinkFeed()).latestRoundData();
        chainlinkPrice = uint256(_chainlinkPrice);
        emaPrice = IFrxEthStableSwap(sfraxEthOracle.pool()).price_oracle();
        stakerPrice = ISfrxEth(sfraxEthOracle.staker()).pricePerShare();
        // _chainlinkPrice 1653.17931000 (165317931000)
        // _emaPrice 0.999494919116874646 (999494919116874646)
        // _stakerPrice 1.016965311876064076 (1016965311876064076)

        staker = sfraxEthOracle.staker();
        stakingPricePrecision = sfraxEthOracle.stakingPricePrecision();
        pool = sfraxEthOracle.pool();
        chainlinkFeed = sfraxEthOracle.chainlinkFeed();
        chainlinkFeedDecimals = sfraxEthOracle.chainlinkFeedDecimals();
        emaPrecision = sfraxEthOracle.emaPrecision();
        emaMax = sfraxEthOracle.emaMax();
        description = sfraxEthOracle.description();
        decimals = sfraxEthOracle.decimals();
        name = sfraxEthOracle.name();
        version = sfraxEthOracle.version();
    }

    function _expectedPrice() internal view returns (uint256 _expectedPrice) {
        _expectedPrice =
            (((chainlinkPrice * 10 ** decimals) / 10 ** chainlinkFeedDecimals) * emaPrice * stakerPrice) /
            (emaPrecision * stakingPricePrecision);
    }

    function testGetPrice() public {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = sfraxEthOracle
            .latestRoundData();
        assertEq(uint256(answer), _expectedPrice());
    }

    function _assertMinWorks() internal {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = sfraxEthOracle
            .latestRoundData();

        // We assume emaPrice will be bound to min
        emaPrice = sfraxEthOracle.emaMin();
        assertEq(uint256(answer), _expectedPrice(), "When frxEth price below minimum, minimum ema used");
    }

    function testGetPriceLtMin() public {
        vm.mockCall(
            Constants_Mainnet.FRXETH_ETH_CURVE_POOL_NOT_LP,
            abi.encodeWithSelector(IFrxEthStableSwap.price_oracle.selector),
            abi.encode(uint256(1e17))
        );

        _assertMinWorks();
    }

    function testGetPriceLtMinSell() public {
        IFrxEthStableSwap _pool = IFrxEthStableSwap(Constants_Mainnet.FRXETH_ETH_CURVE_POOL_NOT_LP);
        address user1 = address(144_438_484);
        faucetFunds(IERC20(Constants_Mainnet.FRXETH_ERC20), 50_000_000e18, user1);
        uint256 _initialPrice = _pool.price_oracle();
        Logger.decimal("_initialPrice", _initialPrice, 1e18);

        startHoax(user1);
        IERC20(Constants_Mainnet.FRXETH_ERC20).approve(
            Constants_Mainnet.FRXETH_ETH_CURVE_POOL_NOT_LP,
            type(uint256).max
        );
        uint256 _out = _pool.exchange(1, 0, 10_000_000e18, 0);
        mineBlocks(150);
        _pool.exchange(1, 0, 10_000_000e18, 0);
        mineBlocks(150);
        _pool.exchange(1, 0, 10_000_000e18, 0);
        mineBlocks(150);
        _pool.exchange(1, 0, 10_000_000e18, 0);
        mineBlocks(150);
        _pool.exchange(1, 0, 10_000_000e18, 0);

        Logger.decimal("_finalPrice  ", _pool.price_oracle(), 1e18);

        // Because so many blocks have passed in this test, overwrite the "expected values" with the latest
        stakerPrice = ISfrxEth(sfraxEthOracle.staker()).pricePerShare();
        (, int256 _chainlinkPrice, , , ) = AggregatorV3Interface(sfraxEthOracle.chainlinkFeed()).latestRoundData();
        chainlinkPrice = uint256(_chainlinkPrice);
        _assertMinWorks();
    }

    function testCanSetMin() public {
        startHoax(Constants_Mainnet.TIMELOCK_ADDRESS);
        sfraxEthOracle.setEmaMin(5e17);
        vm.mockCall(
            Constants_Mainnet.FRXETH_ETH_CURVE_POOL_NOT_LP,
            abi.encodeWithSelector(IFrxEthStableSwap.price_oracle.selector),
            abi.encode(uint256(1e17))
        );
        vm.stopPrank();
        _assertMinWorks();
    }

    function testCannotChangeMin() public {
        vm.expectRevert(Timelock2Step.OnlyTimelock.selector);
        sfraxEthOracle.setEmaMin(5e17);
    }

    function testGetPriceGtMax() public {
        // We assume emaPrice will be bound to min
        emaPrice = sfraxEthOracle.emaMax();

        vm.mockCall(
            Constants_Mainnet.FRXETH_ETH_CURVE_POOL_NOT_LP,
            abi.encodeWithSelector(IFrxEthStableSwap.price_oracle.selector),
            abi.encode(uint256(11e17))
        );
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = sfraxEthOracle
            .latestRoundData();
        assertEq(uint256(answer), _expectedPrice(), "When frxEth price above maximum, maximum ema used");
    }

    function testGetPriceGtMaxSell() public {
        IFrxEthStableSwap _pool = IFrxEthStableSwap(Constants_Mainnet.FRXETH_ETH_CURVE_POOL_NOT_LP);
        address user1 = address(144_438_484);
        faucetFunds(IERC20(Constants_Mainnet.FRXETH_ERC20), 50_000_000e18, user1);
        uint256 _initialPrice = _pool.price_oracle();
        Logger.decimal("_initialPrice", _initialPrice, 1e18);

        startHoax(user1);
        // IERC20(Constants_Mainnet.FRXETH_ERC20).approveConstants_Mainnet.FRXETH_ETH_CURVE_POOL_NOT_LP, type(uint256).max);
        uint256 _out = _pool.exchange{ value: 10_000e18 }(0, 1, 10_000e18, 0);
        mineBlocks(150);
        _pool.exchange{ value: 10_000e18 }(0, 1, 10_000e18, 0);
        mineBlocks(150);
        _pool.exchange{ value: 10_000e18 }(0, 1, 10_000e18, 0);
        mineBlocks(150);
        _pool.exchange{ value: 10_000e18 }(0, 1, 10_000e18, 0);

        Logger.decimal("_finalPrice  ", _pool.get_p(), 1e18);
        Logger.decimal("_finalPrice  ", _pool.price_oracle(), 1e18);

        // Because so many blocks have passed in this test, overwrite the "expected values" with the latest
        stakerPrice = ISfrxEth(sfraxEthOracle.staker()).pricePerShare();
        (, int256 _chainlinkPrice, , , ) = AggregatorV3Interface(sfraxEthOracle.chainlinkFeed()).latestRoundData();
        chainlinkPrice = uint256(_chainlinkPrice);
        // We assume emaPrice will be bound to min
        emaPrice = sfraxEthOracle.emaMax();

        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = sfraxEthOracle
            .latestRoundData();
        assertEq(uint256(answer), _expectedPrice(), "When frxEth price above maximum, maximum ema used");
    }
}
