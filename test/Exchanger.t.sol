// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/interfaces/IExchanger.sol";
import "../src/Exchanger.sol";

contract ExchangerTest is Test, IExchanger {
    ERC20 public token0;
    ERC20 public token1;

    uint256 arbitrumFork;
    string public ARBITRUM_RPC_URL;

    Exchanger public exchanger;

    address internal TOKEN0_ADDRESS;
    address internal TOKEN1_ADDRESS;

    address internal bob;
    address internal david;

    event ExchangeRateUpdated(
        address indexed account,
        uint256 oldExchangeRate,
        uint256 newExchangeRate
    );
    event ExchangeEndPeriodUpdate(address indexed account, uint256 timestamp);
    event Exchanged(
        address indexed account,
        uint256 fromToken0Amount,
        uint256 toToken1Amount
    );

    function setUp() public {
        ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL");

        TOKEN0_ADDRESS = vm.envAddress("USDC_CONTRACT_ADDRESS");
        TOKEN1_ADDRESS = vm.envAddress("LEVI_CONTRACT_ADDRESS");

        arbitrumFork = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbitrumFork);

        token0 = ERC20(TOKEN0_ADDRESS);
        token1 = ERC20(TOKEN1_ADDRESS);

        exchanger = new Exchanger(TOKEN0_ADDRESS, TOKEN1_ADDRESS, 2 ether);

        bob = vm.addr(3);
        vm.label(bob, "bob");

        david = vm.addr(4);
        vm.label(david, "david");
    }

    function test_successfully_constructed() public {
        assertEq(exchanger.EXCHANGE_RATE(), 2 ether);
        assertEq(
            exchanger.EXCHANGE_END_AT_UNIX_TIME(),
            block.timestamp + 3 days
        );
    }

    function test_bobCannotUpdateExchangeRate() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.startPrank(bob);
        exchanger.updateExchangeRate(3 ether);
        vm.stopPrank();
    }

    function test_exchangeRateCannotBeZero() public {
        vm.expectRevert(Exchanger_Rate_Cannont_Be_Zero.selector);
        exchanger.updateExchangeRate(0);
    }

    function test_canUpdateExchangeRate() public {
        uint256 currentRate = exchanger.EXCHANGE_RATE();

        vm.expectEmit(true, true, true, true);
        emit ExchangeRateUpdated(exchanger.owner(), currentRate, 3 ether);

        exchanger.updateExchangeRate(3 ether);
        uint256 newRate = exchanger.EXCHANGE_RATE();

        assertEq(newRate, 3 ether);
    }

    function test_davidCannotRestartExchangePeriod() public {
        vm.warp(block.timestamp + 4 days);
        vm.startPrank(david);
        vm.expectRevert("Ownable: caller is not the owner");
        exchanger.restartExchangePeriod();
        vm.stopPrank();
    }

    function test_canRestartExchangePeriod() public {
        uint256 currentEndPeriod = exchanger.EXCHANGE_END_AT_UNIX_TIME();

        vm.warp(block.timestamp + 4 days);

        vm.expectEmit(true, true, true, true);
        emit ExchangeEndPeriodUpdate(
            exchanger.owner(),
            block.timestamp + 3 days
        );

        exchanger.restartExchangePeriod();
        uint256 newEndPeriod = exchanger.EXCHANGE_END_AT_UNIX_TIME();

        assertEq(
            exchanger.EXCHANGE_END_AT_UNIX_TIME(),
            block.timestamp + 3 days
        );

        assertTrue(newEndPeriod > currentEndPeriod);
    }

    function test_previewReturnZeroWhenAmountIsZero() public {
        uint256 preview = exchanger.previewExchange(0);
        assertEq(preview, 0);
    }

    function test_previewExchange() public {
        uint256 preview = exchanger.previewExchange(20 ether);

        assertEq(preview, 40 ether);
    }

    function test_amountToExchangeCannotBeZero() public {
        vm.startPrank(bob);

        vm.expectRevert(Exchanger_Token0_Amount_Cannot_Be_Zero.selector);
        exchanger.exchange(0);

        vm.stopPrank();
    }

    function test_token1BalanceCannotBeZero() public {
        deal(TOKEN0_ADDRESS, bob, 10 ether);

        vm.startPrank(bob);

        vm.expectRevert(Exchanger_Token1_Zero_Balance.selector);
        exchanger.exchange(10 ether);

        vm.stopPrank();
    }

    function test_token1BalanceCannotBeInsufficientToExchange() public {
        deal(TOKEN0_ADDRESS, bob, 10 ether);
        deal(TOKEN1_ADDRESS, address(exchanger), 2 ether);

        vm.startPrank(bob);

        vm.expectRevert(
            Exchanger_Insufficient_Token1_Balance_For_Exchange.selector
        );
        exchanger.exchange(10 ether);

        vm.stopPrank();
    }

    function test_davidCanExchangeToken0ForToken1() public {
        uint256 valueToExchange = 10 ether;

        vm.startPrank(david);
        token0.approve(address(exchanger), 10 ether);

        deal(TOKEN0_ADDRESS, david, 10 ether);
        deal(TOKEN1_ADDRESS, address(exchanger), 20 ether);

        uint256 previewValue = exchanger.previewExchange(10 ether);

        vm.expectEmit(true, true, true, true);
        emit Exchanged(david, valueToExchange, previewValue);

        uint256 token0BalanceBefore = token0.balanceOf(david);
        uint256 token1BalanceBefore = token1.balanceOf(david);

        exchanger.exchange(valueToExchange);

        uint256 token0BalanceAfter = token0.balanceOf(david);
        uint256 token1BalanceAfter = token1.balanceOf(david);

        assertEq(token0BalanceBefore - valueToExchange, token0BalanceAfter);
        assertEq(token1BalanceBefore + previewValue, token1BalanceAfter);

        vm.stopPrank();
    }
}
