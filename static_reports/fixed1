// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract BaseToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Transfer to the zero address");
        require(balanceOf[_from] >= _value, "Insufficient balance");
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender], "Allowance exceeded");
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), "Approve to the zero address");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}

contract BurnToken is BaseToken {
    event Burn(address indexed from, uint256 value);

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance to burn");
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value, "Insufficient balance to burn");
        require(_value <= allowance[_from][msg.sender], "Allowance exceeded");
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }
}

contract AirdropToken is BaseToken {
    uint256 public airAmount;
    uint256 public airBegintime;
    uint32 public airLimitCount;
    address public airSender;

    mapping(address => uint32) public airCountOf;

    event Airdrop(address indexed from, uint32 indexed count, uint256 tokenValue);

    modifier onlyAirSender() {
        require(msg.sender == airSender, "Caller is not the air sender");
        _;
    }

    function setAirdropParameters(uint256 _airAmount, uint256 _airBegintime, uint32 _airLimitCount) public onlyAirSender {
        airAmount = _airAmount;
        airBegintime = _airBegintime;
        airLimitCount = _airLimitCount;
    }

    function claimAirdrop() public {
        require(block.timestamp >= airBegintime, "Airdrop has not started yet");
        require(airCountOf[msg.sender] < airLimitCount, "Airdrop limit reached");

        _transfer(airSender, msg.sender, airAmount);
        airCountOf[msg.sender] += 1;

        emit Airdrop(msg.sender, airCountOf[msg.sender], airAmount);
    }
}

contract LockToken is BaseToken {
    struct LockMeta {
        uint256 amount;
        uint256 endtime;
    }

    mapping(address => LockMeta) public lockedAddresses;

    function lockTokens(address _holder, uint256 _amount, uint256 _endtime) public {
        require(_holder != address(0), "Invalid address");
        require(_amount <= balanceOf[_holder], "Insufficient balance to lock");
        lockedAddresses[_holder] = LockMeta(_amount, _endtime);
    }

    function _transfer(address _from, address _to, uint256 _value) internal override {
        require(block.timestamp >= lockedAddresses[_from].endtime || 
                balanceOf[_from] - _value >= lockedAddresses[_from].amount, 
                "Tokens are locked");
        super._transfer(_from, _to, _value);
    }
}

contract CustomToken is BaseToken, BurnToken, AirdropToken, LockToken {
    constructor() {
        totalSupply = 100000000000000000;
        name = "CustomToken";
        symbol = "CTK";
        decimals = 18;
        balanceOf[msg.sender] = totalSupply;
    }

    function withdrawEther() public {
        require(msg.sender == airSender, "Caller is not the air sender"); // only the airSender can withdraw Ether
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {}
}
