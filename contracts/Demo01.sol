// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './CarbonQuery.sol';

contract Demo01 {
    address public owner;
    uint256 public standardFee = 0.002 ether;
    uint256 public reducedFee = 0.001 ether;
    uint16 public threshold = 3000;
    CarbonQuery public carbonQueryInstance;

    event CarbonQueryInstanceSet(address indexed _carbonQueryAddress);
    event Working(string indexed _msg, uint256 indexed fee);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor(address _carbonQueryAddress) {
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

    function setTreshold(uint16 _threshold) external onlyOwner {
        threshold = _threshold;
    }

    function doWork() external payable {
        bool isCarbonNeutral = carbonQueryInstance.carbonNeutralPowered(threshold);
        
        uint256 fee = isCarbonNeutral ? reducedFee : standardFee;

        require(msg.value >= fee, "Insufficient fee attached");

        // Perform call to external server here...
        emit Working("Demo01 is working for a fee of ", fee);

        // Transfer the excess funds back to the caller
        if (msg.value > fee) {
            payable(msg.sender).transfer(msg.value - fee);
        }
    }

    
}
