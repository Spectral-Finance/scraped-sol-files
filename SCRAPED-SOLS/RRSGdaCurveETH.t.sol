// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {RouterRobustSwap} from "../base/RouterRobustSwap.sol";
import {UsingGdaCurve} from "../mixins/UsingGdaCurve.sol";
import {UsingETH} from "../mixins/UsingETH.sol";

contract RRSGdaCurveETHTest is RouterRobustSwap, UsingGdaCurve, UsingETH {}
