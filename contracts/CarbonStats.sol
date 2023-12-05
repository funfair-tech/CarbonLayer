// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ConfirmedOwner } from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import "./CarbonLayer.sol";


contract CarbonStats is ConfirmedOwner {

    CarbonLayer public carbonLayerInstance;

    uint16[] public solarPercentageHistory;
    uint16[] public windPercentageHistory;
    uint16[] public hydroPercentageHistory;
    uint16[] public nuclearPercentageHistory;
    uint16[] public biomassPercentageHistory;
    uint16[] public coalPercentageHistory;
    uint16[] public gasPercentageHistory;
    uint16[] public importsPercentageHistory;
    uint16[] public otherPercentageHistory;
    
    Intensity[] public intensityHistory;

    uint256 public averageSolarPercentage;
    uint256 public averageWindPercentage;
    uint256 public averageHydroPercentage;
    uint256 public averageNuclearPercentage;
    uint256 public averageBiomassPercentage;
    uint256 public averageCoalPercentage;
    uint256 public averageGasPercentage;
    uint256 public averageImportsPercentage;
    uint256 public averageOtherPercentage;

    uint256 public totalNeutralPercentage;
    uint256 public totalIntensivePercentage;
    
    Intensity public averageIntensity;

    uint256 public sampleSize;

    constructor(address _carbonLayerAddress) ConfirmedOwner(msg.sender) {
        carbonLayerInstance = CarbonLayer(_carbonLayerAddress);
    }

    function updateStats() external onlyOwner {
        // Get the latest percentages and intensity
        uint16 solarPercentage = carbonLayerInstance.getFuelPercentage("solar");
        uint16 windPercentage = carbonLayerInstance.getFuelPercentage("wind");
        uint16 hydroPercentage = carbonLayerInstance.getFuelPercentage("hydro");
        uint16 nuclearPercentage = carbonLayerInstance.getFuelPercentage("nuclear");
        uint16 biomassPercentage = carbonLayerInstance.getFuelPercentage("biomass");
        uint16 coalPercentage = carbonLayerInstance.getFuelPercentage("coal");
        uint16 gasPercentage = carbonLayerInstance.getFuelPercentage("gas");
        uint16 importsPercentage = carbonLayerInstance.getFuelPercentage("imports");
        uint16 otherPercentage = carbonLayerInstance.getFuelPercentage("other");
        
        Intensity currentIntensity = carbonLayerInstance.intensity();

        // Push new values to history arrays
        solarPercentageHistory.push(solarPercentage);
        windPercentageHistory.push(windPercentage);
        hydroPercentageHistory.push(hydroPercentage);
        nuclearPercentageHistory.push(nuclearPercentage);
        biomassPercentageHistory.push(biomassPercentage);
        coalPercentageHistory.push(coalPercentage);
        gasPercentageHistory.push(gasPercentage);
        importsPercentageHistory.push(importsPercentage);
        otherPercentageHistory.push(otherPercentage);
        
        intensityHistory.push(currentIntensity);

        // Recalculate averages based on updated history
        averageSolarPercentage = calculateAverage(solarPercentageHistory);
        averageWindPercentage = calculateAverage(windPercentageHistory);
        averageHydroPercentage = calculateAverage(hydroPercentageHistory);
        averageNuclearPercentage = calculateAverage(nuclearPercentageHistory);
        averageBiomassPercentage = calculateAverage(biomassPercentageHistory);
        averageCoalPercentage = calculateAverage(coalPercentageHistory);
        averageGasPercentage = calculateAverage(gasPercentageHistory);
        averageImportsPercentage = calculateAverage(importsPercentageHistory);
        averageOtherPercentage = calculateAverage(otherPercentageHistory);
        
        // Recalculate neutral and intensive percentages
        totalNeutralPercentage = (averageSolarPercentage + averageWindPercentage + averageHydroPercentage + averageNuclearPercentage + averageBiomassPercentage);
        totalIntensivePercentage = (averageCoalPercentage + averageGasPercentage + averageImportsPercentage + averageOtherPercentage);

        averageIntensity = calculateAverageIntensity(intensityHistory);

        sampleSize++;
    }

    function calculateAverage(uint16[] memory _history) internal pure returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < _history.length; i++) {
            total += _history[i];
        }
        return _history.length > 0 ? total / _history.length : 0;
    }

    function calculateAverageIntensity(Intensity[] memory _intensityHistory) internal pure returns (Intensity) {
        uint256 totalIntensity = 0;
        for (uint256 i = 0; i < _intensityHistory.length; i++) {
            totalIntensity += uint256(_intensityHistory[i]);
        }

        // Calculate average intensity
        uint256 average = _intensityHistory.length > 0 ? totalIntensity / _intensityHistory.length : 0;

        return Intensity(average);
    }
}
