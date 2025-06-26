// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract CampusCredit is ERC20, ERC20Burnable, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(address => uint256) public dailySpendingLimit;
    mapping(address => uint256) public spentToday;
    mapping(address => uint256) public lastSpendingReset;

    mapping(address => bool) public isMerchant;
    mapping(address => string) public merchantName;

    uint256 public cashbackPercentage = 2; // 2%

    event MerchantRegistered(address merchant, string name);
    event DailyLimitSet(address student, uint256 limit);

    constructor() ERC20("Campus Credit", "CREDIT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _mint(msg.sender, 10_000_000 * 10 ** decimals());
    }

    modifier onlyMerchant() {
        require(isMerchant[msg.sender], "NOT_MERCHANT");
        _;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        uint256 mintLimit = 1_000_000 * 10 ** decimals();
        require(amount <= mintLimit, "Exceed daily mint limit");
        _mint(to, amount);
    }

    function registerMerchant(
        address merchant,
        string memory name
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!isMerchant[merchant], "ALREADY_REGISTERED");
        require(bytes(name).length != 0, "INVALID_NAME");
        isMerchant[merchant] = true;
        merchantName[merchant] = name;
        emit MerchantRegistered(merchant, name);
    }

    function setDailyLimit(
        address student,
        uint256 limit
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        dailySpendingLimit[student] = limit;
        emit DailyLimitSet(student, limit);
    }

    function _checkAndResetDaily(address user) internal {
        if (block.timestamp >= lastSpendingReset[user] + 1 days) {
            spentToday[user] = 0;
            lastSpendingReset[user] = block.timestamp;
        }
    }

    // Override _update to include pause functionality
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override whenNotPaused {
        super._update(from, to, value);
    }
}
