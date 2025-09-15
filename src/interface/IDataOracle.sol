// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IDataOracle
 * @dev Interface for data oracle contracts
 */
interface IDataOracle {
    function getData() external view returns (string memory);
}
