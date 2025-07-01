// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title CampusCredit
 * @dev ERC20 token with pausable transfers, merchant cashback system, and student spending limit
 */
contract CampusCredit is ERC20, ERC20Burnable, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Spending control
    mapping(address => uint256) public dailySpendingLimit;
    mapping(address => uint256) public spentToday;
    mapping(address => uint256) public lastSpendingReset;

    // Merchant registry
    mapping(address => bool) public isMerchant;
    mapping(address => string) public merchantName;

    uint256 public cashbackPercentage = 2; // Cashback 2%

    // Events
    event MerchantRegistered(address indexed merchant, string name);
    event DailyLimitSet(address indexed student, uint256 limit);
    event Spent(address indexed student, uint256 amount, uint256 cashback);
    event CashbackIssued(address indexed student, uint256 amount);

    constructor() ERC20("Campus Credit", "CREDIT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        // TODO: Adjust initial supply policy
        _mint(msg.sender, 10_000_000 * 10 ** decimals());
    }

    modifier onlyMerchant() {
        require(isMerchant[msg.sender], "Not a registered merchant");
        _;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Mint credit to a student (e.g. for scholarship, reward, etc.)
     * TODO: Implement stricter mint limit policy if needed
     */
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        uint256 mintLimit = 1_000_000 * 10 ** decimals(); // Daily/admin limit
        require(amount <= mintLimit, "Exceed daily mint limit");
        _mint(to, amount);
    }

    /**
     * @dev Register new merchant that can receive payments
     * TODO: Add verification mechanism
     */
    function registerMerchant(address merchant, string memory name) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!isMerchant[merchant], "Already registered");
        require(bytes(name).length > 0, "Name required");
        isMerchant[merchant] = true;
        merchantName[merchant] = name;
        emit MerchantRegistered(merchant, name);
    }

    /**
     * @dev Set daily transaction limit for a student
     * Use case: Restrict excessive spending
     */
    function setDailyLimit(address student, uint256 limit) public onlyRole(DEFAULT_ADMIN_ROLE) {
        dailySpendingLimit[student] = limit;
        emit DailyLimitSet(student, limit);
    }

    /**
     * @dev Internal utility: Reset spent amount after 1 day
     */
    function _checkAndResetDaily(address user) internal {
        if (block.timestamp >= lastSpendingReset[user] + 1 days) {
            spentToday[user] = 0;
            lastSpendingReset[user] = block.timestamp;
        }
    }

    /**
     * @dev Spend CampusCredit at merchant. Cashback issued automatically.
     * Called by: Merchant
     */
    function spendAtMerchant(address student, uint256 amount) public onlyMerchant {
        require(balanceOf(student) >= amount, "Insufficient balance"); // ✅ FIX: semicolon
        _checkAndResetDaily(student);

        uint256 newSpent = spentToday[student] + amount;
        require(newSpent <= dailySpendingLimit[student], "Exceeds daily limit");

        spentToday[student] = newSpent;

        // Transfer from student to merchant
        _transfer(student, msg.sender, amount);

        // TODO: Consider cooldown/anti-abuse rules
        uint256 cashback = (amount * cashbackPercentage) / 100;
        _mint(student, cashback);

        emit Spent(student, amount, cashback);
        emit CashbackIssued(student, cashback);
    }

    /**
     * @dev Prevent token transfers while paused
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        require(!paused(), "CampusCredit: token transfer while paused");
        super._beforeTokenTransfer(from, to, amount);
    }
}
