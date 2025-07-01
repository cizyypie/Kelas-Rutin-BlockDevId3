// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/**
 * @title StudentID
 * @dev NFT-based student identity card
 * Features:
 * - Auto-expiry after 4 years
 * 
 * - Renewable untuk active students
 * - Contains student metaata
 * - Non-transferable (soulbound)
 */
contract StudentID is ERC721, ERC721URIStorage, Ownable {
    uint256 private _nextTokenId;

    struct StudentData {
        string nim;
        string name;
        string major;
        uint256 enrollmentYear;
        uint256 expiryDate;
        bool isActive;
        uint8 semester;
    }

    // TODO: Add mappings
    mapping(uint256 => StudentData) public studentData;
    mapping(string => uint256) public nimToTokenId; // Prevent duplicate NIM
    mapping(address => uint256) public addressToTokenId; // One ID per address

    // Events
    event StudentIDIssued(
        uint256 indexed tokenId,
        string nim,
        address student,
        uint256 expiryDate
    );
    event StudentIDRenewed(uint256 indexed tokenId, uint256 newExpiryDate);
    event StudentStatusUpdated(uint256 indexed tokenId, bool isActive);
    event ExpiredIDBurned(uint256 indexed tokenId);

    constructor() ERC721("Student Identity Card", "SID")  {}

    /**
     * @dev Issue new student ID
     * Use case: New student enrollment
     */
    function issueStudentID(
        address to,
        string memory nim,
        string memory name,
        string memory major,
        string memory uri
    ) public onlyOwner {
        // TODO: Implement ID issuance
        // Hints:
        // 1. Check NIM tidak duplicate (use nimToTokenId)
         // 2. Check address belum punya ID (use addressToTokenId)
        require(nimToTokenId[nim] == 0, "NIM Sudah Ada");
        require(addressToTokenId[to] == 0, "Address ini sudah punya ID");


        uint256 nextTokenId = _nextTokenId;
        // 3. Calculate expiry (4 years from now)
        uint256 expiryDate = block.timestamp + (4 * 365 days);

        // 4. Mint NFT
        _mint(to, nextTokenId);

        // 5. Set token URI (foto + metadata)
        _setTokenURI(nextTokenId, uri);

        // 6. Store student data
        studentData[nextTokenId] = StudentData({
            nim: nim,
            name: name,
            major: major,
            enrollmentYear: block.timestamp,
            expiryDate: expiryDate,
            isActive: true,
            semester: 1
        });

        // 7. Update mappings
        nimToTokenId[nim] = nextTokenId;
        addressToTokenId[to] = nextTokenId;

        _nextTokenId++;
        // 8. Emit event
        emit StudentIDIssued(nextTokenId, nim, to, expiryDate);
    }

    /**
     * @dev Renew student ID untuk semester baru
     */
    function renewStudentID(uint256 tokenId) public onlyOwner {
        // TODO: Extend expiry date
        // Check token exists
        require(ownerOf(tokenId) != address(0), "Token tidak ada");
        // Check student is active
        require(studentData[tokenId].isActive, "Siswa tidak aktif");
        // Add 6 months to expiry
        studentData[tokenId].expiryDate += 6 * 30 days;
        // Update semester
        studentData[tokenId].semester += 1;
        // Emit renewal event
        emit StudentIDRenewed(tokenId, studentData[tokenId].expiryDate);
    }

    /**
     * @dev Update student status (active/inactive)
     * Use case: Cuti, DO, atau lulus
     */
    function updateStudentStatus(uint256 tokenId, bool isActive) public onlyOwner {
        // TODO: Update active status
        require(ownerOf(tokenId) != address(0), "Token tidak ada");
        require(studentData[tokenId].isActive != isActive, "Status sudah diperbaharui");
        studentData[tokenId].isActive = isActive;

        emit StudentStatusUpdated(tokenId, isActive);
    }

    /**
     * @dev Burn expired IDs
     * Use case: Cleanup expired cards
     */
    function burnExpired(uint256 tokenId) public {
        // TODO: Allow anyone to burn if expired
        // Check token exists
        require(ownerOf(tokenId) != address(0), "Token tidak ada");
        // Check if expired (block.timestamp > expiryDate)
        require(isExpired(tokenId), "ID belum expire");

        string memory nim = studentData[tokenId].nim;
        address owner = ownerOf(tokenId);

        // Burn token
        _burn(tokenId);

        // Clean up mappings
        delete studentData[tokenId];
        delete nimToTokenId[nim];
        delete addressToTokenId[owner];

        // Emit event
        emit ExpiredIDBurned(tokenId);
    }

    /**
     * @dev Check if ID is expired
     */
    function isExpired(uint256 tokenId) public view returns (bool) {
        // TODO: Return true if expired
        return block.timestamp > studentData[tokenId].expiryDate;
    }

    /**
     * @dev Get student info by NIM
     */
    function getStudentByNIM(string memory nim) public view returns (
        address owner,
        uint256 tokenId,
        StudentData memory data
    ) {
        // TODO: Lookup student by NIM
        uint256 _tokenId = nimToTokenId[nim];
        require(_tokenId != 0, "NIM tidak terdaftar");
        require(ownerOf(_tokenId) != address(0), "Token hangus");

        owner = ownerOf(_tokenId);
        tokenId = _tokenId;
        data = studentData[_tokenId];
    }

    /**
     * @dev Override transfer functions to make non-transferable
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override (ERC721){
        // TODO: Make soulbound (non-transferable)
        // Only allow minting (from == address(0)) and burning (to == address(0))
        require(from == address(0) || to == address(0), "SID is non-transferable");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // Override functions required untuk multiple inheritance
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        string memory nim = studentData[tokenId].nim;
        address owner = ownerOf(tokenId);

        super._burn(tokenId);

        // TODO: Clean up student data when burning
        delete studentData[tokenId];
        delete nimToTokenId[nim];
        delete addressToTokenId[owner];
    }
}