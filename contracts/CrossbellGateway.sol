// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
pragma experimental ABIEncoderV2;

import "./interfaces/IERC20Mintable.sol";
import "./libraries/ECVerify.sol";
import "./interfaces/IValidator.sol";
import "./interfaces/ICrossbellGateway.sol";
import "./storage/CrossbellGatewayStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title CrossbellGateway
 * @dev Logic to handle deposits and withdrawals on Sidechain.
 */
contract CrossbellGateway is ICrossbellGateway, Initializable, Pausable, CrossbellGatewayStorage {
    using ECVerify for bytes32;
    using SafeERC20 for IERC20;

    modifier onlyValidator() {
        _checkValidator();
        _;
    }

    modifier onlyAdmin() {
        _checkAdmin();
        _;
    }

    function _checkAdmin() internal view {
        require(_msgSender() == _admin, "onlyAdmin");
    }

    function _checkValidator() internal view {
        require(IValidator(_validator).isValidator(_msgSender()), "NotValidator");
    }

    function initialize(
        address validator,
        address admin,
        address[] calldata crossbellTokens,
        uint256[] calldata chainIds,
        address[] calldata mainchainTokens,
        uint8[] calldata mainchainTokenDecimals
    ) external initializer {
        _validator = validator;
        _admin = admin;

        // map mainchain tokens
        if (crossbellTokens.length > 0) {
            _mapTokens(crossbellTokens, chainIds, mainchainTokens, mainchainTokenDecimals);
        }
    }

    /**
     * @notice Pause interaction with the gateway contract
     */
    function pause() external whenNotPaused onlyAdmin {
        _pause();
    }

    /**
     * @notice Resume interaction with the gateway contract
     */
    function unpause() external whenPaused onlyAdmin {
        _unpause();
    }

    function batchAckDeposit(
        uint256[] calldata chainIds,
        uint256[] calldata depositIds,
        address[] calldata recipients,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external whenNotPaused onlyValidator {
        require(
            depositIds.length == chainIds.length &&
                depositIds.length == recipients.length &&
                depositIds.length == amounts.length,
            "InvalidArrayLength"
        );

        for (uint256 i; i < depositIds.length; i++) {
            _ackDeposit(chainIds[i], depositIds[i], recipients[i], tokens[i], amounts[i]);
        }
    }

    function batchSubmitWithdrawalSignatures(
        uint256[] calldata chainIds,
        uint256[] calldata withdrawalIds,
        bool[] calldata shouldReplaces,
        bytes[] calldata sigs
    ) external whenNotPaused onlyValidator {
        require(
            withdrawalIds.length == chainIds.length &&
                withdrawalIds.length == shouldReplaces.length &&
                withdrawalIds.length == sigs.length,
            "InvalidArrayLength"
        );

        for (uint256 i; i < withdrawalIds.length; i++) {
            _submitWithdrawalSignatures(chainIds[i], withdrawalIds[i], shouldReplaces[i], sigs[i]);
        }
    }

    function ackDeposit(
        uint256 chainId,
        uint256 depositId,
        address recipient,
        address token,
        uint256 amount
    ) external {
        _ackDeposit(chainId, depositId, recipient, token, amount);
    }

    function _ackDeposit(
        uint256 chainId,
        uint256 depositId,
        address recipient,
        address token,
        uint256 amount
    ) internal whenNotPaused onlyValidator {
        bytes32 hash = keccak256(abi.encode(recipient, chainId, depositId, token, amount));

        DataTypes.Status status = _acknowledge(chainId, depositId, hash, msg.sender);

        if (status == DataTypes.Status.FirstApproved) {
            _depositFor(recipient, token, amount);

            _deposits[chainId][depositId] = DepositEntry(chainId, recipient, token, amount);
            emit Deposited(chainId, depositId, recipient, token, amount);
        }

        emit AckDeposit(chainId, depositId, recipient, token, amount);
    }

    function requestWithdrawal(
        uint256 chainId,
        address recipient,
        address token,
        uint256 amount
    ) external whenNotPaused returns (uint256 withdrawId) {
        DataTypes.MappedToken memory mainchainToken = _getMainchainToken(chainId, token);
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // transform token amount by different chain
        uint256 transformedAmount = _transformWithdrawalAmount(
            token,
            amount,
            mainchainToken.decimals
        );

        withdrawId = _withdrawalCounts[chainId];
        unchecked {
            _withdrawalCounts[chainId]++;
        }
        _withdrawals[chainId][withdrawId] = WithdrawalEntry(
            chainId,
            recipient,
            token,
            transformedAmount,
            amount
        );

        emit RequestWithdrawal(chainId, withdrawId, recipient, token, transformedAmount, amount);
    }

    function _transformWithdrawalAmount(
        address token,
        uint256 amount,
        uint8 destinationDecimals
    ) internal view returns (uint256 transformedAmount) {
        uint8 decimals = IERC20Metadata(token).decimals();

        if (destinationDecimals == decimals) {
            transformedAmount = amount;
        } else if (destinationDecimals > decimals) {
            transformedAmount = amount * 10 ** (destinationDecimals - decimals);
        } else {
            transformedAmount = amount / (10 ** (decimals - destinationDecimals));
        }
    }

    function getMainchainToken(
        uint256 chainId,
        address crossbellToken
    ) external view returns (DataTypes.MappedToken memory token) {
        return _getMainchainToken(chainId, crossbellToken);
    }

    function submitWithdrawalSignatures(
        uint256 chainId,
        uint256 withdrawalId,
        bool shouldReplace,
        bytes calldata sig
    ) external {
        _submitWithdrawalSignatures(chainId, withdrawalId, shouldReplace, sig);
    }

    function _submitWithdrawalSignatures(
        uint256 chainId,
        uint256 withdrawalId,
        bool shouldReplace,
        bytes calldata sig
    ) internal whenNotPaused onlyValidator {
        bytes memory currentSig = withdrawalSig[chainId][withdrawalId][msg.sender];

        bool alreadyHasSig = currentSig.length != 0;

        if (!shouldReplace && alreadyHasSig) {
            return;
        }

        withdrawalSig[chainId][withdrawalId][msg.sender] = sig;
        if (!alreadyHasSig) {
            _withdrawalSigners[chainId][withdrawalId].push(msg.sender);
        }
    }

    /**
     * Request signature again, in case the withdrawer didn't submit to mainchain in time and the set of the validator
     * has changed.
     */
    function requestSignatureAgain(uint256 chainId, uint256 withdrawalId) external whenNotPaused {
        WithdrawalEntry memory entry = _withdrawals[chainId][withdrawalId];

        require(entry.recipient == msg.sender, "NotEntryOwner");

        emit RequestWithdrawalSigAgain(
            chainId,
            withdrawalId,
            entry.recipient,
            entry.token,
            entry.amount
        );
    }

    function _acknowledge(
        uint256 chainId,
        uint256 id,
        bytes32 hash,
        address validator
    ) internal returns (DataTypes.Status) {
        require(_validatorAck[chainId][id][validator] == bytes32(0), "AlreadyAcknowledged");

        _validatorAck[chainId][id][validator] = hash;
        DataTypes.Status status = _ackStatus[chainId][id][hash];
        uint256 count = _ackCount[chainId][id][hash];

        if (IValidator(_validator).checkThreshold(count + 1)) {
            if (status == DataTypes.Status.NotApproved) {
                _ackStatus[chainId][id][hash] = DataTypes.Status.FirstApproved;
            } else {
                _ackStatus[chainId][id][hash] = DataTypes.Status.AlreadyApproved;
            }
        }

        _ackCount[chainId][id][hash]++;

        return _ackStatus[chainId][id][hash];
    }

    function getAcknowledgementStatus(
        uint256 chainId,
        uint256 id,
        bytes32 hash
    ) external view returns (DataTypes.Status) {
        return _ackStatus[chainId][id][hash];
    }

    function getWithdrawalSigners(
        uint256 chainId,
        uint256 withdrawalId
    ) external view returns (address[] memory) {
        return _getWithdrawalSigners(chainId, withdrawalId);
    }

    function getWithdrawalSignatures(
        uint256 chainId,
        uint256 withdrawalId
    ) external view returns (address[] memory signers, bytes[] memory sigs) {
        signers = _getWithdrawalSigners(chainId, withdrawalId);
        sigs = new bytes[](signers.length);
        for (uint256 i = 0; i < signers.length; i++) {
            sigs[i] = withdrawalSig[chainId][withdrawalId][signers[i]];
        }
    }

    /**
     * @notice Returns the address of the validator contract.
     * @return The validator contract address
     */
    function getValidatorContract() external view returns (address) {
        return _validator;
    }

    /**
     * @notice Returns the admin address of the gateway contract.
     * @return The admin address
     */
    function getAdmin() external view returns (address) {
        return _admin;
    }

    function _depositFor(address recipient, address token, uint256 amount) internal {
        uint256 gatewayBalance = IERC20(token).balanceOf(address(this));
        if (gatewayBalance < amount) {
            IERC20Mintable(token).mint(address(this), amount - gatewayBalance);
        }

        IERC20(token).safeTransfer(recipient, amount);
    }

    function _getWithdrawalSigners(
        uint256 chainId,
        uint256 withdrawalId
    ) internal view returns (address[] memory) {
        return _withdrawalSigners[chainId][withdrawalId];
    }

    function _getMainchainToken(
        uint256 chainId,
        address crossbellToken
    ) internal view returns (DataTypes.MappedToken memory token) {
        token = _mainchainToken[crossbellToken][chainId];
    }

    function _mapTokens(
        address[] calldata crossbellTokens,
        uint256[] calldata chainIds,
        address[] calldata mainchainTokens,
        uint8[] calldata mainchainTokenDecimals
    ) internal virtual {
        require(
            crossbellTokens.length == mainchainTokens.length &&
                crossbellTokens.length == mainchainTokenDecimals.length &&
                crossbellTokens.length == chainIds.length,
            "InvalidArrayLength"
        );

        for (uint i = 0; i < crossbellTokens.length; i++) {
            _mainchainToken[crossbellTokens[i]][chainIds[i]] = DataTypes.MappedToken({
                tokenAddr: mainchainTokens[i],
                decimals: mainchainTokenDecimals[i]
            });
        }
        emit TokenMapped(crossbellTokens, chainIds, mainchainTokens, mainchainTokenDecimals);
    }
}