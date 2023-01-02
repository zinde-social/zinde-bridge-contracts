// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../libraries/DataTypes.sol";

/**
 * @title GatewayStorage
 * @dev Storage of deposit and withdraw information.
 */
abstract contract MainchainGatewayStorage {
    event TokenMapped(
        address[] mainchainTokens,
        address[] crossbellTokens,
        uint8[] crossbellTokensDecimals
    );

    event RequestDeposit(
        uint256 indexed depositId,
        address indexed recipient,
        address indexed token,
        uint256 amount // ERC-20 amount
    );

    event Withdrew(
        uint256 indexed withdrawId,
        address indexed recipient,
        address indexed token,
        uint256 amount
    );

    struct DepositEntry {
        address recipient;
        uint256 transformedAmount;
        uint256 originalAmount;
    }

    // keccak256("withdraw(uint256 chainId,uint256 withdrawalId,address recipient,address token,uint256 amount,bytes signatures)")
    bytes32 public constant TYPE_HASH =
        0xed7a87d78461bdc12aba24d19e67131757b33eab78ae3c422b3617d69a018b2f;

    address public _validator;

    uint256 public _depositCount;
    address public _admin;
    mapping(uint256 => bytes32) public _withdrawalHash;

    // @dev Mapping from mainchain token => token address on crossbell network
    mapping(address => DataTypes.MappedToken) internal _crossbellToken;
}
