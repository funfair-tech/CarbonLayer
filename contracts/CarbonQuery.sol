// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol';
import './CarbonLayer.sol';

contract CarbonQuery is ConfirmedOwner {
    CarbonLayer public carbonLayerInstance;

    event CarbonLayerSet(address indexed carbonLayerAddress);

    constructor(address _carbonLayerAddress) ConfirmedOwner(msg.sender) {
        setCarbonLayer(_carbonLayerAddress);
    }

    function setCarbonLayer(address _carbonLayerAddress) public onlyOwner {
        require(_carbonLayerAddress != address(0), 'Invalid CarbonLayer address');

        carbonLayerInstance = CarbonLayer(_carbonLayerAddress);

        emit CarbonLayerSet(_carbonLayerAddress);
    }

    function isSolarPowered(uint16 _threshold) external view returns (bool) {
        require(address(carbonLayerInstance) != address(0), 'CarbonLayer instance not set');

        uint16 percentageSolarFuel = carbonLayerInstance.getFuelPercentage('solar');

        return percentageSolarFuel > _threshold;
    }

    function carbonNeutralPowered(uint16 _threshold) external view returns (bool) {
        require(address(carbonLayerInstance) != address(0), 'CarbonLayer instance not set');

        uint16 percentageRenewableFuel = 0;

        string[] memory carbonNeutralFuels = carbonLayerInstance.getCarbonNeutralFuels();

        for (uint256 i = 0; i < carbonNeutralFuels.length; i++) {
            percentageRenewableFuel += carbonLayerInstance.getFuelPercentage(carbonNeutralFuels[i]);
        }

        return percentageRenewableFuel > _threshold;
    }

    function aboveIntensityThreshold(string memory _threshold) external view returns (bool) {
        require(address(carbonLayerInstance) != address(0), 'CarbonLayer instance not set');

        Intensity intensityThreshold = carbonLayerInstance.parseIntensity(_threshold);

        require(intensityThreshold != Intensity.Invalid, 'Invalid threshold');

        return carbonLayerInstance.intensity() > intensityThreshold;
    }
}
