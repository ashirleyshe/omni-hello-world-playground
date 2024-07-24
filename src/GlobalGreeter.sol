// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import {XApp} from "omni/contracts/src/pkg/XApp.sol";
import {ConfLevel} from "omni/contracts/src/libraries/ConfLevel.sol";

import {Greeting} from "src/Greeting.sol";
import {RollupGreeter} from "src/RollupGreeter.sol";

/**
 * @title GlobalGreeter
 * @notice A contract for recording greetings from all chains
 * @dev This contract serves as a greeting book for all chains, recording greetings transmitted from different chains via cross-chain communication.
 */
contract GlobalGreeter is XApp {
    /**
     * @notice Gas limit used for a cross-chain greet call at destination
     */
    uint64 public constant DEST_TX_GAS_LIMIT = 120_000;

    /**
     * @notice The latest greeting recorded by the contract
     * @dev State variable to store information about the latest greeting received by the contract
     */
    Greeting public lastGreet = Greeting(0, 0, address(0), "Hello Omni!");

    uint64 public destChainID;
    address public rollupChainGreeter;

    /**
     * @dev Initializes a new GlobalGreeter contract with the specified portal address
     * @param portal Address of the portal or relay used for cross-chain communication
     */
    constructor(address portal) XApp(portal, ConfLevel.Latest) {}

    /**
     * @notice Records a greeting from any chain
     * @param _greeting The greeting message received
     * @dev This function is called via cross-chain communication to record a greeting message from any chain.
     *      It updates the lastGreet variable with information about the received greeting.
     */
    function greet(string calldata _greeting) external payable xrecv {

        // Create a Greeting struct to store information about the received greeting
        Greeting memory greeting =
            Greeting(xmsg.sourceChainId, block.timestamp, xmsg.sender, _greeting);

        // Update the lastGreet variable with the information about the received greeting
        lastGreet = greeting;

        // Makes the cross-chain call
        bytes memory data = abi.encodeWithSelector(RollupGreeter.receiveGreet.selector, _greeting);
        xcall(destChainID, rollupChainGreeter, data, DEST_TX_GAS_LIMIT);
    }

    function setDest(uint64 _destChainID, address _rollupChainGreeter) external {
        destChainID = _destChainID;
        rollupChainGreeter = _rollupChainGreeter;
    }
}
