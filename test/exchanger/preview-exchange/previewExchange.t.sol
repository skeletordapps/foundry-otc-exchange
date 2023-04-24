// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../Exchanger.t.sol";

contract PreviewExchangeTest is ExchangerTest {
    function test_previewReturnZeroWhenAmountIsZero() public {
        uint256 preview = exchanger.previewExchange(0);
        assertEq(preview, 0);
    }

    function test_previewExchange() public {
        uint256 preview = exchanger.previewExchange(20 ether);

        assertEq(preview, 40 ether);
    }
}
