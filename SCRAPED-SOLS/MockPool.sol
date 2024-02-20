// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import { ReserveConfiguration } from "aave-v3-core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol";
import { DataTypes }            from "aave-v3-core/contracts/protocol/libraries/types/DataTypes.sol";

import { MockToken } from "./MockToken.sol";

contract MockPool {

    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    /**********************************************************************************************/
    /*** Declarations and Constructor                                                           ***/
    /**********************************************************************************************/

    MockToken public aToken;
    MockToken public debtToken;

    uint256 public liquidityIndex;
    uint256 public accruedToTreasury;

    uint256 public supplyCap;
    uint256 public borrowCap;

    constructor() {
        aToken    = new MockToken();
        debtToken = new MockToken();
    }

    /**********************************************************************************************/
    /*** Pool Functions                                                                         ***/
    /**********************************************************************************************/

    function getReserveData(address) external view returns (DataTypes.ReserveData memory) {
        DataTypes.ReserveConfigurationMap memory configuration
            = DataTypes.ReserveConfigurationMap(0);

        configuration.setBorrowCap(borrowCap);
        configuration.setSupplyCap(supplyCap);

        return DataTypes.ReserveData({
            configuration:               configuration,
            liquidityIndex:              uint128(liquidityIndex),
            currentLiquidityRate:        uint128(0),
            variableBorrowIndex:         uint128(0),
            currentVariableBorrowRate:   uint128(0),
            currentStableBorrowRate:     uint128(0),
            lastUpdateTimestamp:         uint40(0),
            id:                          uint16(0),
            aTokenAddress:               address(aToken),
            stableDebtTokenAddress:      address(0),
            variableDebtTokenAddress:    address(debtToken),
            interestRateStrategyAddress: address(0),
            accruedToTreasury:           uint128(accruedToTreasury),
            unbacked:                    uint128(0),
            isolationModeTotalDebt:      uint128(0)
        });
    }

    /**********************************************************************************************/
    /*** Mock Functions                                                                         ***/
    /**********************************************************************************************/

    function __setSupplyCap(uint256 _supplyCap) external {
        supplyCap = _supplyCap;
    }

    function __setBorrowCap(uint256 _borrowCap) external {
        borrowCap = _borrowCap;
    }

    function __setATokenScaledTotalSupply(uint256 _aTokenScaledTotalSupply) external {
        aToken.__setScaledTotalSupply(_aTokenScaledTotalSupply);
    }

    function __setTotalDebt(uint256 _totalDebt) external {
        debtToken.__setTotalSupply(_totalDebt);
    }

    function __setLiquidityIndex(uint256 _liquidityIndex) external {
        liquidityIndex = _liquidityIndex;
    }

    function __setAccruedToTreasury(uint256 _accruedToTreasury) external {
        accruedToTreasury = _accruedToTreasury;
    }

}
