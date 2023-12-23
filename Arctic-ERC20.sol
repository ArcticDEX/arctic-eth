// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Ball is AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address public donate;
    uint8 public constant taxRate = 95; // 95% tax rate

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) public nonces;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Only admin can call this function");
        _;
    }

    constructor() {
        _setupRole(ADMIN_ROLE, msg.sender);
        donate = msg.sender;
        _totalSupply = 90000000 * 10 ** 8;
        _name = "Ball";
        _symbol = "BALL";
        _decimals = 8;
        _balances[msg.sender] = _totalSupply;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(to != address(0), "Recipient address must not be zero");
        uint256 senderBalance = _balances[msg.sender];
        require(senderBalance >= value, "Insufficient balance");

        uint256 tax = (value * taxRate) / 100;
        uint256 netValue = value - tax;

        _balances[msg.sender] = senderBalance - value;
        _balances[to] += netValue;
        _balances[donate] += tax;

        emit Transfer(msg.sender, to, netValue);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(to != address(0), "Recipient address must not be zero");
        uint256 senderBalance = _balances[from];
        require(senderBalance >= value, "Insufficient balance");
        uint256 allowanceAmount = _allowances[from][msg.sender];
        require(allowanceAmount >= value, "Insufficient allowance");

        uint256 tax = (value * taxRate) / 100;
        uint256 netValue = value - tax;

        _balances[from] = senderBalance - value;
        _balances[to] += netValue;
        _balances[donate] += tax;
        _allowances[from][msg.sender] = allowanceAmount - value;

        emit Transfer(from, to, netValue);
        return true;
    }

    function setDonateAddress(address _donate) external onlyAdmin {
        require(_donate != address(0), "Address must not be zero");
        donate = _donate;
    }

    function retrieveStuckTokens(address tokenAddress, address to, uint256 amount) external onlyAdmin {
        require(tokenAddress != address(this), "Cannot retrieve Ball tokens");
        require(to != address(0), "Address must not be zero");
        IERC20 token = IERC20(tokenAddress);
        token.safeTransfer(to, amount);
    }
}
