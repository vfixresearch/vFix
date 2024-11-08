// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Arbitrator {
    function createDispute(uint256 _choices, bytes memory _extraData) public payable returns (uint256 disputeID) {}
    function appeal(uint256 _disputeID, bytes memory _extraData) public payable {}
    function arbitrationCost(bytes memory _extraData) public view returns (uint256 cost) {}
}

contract ArbitrablePermissionList {
    address public owner;
    Arbitrator public arbitrator;
    bytes public arbitratorExtraData;
    uint256 public timeToChallenge;
    uint256 public constant REGISTER = 1;
    uint256 public constant CLEAR = 2;

    enum ItemStatus { Absent, Submitted, Resubmitted, Registered, ClearingRequested, PreventiveClearingRequested, Cleared }
    struct Item {
        address submitter;
        address challenger;
        uint256 balance;
        uint256 lastAction;
        bool disputed;
        uint256 disputeID;
        ItemStatus status;
    }

    mapping(bytes32 => Item) public items;
    mapping(uint256 => bytes32) public disputeIDToItem;
    bytes32[] public itemsList;

    event ItemStatusChange(address indexed submitter, address indexed challenger, bytes32 value, ItemStatus status, bool disputed);
    event Dispute(Arbitrator arbitrator, uint256 disputeID, uint256 indexed ruling);
    event Ruling(Arbitrator arbitrator, uint256 disputeID, uint256 ruling);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyArbitrator() {
        require(msg.sender == address(arbitrator), "Only arbitrator can call this function");
        _;
    }

    constructor(Arbitrator _arbitrator, bytes memory _arbitratorExtraData, uint256 _timeToChallenge) {
        owner = msg.sender;
        arbitrator = _arbitrator;
        arbitratorExtraData = _arbitratorExtraData;
        timeToChallenge = _timeToChallenge;
    }

    function requestRegistration(bytes32 _value) public payable {
        Item storage item = items[_value];
        require(item.status == ItemStatus.Absent || item.status == ItemStatus.Cleared, "Invalid item status for registration");

        uint256 arbitratorCost = arbitrator.arbitrationCost(arbitratorExtraData);
        require(msg.value >= arbitratorCost, "Insufficient funds for arbitration");

        if (item.status == ItemStatus.Absent) {
            item.status = ItemStatus.Submitted;
        } else {
            item.status = ItemStatus.Resubmitted;
        }

        if (item.lastAction == 0) {
            itemsList.push(_value);
        }

        item.submitter = msg.sender;
        item.balance += msg.value;
        item.lastAction = block.timestamp;

        emit ItemStatusChange(item.submitter, item.challenger, _value, item.status, item.disputed);
    }

    function requestClearing(bytes32 _value) public payable {
        Item storage item = items[_value];
        require(item.status == ItemStatus.Registered || item.status == ItemStatus.Absent, "Invalid item status for clearing");

        uint256 arbitratorCost = arbitrator.arbitrationCost(arbitratorExtraData);
        require(msg.value >= arbitratorCost, "Insufficient funds for arbitration");

        if (item.status == ItemStatus.Registered) {
            item.status = ItemStatus.ClearingRequested;
        } else {
            item.status = ItemStatus.PreventiveClearingRequested;
        }

        if (item.lastAction == 0) {
            itemsList.push(_value);
        }

        item.submitter = msg.sender;
        item.balance += msg.value;
        item.lastAction = block.timestamp;

        emit ItemStatusChange(item.submitter, item.challenger, _value, item.status, item.disputed);
    }

    function challengeRegistration(bytes32 _value) public payable {
        Item storage item = items[_value];
        require(item.status == ItemStatus.Submitted || item.status == ItemStatus.Resubmitted, "Invalid item status for challenge");

        uint256 arbitratorCost = arbitrator.arbitrationCost(arbitratorExtraData);
        require(msg.value >= arbitratorCost, "Insufficient funds to challenge");

        item.challenger = msg.sender;
        item.balance += msg.value - arbitratorCost;
        item.disputed = true;
        item.disputeID = arbitrator.createDispute{value: arbitratorCost}(2, arbitratorExtraData);
        disputeIDToItem[item.disputeID] = _value;

        emit Dispute(arbitrator, item.disputeID, 0);
    }

    function rule(uint256 _disputeID, uint256 _ruling) public onlyArbitrator {
        bytes32 itemID = disputeIDToItem[_disputeID];
        Item storage item = items[itemID];
        require(item.disputed, "No ongoing dispute for this item");

        if (_ruling == REGISTER) {
            if (item.status == ItemStatus.Resubmitted || item.status == ItemStatus.Submitted) {
                item.status = ItemStatus.Registered;
            } else {
                item.challenger.send(item.balance);  // Refund challenger if ruling is to clear
            }
        } else if (_ruling == CLEAR) {
            if (item.status == ItemStatus.PreventiveClearingRequested || item.status == ItemStatus.ClearingRequested) {
                item.submitter.send(item.balance);  // Refund submitter if ruling is to register
            } else {
                item.challenger.send(item.balance); 
            }
        }

        item.balance = 0;
        item.disputed = false;
        emit ItemStatusChange(item.submitter, item.challenger, itemID, item.status, item.disputed);
    }

    function appeal(bytes32 _value) public payable {
        Item storage item = items[_value];
        require(item.disputed, "No ongoing dispute for this item");

        arbitrator.appeal{value: msg.value}(item.disputeID, arbitratorExtraData);
    }

    function executeRequest(bytes32 _value) public {
        Item storage item = items[_value];
        require(block.timestamp - item.lastAction >= timeToChallenge, "Challenge period is not over");

        if (item.status == ItemStatus.Resubmitted || item.status == ItemStatus.Submitted) {
            item.status = ItemStatus.Registered;
        } else if (item.status == ItemStatus.ClearingRequested || item.status == ItemStatus.PreventiveClearingRequested) {
            item.status = ItemStatus.Cleared;
        } else {
            revert("Invalid item status");
        }

        item.disputed = false;
        item.balance = 0;
        
        emit ItemStatusChange(item.submitter, item.challenger, _value, item.status, item.disputed);
    }
}
