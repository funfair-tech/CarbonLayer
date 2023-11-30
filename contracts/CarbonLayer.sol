// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@chainlink/contracts/src/v0.8/ChainlinkClient.sol';
import '@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol';

enum Intensity {
    Invalid,
    Low,
    Medium,
    High
}

contract CarbonLayer is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    uint256 private ORACLE_PAYMENT = 1000000000000000; // LINK Joules

    Intensity public intensity;

    address public automation;
    string[] public carbonNeutralFuels;
    string[] public carbonIntensiveFuels;
    string[] public fuelNames;
    uint16[] public fuelPercentages;

    event RequestIndexFulfilled(bytes32 indexed requestId, string indexed index);
    event RequestGenerationMixFulfilled(bytes32 indexed requestId);

    modifier onlyAuthorised() {
        require(msg.sender == automation || msg.sender == owner(), 'Not authorised');
        _;
    }

    constructor(address _linkNetworkAddress) ConfirmedOwner(msg.sender) {
        setChainlinkToken(_linkNetworkAddress);
        carbonNeutralFuels = ['biomass', 'nuclear', 'hydro', 'solar', 'wind'];
        carbonIntensiveFuels = ['coal', 'gas', 'imports', 'other'];
    }

    function requestIndex(address _oracle, string memory _jobId) public onlyAuthorised {
        Chainlink.Request memory req = buildChainlinkRequest(
            stringToBytes32(_jobId),
            address(this),
            this.fulfillIndex.selector
        );

        sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
    }

    function requestGenerationMix(address _oracle, string memory _jobId) public onlyAuthorised {
        Chainlink.Request memory req = buildChainlinkRequest(
            stringToBytes32(_jobId),
            address(this),
            this.fulfillGenerationMix.selector
        );

        sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
    }

    function fulfillIndex(bytes32 _requestId, string memory _intensity) public recordChainlinkFulfillment(_requestId) {
        Intensity parsedIntensity = parseIntensity(_intensity);
        require(parsedIntensity != Intensity.Invalid, 'Invalid intensity value');
        intensity = parsedIntensity;
        emit RequestIndexFulfilled(_requestId, _intensity);
    }

    function fulfillGenerationMix(
        bytes32 _requestId,
        string[] memory _fuelNames,
        uint16[] memory _fuelPercentages
    ) public recordChainlinkFulfillment(_requestId) {
        require(_fuelNames.length == _fuelPercentages.length, 'Invalid fuel data');

        fuelNames = _fuelNames;
        fuelPercentages = _fuelPercentages;

        emit RequestGenerationMixFulfilled(_requestId);
    }

    function update(
        address _oracle,
        string memory _intensityIndexJobId,
        string memory _generationMixJobId
    ) public onlyAuthorised {
        requestGenerationMix(_oracle, _generationMixJobId);
        requestIndex(_oracle, _intensityIndexJobId);
    }

    function getChainlinkToken() public view returns (address) {
        return chainlinkTokenAddress();
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), 'Unable to transfer');
    }

    function setAutomation(address _automation) public onlyOwner {
        automation = _automation;
    }

    function setCarbonNeutralFuels(string[] memory _carbonNeutralFuels) public onlyOwner {
        require(_carbonNeutralFuels.length > 0, 'Replacement fuel keys cannot be empty');
        carbonNeutralFuels = _carbonNeutralFuels;
    }

    function getCarbonNeutralFuels() public view returns (string[] memory) {
        return carbonNeutralFuels;
    }

    function setCarbonIntensiveFuels(string[] memory _carbonIntensiveFuels) public onlyOwner {
        require(_carbonIntensiveFuels.length > 0, 'Replacement fuel keys cannot be empty');
        carbonIntensiveFuels = _carbonIntensiveFuels;
    }

    function getCarbonIntensiveFuels() public view returns (string[] memory) {
        return carbonIntensiveFuels;
    }

    function getFuelPercentage(string memory _fuelName) public view returns (uint16) {
        require(fuelNames.length > 0, "No fuel data available");

        for (uint256 i = 0; i < fuelNames.length; i++) {
            if (compareStrings(fuelNames[i], _fuelName)) {
                return fuelPercentages[i];
            }
        }

        return 0;
    }

    function setOraclePayment(uint256 _joules) public onlyOwner {
        require(_joules > 0, 'Payment cannot be zero');
        ORACLE_PAYMENT = _joules;
    }

    function getOraclePayment() public view returns (uint256) {
        return ORACLE_PAYMENT;
    }

    function cancelRequest(
        bytes32 _requestId,
        uint256 _payment,
        bytes4 _callbackFunctionId,
        uint256 _expiration
    ) public onlyOwner {
        cancelChainlinkRequest(_requestId, _payment, _callbackFunctionId, _expiration);
    }

    function parseIntensity(string memory _intensity) public pure returns (Intensity) {
        if (compareStrings(_intensity, 'very high')) {
            return Intensity.High;
        } else if (compareStrings(_intensity, 'high')) {
            return Intensity.High;
        } else if (compareStrings(_intensity, 'moderate')) {
            return Intensity.Medium;
        } else if (compareStrings(_intensity, 'low')) {
            return Intensity.Low;
        } else if (compareStrings(_intensity, 'very low')) {
            return Intensity.Low;
        } else {
            return Intensity.Invalid;
        }
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }

}
