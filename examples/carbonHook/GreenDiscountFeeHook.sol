// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {IDynamicFeeManager} from "https://github.com/Uniswap/v4-core/src/interfaces/IDynamicFeeManager.sol";
import {IPoolManager} from "https://github.com/Uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "https://github.com/Uniswap/v4-core/src/libraries/Hooks.sol";
import {PoolKey, PoolIdLibrary} from "https://github.com/Uniswap/v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "https://github.com/Uniswap/v4-core/src/types/BalanceDelta.sol";
import {BaseHook} from "https://github.com/Uniswap/v4-periphery/contracts/BaseHook.sol";
import '../../contracts/CarbonQuery.sol';

// Discount pool fees for pools that involve real world asset tokens that track energy providers
contract GreenDiscountFeeHook is BaseHook, IDynamicFeeManager {
    using PoolIdLibrary for PoolKey;
    address public owner;
    uint256 public standardFee = 3000;
    uint256 public reducedFee = 1000;
    uint16 public threshold = 3000;
    CarbonQuery public carbonQueryInstance;

    event CarbonQueryInstanceSet(address indexed _carbonQueryAddress);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor(IPoolManager _poolManager, address _carbonQueryAddress) BaseHook(_poolManager) {

        owner = msg.sender;
        setCarbonQuery(_carbonQueryAddress);

    }

    function setCarbonQuery(address _carbonQueryAddress) public onlyOwner {
        require(_carbonQueryAddress != address(0), 'Invalid CarbonQuery address');

        carbonQueryInstance = CarbonQuery(_carbonQueryAddress);

        emit CarbonQueryInstanceSet(_carbonQueryAddress);
    }

    function setFees(uint256 _standardFee, uint256 _reducedFee) external onlyOwner {
        standardFee = _standardFee;
        reducedFee = _reducedFee;
    }

    function setThreshold(uint16 _threshold) external onlyOwner {
        threshold = _threshold;
    }

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

    function getFee(address /*sender*/, PoolKey calldata /*key*/) external view returns (uint24 fee)     {
        bool isCarbonNeutral = carbonQueryInstance.carbonNeutralPowered(threshold);

        uint256 result = isCarbonNeutral ? reducedFee : standardFee;

        return uint24(result);

    }
}
