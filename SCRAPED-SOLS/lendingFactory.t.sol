//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20, IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { ILiquidity } from "../../../contracts/liquidity/interfaces/iLiquidity.sol";
import { iToken } from "../../../contracts/protocols/lending/iToken/main.sol";
import { iTokenNativeUnderlying } from "../../../contracts/protocols/lending/iToken/nativeUnderlying/iTokenNativeUnderlying.sol";
import { LendingFactory } from "../../../contracts/protocols/lending/lendingFactory/main.sol";
import { Events as LendingFactoryEvents } from "../../../contracts/protocols/lending/lendingFactory/events.sol";
import { ILendingFactory } from "../../../contracts/protocols/lending/interfaces/iLendingFactory.sol";
import { Liquidity } from "../../../contracts/liquidity/proxy.sol";
import { Error } from "../../../contracts/protocols/lending/error.sol";
import { ErrorTypes } from "../../../contracts/protocols/lending/errorTypes.sol";

import { LiquidityBaseTest } from "../liquidity/liquidityBaseTest.t.sol";
import { RandomAddresses } from "../utils/RandomAddresses.sol";

contract LendingFactoryTest is LiquidityBaseTest, LendingFactoryEvents, RandomAddresses {
    LendingFactory factory;

    ILiquidity liquidityProxy;

    function setUp() public virtual override {
        // native underlying tests must run in fork for WETH support
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

        super.setUp();
        liquidityProxy = ILiquidity(address(liquidity));

        factory = new LendingFactory(liquidityProxy, admin);
    }

    function test_setAuth_RevertIfNotAdmin() public {
        vm.prank(alice);
        vm.expectRevert("UNAUTHORIZED");
        factory.setAuth(address(alice), true);
    }

    function test_setAuth_RevertIfNotValidAddress() public {
        vm.prank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(Error.FluidLendingError.selector, ErrorTypes.LendingFactory__ZeroAddress)
        );
        factory.setAuth(address(0), true);
    }

    function test_setAuth() public {
        vm.expectEmit(true, true, true, true);
        emit LendingFactoryEvents.LogSetAuth(address(alice), true);
        vm.prank(admin);
        factory.setAuth(address(alice), true);

        assertEq(factory.isAuth(address(alice)), true);
        vm.expectEmit(false, false, false, false);
        emit LendingFactoryEvents.LogSetAuth(address(alice), false);

        vm.prank(admin);
        factory.setAuth(address(alice), false);

        assertEq(factory.isAuth(address(alice)), false);
    }

    function test_setDeployer_RevertIfNotAdmin() public {
        vm.prank(alice);
        vm.expectRevert("UNAUTHORIZED");
        factory.setDeployer(address(alice), true);
    }

    function test_setDeployer_RevertIfNotValidAddress() public {
        vm.prank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(Error.FluidLendingError.selector, ErrorTypes.LendingFactory__ZeroAddress)
        );
        factory.setDeployer(address(0), true);
    }

    function test_setDeployer() public {
        vm.expectEmit(true, true, true, true);
        emit LendingFactoryEvents.LogSetDeployer(address(alice), true);
        vm.prank(admin);
        factory.setDeployer(address(alice), true);

        assertEq(factory.isDeployer(address(alice)), true);
        vm.expectEmit(false, false, false, false);
        emit LendingFactoryEvents.LogSetDeployer(address(alice), false);

        vm.prank(admin);
        factory.setDeployer(address(alice), false);

        assertEq(factory.isDeployer(address(alice)), false);
    }

    function test_setITokenCreationCode() public {
        vm.prank(admin);
        factory.setITokenCreationCode("iToken", type(iToken).creationCode);
        assertEq(factory.iTokenCreationCode("iToken"), type(iToken).creationCode);
    }

    function test_iTokenTypes() public {
        vm.prank(admin);
        factory.setITokenCreationCode("iToken", new bytes(0));

        string[] memory iTokenTypes = factory.iTokenTypes();
        assertEq(iTokenTypes.length, 0);

        vm.prank(admin);
        factory.setITokenCreationCode("NativeUnderlying", type(iTokenNativeUnderlying).creationCode);

        iTokenTypes = factory.iTokenTypes();
        assertEq(iTokenTypes.length, 1);
        assertEq(iTokenTypes[0], "NativeUnderlying");

        vm.prank(admin);
        factory.setITokenCreationCode("iToken", type(iToken).creationCode);

        iTokenTypes = factory.iTokenTypes();
        assertEq(iTokenTypes.length, 2);
        assertEq(iTokenTypes[0], "NativeUnderlying");
        assertEq(iTokenTypes[1], "iToken");
    }
}

