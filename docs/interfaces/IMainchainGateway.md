# Solidity API

## IMainchainGateway

### TokenMapped

```solidity
event TokenMapped(address[] mainchainTokens, address[] crossbellTokens, uint8[] crossbellTokensDecimals)
```

_Emitted when the tokens are mapped_

### RequestDeposit

```solidity
event RequestDeposit(uint256 depositId, address recipient, address token, uint256 amount)
```

_Emitted when the deposit is requested_

### Withdrew

```solidity
event Withdrew(uint256 withdrawId, address recipient, address token, uint256 amount)
```

_Emitted when the assets are withdrawn on mainchain_

### LockedThresholdsUpdated

```solidity
event LockedThresholdsUpdated(address[] tokens, uint256[] thresholds)
```

_Emitted when the thresholds for locked withdrawals are updated_

### DailyWithdrawalLimitsUpdated

```solidity
event DailyWithdrawalLimitsUpdated(address[] tokens, uint256[] limits)
```

_Emitted when the daily limit thresholds are updated_

### WithdrawalLocked

```solidity
event WithdrawalLocked(uint256 withdrawId)
```

_Emitted when the withdrawal is locked_

### WithdrawalUnlocked

```solidity
event WithdrawalUnlocked(uint256 withdrawId)
```

_Emitted when the withdrawal is unlocked_

### TYPE_HASH

```solidity
function TYPE_HASH() external view returns (bytes32)
```

### initialize

```solidity
function initialize(address validator, address admin, address withdrawalUnlocker, address[] mainchainTokens, uint256[][2] thresholds, address[] crossbellTokens, uint8[] crossbellTokenDecimals) external
```

Initializes the MainchainGateway.
Note that the thresholds contains:
 - thresholds[0]: lockedThresholds The amount thresholds to lock withdrawal.
 - thresholds[1]: dailyWithdrawalLimits Daily withdrawal limits for mainchain tokens.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| validator | address | Address of validator contract. |
| admin | address | Address of gateway admin. |
| withdrawalUnlocker | address | Address of operator who can unlock the locked withdrawals. |
| mainchainTokens | address[] | Addresses of mainchain tokens. |
| thresholds | uint256[][2] | The amount thresholds  for withdrawal. |
| crossbellTokens | address[] | Addresses of crossbell tokens. |
| crossbellTokenDecimals | uint8[] | Decimals of crossbell tokens. |

### pause

```solidity
function pause() external
```

Pause interaction with the gateway contract

### unpause

```solidity
function unpause() external
```

Resume interaction with the gateway contract

### requestDeposit

```solidity
function requestDeposit(address recipient, address token, uint256 amount) external returns (uint256 depositId)
```

Request deposit to crossbell chain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| recipient | address | Address to receive deposit on crossbell chain |
| token | address | Address of token to deposit |
| amount | uint256 | Amount of token to deposit |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| depositId | uint256 | Deposit id |

### withdraw

```solidity
function withdraw(uint256 chainId, uint256 withdrawalId, address recipient, address token, uint256 amount, struct DataTypes.Signature[] signatures) external returns (bool locked)
```

Withdraw based on the validator signatures.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainId | uint256 | ChainId |
| withdrawalId | uint256 | Withdrawal ID from crossbell chain |
| recipient | address | Address to receive withdrawal on mainchain chain |
| token | address | Address of token to withdraw |
| amount | uint256 | Amount of token to withdraw |
| signatures | struct DataTypes.Signature[] | Validator signatures for withdrawal |

### unlockWithdrawal

```solidity
function unlockWithdrawal(uint256 chainId, uint256 withdrawalId, address recipient, address token, uint256 amount) external
```

Approves a specific withdrawal..
Note that the caller must have WITHDRAWAL_UNLOCKER_ROLE.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainId | uint256 | ChainId |
| withdrawalId | uint256 | Withdrawal ID from crossbell chain |
| recipient | address | Address to receive withdrawal on mainchain chain |
| token | address | Address of token to withdraw |
| amount | uint256 | Amount of token to withdraw |

### setLockedThresholds

```solidity
function setLockedThresholds(address[] tokens, uint256[] thresholds) external
```

Sets the amount thresholds to lock withdrawal.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokens | address[] | Addresses of token to set |
| thresholds | uint256[] | Thresholds corresponding to the tokens to set |

### setDailyWithdrawalLimits

```solidity
function setDailyWithdrawalLimits(address[] tokens, uint256[] limits) external
```

Sets daily limit amounts for the withdrawals.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokens | address[] | Addresses of token to set |
| limits | uint256[] | Limits corresponding to the tokens to set Requirements: - The caller must have the admin role. - The arrays have the same length. Emits the `DailyWithdrawalLimitsUpdated` event. |

### verifySignatures

```solidity
function verifySignatures(bytes32 hash, struct DataTypes.Signature[] signatures) external view returns (bool)
```

Returns true if there is enough signatures from validators.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| hash | bytes32 | WithdrawHash |
| signatures | struct DataTypes.Signature[] | Validator's withdrawal signatures synced from crossbell network |

### getValidatorContract

```solidity
function getValidatorContract() external view returns (address)
```

Returns the address of the validator contract.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The validator contract address |

### getDepositCount

```solidity
function getDepositCount() external view returns (uint256)
```

Returns the deposit count of the gateway contract.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The deposit count |

### getWithdrawalHash

```solidity
function getWithdrawalHash(uint256 withdrawalId) external view returns (bytes32)
```

Returns the withdrawal hash by withdrawal id.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| withdrawalId | uint256 | WithdrawalId to query |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | The withdrawal hash |

### getWithdrawalLocked

```solidity
function getWithdrawalLocked(uint256 withdrawalId) external view returns (bool)
```

Returns whether the withdrawal is locked or not.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| withdrawalId | uint256 | WithdrawalId to query |

### getWithdrawalLockedThreshold

```solidity
function getWithdrawalLockedThreshold(address token) external view returns (uint256)
```

Returns the amount thresholds to lock withdrawal.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | Token address |

### reachedDailyWithdrawalLimit

```solidity
function reachedDailyWithdrawalLimit(address token, uint256 amount) external view returns (bool)
```

Checks whether the withdrawal reaches the daily limitation.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | Token address to withdraw |
| amount | uint256 | Token amount to withdraw |

### getCrossbellToken

```solidity
function getCrossbellToken(address mainchainToken) external view returns (struct DataTypes.MappedToken token)
```

Get mapped tokens from crossbell chain

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| mainchainToken | address | Token address on mainchain |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | struct DataTypes.MappedToken | Mapped token from crossbell chain |
