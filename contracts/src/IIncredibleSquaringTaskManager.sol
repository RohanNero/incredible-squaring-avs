// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@eigenlayer-middleware/src/libraries/BN254.sol";
import "@eigenlayer-middleware/src/interfaces/IBLSSignatureChecker.sol";

interface IIncredibleSquaringTaskManager {
    // EVENTS
    event NewTaskCreated(uint32 indexed taskIndex, Task task);

    event TaskResponded(
        TaskResponse taskResponse,
        TaskResponseMetadata taskResponseMetadata
    );

    event TaskCompleted(uint32 indexed taskIndex);

    event TaskChallengedSuccessfully(
        uint32 indexed taskIndex,
        address indexed challenger
    );

    event TaskChallengedUnsuccessfully(
        uint32 indexed taskIndex,
        address indexed challenger
    );

    event AggregatorUpdated(
        address indexed oldAggregator,
        address indexed newAggregator
    );

    event GeneratorUpdated(
        address indexed oldGenerator,
        address indexed newGenerator
    );

    // STRUCTS
    struct Task {
        uint256 numberToBeSquared;
        uint32 taskCreatedBlock;
        // task submitter decides on the criteria for a task to be completed
        // note that this does not mean the task was "correctly" answered (i.e. the number was squared correctly)
        //      this is for the challenge logic to verify
        // task is completed (and contract will accept its TaskResponse) when each quorumNumbers specified here
        // are signed by at least quorumThresholdPercentage of the operators
        // note that we set the quorumThresholdPercentage to be the same for all quorumNumbers, but this could be changed
        bytes quorumNumbers;
        uint32 quorumThresholdPercentage;
    }

    // Task response is hashed and signed by operators.
    // These signatures are aggregated and sent to the contract as response.
    struct TaskResponse {
        // Can be obtained by the operator from the event NewTaskCreated.
        uint32 referenceTaskIndex;
        // This is just the response that the operator has to compute by itself.
        uint256 numberSquared;
    }

    // Extra information related to taskResponse, which is filled inside the contract.
    // It thus cannot be signed by operators, so we keep it in a separate struct than TaskResponse
    // This metadata is needed by the challenger, so we emit it in the TaskResponded event
    struct TaskResponseMetadata {
        uint32 taskRespondedBlock;
        bytes32 hashOfNonSigners;
    }

    // FUNCTIONS
    // NOTE: this function creates a new task.
    function createNewTask(
        uint256 numberToBeSquared,
        uint32 quorumThresholdPercentage,
        bytes calldata quorumNumbers
    ) external;

    // NOTE: this function responds to a created task.
    function respondToTask(
        Task calldata task,
        TaskResponse calldata taskResponse,
        IBLSSignatureChecker.NonSignerStakesAndSignature
            memory nonSignerStakesAndSignature
    ) external;

    /// @notice Returns the current 'taskNumber' for the middleware
    function taskNumber() external view returns (uint32);

    // NOTE: this function raises a challenge to existing tasks.
    function raiseAndResolveChallenge(
        Task calldata task,
        TaskResponse calldata taskResponse,
        TaskResponseMetadata calldata taskResponseMetadata,
        BN254.G1Point[] memory pubkeysOfNonSigningOperators
    ) external;

    /// @notice Returns the TASK_RESPONSE_WINDOW_BLOCK
    function getTaskResponseWindowBlock() external view returns (uint32);
}
