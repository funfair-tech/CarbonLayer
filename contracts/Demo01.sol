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
    event Refunding(string indexed _msg, uint256 indexed fee);
    event Withdraw(string indexed _msg, uint256 indexed fee, address indexed recipient);

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

    function setThreshold(uint16 _threshold) external onlyOwner {
        threshold = _threshold;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        require(balance > 0, "No funds to withdraw");

        payable(owner).transfer(balance);

        emit Withdraw("Fee withdraw processed", balance, owner);
    }

    function quote() public view returns (uint256) {
        bool isCarbonNeutral = carbonQueryInstance.carbonNeutralPowered(threshold);
        
        uint256 fee = isCarbonNeutral ? reducedFee : standardFee;

        return fee;
    }

    function doWork() external payable {
        
        uint256 fee = quote();

        require(msg.value >= fee, "Insufficient fee attached");

        // TODO: Perform call to external server here...
        emit Working("Demo01 is working for a fee of ", fee);

        // Transfer the excess funds back to the caller
        if (msg.value > fee) {
            // In Solidity versions 0.8.0 and later, 
            // the SafeMath library functions are part of the standard arithmetic operations for uint256.
            uint256 refund = msg.value - fee;
            payable(msg.sender).transfer(refund);

            emit Refunding("Refunding exess fee to caller", refund);

        }
    }

    
}
