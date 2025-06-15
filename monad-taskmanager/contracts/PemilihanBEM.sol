// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract PemilihanBEM {
    struct Kandidat {
        string nama;
        string visi;
        uint256 suara;
    }
    
    Kandidat[] public kandidat;
    mapping(address => bool) public sudahMemilih;
    mapping(address => bool) public pemilihTerdaftar;
    
    uint256 public waktuMulai;
    uint256 public waktuSelesai;
    address public admin;
    
    event VoteCasted(address indexed voter, uint256 kandidatIndex);
    event KandidatAdded(string nama);
    event VotingStarted(uint256 waktuMulai, uint256);
    
    modifier onlyDuringVoting() {
        require(
            block.timestamp >= waktuMulai && 
            block.timestamp <= waktuSelesai, 
            "Voting belum dimulai atau sudah selesai"
        );
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Anda tidak punya akses");
        _;
    }

    constructor(uint256 _waktuMulai, uint256 _waktuSelesai) {
        admin = msg.sender;
        waktuMulai = _waktuMulai;
        waktuSelesai = _waktuSelesai;
        emit VotingStarted(_waktuMulai, _waktuSelesai);
    }
    // TODO: Implementasikan add candidate function
    function addCandidate(string memory nama, string memory visi ) public onlyAdmin {
        kandidat.push(Kandidat(nama, visi, 0));
        emit KandidatAdded(nama);
    }

    // TODO: Implementasikan vote function
    function vote(uint256 _kandidatIndex) public onlyDuringVoting {
        require(!sudahMemilih[msg.sender], "Anda sudah memilih");
        kandidat[_kandidatIndex].suara += 1;

        emit VoteCasted(msg.sender, _kandidatIndex);
    }
    // TODO: Implementasikan get results function
    function getResult() public view  returns (string memory nama, uint256 suara){
        for(uint i = 0; kandidat.length > i; ++i) {
            if (kandidat[i].suara > suara) {
                return (kandidat[i].nama, kandidat[i].suara);
            }
        }
    }

}