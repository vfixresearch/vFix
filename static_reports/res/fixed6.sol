// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title AppCoins - Basic ERC20 Token
contract AppCoins is IERC20, Ownable {
    using SafeMath for uint256;

    string public constant name = "AppCoins";
    string public constant symbol = "APPC";
    uint8 public constant decimals = 18;
    uint256 private _totalSupply;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;

    event Burn(address indexed from, uint256 value);

    constructor(uint256 initialSupply) {
        _totalSupply = initialSupply * 10 ** uint256(decimals);
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(recipient != address(0), "Transfer to the zero address");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(recipient != address(0), "Transfer to the zero address");
        require(balances[sender] >= amount, "Insufficient balance");
        require(allowance[sender][msg.sender] >= amount, "Transfer amount exceeds allowance");

        allowance[sender][msg.sender] = allowance[sender][msg.sender].sub(amount);
        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        require(spender != address(0), "Approve to the zero address");

        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance to burn");

        balances[msg.sender] = balances[msg.sender].sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Burn(msg.sender, amount);
        return true;
    }

    function burnFrom(address account, uint256 amount) public returns (bool) {
        require(balances[account] >= amount, "Insufficient balance to burn");
        require(allowance[account][msg.sender] >= amount, "Burn amount exceeds allowance");

        balances[account] = balances[account].sub(amount);
        allowance[account][msg.sender] = allowance[account][msg.sender].sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Burn(account, amount);
        return true;
    }
}

/// @title BaseAdvertisement - Basic Advertisement Contract with Role-based Access Control
contract BaseAdvertisement is Ownable {
    IERC20 public appc;
    mapping(address => uint256) public adBalances;
    event FundsTransferred(address indexed from, address indexed to, uint256 amount);

    constructor(IERC20 _appcToken) {
        appc = _appcToken;
    }

    function transferAdFunds(address from, address to, uint256 amount) public onlyOwner {
        require(to != address(0), "Transfer to zero address");
        require(appc.balanceOf(from) >= amount, "Insufficient balance");

        bool success = appc.transferFrom(from, to, amount);
        require(success, "Token transfer failed");

        emit FundsTransferred(from, to, amount);
    }
}

/// @title ExtendedFinance - Extended Financial Operations for Advertisement Management
contract ExtendedFinance is Ownable {
    using SafeMath for uint256;
    IERC20 public appc;

    mapping(address => uint256) private rewards;

    event RewardsWithdrawn(address indexed user, uint256 amount);

    constructor(IERC20 _appcToken) {
        appc = _appcToken;
    }

    function withdrawRewards(address user) external onlyOwner {
        uint256 rewardBalance = rewards[user];
        require(rewardBalance > 0, "No rewards to withdraw");

        rewards[user] = 0;
        bool success = appc.transfer(user, rewardBalance);
        require(success, "Transfer failed");

        emit RewardsWithdrawn(user, rewardBalance);
    }

    function setRewardBalance(address user, uint256 amount) external onlyOwner {
        rewards[user] = amount;
    }

    function getRewardBalance(address user) external view returns (uint256) {
        return rewards[user];
    }
}
