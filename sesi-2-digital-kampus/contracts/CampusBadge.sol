// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

/**
 * @title CampusBadge
 * @dev Multi-token untuk berbagai badges dan certificates
 */
contract CampusBadge is ERC1155, AccessControl, Pausable, ERC1155Supply {
    // Role definitions
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Token ID ranges untuk organization
    uint256 public constant CERTIFICATE_BASE = 1000;
    uint256 public constant EVENT_BADGE_BASE = 2000;
    uint256 public constant ACHIEVEMENT_BASE = 3000;
    uint256 public constant WORKSHOP_BASE = 4000;

    // Token metadata structure
    struct TokenInfo {
        string name;
        string category;
        uint256 maxSupply;
        bool isTransferable;
        uint256 validUntil; // 0 = no expiry
        address issuer;
    }

    // TODO: Add mappings
    mapping(uint256 => TokenInfo) public tokenInfo;
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => uint256) private _tokenCounters;

    // Track student achievements
    mapping(address => uint256[]) public studentBadges;
    mapping(uint256 => mapping(address => uint256)) public earnedAt; // Timestamp

    // Counter untuk generate unique IDs
    uint256 private _certificateCounter;
    uint256 private _eventCounter;
    uint256 private _achievementCounter;
    uint256 private _workshopCounter;

    error CertificateTypeDoesNotExist();
    error MaxSupplyExceeded();
    error StudentHasNoBadges();
    error CertificateIsExpired();

    constructor() ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function createCertificateType(
        string memory name,
        uint256 maxSupply,
        string memory certificateURI
    ) public onlyRole(MINTER_ROLE) returns (uint256) {
        uint256 certificateId = CERTIFICATE_BASE + _certificateCounter++;
        TokenInfo memory info = TokenInfo({
            name: name,
            category: "Certificate",
            maxSupply: maxSupply,
            isTransferable: false,
            validUntil: 0,
            issuer: msg.sender
        });
        tokenInfo[certificateId] = info;
        _tokenCounters[certificateId] = 0;
        _tokenURIs[certificateId] = certificateURI;
        return certificateId;
    }

    function issueCertificate(
        address student,
        uint256 certificateType,
        string memory additionalData
    ) public onlyRole(MINTER_ROLE) {
        TokenInfo memory info = tokenInfo[certificateType];
        if (bytes(info.name).length == 0) {
            revert CertificateTypeDoesNotExist();
        }
        uint256 mintedAmount = _tokenCounters[certificateType];
        if (mintedAmount >= info.maxSupply) {
            revert MaxSupplyExceeded();
        }
        _tokenCounters[certificateType]++;
        _mint(student, certificateType, 1, bytes(additionalData));
        earnedAt[certificateType][student] = block.timestamp;
        studentBadges[student].push(certificateType);
    }

    function mintEventBadges(
        address[] memory attendees,
        uint256 eventId,
        uint256 amount
    ) public onlyRole(MINTER_ROLE) {
        uint256 badgeId = EVENT_BADGE_BASE + eventId;
        for (uint256 i = 0; i < attendees.length; i++) {
            address attendee = attendees[i];
            _mint(attendee, badgeId, amount, "");
            studentBadges[attendee].push(badgeId);
        }
    }

    function setTokenURI(uint256 tokenId, string memory newuri) 
        public onlyRole(URI_SETTER_ROLE) 
    {
        _tokenURIs[tokenId] = newuri;
    }

    function getStudentBadges(address student) 
        public view returns (uint256[] memory) 
    {
        return studentBadges[student];
    }

    function verifyBadge(address student, uint256 tokenId) 
        public view returns (bool isValid, uint256 earnedTimestamp) 
    {
        if (balanceOf(student, tokenId) == 0) {
            revert StudentHasNoBadges();
        }
        isValid = tokenInfo[tokenId].validUntil == 0 || tokenInfo[tokenId].validUntil > block.timestamp;
        return (isValid, earnedAt[tokenId][student]);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        if (paused()) revert("Token transfers are paused");

        for (uint i = 0; i < ids.length; i++) {
            if (from != address(0) && to != address(0)) {
                require(tokenInfo[ids[i]].isTransferable, "Token not transferable");
            }
        }

        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function grantAchievement(
        address student,
        string memory achievementName,
        uint256 rarity
    ) public onlyRole(MINTER_ROLE) returns (uint256) {
        uint256 achievementId = ACHIEVEMENT_BASE + _achievementCounter++;
        TokenInfo memory info = TokenInfo({
            name: achievementName,
            category: "Achievement",
            maxSupply: rarity == 1 ? 1000 : (rarity == 2 ? 100 : 10),
            isTransferable: false,
            validUntil: 0,
            issuer: msg.sender
        });
        tokenInfo[achievementId] = info;
        _mint(student, achievementId, 1, "");

        return achievementId;
    }

    function createWorkshopSeries(
        string memory seriesName,
        uint256 totalSessions
    ) public onlyRole(MINTER_ROLE) returns (uint256[] memory) {
        uint256[] memory workshopIDs = new uint256[](totalSessions);
        for (uint256 i = 0; i < totalSessions; i++) {
            uint256 workshopId = WORKSHOP_BASE + _workshopCounter++;
            TokenInfo memory info = TokenInfo({
                name: seriesName,
                category: "Workshop",
                maxSupply: totalSessions,
                isTransferable: false,
                validUntil: 0,
                issuer: msg.sender
            });
            tokenInfo[workshopId] = info;
            workshopIDs[i] = workshopId;
        }

        return workshopIDs;
    }
}
