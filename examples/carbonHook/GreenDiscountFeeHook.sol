// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { ConfirmedOwner } from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {IDynamicFeeManager} from "https://github.com/Uniswap/v4-core/src/interfaces/IDynamicFeeManager.sol";
import {IPoolManager} from "https://github.com/Uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "https://github.com/Uniswap/v4-core/src/libraries/Hooks.sol";
import {PoolKey, PoolIdLibrary} from "https://github.com/Uniswap/v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "https://github.com/Uniswap/v4-core/src/types/BalanceDelta.sol";
import {BaseHook} from "https://github.com/Uniswap/v4-periphery/contracts/BaseHook.sol";
import '../../contracts/CarbonQuery.sol';

/**
 * @title GreenDiscountFeeHook
 * @notice This is an example contract to show how CarbonLayer could be used with Uniswap V4 Pools that involve RWA's
 *      charge a fee dependent on the current state of energy production
 */
contract GreenDiscountFeeHook is BaseHook, IDynamicFeeManager, ConfirmedOwner {
    using PoolIdLibrary for PoolKey;
    uint256 public standardFee = 3000;
    uint256 public reducedFee = 1000;
    uint16 public threshold = 3000;
    CarbonQuery public carbonQueryInstance;

    // Events
    event CarbonQueryInstanceSet(address indexed _carbonQueryAddress);

    /**
     * @notice Initializes the contract with the carbon query address and sets the contract owner
     * @param _poolManager The address of the Uniswap V4 pool manager contract
     * @param _carbonQueryAddress The address of the contract to call to get the current carbon index
     */
    constructor(IPoolManager _poolManager, address _carbonQueryAddress) BaseHook(_poolManager) ConfirmedOwner(msg.sender){
        setCarbonQuery(_carbonQueryAddress);
    }

    /**
     * @notice Update the retained address of the carbon index contract
     * @param _carbonQueryAddress The address of the contract to call to get the current carbon index
     */
    function setCarbonQuery(address _carbonQueryAddress) public onlyOwner {
        require(_carbonQueryAddress != address(0), 'Invalid CarbonQuery address');

        carbonQueryInstance = CarbonQuery(_carbonQueryAddress);

        emit CarbonQueryInstanceSet(_carbonQueryAddress);
    }

    /**
     * @notice Update the fees charged for swaps.
     * @param _standardFee Setter fof the fee charged when the index is below the threshold
     * @param _reducedFee Setter for the fee charged when the index is above the threshold
     */
    function setFees(uint256 _standardFee, uint256 _reducedFee) external onlyOwner {
        standardFee = _standardFee;
        reducedFee = _reducedFee;
    }

    /**
     * @notice Update the threshold at which reduced fees are charged
     * @param _threshold Setter for the rescued charges threshold
     */
    function setThreshold(uint16 _threshold) external onlyOwner {
        threshold = _threshold;
    }


    /**
     * @notice Gets the hooks that this overrides
     */
    function getHooksCalls() public pure override returns (Hooks.Calls memory) {
        return Hooks.Calls({
            beforeInitialize: false,
            afterInitialize: false,

            beforeModifyPosition: false,
            afterModifyPosition: false,

            beforeSwap: false,
            afterSwap: false,

            beforeDonate: false,
            afterDonate: false,
            noOp: false
        });
    }

    /**
     * @notice The dynamic fee manager determines fees for pools
     * @dev note that this pool is only called if the PoolKey fee value is equal to the DYNAMIC_FEE magic value
     */
    function getFee(address /*sender*/, PoolKey calldata /*key*/) external view returns (uint24 fee) {
        bool isCarbonNeutral = carbonQueryInstance.carbonNeutralPowered(threshold);

        uint256 result = isCarbonNeutral ? reducedFee : standardFee;

        return uint24(result);
    }
}
