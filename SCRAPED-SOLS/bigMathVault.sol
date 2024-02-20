// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import { BigMathMinified } from "./bigMathMinified.sol";

/// @title Extended version of BigMathMinified. Implements functions for normal operators (*, /, etc) modified to interact with big numbers.
/// @notice this is an optimized version mainly created by taking Fluid vault's codebase into consideration so it's use is limited for other cases.
library BigMathVault {
    uint private constant COEFFICIENT_SIZE_DEBT_FACTOR = 35;
    uint private constant EXPONENT_SIZE_DEBT_FACTOR = 15;
    uint private constant COEFFICIENT_MAX_DEBT_FACTOR = (1 << COEFFICIENT_SIZE_DEBT_FACTOR) - 1;
    uint private constant EXPONENT_MAX_DEBT_FACTOR = (1 << EXPONENT_SIZE_DEBT_FACTOR) - 1;
    uint private constant DECIMALS_DEBT_FACTOR = 16384;
    uint internal constant MAX_MASK_DEBT_FACTOR = (1 << (COEFFICIENT_SIZE_DEBT_FACTOR + EXPONENT_SIZE_DEBT_FACTOR)) - 1;

    // Having precision as 2**64 on vault
    uint internal constant PRECISION = 64;
    uint internal constant TWO_POWER_64 = 1 << PRECISION;
    // Max bit for 35 bits * 35 bits number will be 70
    uint internal constant TWO_POWER_69_MINUS_1 = (1 << 69) - 1;

    uint private constant COEFFICIENT_PLUS_PRECISION = COEFFICIENT_SIZE_DEBT_FACTOR + PRECISION;
    uint private constant TWO_POWER_COEFFICIENT_PLUS_PRECISION_MINUS_1 = (1 << (COEFFICIENT_PLUS_PRECISION - 1)) - 1;
    uint private constant COEFFICIENT_PLUS_PRECISION_MINUS_1 = COEFFICIENT_PLUS_PRECISION - 1;
    uint private constant TWO_POWER_COEFFICIENT_PLUS_PRECISION_MINUS_1_MINUS_1 =
        (1 << (COEFFICIENT_PLUS_PRECISION_MINUS_1 - 1)) - 1;

    /// @dev multiplies a `normal` number with a `bigNumber1` and then divides by `bigNumber2`.
    /// @dev Coefficient of bigNumbers are always 35bit number which means that they are in range 17179869184 <= coefficnet <= 34359738367.
    /// @dev bigNumber2 always > bigNumber1.
    /// e.g.
    /// res = normal * bigNumber1 / bigNumber2
    /// normal:  normal number 281474976710656
    /// bigNumber1: bigNumber 265046402172 [(0011,1101,1011,0101,1111,1111,0010,0100)Coefficient, (0111,1100)Exponent]
    /// bigNumber2: bigNumber 178478830197 [(0010 1001 1000 1110 0010 1010 1101 0010)Coefficient, (0111 0101)Exponent
    /// @return normal number 53503841411969141
    function mulDivNormal(uint256 normal, uint256 bigNumber1, uint256 bigNumber2) internal pure returns (uint256) {
        unchecked {
            // For vault, bigNumber2 always > bigNumber1.
            // exponent2_ - exponent1_
            uint netExponent_ = (bigNumber2 & EXPONENT_MAX_DEBT_FACTOR) - (bigNumber1 & EXPONENT_MAX_DEBT_FACTOR);
            if (netExponent_ < 129) {
                // (normal * coefficient1_) / (coefficient2_ << netExponent_);
                return ((normal * (bigNumber1 >> EXPONENT_SIZE_DEBT_FACTOR)) /
                    ((bigNumber2 >> EXPONENT_SIZE_DEBT_FACTOR) << netExponent_));
            }
            return 0;
        }
    }

    /// @dev multiplies a `bigNumber` with normal `number1` and then divides by  `TWO_POWER_64`.
    /// @dev number1 must be always > 0
    /// @param bigNumber Coefficient | Exponent. Coefficient is always 35bit number which means that is in range 17179869184 <= coefficnet <= 34359738367.
    /// @param number1 normal number. For vault's use case. This will always be < TWO_POWER_64
    /// @return result bigNumber * number1 / TWO_POWER_64. number1 is intialized as TWO_POWER_64 and reduce from there, hence it's less than TWO_POWER_64.
    function mulDivBigNumber(uint256 bigNumber, uint256 number1) internal pure returns (uint256 result) {
        // using unchecked as we are only at 1 place in Vault and it won't overflow there.
        unchecked {
            uint256 _resultNumerator = (bigNumber >> EXPONENT_SIZE_DEBT_FACTOR) * number1;
            // 99% chances are that most sig bit should be 64 + 35 - 1 or 64 + 35 - 2
            // diff = mostSigBit
            uint256 diff = (_resultNumerator > TWO_POWER_COEFFICIENT_PLUS_PRECISION_MINUS_1)
                ? COEFFICIENT_PLUS_PRECISION
                : (_resultNumerator > TWO_POWER_COEFFICIENT_PLUS_PRECISION_MINUS_1_MINUS_1)
                ? COEFFICIENT_PLUS_PRECISION_MINUS_1
                : BigMathMinified.mostSignificantBit(_resultNumerator);

            // diff = difference in bits to make the _resultNumerator 35 bits again
            diff = diff - COEFFICIENT_SIZE_DEBT_FACTOR;
            _resultNumerator = _resultNumerator >> diff;
            // starting exponent is 16384, so exponent should never get 0 here
            result =
                (_resultNumerator << EXPONENT_SIZE_DEBT_FACTOR) +
                (bigNumber & EXPONENT_MAX_DEBT_FACTOR) +
                diff -
                PRECISION; // + exponent
        }
    }

    /// @dev multiplies a `bigNumber1` with another `bigNumber2`.
    /// @dev sum of exponents from `bigNumber1` `bigNumber2` should be > 16384.
    /// e.g. res = bigNumber1 * bigNumber2 = [(coe1, exp1) * (coe2, exp2)] >> decimal
    ///          = (coe1*coe2>>overflow, exp1+exp2+overflow-decimal)
    /// @param bigNumber1          BigNumber format with coefficient and exponent. Coefficient is always 35bit number which means that is in range 17179869184 <= coefficnet <= 34359738367.
    /// @param bigNumber2          BigNumber format with coefficient and exponent. Coefficient is always 35bit number which means that is in range 17179869184 <= coefficnet <= 34359738367.
    /// @return                    BigNumber format with coefficient and exponent
    function mulBigNumber(uint256 bigNumber1, uint256 bigNumber2) internal pure returns (uint256) {
        unchecked {
            // coefficient1_ * coefficient2_
            uint resCoefficient_ = (bigNumber1 >> EXPONENT_SIZE_DEBT_FACTOR) *
                (bigNumber2 >> EXPONENT_SIZE_DEBT_FACTOR);
            uint overflowLen_ = resCoefficient_ > TWO_POWER_69_MINUS_1
                ? COEFFICIENT_SIZE_DEBT_FACTOR
                : COEFFICIENT_SIZE_DEBT_FACTOR - 1;
            resCoefficient_ = resCoefficient_ >> overflowLen_;

            // bigNumber2 is connection factor
            // exponent1_ + exponent2_ + overflowLen_ - decimals
            uint resExponent_ = ((bigNumber1 & EXPONENT_MAX_DEBT_FACTOR) +
                (bigNumber2 & EXPONENT_MAX_DEBT_FACTOR) +
                overflowLen_) - DECIMALS_DEBT_FACTOR;

            // if resExponent_ is not within limits that means user's got ~100% (something like 99.999999999999...)
            if (resExponent_ <= EXPONENT_MAX_DEBT_FACTOR) {
                return ((resCoefficient_ << EXPONENT_SIZE_DEBT_FACTOR) | resExponent_);
            }

            // this situation will probably never happen and this basically means user's position is ~100% liquidated
            return MAX_MASK_DEBT_FACTOR;
        }
    }

    /// @dev divides a `bigNumber1` by `bigNumber2`.
    /// e.g. res = bigNumber1 / bigNumber2 = [(coe1, exp1) / (coe2, exp2)] << decimal
    ///          = ((coe1<<precision_)/coe2, exp1+decimal-exp2-precision_)
    /// @param bigNumber1          BigNumber format with coefficient and exponent. Coefficient is always 35bit number which means that is in range 17179869184 <= coefficnet <= 34359738367.
    /// @param bigNumber2          BigNumber format with coefficient and exponent. Coefficient is always 35bit number which means that is in range 17179869184 <= coefficnet <= 34359738367.
    /// @return                    BigNumber format with coefficient and exponent
    function divBigNumber(uint256 bigNumber1, uint256 bigNumber2) internal pure returns (uint256) {
        unchecked {
            // (coefficient1_ << PRECISION) / coefficient2_
            uint256 resCoefficient_ = ((bigNumber1 >> EXPONENT_SIZE_DEBT_FACTOR) << PRECISION) /
                (bigNumber2 >> EXPONENT_SIZE_DEBT_FACTOR);

            // mostSigBit will be PRECISION + 1 or PRECISION
            uint256 overflowLen_ = ((resCoefficient_ >> PRECISION) == 1) ? (PRECISION + 1) : PRECISION;
            // Overflow will be PRECISION - COEFFICIENT_SIZE_DEBT_FACTOR or (PRECISION - 1) - COEFFICIENT_SIZE_DEBT_FACTOR
            // Meaning 64 - 35 = 29 or 64 - 35 - 1 = 28
            overflowLen_ = overflowLen_ - COEFFICIENT_SIZE_DEBT_FACTOR;
            resCoefficient_ = resCoefficient_ >> overflowLen_;

            // exponent1_ will always be less than or equal to 16384
            // exponent2_ will always be less than or equal to 16384
            // Even if exponent2_ is 0 (not possible) & resExponent_ = DECIMALS_DEBT_FACTOR then also resExponent_ will be less than max limit, so no overflow
            // (exponent1_ + DECIMALS_DEBT_FACTOR + overflowLen_) - (exponent2_ + PRECISION);
            uint256 resExponent_ = ((bigNumber1 & EXPONENT_MAX_DEBT_FACTOR) + // exponent1_
                DECIMALS_DEBT_FACTOR +
                overflowLen_) - ((bigNumber2 & (EXPONENT_MAX_DEBT_FACTOR)) + PRECISION); // exponent2_

            return ((resCoefficient_ << EXPONENT_SIZE_DEBT_FACTOR) | resExponent_);
        }
    }
}
