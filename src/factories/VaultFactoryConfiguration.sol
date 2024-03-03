// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {BorrowInterestRateAdjustmentMath} from "../libraries/BorrowInterestRateAdjustmentMath.sol";
import {CommonErrors} from "../interfaces/CommonErrors.sol";
import {IVaultFactory} from "../interfaces/IVaultFactory.sol";
import {Constants} from "../libraries/Constants.sol";
import {StackVault} from "../vaults/StackVault.sol";
import {VaultFactoryBulkOperations} from "./VaultFactoryBulkOperations.sol";
import {VaultFactoryERC7201} from "./VaultFactoryERC7201.sol";

/**
 * @title Vault Factory Configuration Contract
 * @notice Abstract contract for managing global configuration settings of the vault factory.
 * @dev Extends the VaultFactoryERC7201 contract to provide functionalities for updating key configuration parameters
 *      such as borrow token oracle, interest rate manager, swap targets, and various fee-related settings.
 *      It includes events for tracking changes to these configurations. The contract ensures that only the owner can
 *      modify these critical settings. It also provides functions to view current configuration states.
 *      Additionally, it contains the logic for accruing interest across all vaults.
 * @author SeaZarrgh LaBuoy
 */
abstract contract VaultFactoryConfiguration is
    CommonErrors,
    OwnableUpgradeable,
    VaultFactoryBulkOperations,
    VaultFactoryERC7201
{
    using BorrowInterestRateAdjustmentMath for uint256;
    using SafeCast for uint256;

    event BorrowTokenOracleChanged(address indexed oldOracle, address indexed newOracle);
    event BorrowInterestRateChanged(uint256 oldInterestRate, uint256 newInterestRate);
    event DebtCollectorChanged(address indexed oldDebtCollector, address indexed newDebtCollector);
    event FeeReceiverChanged(address indexed oldFeeReceiver, address indexed newFeeReceiver);
    event InterestRateManagerChanged(address indexed oldManager, address indexed newManager);
    event PenaltyReceiverChanged(address indexed oldPenaltyReceiver, address indexed newPenaltyReceiver);
    event SwapTargetTrustChanged(address indexed target, bool oldTrust, bool newTrust);
    event VaultDeployerChanged(address indexed oldVaultDeployer, address indexed newVaultDeployer);
    event LiquidationPenaltyFeeChanged(uint256 oldFee, uint256 newFee);
    event LiquidatorPenaltyShareChanged(uint96 oldShare, uint96 newShare);

    constructor(address _borrowTokenMinter) VaultFactoryERC7201(_borrowTokenMinter) {}

    /**
     * @inheritdoc IVaultFactory
     */
    function accrueInterest() public virtual override(IVaultFactory, VaultFactoryBulkOperations);

    /**
     * @notice Gets the address of the oracle used for the borrow token.
     * @dev Returns the address of the borrow token oracle from the VaultFactoryStorage.
     *      This oracle provides price data for the borrow token, which is crucial for various calculations and
     *      operations in the system.
     * @return oracle The address of the borrow token oracle.
     */
    function borrowTokenOracle() external view returns (address oracle) {
        VaultFactoryStorage storage $ = _getVaultFactoryStorage();
        oracle = $.borrowTokenOracle;
    }

    /**
     * @notice Retrieves the current borrow interest rate.
     * @dev Returns the current global borrow interest rate from the VaultFactoryStorage.
     *      This rate is used to calculate interest on borrowed funds across all vaults.
     * @return rate The current global borrow interest rate.
     */
    function borrowInterestRate() external view returns (uint256 rate) {
        VaultFactoryStorage storage $ = _getVaultFactoryStorage();
        rate = $.borrowInterestRate;
    }

    /**
     * @notice Gets the address of the debt collector.
     * @dev Returns the address responsible for debt collection from the VaultFactoryStorage.
     *      The debt collector is a crucial component in managing debts across the vault system.
     * @return collector The address of the current debt collector.
     */
    function debtCollector() external view returns (address collector) {
        VaultFactoryStorage storage $ = _getVaultFactoryStorage();
        collector = $.debtCollector;
    }

    /**
     * @notice Retrieves the address where collected fees are sent.
     * @dev Returns the address of the fee receiver from the VaultFactoryStorage.
     *      The fee receiver is the entity to which various fees collected within the vault system are sent.
     * @return receiver The address of the current fee receiver.
     */
    function feeReceiver() external view returns (address receiver) {
        VaultFactoryStorage storage $ = _getVaultFactoryStorage();
        receiver = $.feeReceiver;
    }

    /**
     * @notice Retrieves the address of the interest rate manager.
     * @dev Returns the address of the entity responsible for managing interest rates from the VaultFactoryStorage.
     *      The interest rate manager plays a key role in adjusting and updating interest rates within the system.
     * @return manager The address of the current interest rate manager.
     */
    function interestRateManager() external view returns (address manager) {
        VaultFactoryStorage storage $ = _getVaultFactoryStorage();
        manager = $.interestRateManager;
    }

    /**
     * @notice Gets the address where penalties are sent.
     * @dev Returns the address of the penalty receiver from the VaultFactoryStorage.
     *      This entity receives the penalties incurred in various operations within the vault system, such as
     *      liquidations.
     * @return receiver The address of the current penalty receiver.
     */
    function penaltyReceiver() external view returns (address receiver) {
        VaultFactoryStorage storage $ = _getVaultFactoryStorage();
        receiver = $.penaltyReceiver;
    }

    /**
     * @notice Retrieves the share of penalties allocated to the liquidator.
     * @dev Returns the share of liquidation penalties allocated to the liquidator from the VaultFactoryStorage.
     *      This share determines the portion of penalties received by the liquidator during the liquidation process.
     * @return share The share of liquidation penalties allocated to the liquidator.
     */
    function liquidatorPenaltyShare() external view returns (uint256 share) {
        VaultFactoryStorage storage $ = _getVaultFactoryStorage();
        share = $.liquidatorPenaltyShare;
    }

    /**
     * @notice Retrieves the address of the vault deployer.
     * @dev Returns the address of the vault deployer from the VaultFactoryStorage.
     *     The vault deployer is responsible for creating new vaults within the system.
     * @return deployer The address of the current vault deployer.
     */
    function vaultDeployer() external view returns (address deployer) {
        VaultFactoryStorage storage $ = _getVaultFactoryStorage();
        return $.vaultDeployer;
    }

    /**
     * @notice Checks if a given address is a trusted swap target.
     * @dev Returns a boolean indicating whether the specified target address is marked as trusted for swaps in the
     *      VaultFactoryStorage.
     *      Trusted swap targets are addresses that are allowed to be used for swapping assets within the system.
     * @param target The address to check for trust status.
     * @return trusted A boolean indicating if the target is a trusted swap target.
     */
    function isTrustedSwapTarget(address target) external view returns (bool trusted) {
        VaultFactoryStorage storage $ = _getVaultFactoryStorage();
        trusted = $.trustedSwapTargets[target];
    }

    /**
     * @notice Sets a new oracle for the borrow token.
     * @dev Updates the address of the borrow token oracle in the VaultFactoryStorage.
     *      The borrow token oracle provides essential price data for the borrow token.
     *      This action can only be performed by the contract owner.
     *      Emits a `BorrowTokenOracleChanged` event upon successful update.
     *      Reverts if the new oracle address is the same as the current one to prevent unnecessary transactions.
     * @param newOracle The address of the new oracle for the borrow token.
     */
    function setBorrowTokenOracle(address newOracle) public onlyOwner {
        VaultFactoryStorage storage $ = _getVaultFactoryStorage();
        if (newOracle == address(0)) {
            revert InvalidZeroAddress();
        }
        address oldOracle = $.borrowTokenOracle;
        if (oldOracle == newOracle) {
            revert ValueUnchanged();
        }
        $.borrowTokenOracle = newOracle;
        emit BorrowTokenOracleChanged(oldOracle, newOracle);
    }

    /**
     * @notice Assigns a new interest rate manager.
     * @dev Updates the address responsible for managing interest rates in the VaultFactoryStorage.
     *      The interest rate manager is authorized to adjust interest rates within the system.
     *      Access to this function is restricted to the contract owner.
     *      Reverts if the new manager address is the same as the current one to avoid unnecessary updates.
     * @param newManager The address of the new interest rate manager.
     */
    function setInterestRateManager(address newManager) public onlyOwner {
        VaultFactoryStorage storage $ = _getVaultFactoryStorage();
        address oldManager = $.interestRateManager;
        if (oldManager == newManager) {
            revert ValueUnchanged();
        }
        $.interestRateManager = newManager;
        emit InterestRateManagerChanged(oldManager, newManager);
    }

    /**
     * @notice Updates the trust status of a swap target address.
     * @dev Sets the specified address as a trusted or untrusted swap target in the VaultFactoryStorage.
     *      Trusted swap targets are allowed for asset swaps within the system.
     *      Access to this function is restricted to the contract owner.
     *      Reverts if the target's new trust status is the same as the current status to avoid unnecessary updates.
     * @param target The address of the swap target to update.
     * @param trusted A boolean indicating whether the target should be trusted.
     */
    function setTrustedSwapTarget(address target, bool trusted) public onlyOwner {
        VaultFactoryStorage storage $ = _getVaultFactoryStorage();
        bool wasTrusted = $.trustedSwapTargets[target];
        if (wasTrusted == trusted) {
            revert ValueUnchanged();
        }
        $.trustedSwapTargets[target] = trusted;
        emit SwapTargetTrustChanged(target, wasTrusted, trusted);
    }

    /**
     * @notice Updates the global borrow interest rate based on the reference price.
     * @dev Adjusts the borrow interest rate using a reference price, typically provided by an oracle.
     *      Invokes `accrueInterest` to ensure interest is accrued before updating the rate.
     *      Can only be called by the interest rate manager.
     *      Emits a `BorrowInterestRateChanged` event upon successful update.
     *      Reverts if the caller is not the interest rate manager or if the updated rate is the same as the current
     *      rate.
     * @param referencePrice The reference price used to adjust the borrow interest rate.
     */
    function updateBorrowInterestRate(uint256 referencePrice) external {
        accrueInterest();
        VaultFactoryStorage storage $ = _getVaultFactoryStorage();
        if (msg.sender != $.interestRateManager) {
            revert UnauthorizedCaller();
        }
        uint256 oldInterestRate = $.borrowInterestRate;
        uint256 newInterestRate =
            oldInterestRate.adjustBorrowInterestRate(referencePrice, Constants.ORACLE_PRICE_PRECISION);
        if (oldInterestRate == newInterestRate) {
            revert ValueUnchanged();
        }
        $.borrowInterestRate = SafeCast.toUint96(newInterestRate);
        emit BorrowInterestRateChanged(oldInterestRate, newInterestRate);
    }

    /**
     * @notice Overrides the current borrow interest rate with a new rate.
     * @dev Directly sets a new borrow interest rate in the VaultFactoryStorage.
     *      Invokes `accrueInterest` before applying the new rate to ensure up-to-date interest calculations.
     *      Restricted to the contract owner.
     *      Emits a `BorrowInterestRateChanged` event upon successful update.
     *      Reverts if the new interest rate is the same as the current rate to prevent unnecessary updates.
     * @param newInterestRate The new borrow interest rate to be set.
     */
    function overrideBorrowInterestRate(uint256 newInterestRate) public onlyOwner {
        accrueInterest();
        VaultFactoryStorage storage $ = _getVaultFactoryStorage();
        uint256 oldInterestRate = $.borrowInterestRate;
        if (oldInterestRate == newInterestRate) {
            revert ValueUnchanged();
        }
        $.borrowInterestRate = SafeCast.toUint96(newInterestRate);
        emit BorrowInterestRateChanged(oldInterestRate, newInterestRate);
    }

    /**
     * @notice Assigns a new debt collector.
     * @dev Updates the address responsible for debt collection in the VaultFactoryStorage.
     *      The debt collector is a key entity in managing and collecting debts within the system.
     *      Restricted to the contract owner.
     *      Emits a `DebtCollectorChanged` event upon successful update.
     *      Reverts if the new debt collector's address is the same as the current one to prevent unnecessary updates.
     * @param newDebtCollector The address of the new debt collector.
     */
    function setDebtCollector(address newDebtCollector) public onlyOwner {
        VaultFactoryStorage storage $ = _getVaultFactoryStorage();
        address oldDebtCollector = $.debtCollector;
        if (oldDebtCollector == newDebtCollector) {
            revert ValueUnchanged();
        }
        $.debtCollector = newDebtCollector;
        emit DebtCollectorChanged(oldDebtCollector, newDebtCollector);
    }

    /**
     * @notice Sets a new address for receiving fees.
     * @dev Updates the fee receiver's address in the VaultFactoryStorage.
     *      The fee receiver is the entity where various fees collected within the system are sent.
     *      Restricted to the contract owner.
     *      Emits a `FeeReceiverChanged` event upon successful update.
     *      Reverts if the new fee receiver's address is either the zero address or the same as the current one.
     * @param newFeeReceiver The address of the new fee receiver.
     */
    function setFeeReceiver(address newFeeReceiver) public onlyOwner {
        VaultFactoryStorage storage $ = _getVaultFactoryStorage();
        if (newFeeReceiver == address(0)) {
            revert InvalidZeroAddress();
        }
        address oldFeeReceiver = $.feeReceiver;
        if (oldFeeReceiver == newFeeReceiver) {
            revert ValueUnchanged();
        }
        $.feeReceiver = newFeeReceiver;
        emit FeeReceiverChanged(oldFeeReceiver, newFeeReceiver);
    }

    /**
     * @notice Assigns a new address for receiving penalties.
     * @dev Updates the penalty receiver's address in the VaultFactoryStorage.
     *      The penalty receiver is the entity where penalties incurred within the system, such as liquidation
     *      penalties, are sent.
     *      Restricted to the contract owner.
     *      Emits a `PenaltyReceiverChanged` event upon successful update.
     *      Reverts if the new penalty receiver's address is either the zero address or the same as the current one.
     * @param newPenaltyReceiver The address of the new penalty receiver.
     */
    function setPenaltyReceiver(address newPenaltyReceiver) public onlyOwner {
        VaultFactoryStorage storage $ = _getVaultFactoryStorage();
        if (newPenaltyReceiver == address(0)) {
            revert InvalidZeroAddress();
        }
        address oldPenaltyReceiver = $.penaltyReceiver;
        if (oldPenaltyReceiver == newPenaltyReceiver) {
            revert ValueUnchanged();
        }
        $.penaltyReceiver = newPenaltyReceiver;
        emit PenaltyReceiverChanged(oldPenaltyReceiver, newPenaltyReceiver);
    }

    /**
     * @notice Updates the share of liquidation penalties allocated to the liquidator.
     * @dev Sets a new liquidator penalty share in the VaultFactoryStorage.
     *      This share determines the fraction of liquidation penalties that are allocated to the liquidator during the
     *      liquidation process.
     *      Restricted to the contract owner.
     *      Emits a `LiquidatorPenaltyShareChanged` event upon successful update.
     *      Reverts if the new share is the same as the current share to avoid unnecessary updates.
     * @param newShare The new share of liquidation penalties to be allocated to the liquidator.
     */
    function setLiquidatorPenaltyShare(uint96 newShare) public onlyOwner {
        VaultFactoryStorage storage $ = _getVaultFactoryStorage();
        uint96 oldShare = $.liquidatorPenaltyShare;
        if (oldShare == newShare) {
            revert ValueUnchanged();
        }
        $.liquidatorPenaltyShare = newShare;
        emit LiquidatorPenaltyShareChanged(oldShare, newShare);
    }

    /**
     * @notice Updates the vault deployer address.
     * @dev Sets a new address for the vault deployer in the VaultFactoryStorage.
     *      The vault deployer is responsible for creating new vaults within the system.
     *      Restricted to the contract owner.
     *      Reverts if the new vault deployer's address is the same as the current one to prevent unnecessary updates.
     * @param newVaultDeployer The address of the new vault deployer.
     */
    function setVaultDeployer(address newVaultDeployer) public onlyOwner {
        VaultFactoryStorage storage $ = _getVaultFactoryStorage();
        if (newVaultDeployer == address(0)) {
            revert InvalidZeroAddress();
        }
        address oldVaultDeployer = $.vaultDeployer;
        if (oldVaultDeployer == newVaultDeployer) {
            revert ValueUnchanged();
        }
        $.vaultDeployer = newVaultDeployer;
        emit VaultDeployerChanged(oldVaultDeployer, newVaultDeployer);
    }
}
