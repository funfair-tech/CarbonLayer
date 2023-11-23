// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol';
import './CarbonLayer.sol';

contract CarbonAware is ConfirmedOwner {
    
    CarbonLayer public carbonLayerInstance;

    modifier solarPowered(uint16 _threshold) {
        require(address(carbonLayerInstance) != address(0), 'CarbonLayer instance not set');

        uint16 perecentageSolarFuel = carbonLayerInstance.fuelData('solar');

        require(perecentageSolarFuel > _threshold, 'Solar fuel percentage below threshold');

        _;
    }

    modifier carbonNeutralPowered(uint16 _threshold) {
        require(address(carbonLayerInstance) != address(0), 'CarbonLayer instance not set');

        uint16 perecentageRenewableFuel = 0;

        string[] memory carbonNeutralFuels = carbonLayerInstance.getCarbonNeutralFuels();

        for (uint256 i = 0; i < carbonNeutralFuels.length ; i++) {
            perecentageRenewableFuel += carbonLayerInstance.fuelData(carbonNeutralFuels[i]);
        }

        require(perecentageRenewableFuel > _threshold, 'Carbon neutral fuel below threshold');

        _;
    }

    modifier belowIntensityThreshold(string memory _threshold) {
        require(address(carbonLayerInstance) != address(0), 'CarbonLayer instance not set');

        Intensity intensityThreshold = carbonLayerInstance.parseIntensity(_threshold);
        
        require(intensityThreshold != Intensity.Invalid, 'Invalid threshold');

        require(carbonLayerInstance.intensity() < intensityThreshold, 'Carbon intensity index above threshold');

        _;
    }

    event CarbonLayerSet(address indexed carbonLayerAddress);

    constructor(address _carbonLayerAddress) ConfirmedOwner(msg.sender) {
        setCarbonLayer(_carbonLayerAddress);
    }

    function setCarbonLayer(address _carbonLayerAddress) public onlyOwner {
        require(_carbonLayerAddress != address(0), 'Invalid CarbonLayer address');

        carbonLayerInstance = CarbonLayer(_carbonLayerAddress);

        emit CarbonLayerSet(_carbonLayerAddress);
    }
}
