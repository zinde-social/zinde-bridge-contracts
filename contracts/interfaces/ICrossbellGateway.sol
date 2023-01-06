// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../libraries/DataTypes.sol";

interface ICrossbellGateway {
    /**
     * @dev Emitted when the tokens are mapped
     * @param crossbellTokens Addresses of crossbell tokens.
     * @param chainIds ChainIds of mainchain networks.
     * @param mainchainTokens Addresses of mainchain tokens.
     * @param mainchainTokenDecimals Decimals of mainchain tokens.
     */
    event TokenMapped(
        address[] crossbellTokens,
        uint256[] chainIds,
        address[] mainchainTokens,
        uint8[] mainchainTokenDecimals
    );

    /**
     * @dev Emitted when the assets are deposited
     * @param chainId ChainId of mainchain network.
     * @param depositId Deposit identifier id.
     * @param recipient The address of account to receive the deposit.
     * @param token The address of token to deposit.
     * @param amount The amount of token to deposit.
     */
    event Deposited(
        uint256 indexed chainId,
        uint256 indexed depositId,
        address indexed recipient,
        address token,
        uint256 amount
    );

    /**
     * @dev Emitted when the deposit is acknowledged by a validator
     * @param chainId The ChainId of mainchain network.
     * @param depositId Deposit identifier id.
     * @param recipient The address of account to receive the deposit.
     * @param token The address of token to deposit.
     * @param amount The amount of token to deposit.
     */
    event AckDeposit(
        uint256 indexed chainId,
        uint256 indexed depositId,
        address indexed recipient,
        address token,
        uint256 amount
    );
    /**
     * @dev Emitted when the withdrawal is requested
     * @param chainId The ChainId of mainchain network.
     * @param withdrawId Withdrawal identifier id.
     * @param recipient The address of account to receive the withdrawal.
     * @param token The address of token to withdraw.
     * @param amount The amount of token to be withdrawn on mainchain network. Note that validator should use this `amount' for submitting signature
     * @param fee The fee amount to pay for the withdrawal tx sender on mainchain network.
     */
    event RequestWithdrawal(
        uint256 indexed chainId,
        uint256 indexed withdrawId,
        address indexed recipient,
        address token,
        uint256 amount,
        uint256 fee
    );

    /**
     * @dev Emitted when the withdrawal signatures is requested.
     * @param chainId The ChainId of mainchain network.
     * @param withdrawId Withdrawal identifier id.
     * @param recipient The address of account to receive the withdrawal.
     * @param token The address of token to withdraw.
     * @param amount The amount of token to be withdrawn on mainchain network. Note that validator should use this `amount' for submitting signature
     * @param fee The fee amount to pay for the withdrawal tx sender on mainchain network.
     */
    event RequestWithdrawalSignatures(
        uint256 indexed chainId,
        uint256 indexed withdrawId,
        address indexed recipient,
        address token,
        uint256 amount,
        uint256 fee
    );

    /**
     * @notice Initializes the CrossbellGateway.
     * @param validator Address of validator contract.
     * @param admin Address of gateway admin.
     * @param crossbellTokens Addresses of crossbell tokens.
     * @param chainIds ChainIds of mainchain networks.
     * @param mainchainTokens Addresses of mainchain tokens.
     * @param mainchainTokenDecimals Decimals of mainchain tokens.
     */
    function initialize(
        address validator,
        address admin,
        address[] calldata crossbellTokens,
        uint256[] calldata chainIds,
        address[] calldata mainchainTokens,
        uint8[] calldata mainchainTokenDecimals
    ) external;

    /**
     * @notice Pause interaction with the gateway contract
     */
    function pause() external;

    /**
     * @notice Resume interaction with the gateway contract
     */
    function unpause() external;

    /**
     * @notice Maps mainchain tokens to Crossbell network.
     * @param crossbellTokens Addresses of crossbell tokens.
     * @param chainIds ChainIds of mainchain networks.
     * @param mainchainTokens Addresses of mainchain tokens.
     * @param mainchainTokenDecimals Decimals of mainchain tokens.
     */
    function mapTokens(
        address[] calldata crossbellTokens,
        uint256[] calldata chainIds,
        address[] calldata mainchainTokens,
        uint8[] calldata mainchainTokenDecimals
    ) external;

