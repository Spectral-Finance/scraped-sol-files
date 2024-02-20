//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { BigMathUnsafe } from "../../../../contracts/libraries/bigMathUnsafe.sol";
import { BigMathVault } from "../../../../contracts/libraries/bigMathVault.sol";
import { BigMathTolerance } from "./bigMathTolerance.sol";
import { BigMathTestHelper } from "./bigMathTestHelper.sol";
import { BigMathVaultTestHelper } from "./bigMathVaultTestHelper.sol";
import { BigMathTolerance } from "./bigMathTolerance.sol";
import { BigMathVaultTolerance } from "./bigMathVaultTolerance.sol";

contract LibraryBigMathBaseTest is Test {
    // use testHelper contract to measure gas for library methods via forge --gas-report
    BigMathTestHelper testHelper;
    BigMathVaultTestHelper testVaultHelper;

    function setUp() public {
        testHelper = new BigMathTestHelper();
        testVaultHelper = new BigMathVaultTestHelper();
    }
}

contract LibraryBigMathVaultTest is LibraryBigMathBaseTest {
    uint256 COEFFICIENT_SIZE_DEBT_FACTOR = 35;
    uint256 EXPONENT_SIZE_DEBT_FACTOR = 15;
    uint256 EXPONENT_MAX_DEBT_FACTOR = (1 << EXPONENT_SIZE_DEBT_FACTOR) - 1;
    uint256 DECIMALS_DEBT_FACTOR = 16384;
    uint256 TWO_POWER_69_MINUS_1 = (1 << 69) - 1;
    uint256 MAX_MASK_DEBT_FACTOR = (1 << (COEFFICIENT_SIZE_DEBT_FACTOR + EXPONENT_SIZE_DEBT_FACTOR)) - 1;
    uint256 COEFFICIENT_MAX = (1 << 35) - 1;
    uint256 COEFFICIENT_MIN = (1 << 34);
    uint256 EXPONENT_MAX = (1 << 15) - 1;

    uint8 DEFAULT_COEFFICIENT_SIZE = 56;
    uint8 DEFAULT_EXPONENT_SIZE = 8;
    uint256 DEFAULT_EXPONENT_MASK = 0xFF;

    uint PRECISION = 64;
    uint TWO_POWER_64 = 1 << PRECISION;

    // ===== mulDivNormal ====

    function test_mulDivNormal_NormalIsZero() public {
        uint256 normal1 = 0;
        // COEFFICIENT_MIN = (1 << 34)
        uint256 bigNumber1 = (COEFFICIENT_MIN << 15) | 16384;
        // normal (from bigNumber1) =  coefficient * (2^(exponent - DECIMALS_DEBT_FACTOR))
        // normal =  17179869184 * (2^(16384 - 16384))
        // normal =  17179869184 * (2^(16384 - 16384))
        // normal =  17179869184

        // COEFFICIENT_MAX = (1 << 35) - 1
        uint256 bigNumber2 = (COEFFICIENT_MAX << 15) | 16384;
        // normal (from bigNumber2) =  coefficient * (2^(exponent - DECIMALS_DEBT_FACTOR))
        // normal =  34359738367 * (2^(16384 - 16384))
        // normal =  34359738367 * (2^(16384 - 16384))
        // normal =  34359738367
        uint256 result = testVaultHelper.mulDivNormal(normal1, bigNumber1, bigNumber2);
        // expected = normal1 * bigNumber1 / bigNumber2 = 0 * 17179869184 / 34359738367 = 0
        assertEq(result, 0);
    }

    function test_mulDivNormal_BigNumber1IsZero() public {
        uint256 normal1 = 17179869184;
        uint256 bigNumber1 = 0;
        // normal (from bigNumber1) =  coefficient * (2^(exponent - DECIMALS_DEBT_FACTOR))
        // normal =  17179869184 * (2^(16384 - 16384))
        // normal =  17179869184 * (2^(16384 - 16384))
        // normal =  17179869184

        // COEFFICIENT_MAX = (1 << 35) - 1
        uint256 bigNumber2 = (COEFFICIENT_MAX << 15) | 16384;
        // normal (from bigNumber2) =  coefficient * (2^(exponent - DECIMALS_DEBT_FACTOR))
        // normal =  34359738367 * (2^(16384 - 16384))
        // normal =  34359738367 * (2^(16384 - 16384))
        // normal =  34359738367
        uint256 result = testVaultHelper.mulDivNormal(normal1, bigNumber1, bigNumber2);
        // expected = normal1 * bigNumber1 / bigNumber2 = 0 * 17179869184 / 34359738367 = 0
        assertEq(result, 0);
    }

    function test_mulDivNormal_AllSameNumbers() public {
        // COEFFICIENT_MIN = (1 << 34)
        uint256 bigNumber1 = (COEFFICIENT_MIN << 15) | 16384;
        // normal (from bigNumber2)) =  coefficient * (2^(exponent - DECIMALS_DEBT_FACTOR))
        // normal =  17179869184 * (2^(16384 - 16384))
        // normal =  17179869184 * (2^(16384 - 16384))
        // normal =  17179869184
        uint256 normal1 = 17179869184;
        uint256 result = testVaultHelper.mulDivNormal(normal1, bigNumber1, bigNumber1);
        // expected = normal1 * bigNumber1 / bigNumber1 = 17179869184 * 17179869184 / 17179869184 = 17179869184
        // expected = 17179869184
        assertEq(result, 17179869184);

        uint256 normal2 = 34359738367;

        // COEFFICIENT_MAX = (1 << 35) - 1
        uint256 bigNumber2 = (COEFFICIENT_MAX << EXPONENT_SIZE_DEBT_FACTOR) | 16384;
        // normal (from bigNumber2) =  coefficient * (2^(exponent - DECIMALS_DEBT_FACTOR))
        // normal  =  34359738367  * (2^(16384 - 16384))
        // normal  =  34359738367
        uint256 result2 = testVaultHelper.mulDivNormal(normal2, bigNumber2, bigNumber2);
        // expected = normal2 * bigNumber2 / bigNumber2 = 34359738367 * 34359738367 / 34359738367 = 34359738367
        // expected = 34359738367
        // TODO: Here we loose 1 unit. Is that acceptable? 34359738366
        assertApproxEqAbs(result2, COEFFICIENT_MAX, 1);
    }

    function test_mulDivNormal_WithTheSmallestValueForFirstNumber() public {
        uint256 normal1 = 17179869184;
        uint256 bigNumber1 = (25769803775 << 15) | 16384;
        // normal (from bigNumber1) =  coefficient * (2^(exponent - DECIMALS_DEBT_FACTOR))
        // normal =  25769803775 * (2^(16384 - 16384))
        // normal =  25769803775 * (2^(16384 - 16384))
        // normal =  25769803775

        // COEFFICIENT_MAX = (1 << 35) - 1
        uint256 bigNumber2 = (COEFFICIENT_MAX << 15) | 16384;
        // normal (from bigNumber2) =  coefficient * (2^(exponent - DECIMALS_DEBT_FACTOR))
        // normal =  34359738367 * (2^(16384 - 16384))
        // normal =  34359738367 * (2^(16384 - 16384))
        // normal =  34359738367
        uint256 result = testVaultHelper.mulDivNormal(normal1, bigNumber1, bigNumber2);
        // expected = normal1 * bigNumber1 / bigNumber2 = 17179869184 * 25769803775 / 34359738367 = 1.28849018878749999999963620211928024079299299747197053504269 × 10^10
        // expected = 1.28849018878749999999963620211928024079299299747197053504269 × 10^10 = 12884901887
        assertEq(result, 12884901887);
    }

    function test_mulDivNormal_WithTheSmallestValueForSecondNumber() public {
        uint256 normal1 = 25769803775;

        // COEFFICIENT_MIN = (1 << 34)
        uint256 bigNumber1 = (COEFFICIENT_MIN << 15) | 16384;
        // normal (from bigNumber1) =  coefficient * (2^(exponent - DECIMALS_DEBT_FACTOR))
        // normal =  17179869184 * (2^(16384 - 16384))
        // normal =  17179869184 * (2^(16384 - 16384))
        // normal =  17179869184

        // COEFFICIENT_MAX = (1 << 35) - 1
        uint256 bigNumber2 = (COEFFICIENT_MAX << 15) | 16384;
        // normal (from bigNumber2) =  coefficient * (2^(exponent - DECIMALS_DEBT_FACTOR))
        // normal =  34359738367 * (2^(16384 - 16384))
        // normal =  34359738367 * (2^(16384 - 16384))
        // normal =  34359738367
        uint256 result = testVaultHelper.mulDivNormal(normal1, bigNumber1, bigNumber2);
        // expected = normal1 * bigNumber1 / bigNumber2 = 25769803775 * 17179869184 / 34359738367 = 1.28849018878749999999963620211928024079299299747197053504269 × 10^10
        // expected = 1.28849018878749999999963620211928024079299299747197053504269 × 10^10 = 12884901887
        assertEq(result, 12884901887);
    }

    // TODO: Commented as it takes a few minutes to finish.
    // function testFuzz_mulDivNormal_matchesJavascriptImpl(
    //     uint256 normal,
    //     uint256 coefficient1,
    //     uint256 exponent1,
    //     uint256 coefficient2,
    //     uint256 exponent2
    // ) public {
    //     // COEFFICIENT_MAX = (1 << 35) - 1
    //     // COEFFICIENT_MIN = (1 << 34)
    //     normal = bound(normal, 1, 1e18 - 1);
    //     coefficient1 = bound(coefficient1, COEFFICIENT_MIN, COEFFICIENT_MAX);
    //     exponent1 = bound(exponent1, (1 << 14), (1 << 15) - 1);
    //     coefficient2 = bound(coefficient2, COEFFICIENT_MIN, COEFFICIENT_MAX);
    //     exponent2 = bound(exponent2, (1 << 14), (1 << 15) - 1);
    //     vm.assume(normal > 0);
    //     vm.assume(coefficient2 > coefficient1);
    //     vm.assume(exponent2 >= exponent1);

    //     BigNumber memory bigNumber1 = BigNumber({ coefficient: coefficient1, exponent: exponent1 });
    //     BigNumber memory bigNumber2 = BigNumber({ coefficient: coefficient2, exponent: exponent2 });
    //     uint256 result = multiplyDivideNormal(normal, bigNumber1, bigNumber2);
    //     if (exponent2 - exponent1 < 129) {
    //         string[] memory runJsInputs = new string[](10);

    //         // Build FFI command string
    //         runJsInputs[0] = "npm";
    //         runJsInputs[1] = "--silent";
    //         runJsInputs[2] = "run";
    //         runJsInputs[3] = "forge-test-bigMathVault-mulDivNormal";

    //         // Add parameters to JavaScript script
    //         runJsInputs[4] = vm.toString(normal);
    //         runJsInputs[5] = vm.toString(bigNumber1.coefficient);
    //         runJsInputs[6] = vm.toString(bigNumber1.exponent);
    //         runJsInputs[7] = vm.toString(bigNumber2.coefficient);
    //         runJsInputs[8] = vm.toString(bigNumber2.exponent);
    //         runJsInputs[9] = vm.toString(result);

    //         // Call JavaScript script and get result
    //         bytes memory jsResult = vm.ffi(runJsInputs);
    //         bool isCorrect = abi.decode(jsResult, (bool));

    //         // Assert the result
    //         assertEq(isCorrect, true);
    //     } else {
    //         assertEq(result, 0);
    //     }
    // }

    function multiplyDivideNormal(
        uint256 normal,
        BigNumber memory bigNumber1,
        BigNumber memory bigNumber2
    ) internal returns (uint256) {
        // TODO change exponent

        (uint256 value1, bool success1) = BigMathTolerance.safeMultiply(bigNumber1.coefficient, 32768);
        (uint256 value2, bool success2) = BigMathTolerance.safeMultiply(bigNumber2.coefficient, 32768);
        require(success1 && success2, "Multiplication failed");

        uint256 bigNumberValue1 = value1 | bigNumber1.exponent;
        uint256 bigNumberValue2 = value2 | bigNumber2.exponent;
        uint256 mulDivResult = testVaultHelper.mulDivNormal(normal, bigNumberValue1, bigNumberValue2);

        // its normal number
        return mulDivResult;
    }

    // ===== mulDivBigNumber ====

    function test_mulDivBigNumber_MultiplicationOfSameBigNumber() public {
        // COEFFICIENT_MIN = (1 << 34)
        uint256 bigNumber1 = (COEFFICIENT_MIN << 15) | 16384;
        // normal1 =  coefficient * (2^(exponent - DECIMALS_DEBT_FACTOR))
        // normal1 =  17179869184 * (2^(16384 - 16384))
        // normal1 =  17179869184 * (2^(16384 - 16384))
        // normal1 =  17179869184
        uint256 bigNumber1Coefficient = bigNumber1 >> EXPONENT_SIZE_DEBT_FACTOR;
        uint256 bigNumber1Exponent = bigNumber1 & EXPONENT_MAX_DEBT_FACTOR;
        uint256 number1 = bigNumber1Coefficient * (2 ** (bigNumber1Exponent - DECIMALS_DEBT_FACTOR));
        uint256 result = testVaultHelper.mulDivBigNumber(bigNumber1, number1);
        // expected = normal1 * number1 / TWO_POWER_64 = 17179869184 * 17179869184 / 18446744073709551616 (TWO_POWER_64)
        // expected = 16
        uint256 coefficient = result >> EXPONENT_SIZE_DEBT_FACTOR;
        uint256 exponent = result & EXPONENT_MAX_DEBT_FACTOR;
        assertEq(coefficient, COEFFICIENT_MIN);
        assertEq(exponent, 16354);

        // coefficient * (2^(exponent - DECIMALS_DEBT_FACTOR))
        // 17179869184 * (2^(16354 - 16384)) = 16

        // COEFFICIENT_MAX = (1 << 35) - 1
        uint256 bigNumber2 = (COEFFICIENT_MAX << EXPONENT_SIZE_DEBT_FACTOR) | 16384;
        // normal2 =  coefficient * (2^(exponent - DECIMALS_DEBT_FACTOR))
        // normal2 =  34359738367  * (2^(16384 - 16384))
        // normal2 =  34359738367
        uint256 bigNumber2Coefficient = bigNumber2 >> EXPONENT_SIZE_DEBT_FACTOR;
        uint256 bigNumber2Exponent = bigNumber2 & EXPONENT_MAX_DEBT_FACTOR;
        uint256 number2 = bigNumber2Coefficient * (2 ** (bigNumber2Exponent - DECIMALS_DEBT_FACTOR));
        uint256 result2 = testVaultHelper.mulDivBigNumber(bigNumber2, number2);
        // expected = normal2 * number2 / TWO_POWER_64 = 34359738367 * 34359738367 / 18446744073709551616 (TWO_POWER_64)
        // expected = 63.999999996274709701592296046124275221700372640043497085571289062
        uint256 coefficient2 = result2 >> EXPONENT_SIZE_DEBT_FACTOR;
        uint256 exponent2 = result2 & EXPONENT_MAX_DEBT_FACTOR;
        assertEq(coefficient2, 34359738366);
        assertEq(exponent2, 16355);

        // coefficient * (2^(exponent - DECIMALS_DEBT_FACTOR))
        // 34359738366 * (2^(16355 - 16384)) = 63.9999999962747097015380859375
    }

    function test_mulDivBigNumber_MultiplicationOfDoubledBigNumber() public {
        // COEFFICIENT_MAX = (1 << 35) - 1
        uint256 bigNumber1 = (COEFFICIENT_MAX << EXPONENT_SIZE_DEBT_FACTOR) | 16384;
        //normal1 =
        // coefficient * (2^(exponent - DECIMALS_DEBT_FACTOR))
        // 34359738367 * (2^(16384 - 16384))
        // 34359738367
        uint256 bigNumber1Coefficient = bigNumber1 >> EXPONENT_SIZE_DEBT_FACTOR;
        uint256 bigNumber1Exponent = bigNumber1 & EXPONENT_MAX_DEBT_FACTOR;
        uint256 number1 = bigNumber1Coefficient * (2 ** (bigNumber1Exponent - DECIMALS_DEBT_FACTOR)) * 2; //multiplication by 2
        uint256 result = testVaultHelper.mulDivBigNumber(bigNumber1, number1);
        // expected = normal1 * number1 / TWO_POWER_64 = 34359738367 * 34359738367 * 2 / 18446744073709551616 (TWO_POWER_64)
        // expected = 127.99999999254941940318459209224855044340074528008699417114257812
        uint256 coefficient = result >> EXPONENT_SIZE_DEBT_FACTOR;
        uint256 exponent = result & EXPONENT_MAX_DEBT_FACTOR;

        // COEFFICIENT_MIN = (1 << 34)
        assertEq(coefficient, 34359738366);
        assertEq(exponent, 16356);
        // expected = 34359738366 * (2^(16356 - 16384)) = 127.999999992549419403076171875
    }

    function test_mulDivBigNumber_WithSmallerCoefficientOfDivisor() public {
        // COEFFICIENT_MAX = (1 << 35) - 1
        uint256 bigNumber1 = (COEFFICIENT_MAX << EXPONENT_SIZE_DEBT_FACTOR) | (1 << 14);
        // bigNumber1
        // coefficient1 = 34359738367 = ((1 << 35) - 1)
        // exponent1 = (1 << 14)
        // normal1 = coefficient * (2^(exponent - 16384))
        // normal1 = ((34359738367 * (2^((1 << 14) - 16384))
        // normal1 = 34359738367 * (2^(16384 - 16384))
        // normal1 = 34359738367
        uint256 normal2 = 17179869184;
        uint256 result = testVaultHelper.mulDivBigNumber(bigNumber1, normal2);
        // multiplication
        // normal1 * normal2 = 34359738367 * 17179869184 / TWO_POWER_64 = 590295810341525782528 / 18446744073709551616 = 31.999999999068677425384521484375
        uint256 coefficient = result >> EXPONENT_SIZE_DEBT_FACTOR;
        uint256 exponent = result & EXPONENT_MAX_DEBT_FACTOR;

        assertEq(coefficient, COEFFICIENT_MAX);
        assertEq(exponent, 16354);
        // 34359738367 * (2^(16354 - 16384)) = 31.999999999068677425384521484375
    }

    function test_mulDivBigNumber_WithSmallerExponentOfDivisor() public {
        // COEFFICIENT_MAX = (1 << 35) - 1
        uint256 bigNumber1 = (COEFFICIENT_MAX << EXPONENT_SIZE_DEBT_FACTOR) | (1 << 14);
        // bigNumber1
        // coefficient1 = 34359738367
        // exponent1 = (1 << 14)
        // normal1 = coefficient * (2^(exponent - 16384))
        // normal1 = (34359738367 * (2^((1 << 14) - 16384)) =
        // normal1 = 34359738367 * (2^(16384 - 16384)) = 34359738367
        uint256 number2 = 34359738367;
        uint256 result = testVaultHelper.mulDivBigNumber(bigNumber1, number2);
        uint256 coefficient = result >> EXPONENT_SIZE_DEBT_FACTOR;
        uint256 exponent = result & EXPONENT_MAX_DEBT_FACTOR;

        // normal1 * number2 / TWO_POWER_64 = 34359738367 * 34359738367 / 18446744073709551616 = 63.999999996274709701592296046124275221700372640043497085571289062

        // expected =>
        assertEq(coefficient, 34359738366);
        assertEq(exponent, 16355);
        // 34359738366 * (2^(16355 - 16384)) = 63.9999999962747097015380859375
    }

    function test_mulDivBigNumber_Basic1() public {
        // COEFFICIENT_MAX = (1 << 35) - 1
        uint256 bigNumber1 = (COEFFICIENT_MAX << EXPONENT_SIZE_DEBT_FACTOR) | (1 << 14);
        // bigNumber1
        // coefficient1 = (1 << 35) - 1
        // exponent1 = (1 << 14)
        // normal1 = coefficient * (2^(exponent - 16384))
        // normal1 = (((1 << 35) - 1) * (2^((1 << 14) - 16384)) =
        // normal1 = (34359738367 * (2^(16384 - 16384))
        // normal1 = 34359738367
        uint256 number2 = 25769803776;
        uint256 result = testVaultHelper.mulDivBigNumber(bigNumber1, number2);
        uint256 coefficient = result >> EXPONENT_SIZE_DEBT_FACTOR;
        uint256 exponent = result & EXPONENT_MAX_DEBT_FACTOR;

        // multiplication
        // normal1 * normal2 = 34359738367 * 25769803776 / TWO_POWER_64 = 885443715512288673792 / 18446744073709551616 = 47.9999999986030161380767822265625

        assertEq(coefficient, 25769803775);
        assertEq(exponent, 16355);
        // 25769803775 * (2^(16355 - 16384)) = 47.99999999813735485076904296875
    }

    function test_mulDivBigNumber_Basic2() public {
        // COEFFICIENT_MAX = (1 << 35) - 1
        uint256 bigNumber1 = (COEFFICIENT_MAX << EXPONENT_SIZE_DEBT_FACTOR) | ((1 << 14) - 2);
        // bigNumber1
        // coefficient1 = 34359738367
        // exponent1 = (1 << 14) + 2 = 16384 + 2
        // normal = coefficient * (2^(exponent - 16384))
        // normal = 34359738367 * (2^(16382 - 16384))
        // normal = 34359738367 * (2^(16382 - 16384))
        // normal = 8.58993459175 × 10^9
        uint256 number2 = 34359738367;
        uint256 result = testVaultHelper.mulDivBigNumber(bigNumber1, number2);
        // multiplication
        // normal*number2/TWO_POWER_64 = 8.58993459175 × 10^9 * 34359738367 / 18446744073709551616 =
        // 15.999999999068677425398074011531068805425093160010874271392822265
        uint256 coefficient = result >> EXPONENT_SIZE_DEBT_FACTOR;
        uint256 exponent = result & EXPONENT_MAX_DEBT_FACTOR;

        // expected = 34359738366 * (2^(16353 - 16384)) = 15.999999999068677425384521484375
        assertEq(coefficient, 34359738366);
        assertEq(exponent, 16353);
    }

    // TODO: Commented as it takes a few minutes to finish.
    // function testFuzz_mulDivBigNumber_matchesJavascriptImpl(
    //     uint256 coefficient1,
    //     uint256 exponent1,
    //     uint256 number2
    // ) public {
    //     // COEFFICIENT_MAX = (1 << 35) - 1
    //     // COEFFICIENT_MIN = (1 << 34)
    //     coefficient1 = bound(coefficient1, COEFFICIENT_MIN, COEFFICIENT_MAX);
    //     exponent1 = bound(exponent1, (1 << 14), (1 << 15) - 1);
    //     vm.assume(number2 > 0);
    //     vm.assume(number2 < 18446744073709551616);

    //     BigNumber memory bigNumber1 = BigNumber({ coefficient: coefficient1, exponent: exponent1 });
    //     BigNumber memory resultBigNumber = multiplyDivideBigNumbers(bigNumber1, number2);
    //     string[] memory runJsInputs = new string[](10);

    //     // Build FFI command string
    //     runJsInputs[0] = "npm";
    //     runJsInputs[1] = "--silent";
    //     runJsInputs[2] = "run";
    //     runJsInputs[3] = "forge-test-bigMathVault-mulDivBigNumber";

    //     // Add parameters to JavaScript script
    //     runJsInputs[4] = vm.toString(bigNumber1.coefficient);
    //     runJsInputs[5] = vm.toString(bigNumber1.exponent);
    //     runJsInputs[6] = vm.toString(number2);
    //     runJsInputs[7] = vm.toString(resultBigNumber.coefficient);
    //     runJsInputs[8] = vm.toString(resultBigNumber.exponent);

    //     // Call JavaScript script and get result
    //     bytes memory jsResult = vm.ffi(runJsInputs);
    //     bool isCorrect = abi.decode(jsResult, (bool));

    //     // Assert the result
    //     assertEq(isCorrect, true);
    // }

    function multiplyDivideBigNumbers(
        BigNumber memory bigNumber1,
        uint256 number2
    ) internal returns (BigNumber memory) {
        (uint256 value1, bool success1) = BigMathTolerance.safeMultiply(bigNumber1.coefficient, 32768);
        require(success1, "Multiplication failed");

        uint256 bigNumberValue1 = value1 | bigNumber1.exponent;
        uint256 multiplicationResult = testVaultHelper.mulDivBigNumber(bigNumberValue1, number2);

        BigNumber memory result;
        result.coefficient = multiplicationResult >> EXPONENT_SIZE_DEBT_FACTOR;
        result.exponent = multiplicationResult & EXPONENT_MAX_DEBT_FACTOR;
        return result;
    }

    // ===== mulBigNumber ====

    function test_mulBigNumber_ReturnMaxMask() public {
        // make resExponent equals EXPONENT_MAX_DEBT_FACTOR which will lead to return MAX_MASK_DEBT_FACTOR
        uint256 exponent1 = 24559;
        uint256 exponent2 = 24559;
        uint256 coefficient1 = (1 << 34);
        uint256 coefficient2 = (1 << 34);

        uint256 bigNumber1 = (coefficient1 << EXPONENT_SIZE_DEBT_FACTOR) | exponent1;
        uint256 bigNumber2 = (coefficient2 << EXPONENT_SIZE_DEBT_FACTOR) | exponent2;

        uint256 resultBigNumber = testVaultHelper.mulBigNumber(bigNumber1, bigNumber2);
        assertEq(resultBigNumber, MAX_MASK_DEBT_FACTOR);
    }

    function test_mulBigNumber_RightBelowMaxDebtFactor() public {
        // make resExponent right BELOW EXPONENT_MAX_DEBT_FACTOR which will lead to return MAX_MASK_DEBT_FACTOR
        uint256 coefficient1 = (1 << 34);
        uint256 exponent1 = 24558;
        uint256 coefficient2 = (1 << 34);
        uint256 exponent2 = 24558;

        uint256 bigNumber1 = (coefficient1 << EXPONENT_SIZE_DEBT_FACTOR) | exponent1;
        uint256 bigNumber2 = (coefficient2 << EXPONENT_SIZE_DEBT_FACTOR) | exponent2;

        uint256 resultBigNumber = testVaultHelper.mulBigNumber(bigNumber1, bigNumber2);
        assertTrue(resultBigNumber != MAX_MASK_DEBT_FACTOR);
    }

    function test_mulBigNumber_MultiplicationOfSameBigNumber() public {
        // COEFFICIENT_MIN = (1 << 34)
        uint256 bigNumber1 = (COEFFICIENT_MIN << 15) | 16384;
        // normal =  coefficient * (2^(exponent - DECIMALS_DEBT_FACTOR))
        // normal =  17179869184 * (2^(16384 - 16384))
        // normal =  17179869184 * (2^(16384 - 16384))
        // normal =  17179869184

        uint256 result = testVaultHelper.mulBigNumber(bigNumber1, bigNumber1);
        // expected = normal * normal = 17179869184 * 17179869184 = 295147905179352825856
        uint256 coefficient = result >> EXPONENT_SIZE_DEBT_FACTOR;
        uint256 exponent = result & EXPONENT_MAX_DEBT_FACTOR;

        assertEq(coefficient, COEFFICIENT_MIN);
        assertEq(exponent, 16418);

        // coefficient * (2^(exponent - DECIMALS_DEBT_FACTOR))
        // 17179869184 * (2^(16418 - 16384)) = 295147905179352825856

        // COEFFICIENT_MAX = (1 << 35) - 1
        uint256 bigNumber2 = (COEFFICIENT_MAX << EXPONENT_SIZE_DEBT_FACTOR) | 16384;

        // normal =  coefficient * (2^(exponent - DECIMALS_DEBT_FACTOR))
        // normal =  34359738367  * (2^(16384 - 16384))
        // normal =  34359738367
        uint256 result2 = testVaultHelper.mulBigNumber(bigNumber2, bigNumber2);
        // expected = normal * normal = 1180591620648691826689
        uint256 coefficient2 = result2 >> EXPONENT_SIZE_DEBT_FACTOR;
        uint256 exponent2 = result2 & EXPONENT_MAX_DEBT_FACTOR;
        assertApproxEqAbs(coefficient2, COEFFICIENT_MAX, 1);
        assertEq(exponent2, 16419);
        // coefficient * (2^(exponent - DECIMALS_DEBT_FACTOR))
        // 34359738366 * (2^(16419 - 16384)) = 1180591620648691826688
    }

    function test_mulBigNumber_MultiplicationOfDoubledBigNumber() public {
        // COEFFICIENT_MAX = (1 << 35) - 1
        uint256 bigNumber1 = (COEFFICIENT_MAX << EXPONENT_SIZE_DEBT_FACTOR) | 8192;
        //normal1 =
        // coefficient * (2^(exponent - DECIMALS_DEBT_FACTOR))
        // 34359738367 * (2^(8192 - 16384))
        // 1.03222721183313874945602509093959966971515740029255981118... × 10^-2451

        // COEFFICIENT_MIN = (1 << 34)
        uint256 bigNumber2 = (COEFFICIENT_MIN << EXPONENT_SIZE_DEBT_FACTOR) | 8192;
        //normal2 =
        // coefficient * (2^(exponent - DECIMALS_DEBT_FACTOR))
        // 17179869184 * (2^(8192 - 16384))
        // 1.57505372899343681252445234823547312883782562300500459470 × 10^-2456
        uint256 result = testVaultHelper.mulBigNumber(bigNumber1, bigNumber2);
        (bigNumber1, bigNumber2);
        uint256 coefficient = result >> EXPONENT_SIZE_DEBT_FACTOR;
        uint256 exponent = result & EXPONENT_MAX_DEBT_FACTOR;
        assertEq(coefficient, COEFFICIENT_MAX);
        assertEq(exponent, 34);
        // expected
        // normal1 * normal2 = (34359738367 * (2^(8192 - 16384))) * (17179869184 * (2^(8192 - 16384))) =
        // = 4.96158849828786015991568395722911073362949985517286680110... × 10^-4912

        // returned
        // coefficient * (2^(exponent - DECIMALS_DEBT_FACTOR))
        // 34359738367 * (2^(34 - 16384)) =
        // 4.96158849828786015991568395722911073362949985517286680110... × 10^-4912
    }

    function test_mulBigNumber_WithSmallerCoefficientOfDivisor() public {
        // COEFFICIENT_MAX = (1 << 35) - 1
        uint256 bigNumber1 = (COEFFICIENT_MAX << EXPONENT_SIZE_DEBT_FACTOR) | (1 << 14);
        // bigNumber1
        // coefficient1 = 34359738367 = ((1 << 35) - 1)
        // exponent1 = (1 << 14)
        // normal = coefficient * (2^(exponent - 16384))
        // normal = ((34359738367 * (2^((1 << 14) - 16384))
        // normal = 34359738367 * (2^(16384 - 16384))
        // normal = 34359738367

        // COEFFICIENT_MIN = (1 << 34)
        uint256 bigNumber2 = (COEFFICIENT_MIN << EXPONENT_SIZE_DEBT_FACTOR) | (1 << 14);
        // bigNumber2
        // coefficient2 = 17179869184
        // exponent2 = (1 << 14)
        // normal = coefficient * (2^(exponent - 16384))
        // normal = 17179869184 * (2^((1 << 14) - 16384))
        // normal = 17179869184 * (2^(16384 - 16384))
        // normal = 17179869184
        uint256 result = testVaultHelper.mulBigNumber(bigNumber1, bigNumber2);
        // multiplication
        // normal * normal2 = 34359738367 * 17179869184 = 590295810341525782528
        uint256 coefficient = result >> EXPONENT_SIZE_DEBT_FACTOR;
        uint256 exponent = result & EXPONENT_MAX_DEBT_FACTOR;

        assertEq(coefficient, COEFFICIENT_MAX);
        assertEq(exponent, 16418);
        // 34359738367 * (2^(16418 - 16384)) = 590295810341525782528
        // 34359738365 * (2^(16418 - 16384)) = 590295810307166044160
    }

    function test_mulBigNumber_WithSmallerExponentOfDivisor() public {
        // COEFFICIENT_MAX = (1 << 35) - 1
        uint256 bigNumber1 = (COEFFICIENT_MAX << EXPONENT_SIZE_DEBT_FACTOR) | (1 << 14);
        // bigNumber1
        // coefficient1 = 34359738367
        // exponent1 = (1 << 14)
        // normal1 = coefficient * (2^(exponent - 16384))
        // normal1 = (34359738367 * (2^((1 << 14) - 16384)) =
        // normal1 = 34359738367 * (2^(16384 - 16384)) = 34359738367
        uint256 bigNumber2 = (COEFFICIENT_MAX << EXPONENT_SIZE_DEBT_FACTOR) | (1 << 13);
        // bigNumber2
        // coefficient2 = 34359738367
        // exponent2 = (1 << 13)
        // normal2 = coefficient * (2^(exponent - 16384))
        // normal2 = (34359738367 * (2^((1 << 13) - 16384))
        // normal2 = 34359738367 * (2^(8192 - 16384))
        // normal2 = 3.15010745789519343167116233818987563807322708771219094085 × 10^-2456
        uint256 result = testVaultHelper.mulBigNumber(bigNumber1, bigNumber2);
        uint256 coefficient = result >> EXPONENT_SIZE_DEBT_FACTOR;
        uint256 exponent = result & EXPONENT_MAX_DEBT_FACTOR;

        // division
        // normal1*normal2 = 1.08236868081214314819078029518988099292463266721168241323 × 10^-2445

        // expected =>
        assertEq(coefficient, 34359738366);
        assertEq(exponent, 8227);
        // 34359738366 * (2^(8227 - 16384)) = 1.08236868081214314818986349325610356934182196101565817165 × 10^-2445
    }

    function test_mulBigNumber_WithSmallerCoefficientOfFirstNumber() public {
        // COEFFICIENT_MAX = (1 << 35) - 1
        uint256 bigNumber1 = (COEFFICIENT_MAX << EXPONENT_SIZE_DEBT_FACTOR) | (1 << 14);
        // bigNumber1
        // coefficient1 = (1 << 35) - 1
        // exponent1 = (1 << 14)
        // normal1 = coefficient * (2^(exponent - 16384))
        // normal1 = (((1 << 35) - 1) * (2^((1 << 14) - 16384)) =
        // normal1 = (34359738367 * (2^(16384 - 16384))
        // normal1 = 34359738367
        uint256 bigNumber2 = (25769803776 << EXPONENT_SIZE_DEBT_FACTOR) | (1 << 14);
        // bigNumber2
        // coefficient2 = 25769803776
        // exponent2 = (1 << 14)
        // normal2 = coefficient * (2^(exponent - 16384))
        // normal2 = (((((25769803776 * (2^((1 << 14) - 16384))
        // normal2 = (25769803776 * (2^(16384 - 16384))
        // normal2 = 25769803776
        uint256 result = testVaultHelper.mulBigNumber(bigNumber1, bigNumber2);
        uint256 coefficient = result >> EXPONENT_SIZE_DEBT_FACTOR;
        uint256 exponent = result & EXPONENT_MAX_DEBT_FACTOR;

        // multiplication
        // normal1 * normal2 = 34359738367 * 25769803776 = 885443715512288673792

        assertEq(coefficient, 25769803775);
        assertEq(exponent, 16419);
        // 25769803775 * (2^(16419 - 16384)) = 885443715503698739200

        // 885443715512288673792 - 885443715503698739200 = 8589934592
    }

    function test_mulBigNumber_WithSmallerExponentOfFirstNumber() public {
        uint256 bigNumber1 = ((1 << 15) << EXPONENT_SIZE_DEBT_FACTOR) | (1 << 13);
        // bigNumber1
        // coefficient1 = (1 << 15)
        // exponent1 = (1 << 13)
        // normal = coefficient * (2^(exponent - 16384))
        // normal = (1 << 15)* (2^((1 << 13) - 16384))
        // normal = 32768* (2^(8192 - 16384))
        // normal = 3.00417657660186159615412206313223481910290836907387656156... × 10^-2462
        uint256 bigNumber2 = ((1 << 15) << EXPONENT_SIZE_DEBT_FACTOR) | (1 << 14);
        // bigNumber2
        // coefficient2 = (1 << 15)
        // exponent2 = (1 << 14)
        // normal = coefficient * (2^exponent - 16384)
        // normal = 32768 * (2^(16384 - 16384))
        // normal = 32768
        uint256 result = testVaultHelper.mulBigNumber(bigNumber1, bigNumber2);
        // multiplication
        // normal*normal2 = 9.16801933777423582810706196024241582978182485679283618641... × 10^-2467
        uint256 coefficient = result >> EXPONENT_SIZE_DEBT_FACTOR;
        uint256 exponent = result & EXPONENT_MAX_DEBT_FACTOR;

        // expected => 0
        assertEq(coefficient, 0);
        // if coefficient == 0 then exponent doesnt matter
    }

    // TODO: Commented as it takes a few minutes to finish.
    // function testFuzz_mulBigNumber_matchesJavascriptImpl(
    //     uint256 coefficient1,
    //     uint256 exponent1,
    //     uint256 coefficient2,
    //     uint256 exponent2
    // ) public {
    //     // COEFFICIENT_MAX = (1 << 35) - 1
    //     // COEFFICIENT_MIN = (1 << 34)
    //     coefficient1 = bound(coefficient1, COEFFICIENT_MIN, COEFFICIENT_MAX);
    //     exponent1 = bound(exponent1, (1 << 5) + 3, (1 << 15));
    //     coefficient2 = bound(coefficient2, COEFFICIENT_MIN, COEFFICIENT_MAX);
    //     exponent2 = bound(exponent2, (1 << 5) + 3, (1 << 15));
    //     vm.assume(exponent1 + exponent2 > (1 << 14));
    //     BigNumber memory bigNumber1 = BigNumber({ coefficient: coefficient1, exponent: exponent1 });
    //     BigNumber memory bigNumber2 = BigNumber({ coefficient: coefficient2, exponent: exponent2 });
    //     BigNumber memory resultBigNumber = multiplyBigNumbers(bigNumber1, bigNumber2);
    //     compareWithJsImplementation(bigNumber1, bigNumber2, resultBigNumber, "forge-test-bigMathVault-mulBigNumber");
    // }

    function multiplyBigNumbers(
        BigNumber memory bigNumber1,
        BigNumber memory bigNumber2
    ) internal returns (BigNumber memory) {
        (uint256 value1, bool success1) = BigMathTolerance.safeMultiply(bigNumber1.coefficient, 32768);
        (uint256 value2, bool success2) = BigMathTolerance.safeMultiply(bigNumber2.coefficient, 32768);
        require(success1 && success2, "Multiplication failed");

        uint256 bigNumberValue1 = value1 | bigNumber1.exponent;
        uint256 bigNumberValue2 = value2 | bigNumber2.exponent;
        uint256 multiplicationResult = testVaultHelper.mulBigNumber(bigNumberValue1, bigNumberValue2);

        BigNumber memory result;
        result.coefficient = multiplicationResult >> EXPONENT_SIZE_DEBT_FACTOR;
        result.exponent = multiplicationResult & EXPONENT_MAX_DEBT_FACTOR;

        return result;
    }

    // ===== divBigNumber ====

    function test_divBigNumber_DivideByZero() public {
        uint256 bigNumber1 = ((1 << COEFFICIENT_SIZE_DEBT_FACTOR) | 1);
        uint256 bigNumber2 = 0;
        vm.expectRevert();
        uint256 result = testVaultHelper.divBigNumber(bigNumber1, bigNumber2);
    }

    function test_divBigNumber_ZeroValue() public {
        uint256 bigNumber1 = 0;
        uint256 bigNumber2 = ((1 << COEFFICIENT_SIZE_DEBT_FACTOR) | 1);
        uint256 result = testVaultHelper.divBigNumber(bigNumber1, bigNumber2);
        uint256 coefficient = result >> EXPONENT_SIZE_DEBT_FACTOR;
        uint256 exponent = result & EXPONENT_MAX_DEBT_FACTOR;
        assertEq(coefficient, 0);
        // if coefficient == 0 then exponent doesnt matter
    }

    function test_divBigNumber_CheckWithMultiplication() public {
        // COEFFICIENT_MAX = (1 << 35) - 1
        // COEFFICIENT_MIN = (1 << 34)
        uint256 bigNumber1 = (COEFFICIENT_MAX << EXPONENT_SIZE_DEBT_FACTOR) | (1 << 14);
        uint256 bigNumber2 = (COEFFICIENT_MIN << EXPONENT_SIZE_DEBT_FACTOR) | (1 << 14);

        uint256 mulResult = testVaultHelper.mulBigNumber(bigNumber1, bigNumber2);

        uint256 divResult = testVaultHelper.divBigNumber(mulResult, bigNumber2);

        assertEq(divResult, bigNumber1, "Division did not correctly invert the multiplication");
    }

    function test_divBigNumber_DivisionOfSameBigNumber() public {
        // COEFFICIENT_MIN = (1 << 34)
        uint256 bigNumber1 = (COEFFICIENT_MIN << EXPONENT_SIZE_DEBT_FACTOR) | 8192;

        uint256 result = testVaultHelper.divBigNumber(bigNumber1, bigNumber1);
        uint256 coefficient = result >> EXPONENT_SIZE_DEBT_FACTOR;
        uint256 exponent = result & EXPONENT_MAX_DEBT_FACTOR;

        // COEFFICIENT_MIN = (1 << 34)
        assertEq(coefficient, COEFFICIENT_MIN);
        assertEq(exponent, 16350);
        // coefficient * (2^(exponent - DECIMALS_DEBT_FACTOR))
        // 17179869184 * (2^(16350 - 16384)) = 1
        // equals 1 in normal format

        // COEFFICIENT_MAX = (1 << 35) - 1
        uint256 bigNumber2 = (COEFFICIENT_MAX << EXPONENT_SIZE_DEBT_FACTOR) | 8192;

        uint256 result2 = testVaultHelper.divBigNumber(bigNumber2, bigNumber2);
        uint256 coefficient2 = result >> EXPONENT_SIZE_DEBT_FACTOR;
        uint256 exponent2 = result2 & EXPONENT_MAX_DEBT_FACTOR;

        // COEFFICIENT_MIN = (1 << 34)
        assertEq(coefficient2, COEFFICIENT_MIN);
        assertEq(exponent2, 16350);
        // coefficient * (2^(exponent - DECIMALS_DEBT_FACTOR))
        // 17179869184 * (2^(16350 - 16384)) = 1
        // equals 1 in normal format
    }

    function test_divBigNumber_WithSmallerCoefficientOfDivisor() public {
        // COEFFICIENT_MAX = (1 << 35) - 1
        uint256 bigNumber1 = (COEFFICIENT_MAX << EXPONENT_SIZE_DEBT_FACTOR) | (1 << 14);
        // bigNumber1
        // coefficient1 = 34359738367
        // exponent1 = (1 << 14)
        // normal1 = coefficient * (2^exponent - 16384)
        // normal1 = 34359738367 * (2^((1 << 14) - 16384)) =
        // normal1 = 34359738367 * (2^(16384 - 16384)) =
        // normal1 = 34359738367

        // COEFFICIENT_MIN = (1 << 34)
        uint256 bigNumber2 = (COEFFICIENT_MIN << EXPONENT_SIZE_DEBT_FACTOR) | (1 << 14);
        // bigNumber2
        // coefficient2 = 17179869184
        // exponent2 = (1 << 14)
        // normal2 = coefficient * (2^exponent - 16384)
        // normal2 = 17179869184 * (2^((1 << 14) - 16384))
        // normal2 = 17179869184 * (2^(16384 - 16384))
        // normal2 = 17179869184
        uint256 result = testVaultHelper.divBigNumber(bigNumber1, bigNumber2);
        uint256 coefficient = result >> EXPONENT_SIZE_DEBT_FACTOR;
        uint256 exponent = result & EXPONENT_MAX_DEBT_FACTOR;

        // division
        // normal1/normal2 = 34359738367/17179869184 = ~2
        // expected 2
        assertEq(coefficient, COEFFICIENT_MAX);
        assertEq(exponent, 16350);
        // 34359738367 * (2^(16350 - 16384)) = ~2
    }

    function test_divBigNumber_WithSmallerExponentOfDivisor() public {
        // COEFFICIENT_MAX = (1 << 35) - 1
        uint256 bigNumber1 = (COEFFICIENT_MAX << EXPONENT_SIZE_DEBT_FACTOR) | (1 << 14);
        // bigNumber1
        // coefficient1 = 34359738367
        // exponent1 = (1 << 14)
        // normal1 = coefficient * (2^(exponent - 16384))
        // normal1 = 34359738367 * (2^((1 << 14) - 16384))
        // normal1 = (34359738367 * (2^(16384 - 16384))
        // normal1 = 34359738367
        uint256 bigNumber2 = (COEFFICIENT_MAX << EXPONENT_SIZE_DEBT_FACTOR) | (1 << 13);
        // bigNumber2
        // coefficient2 = 34359738367
        // exponent2 = (1 << 13)
        // normal2 = coefficient * (2^(exponent - 16384))
        // normal2 = 34359738367 * (2^((1 << 13) - 16384))
        // normal2 = 34359738367 * (2^(8192 - 16384))
        // normal2 = 3.15010745789519343167116233818987563807322708771219094085 × 10^-2456
        uint256 result = testVaultHelper.divBigNumber(bigNumber1, bigNumber2);
        uint256 coefficient = result >> EXPONENT_SIZE_DEBT_FACTOR;
        uint256 exponent = result & EXPONENT_MAX_DEBT_FACTOR;

        // division
        // normal1/normal2 = 32768 / 3.15010745789519343167116233818987563807322708771219094085 × 10^-2456
        // normal1/normal2 = 1.090748135619415929462984244733782862448264161996232692431 × 10^2466

        // expected => 1.090748135619415929462984244733782862448264161996232692431 × 10^2466

        // COEFFICIENT_MIN = (1 << 34)
        assertEq(coefficient, COEFFICIENT_MIN);
        assertEq(exponent, 24542);
        // 17179869184 * (2^(24542 - 16384)) = 1.090748135619415929462984244733782862448264161996232692431... × 10^2466
    }

    function test_divBigNumber_WithSmallerCoefficientOfFirstNumber() public {
        // COEFFICIENT_MIN = (1 << 34)
        uint256 bigNumber1 = (COEFFICIENT_MIN << EXPONENT_SIZE_DEBT_FACTOR) | (1 << 14);
        // bigNumber1
        // coefficient1 = 17179869184
        // exponent1 = (1 << 14)
        // normal1 = coefficient * (2^(exponent - 16384))
        // normal1 = 17179869184* (2^((1 << 14) - 16384)) =
        // normal1 = 17179869184 * (2^(16384 - 16384)) = 17179869184

        // COEFFICIENT_MAX = (1 << 35) - 1
        uint256 bigNumber2 = (COEFFICIENT_MAX << EXPONENT_SIZE_DEBT_FACTOR) | (1 << 14);
        // bigNumber2
        // coefficient2 = 34359738367
        // exponent2 = (1 << 14)
        // normal2 = coefficient * (2^(exponent - 16384))
        // normal2 = 34359738367 * (2^((1 << 14) - 16384))
        // normal2 = 34359738367 * (2^(16384 - 16384))
        // normal2 = 34359738367
        uint256 result = testVaultHelper.divBigNumber(bigNumber1, bigNumber2);
        uint256 coefficient = result >> EXPONENT_SIZE_DEBT_FACTOR;
        uint256 exponent = result & EXPONENT_MAX_DEBT_FACTOR;

        // division
        // normal1/normal2 = 17179869184/34359738367 = ~0.5

        // expected => 0
        // COEFFICIENT_MIN = (1 << 34)
        assertEq(coefficient, COEFFICIENT_MIN);
        assertEq(exponent, 16349);
        // 17179869184 * (2^(16349 - 16384)) = 0.5 which will be 0 in Solidity
    }

    function test_divBigNumber_WithSmallerExponentOfFirstNumber() public {
        // COEFFICIENT_MAX = (1 << 35) - 1
        uint256 bigNumber1 = (COEFFICIENT_MAX << EXPONENT_SIZE_DEBT_FACTOR) | (1 << 13);
        // bigNumber1
        // coefficient1 = 34359738367
        // exponent1 = (1 << 15)
        // normal1 = coefficient * (2^(exponent - 16384))
        // normal1 = 34359738367 * (2^((1 << 13) - 16384)) =
        // normal1 = 34359738367 * (2^(8192 - 16384)) =
        // normal1 = 3.15010745789519343167116233818987563807322708771219094085 × 10^-2456
        uint256 bigNumber2 = (COEFFICIENT_MAX << EXPONENT_SIZE_DEBT_FACTOR) | (1 << 14);
        // bigNumber2
        // coefficient2 = 34359738367
        // exponent2 = (1 << 14)
        // normal2 = coefficient * (2^exponent - 16384)
        // normal2 = 34359738367 * (2^(1 << 14) - 16384)
        // normal2 = 34359738367 * (2^(16384 - 16384)) =
        // normal2 = 34359738367
        uint256 result = testVaultHelper.divBigNumber(bigNumber1, bigNumber2);
        uint256 coefficient = result >> EXPONENT_SIZE_DEBT_FACTOR;
        uint256 exponent = result & EXPONENT_MAX_DEBT_FACTOR;

        // division
        // normal11/normal2 = 9.16801933777423582810706196024241582978182485679283618641 × 10^-2467

        // COEFFICIENT_MIN = (1 << 34)
        assertEq(coefficient, COEFFICIENT_MIN);
        assertEq(exponent, 8158);
        // 17179869184 * (2^(8158 - 16384)) = 9.16801933777423582810706196024241582978182485679283618641 × 10^-2467
    }

    struct BigNumber {
        uint256 coefficient;
        uint256 exponent;
    }

    // TODO: Commented as it takes a few minutes to finish.
    // function testFuzz_divBigNumber_matchesJavascriptImpl(
    //     uint256 coefficient1,
    //     uint256 exponent1,
    //     uint256 coefficient2,
    //     uint256 exponent2
    // ) public {
    //     // COEFFICIENT_MAX = (1 << 35) - 1
    //     // COEFFICIENT_MIN = (1 << 34)
    //     coefficient1 = bound(coefficient1, COEFFICIENT_MIN, COEFFICIENT_MAX);
    //     exponent1 = bound(exponent1, (1 << 5) + 3, (1 << 14));
    //     coefficient2 = bound(coefficient2, COEFFICIENT_MIN, COEFFICIENT_MAX);
    //     exponent2 = bound(exponent2, (1 << 5) + 3, (1 << 14));
    //     BigNumber memory bigNumber1 = BigNumber({ coefficient: coefficient1, exponent: exponent1 });
    //     BigNumber memory bigNumber2 = BigNumber({ coefficient: coefficient2, exponent: exponent2 });
    //     BigNumber memory resultBigNumber = divideBigNumbers(bigNumber1, bigNumber2);
    //     compareWithJsImplementation(bigNumber1, bigNumber2, resultBigNumber, "forge-test-bigMathVault-divBigNumber");
    // }

    function divideBigNumbers(
        BigNumber memory bigNumber1,
        BigNumber memory bigNumber2
    ) internal returns (BigNumber memory) {
        (uint256 value1, bool success1) = BigMathTolerance.safeMultiply(bigNumber1.coefficient, 32768);
        (uint256 value2, bool success2) = BigMathTolerance.safeMultiply(bigNumber2.coefficient, 32768);
        require(success1 && success2, "Multiplication failed");

        uint256 bigNumberValue1 = value1 | bigNumber1.exponent;
        uint256 bigNumberValue2 = value2 | bigNumber2.exponent;
        uint256 divisionResult = testVaultHelper.divBigNumber(bigNumberValue1, bigNumberValue2);

        BigNumber memory result;
        result.coefficient = divisionResult >> EXPONENT_SIZE_DEBT_FACTOR;
        result.exponent = divisionResult & EXPONENT_MAX_DEBT_FACTOR;

        return result;
    }

    function compareWithJsImplementation(
        BigNumber memory bigNumber1,
        BigNumber memory bigNumber2,
        BigNumber memory resultFromDivision,
        string memory jsScriptName
    ) internal {
        string[] memory runJsInputs = new string[](10);

        // Build FFI command string
        runJsInputs[0] = "npm";
        runJsInputs[1] = "--silent";
        runJsInputs[2] = "run";
        runJsInputs[3] = jsScriptName;

        // Add parameters to JavaScript script
        runJsInputs[4] = vm.toString(bigNumber1.coefficient);
        runJsInputs[5] = vm.toString(bigNumber1.exponent);
        runJsInputs[6] = vm.toString(bigNumber2.coefficient);
        runJsInputs[7] = vm.toString(bigNumber2.exponent);
        runJsInputs[8] = vm.toString(resultFromDivision.coefficient);
        runJsInputs[9] = vm.toString(resultFromDivision.exponent);

        // Call JavaScript script and get result
        bytes memory jsResult = vm.ffi(runJsInputs);
        bool isCorrect = abi.decode(jsResult, (bool));

        // Assert the result
        assertEq(isCorrect, true);
    }
}
