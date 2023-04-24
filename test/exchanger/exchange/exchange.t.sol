// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../Exchanger.t.sol";

contract ExchangeTest is ExchangerTest {
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

    function testFuzz_BobCanExchangeToken0ForToken1(
        uint256 amountToExchange
    ) public {
        vm.assume(
            amountToExchange > 0 &&
                amountToExchange <= exchanger.TOKEN0_MAX_LIMIT_PER_TX()
        );
        vm.startPrank(bob);
        token0.approve(address(exchanger), amountToExchange);

        deal(TOKEN0_ADDRESS, bob, amountToExchange);
        deal(TOKEN1_ADDRESS, address(exchanger), amountToExchange * 10);

        uint256 previewValue = exchanger.previewExchange(amountToExchange);

        vm.expectEmit(true, true, true, true);
        emit Exchanged(bob, amountToExchange, previewValue);

        uint256 token0BalanceBefore = token0.balanceOf(bob);
        uint256 token1BalanceBefore = token1.balanceOf(bob);

        exchanger.exchange(amountToExchange);

        uint256 token0BalanceAfter = token0.balanceOf(bob);
        uint256 token1BalanceAfter = token1.balanceOf(bob);

        assertEq(token0BalanceBefore - amountToExchange, token0BalanceAfter);
        assertEq(token1BalanceBefore + previewValue, token1BalanceAfter);

        vm.stopPrank();
    }
}
