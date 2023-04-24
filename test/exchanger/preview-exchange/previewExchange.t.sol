// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../Exchanger.t.sol";

contract PreviewExchangeTest is ExchangerTest {
    using SafeMath for uint256;

    function test_previewReturnZeroWhenAmountIsZero() public {
        uint256 preview = exchanger.previewExchange(0);
        assertEq(preview, 0);
    }

    function test_previewExchange() public {
        uint256 preview = exchanger.previewExchange(20 ether);

        assertEq(preview, 40 ether);
    }

    function testFuzz_previewExchange(uint256 amount) public {
        vm.assume(amount > 0 && amount <= exchanger.TOKEN0_MAX_LIMIT_PER_TX());

        uint256 token0Decimals = exchanger.token0Decimals();
        uint256 token1Decimals = exchanger.token1Decimals();
        uint256 expectedValue = amount
            .mul(exchanger.EXCHANGE_RATE())
            .mul(10 ** token1Decimals)
            .div(10 ** (token0Decimals.add(token1Decimals)))
            .div(10 ** (token1Decimals.sub(token0Decimals)));

        uint256 preview = exchanger.previewExchange(amount);

        assertEq(preview, expectedValue);
    }
}