contract LendingFactoryCreateTokenTest is LendingFactoryTest {
    function setUp() public virtual override {
        super.setUp();

        vm.prank(admin);
        factory.setITokenCreationCode("iToken", type(iToken).creationCode);
    }

    function test_createToken_UnsetToken_RevertIfiTokenTypeNotExist() public {
        vm.expectRevert(
            abi.encodeWithSelector(Error.FluidLendingError.selector, ErrorTypes.LendingFactory__InvalidParams)
        );
        vm.prank(admin);
        factory.createToken(address(USDC), "someITokenType", false);
    }

    function test_createToken_RevertIfTokenAlreadyExists() public {
        vm.prank(admin);
        factory.createToken(address(USDC), "iToken", false);
        vm.expectRevert(
            abi.encodeWithSelector(Error.FluidLendingError.selector, ErrorTypes.LendingFactory__TokenExists)
        );
        vm.prank(admin);
        factory.createToken(address(USDC), "iToken", false);
    }

    function test_createToken_RevertIfLiquidityNotConfigured() public {
        vm.expectRevert(
            abi.encodeWithSelector(Error.FluidLendingError.selector, ErrorTypes.LendingFactory__LiquidityNotConfigured)
        );
        vm.prank(admin);
        factory.createToken(address(randomAddresses[0]), "iToken", false);
    }

    function test_createToken_RevertIfUnauthorized() public {
        vm.expectRevert(
            abi.encodeWithSelector(Error.FluidLendingError.selector, ErrorTypes.LendingFactory__Unauthorized)
        );
        vm.prank(alice);
        factory.createToken(address(randomAddresses[0]), "iToken", false);
    }

    function test_createToken_RevertIfAuth() public {
        vm.prank(admin);
        factory.setAuth(alice, true);

        vm.expectRevert(
            abi.encodeWithSelector(Error.FluidLendingError.selector, ErrorTypes.LendingFactory__Unauthorized)
        );
        vm.prank(alice);
        factory.createToken(address(randomAddresses[0]), "iToken", false);
    }

    function test_createToken_AsDeployer() public {
        vm.prank(admin);
        factory.setDeployer(alice, true);

        vm.prank(alice);
        address token = factory.createToken(address(USDC), "iToken", false);
        assertTrue(token != address(0));
    }

    function test_createToken_iToken() public {
        uint256 expectedTokensArrayLength = 1;
        vm.expectEmit(false, true, true, false);
        emit LendingFactoryEvents.LogTokenCreated(address(0), address(USDC), expectedTokensArrayLength, "iToken");
        vm.prank(admin);
        address token = factory.createToken(address(USDC), "iToken", false);

        assertTrue(token != address(0));
        assertEq(IERC20Metadata(token).name(), "Fluid Interest USDC");
        assertEq(IERC20Metadata(token).symbol(), "fiUSDC");

        address[] memory allTokens = factory.allTokens();
        assertEq(allTokens.length, expectedTokensArrayLength);
        assertEq(allTokens[0], token);
    }

    function test_createToken_NativeUnderlyingToken() public {
        vm.prank(admin);
        factory.setITokenCreationCode("NativeUnderlying", type(iTokenNativeUnderlying).creationCode);

        address expectedTokenAddress = factory.computeToken(address(WETH_ADDRESS), "NativeUnderlying");
        uint256 expectedTokensArrayLength = 1;
        vm.expectEmit(true, true, true, true);
        emit LendingFactoryEvents.LogTokenCreated(
            expectedTokenAddress,
            address(WETH_ADDRESS),
            expectedTokensArrayLength,
            "NativeUnderlying"
        );

        vm.prank(admin);
        address token = factory.createToken(address(WETH_ADDRESS), "NativeUnderlying", true);

        assertEq(expectedTokenAddress, token);
        assertTrue(token != address(0));
        assertEq(IERC20Metadata(token).name(), "Fluid Interest Wrapped Ether");
        assertEq(IERC20Metadata(token).symbol(), "fiWETH");

        address[] memory allTokens = factory.allTokens();
        assertEq(allTokens.length, expectedTokensArrayLength);
        assertEq(allTokens[0], token);

        // todo assert token has no signature deposits
    }

    function test_allTokens() public {
        vm.prank(admin);
        factory.setITokenCreationCode("NativeUnderlying", type(iTokenNativeUnderlying).creationCode);

        vm.prank(admin);
        address token1 = factory.createToken(address(WETH_ADDRESS), "NativeUnderlying", true);
        vm.prank(admin);
        address token2 = factory.createToken(address(DAI), "iToken", false);

        address[] memory allTokens = factory.allTokens();
        assertEq(allTokens.length, 2);
        assertEq(allTokens[0], token1);
        assertEq(allTokens[1], token2);

        // todo assert token has no signature deposits
    }
}