    /**
     * @notice Tries bulk deposit.
     */
    function batchAckDeposit(
        uint256[] calldata chainIds,
        uint256[] calldata depositIds,
        address[] calldata recipients,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external;

    /**
     * @notice Tries bulk submit withdrawal signatures.
     * Note that the caller must be a validator.
     */
    function batchSubmitWithdrawalSignatures(
        uint256[] calldata chainIds,
        uint256[] calldata withdrawalIds,
        bool[] calldata shouldReplaces,
        bytes[] calldata sigs
    ) external;

    /**
     * @notice Acknowledges a deposit.
     * Note that the caller must be a validator.
     * @param chainId ChainId of mainchain network
     * @param depositId Deposit identifier id.
     * @param recipient Address to receive deposit on crossbell network
     * @param token Token address to deposit on crossbell network
     * @param amount Token amount to deposit on crossbell network
     */
    function ackDeposit(
        uint256 chainId,
        uint256 depositId,
        address recipient,
        address token,
        uint256 amount
    ) external;

    /**
     * @notice Locks the assets and request withdrawal.
     * @param chainId ChainId of mainchain network
     * @param recipient Address to receive withdrawal on mainchain network
     * @param token Token address to withdraw from crossbell network
     * @param amount Token amount to withdraw from crossbell network
     * @param fee Fee amount to pay on mainchain network. This is subtracted from the `amount`.
     * @return withdrawId The newly generated withdrawId
     */
    function requestWithdrawal(
        uint256 chainId,
        address recipient,
        address token,
        uint256 amount,
        uint256 fee
    ) external returns (uint256 withdrawId);

    /**
     * @notice Request withdrawal signatures, in case the withdrawer didn't submit to mainchain in time and the set of the validator
     * has changed.
     * @param chainId ChainId
     * @param withdrawalId WithdrawalId
     */
    function requestWithdrawalSignatures(uint256 chainId, uint256 withdrawalId) external;

    /**
     * @notice Submits validator signature for withdrawal.
     * Note that the caller must be a validator.
     * @param chainId ChainId of mainchain network
     * @param withdrawalId WithdrawalId
     * @param shouldReplace Whether the old signature should be replaced
     * @param sig Validator signature for the withdrawal
     */
    function submitWithdrawalSignatures(
        uint256 chainId,
        uint256 withdrawalId,
        bool shouldReplace,
        bytes calldata sig
    ) external;

    /**
     * @notice Returns mapped token on mainchain.
     * @param chainId ChainId of mainchain
     * @param crossbellToken Token address on crossbell
     * @return token Mapped token on mainchain chain
     */
    function getMainchainToken(
        uint256 chainId,
        address crossbellToken
    ) external view returns (DataTypes.MappedToken memory token);

    /**
     * @notice Returns the acknowledge depositHash by validator.
     * @param chainId ChainId of mainchain
     * @param id DepositId
     * @param validator Validator address
     * @return bytes32 depositHash if validator has acknowledged, otherwise 0
     */
    function getValidatorAcknowledgementHash(
        uint256 chainId,
        uint256 id,
        address validator
    ) external view returns (bytes32);

    /**
     * @notice Returns the acknowledge status of deposit by validators.
     * @param chainId ChainId of mainchain
     * @param id DepositId
     * @param hash depositHash
     * @return DataTypes.Status Acknowledgement status
     */
    function getAcknowledgementStatus(
        uint256 chainId,
        uint256 id,
        bytes32 hash
    ) external view returns (DataTypes.Status);

    /**
     * @notice Returns the acknowledge count of deposit by validators.
     * @param chainId ChainId of mainchain
     * @param id DepositId
     * @param hash depositHash
     * @return uint256 Acknowledgement count
     */
    function getAcknowledgementCount(
        uint256 chainId,
        uint256 id,
        bytes32 hash
    ) external view returns (uint256);

    /**
     * @notice Returns withdrawal signers.
     * @param chainId ChainId of mainchain
     * @param withdrawalId Withdrawal Id to query
     * @return address[] Signer addresses
     */
    function getWithdrawalSigners(
        uint256 chainId,
        uint256 withdrawalId
    ) external view returns (address[] memory);

    /**
     * @notice Returns withdrawal signatures.
     * @param chainId ChainId of mainchain
     * @param withdrawalId Withdrawal Id to query
     */
    function getWithdrawalSignatures(
        uint256 chainId,
        uint256 withdrawalId
    ) external view returns (address[] memory signers, bytes[] memory sigs);

    /**
     * @notice Returns the address of the validator contract.
     * @return The validator contract address
     */
    function getValidatorContract() external view returns (address);

    /**
     * @notice Returns the deposit entry.
     * @param chainId ChainId of mainchain
     * @param depositId Deposit Id to query
     * @return DataTypes.DepositEntry Deposit entry
     */
    function getDepositEntry(
        uint256 chainId,
        uint256 depositId
    ) external view returns (DataTypes.DepositEntry memory);

    /**
     * @notice Returns the withdrawal count of different mainchain networks.
     * @param chainId ChainId of mainchain
     * @return uint256 Withdrawal count
     */
    function getWithdrawalCount(uint256 chainId) external view returns (uint256);

    /**
     * @notice Returns the withdrawal entry.
     * @param chainId ChainId of mainchain
     * @param withdrawalId Withdrawal Id to query
     * @return DataTypes.WithdrawalEntry Withdrawal entry
     */
    function getWithdrawalEntry(
        uint256 chainId,
        uint256 withdrawalId
    ) external view returns (DataTypes.WithdrawalEntry memory);
}
