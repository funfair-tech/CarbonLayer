// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import '../../contracts/CarbonQuery.sol';

import { FunctionsClient } from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import { ConfirmedOwner } from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import { FunctionsRequest } from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";


/**
 * @title CarbonCompute
 * @notice This is an example contract to show how to make HTTP requests using CarbonLayer
 *      and charge a fee dependent on the current state of energy production
 */
contract CarbonCompute is FunctionsClient, ConfirmedOwner {
    using FunctionsRequest for FunctionsRequest.Request;

    // State variables to store the fees and energy source threshold where the reduced fee is charged
    uint256 public standardFee = 0.002 ether;
    uint256 public reducedFee = 0.001 ether;
    uint16 public threshold = 3000; // Above this is reduced fees are charged (TODO! unit?)
    CarbonQuery public carbonQueryInstance; // The contract to call to get the current carbon index
 
    // State variables to store the last request ID, response, and error returned from the lambda function call
    bytes32 public lastRequestId;
    bytes public lastResponse;
    bytes public lastError;
        
    uint32 private callbackGasLimit = 300000;

    // State variable to store the returned apicall information
    string public apiResponse;

    // Errors
    error UnexpectedRequestID(bytes32 requestId);
    
    // Events
    event CarbonQueryInstanceSet(address indexed _carbonQueryAddress);
    event Working(string indexed _msg, uint256 indexed fee);
    event Refunding(string indexed _msg, uint256 indexed fee);
    event Withdraw(string indexed _msg, uint256 indexed fee, address indexed recipient);
    event Response(
        bytes32 indexed requestId,
        string apiResonse,
        bytes response,
        bytes err
    );

    // Chaink link fixed Router address and donID - Hardcoded for Sepolia, make adjustable to use in production 
    // Addresses supported network https://docs.chain.link/chainlink-functions/supported-networks
    address private router = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;
    bytes32 private donID = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;

    /**
     * @notice Initializes the contract with the Chainlink router address and sets the contract owner
     * @param _carbonQueryAddress The address of the contract to call to get the current carbon index 
     */
    constructor(address _carbonQueryAddress) FunctionsClient(router) ConfirmedOwner(msg.sender) {
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
     * @notice Update the fees charged for calling doWork
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
        require(_threshold <= 1000, 'Invalid threshold');
        threshold = _threshold;
    }

   /**
     * @notice With draw all the accumulated fees to the owners address
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        require(balance > 0, "No funds to withdraw");

        payable(owner()).transfer(balance);

        emit Withdraw("Fee withdraw processed", balance, owner());
    }

   /**
     * @notice The main public entry point to the contract
     * @param _subscriptionID The Chainlink link subscription to use
     */
    function doWork(uint64 _subscriptionID) external payable {
        
        // Get the fee we're going to charge for this work       
        uint256 fee = quote();

        require(msg.value >= fee, "Insufficient fee attached");

        // Call the lambda function 
        sendRequest(_subscriptionID);
        
        emit Working("CarbonCompute doing work for a fee of ", fee);

        // Transfer the excess funds back to the caller
        if (msg.value > fee) {
            uint256 refund = msg.value - fee;
            payable(msg.sender).transfer(refund);

            emit Refunding("Refunding excess fee to caller", refund);
        }
    }

   /**
     * @notice Call the carbonQuery contract to establish the fees to charge for this work
     */
    function quote() public view returns (uint256) {
        bool isCarbonNeutral = carbonQueryInstance.carbonNeutralPowered(threshold);
        
        uint256 fee = isCarbonNeutral ? reducedFee : standardFee;

        return fee;
    }


    // JavaScript source code to be executed as a Chainlink function
    // Call an AWS lambda function and return the result
    // Documentation: https://aws.amazon.com/lambda/resources/?aws-lambda-resources-blog.sort-by=item.additionalFields.createdDate&aws-lambda-resources-blog.sort-order=desc
    string source =
        "const apiResponse = await Functions.makeHttpRequest({"
        "url: `https://v2nnosvq76yihfm2mxk7bvep2q0jtnrl.lambda-url.eu-west-2.on.aws/`"
        "});"
        "if (apiResponse.error) {"
        "throw Error('Request failed');"
        "}"
        "const { data } = apiResponse;"
        "return Functions.encodeString(JSON.stringify(data));";


    /**
     * @notice Sends an HTTP request
     * @param subscriptionId The ID for the Chainlink subscription
     * @return requestId The ID of the request
     */
    function sendRequest(
        uint64 subscriptionId
    ) private returns (bytes32 requestId) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source); // Initialize the request with JS code

        // Send the request and store the request ID
        lastRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            callbackGasLimit,
            donID
        );

        return lastRequestId;
    }

    /**
     * @notice Callback function for fulfilling a request
     * @param requestId The ID of the request to fulfill
     * @param response The HTTP response data
     * @param err Any errors from the Functions request
     */
    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId); // Check if request IDs match
        }
        // Update the contract's state variables with the response and any errors
        lastResponse = response;
        apiResponse = string(response);
        lastError = err;

        // Emit an event to log the response
        emit Response(requestId, apiResponse, lastResponse, lastError);
    }
}
