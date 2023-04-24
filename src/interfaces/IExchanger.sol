// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

interface IExchanger {
    error Exchanger_Token0_Amount_Cannot_Be_Zero();
    error Exchanger_Token1_Zero_Balance();
    error Exchanger_Insufficient_Token1_Balance_For_Exchange();
}
