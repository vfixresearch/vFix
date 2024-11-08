// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Owned {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        owner = newOwner;
    }
}

contract TokenBase is Owned {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    uint public foundingTime;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed owner, address indexed spender, uint value);

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0), "Transfer to zero address");
        require(balanceOf[_from] >= _value, "Insufficient balance");
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender], "Allowance exceeded");
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        require(_spender != address(0), "Approve to zero address");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}

contract WorkProof is TokenBase {
    uint public oneYear = 1 years;
    uint public minerTotalSupply = 3900 * 1e18;
    uint public minerTotalReward;
    uint public minerDifficulty = 10**32;
    uint public minerTimeOfLastProof;
    bytes32 public minerCurrentChallenge;

    function proofOfWork(uint nonce) public {
        require(minerTotalReward < minerTotalSupply, "Total reward limit reached");

        bytes8 n = bytes8(keccak256(abi.encodePacked(nonce, minerCurrentChallenge)));
        require(uint256(keccak256(abi.encodePacked(n))) < minerDifficulty, "Difficulty limit exceeded");

        uint timeSinceLastProof = block.timestamp - minerTimeOfLastProof;
        require(timeSinceLastProof >= 5 seconds, "Wait at least 5 seconds between mining");

        uint reward = timeSinceLastProof / 60 seconds;
        balanceOf[msg.sender] += reward;
        totalSupply += reward;
        minerTotalReward += reward;

        minerDifficulty = (minerDifficulty * 10 minutes) / timeSinceLastProof + 1;
        minerTimeOfLastProof = block.timestamp;
        minerCurrentChallenge = keccak256(abi.encodePacked(nonce, minerCurrentChallenge, blockhash(block.number - 1)));

        emit Transfer(address(0), address(this), reward);
        emit Transfer(address(this), msg.sender, reward);
    }
}

contract Option is WorkProof {
    uint public optionTotalSupply;
    uint public optionInitialSupply = 6600 * 1e18;
    uint public optionExerciseSpan = 1 years;

    mapping(address => uint) public optionOf;
    mapping(address => uint) public optionExerciseOf;

    event OptionTransfer(address indexed from, address indexed to, uint option, uint exercised);

    function optionTransfer(address _from, address _to, uint _option, uint _exercised) public onlyOwner {
        require(optionOf[_from] >= _option, "Insufficient options");
        require(optionExerciseOf[_from] >= _exercised, "Insufficient exercised options");
        require(_to != address(0), "Transfer to zero address");

        optionOf[_from] -= _option;
        optionOf[_to] += _option;
        optionExerciseOf[_from] -= _exercised;
        optionExerciseOf[_to] += _exercised;

        emit OptionTransfer(_from, _to, _option, _exercised);
    }

    function optionExercise(uint value) public {
        require(optionOf[msg.sender] >= value, "Insufficient options");
        require(optionExerciseOf[msg.sender] + value <= optionOf[msg.sender], "Exceeds exercisable options");

        optionExerciseOf[msg.sender] += value;
        balanceOf[msg.sender] += value;
        totalSupply += value;

        emit Transfer(address(0), address(this), value);
        emit Transfer(address(this), msg.sender, value);
    }
}

contract Token is Option {
    uint public initialSupply = 0 * 1e18;
    uint public reserveSupply = 10500 * 1e18;

    constructor() {
        name = "TokenName";
        symbol = "TKN";
        decimals = 18;
        totalSupply = initialSupply;
        balanceOf[msg.sender] = totalSupply;
        foundingTime = block.timestamp;
    }
}
