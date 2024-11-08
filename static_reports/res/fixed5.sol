// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Basic ERC20 Token Implementation
contract BasicToken is IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(recipient != address(0), "Transfer to the zero address");
        require(_balances[msg.sender] >= amount, "Insufficient balance");

        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
}

/// @title Standard ERC20 Token with Approve and TransferFrom Functions
contract StandardToken is BasicToken {
    mapping(address => mapping(address => uint256)) private _allowances;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0), "Approve to the zero address");
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "Transfer to the zero address");
        require(_allowances[sender][msg.sender] >= amount, "Transfer amount exceeds allowance");
        require(balanceOf(sender) >= amount, "Insufficient balance");

        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount);
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
        return true;
    }
}

/// @title Freezeable Token Implementation
contract FreezeableToken is StandardToken, Ownable {
    mapping(address => bool) private _frozenAccounts;

    event Freeze(address indexed account);
    event Unfreeze(address indexed account);

    modifier notFrozen(address account) {
        require(!_frozenAccounts[account], "Account is frozen");
        _;
    }

    function freeze(address account) external onlyOwner {
        require(!_frozenAccounts[account], "Account already frozen");
        _frozenAccounts[account] = true;
        emit Freeze(account);
    }

    function unfreeze(address account) external onlyOwner {
        require(_frozenAccounts[account], "Account is not frozen");
        _frozenAccounts[account] = false;
        emit Unfreeze(account);
    }

    function isFrozen(address account) external view returns (bool) {
        return _frozenAccounts[account];
    }

    function transfer(address recipient, uint256 amount) public override notFrozen(msg.sender) returns (bool) {
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override notFrozen(sender) returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }
}

/// @title Mintable Token Implementation
contract MintableToken is FreezeableToken {
    event Mint(address indexed to, uint256 amount);

    function mint(address account, uint256 amount) external onlyOwner {
        require(account != address(0), "Mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);

        emit Mint(account, amount);
        emit Transfer(address(0), account, amount);
    }
}

/// @title XMX Token Implementation
contract XmxToken is MintableToken {
    string public constant name = "XMAX";
    string public constant symbol = "XMX";
    uint8 public constant decimals = 18;

    constructor(uint256 initialSupply) {
        _totalSupply = initialSupply * 10**uint256(decimals);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
}
