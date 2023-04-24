// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/interfaces/IExchanger.sol";
import "../../src/interfaces/ISettings.sol";
import "../../src/Exchanger.sol";

contract ExchangerTest is Test, IExchanger, ISettings {
    ERC20 public token0;
    ERC20 public token1;

    uint256 public initialExchangeRate;
    uint256 public exchangePeriodDuration;

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

        initialExchangeRate = 2 ether;
        exchangePeriodDuration = 3 days;

        arbitrumFork = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbitrumFork);

        token0 = ERC20(TOKEN0_ADDRESS);
        token1 = ERC20(TOKEN1_ADDRESS);

        exchanger = new Exchanger(
            TOKEN0_ADDRESS,
            TOKEN1_ADDRESS,
            initialExchangeRate,
            exchangePeriodDuration
        );

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
}
