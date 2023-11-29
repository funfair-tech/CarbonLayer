// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import '../../contracts/CarbonQuery.sol';

import { FunctionsClient } from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import { ConfirmedOwner } from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import { FunctionsRequest } from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";


/**
 * @title FunctionClient
 * @notice This is an example contract to show how to make HTTP requests using CarbonLayer
 */
contract CarbonCompute is FunctionsClient, ConfirmedOwner {
    using FunctionsRequest for FunctionsRequest.Request;

    // State variables to store the last request ID, response, and error
    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    bytes public s_lastError;

    // State variables to store the fees and energy source threshold
    uint256 public standardFee = 0.002 ether;
    uint256 public reducedFee = 0.001 ether;
    uint16 public threshold = 3000;
    CarbonQuery public carbonQueryInstance;

    // Errors
    error UnexpectedRequestID(bytes32 requestId);
    
    // Events
    event CarbonQueryInstanceSet(address indexed _carbonQueryAddress);
    event Working(string indexed _msg, uint256 indexed fee);
    event Refunding(string indexed _msg, uint256 indexed fee);
    event Withdraw(string indexed _msg, uint256 indexed fee, address indexed recipient);
    event Response(
        bytes32 indexed requestId,
        string character,
        bytes response,
        bytes err
    );

    // Chaink link fixed Router address and donID - Hardcoded for Sepolia, make adjustable to use in production 
    // Addresses supported network https://docs.chain.link/chainlink-functions/supported-networks
    address router = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;
    bytes32 donID = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;

    // JavaScript source code
    // Trigger an AWS lambda function.
    // Documentation: https://aws.amazon.com/lambda/resources/?aws-lambda-resources-blog.sort-by=item.additionalFields.createdDate&aws-lambda-resources-blog.sort-order=desc
    string source =
        "const characterId = args[0];"
        "const apiResponse = await Functions.makeHttpRequest({"
        "url: `https://v2nnosvq76yihfm2mxk7bvep2q0jtnrl.lambda-url.eu-west-2.on.aws/`"
        "});"
        "if (apiResponse.error) {"
        "throw Error('Request failed');"
        "}"
        "const { data } = apiResponse;"
        "return Functions.encodeString(data.name);";

    //Callback gas limit
    uint32 gasLimit = 300000;

    // State variable to store the returned character information
    string public character;

    /**
     * @notice Initializes the contract with the Chainlink router address and sets the contract owner
     */
    constructor(address _carbonQueryAddress) FunctionsClient(router) ConfirmedOwner(msg.sender) {
        setCarbonQuery(_carbonQueryAddress);
    }

    /**
     * @notice Admin functions to control the fees
     */
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

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        require(balance > 0, "No funds to withdraw");

        payable(owner()).transfer(balance);

        emit Withdraw("Fee withdraw processed", balance, owner());
    }

    function doWork(uint64 _subscriptionID, string[] calldata _args) external payable {
        
        uint256 fee = quote();

        require(msg.value >= fee, "Insufficient fee attached");

        sendRequest(_subscriptionID, _args);
        
        emit Working("Demo01 is doing work for a fee of ", fee);

        // Transfer the excess funds back to the caller
        if (msg.value > fee) {
            // In Solidity versions 0.8.0 and later, 
            // the SafeMath library functions are part of the standard arithmetic operations for uint256.
            uint256 refund = msg.value - fee;
            payable(msg.sender).transfer(refund);

            emit Refunding("Refunding exess fee to caller", refund);

        }
    }

    function quote() public view returns (uint256) {
        bool isCarbonNeutral = carbonQueryInstance.carbonNeutralPowered(threshold);
        
        uint256 fee = isCarbonNeutral ? reducedFee : standardFee;

        return fee;
    }

    /**
     * @notice Sends an HTTP request for character information
     * @param subscriptionId The ID for the Chainlink subscription
     * @param args The arguments to pass to the HTTP request
     * @return requestId The ID of the request
     */
    function sendRequest(
        uint64 subscriptionId,
        string[] calldata args
    ) private onlyOwner returns (bytes32 requestId) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source); // Initialize the request with JS code
        if (args.length > 0) req.setArgs(args); // Set the arguments for the request

        // Send the request and store the request ID
        s_lastRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donID
        );

        return s_lastRequestId;
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
        if (s_lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId); // Check if request IDs match
        }
        // Update the contract's state variables with the response and any errors
        s_lastResponse = response;
        character = string(response);
        s_lastError = err;

        // Emit an event to log the response
        emit Response(requestId, character, s_lastResponse, s_lastError);
    }
}
