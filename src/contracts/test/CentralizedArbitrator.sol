/**
 *  @authors: [@clesaege, @n1c01a5, @epiqueras, @ferittuncer]
 *  @reviewers: [@clesaege*, @unknownunknown1*]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 *  @tools: [MythX]
 */

// Pumped to 0.8.0 by Lauri Tahvanainen

pragma solidity >=0.8.0 <0.9.0;

import "../dep/Arbitrator.sol";

/** @title Centralized Arbitrator
 *  @dev This is a centralized arbitrator deciding alone on the result of disputes. No appeals are possible.
 */
contract CentralizedArbitrator is Arbitrator {
    address public owner = msg.sender;
    uint256 arbitrationPrice; // Not public because arbitrationCost already acts as an accessor.
    uint256 constant NOT_PAYABLE_VALUE = (2**256 - 2) / 2; // High value to be sure that the appeal is too expensive.

    struct DisputeStruct {
        Arbitrable arbitrated;
        uint256 choices;
        uint256 fee;
        uint256 ruling;
        DisputeStatus status;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Can only be called by the owner.");
        _;
    }

    DisputeStruct[] public disputes;

    /** @dev Constructor. Set the initial arbitration price.
     *  @param _arbitrationPrice Amount to be paid for arbitration.
     */
    constructor(uint256 _arbitrationPrice) {
        arbitrationPrice = _arbitrationPrice;
    }

    /** @dev Set the arbitration price. Only callable by the owner.
     *  @param _arbitrationPrice Amount to be paid for arbitration.
     */
    function setArbitrationPrice(uint256 _arbitrationPrice) public onlyOwner {
        arbitrationPrice = _arbitrationPrice;
    }

    /** @dev Cost of arbitration. Accessor to arbitrationPrice.
     *  @param _extraData Not used by this contract.
     *  @return fee Amount to be paid.
     */
    function arbitrationCost(bytes memory _extraData)
        public
        view
        override
        returns (uint256 fee)
    {
        return arbitrationPrice;
    }

    /** @dev Cost of appeal. Since it is not possible, it's a high value which can never be paid.
     *  @param _disputeID ID of the dispute to be appealed. Not used by this contract.
     *  @param _extraData Not used by this contract.
     *  @return fee Amount to be paid.
     */
    function appealCost(uint256 _disputeID, bytes memory _extraData)
        public
        view
        override
        returns (uint256 fee)
    {
        return NOT_PAYABLE_VALUE;
    }

    /** @dev Create a dispute. Must be called by the arbitrable contract.
     *  Must be paid at least arbitrationCost().
     *  @param _choices Amount of choices the arbitrator can make in this dispute. When ruling ruling<=choices.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return disputeID ID of the dispute created.
     */
    function createDispute(uint256 _choices, bytes memory _extraData)
        public
        payable
        override
        returns (uint256 disputeID)
    {
        super.createDispute(_choices, _extraData);
        disputes.push(
            DisputeStruct({
                arbitrated: Arbitrable(msg.sender),
                choices: _choices,
                fee: msg.value,
                ruling: 0,
                status: DisputeStatus.Waiting
            })
        ); // Create the dispute and return its number.
        emit DisputeCreation(disputeID, Arbitrable(msg.sender));
        return disputes.length - 1;
    }

    /** @dev Give a ruling. UNTRUSTED.
     *  @param _disputeID ID of the dispute to rule.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 means "Not able/wanting to make a decision".
     */
    function _giveRuling(uint256 _disputeID, uint256 _ruling) internal {
        DisputeStruct storage dispute = disputes[_disputeID];
        require(_ruling <= dispute.choices, "Invalid ruling.");
        require(
            dispute.status != DisputeStatus.Solved,
            "The dispute must not be solved already."
        );

        dispute.ruling = _ruling;
        dispute.status = DisputeStatus.Solved;

        payable(msg.sender).transfer(dispute.fee); // Avoid blocking.
        dispute.arbitrated.rule(_disputeID, _ruling);
    }

    /** @dev Give a ruling. UNTRUSTED.
     *  @param _disputeID ID of the dispute to rule.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 means "Not able/wanting to make a decision".
     */
    function giveRuling(uint256 _disputeID, uint256 _ruling) public onlyOwner {
        return _giveRuling(_disputeID, _ruling);
    }

    /** @dev Return the status of a dispute.
     *  @param _disputeID ID of the dispute to rule.
     *  @return status The status of the dispute.
     */
    function disputeStatus(uint256 _disputeID)
        public
        view
        override
        returns (DisputeStatus status)
    {
        return disputes[_disputeID].status;
    }

    /** @dev Return the ruling of a dispute.
     *  @param _disputeID ID of the dispute to rule.
     *  @return ruling The ruling which would or has been given.
     */
    function currentRuling(uint256 _disputeID)
        public
        view
        override
        returns (uint256 ruling)
    {
        return disputes[_disputeID].ruling;
    }
}
