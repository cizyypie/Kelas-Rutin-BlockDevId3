// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract SistemAkademik {
    struct Mahasiswa {
        string nama;
        uint256 nim;
        string jurusan;
        uint256[] nilai;
        bool isActive;
    }
    
    mapping(uint256 => Mahasiswa) public mahasiswa;
    mapping(address => bool) public authorized;
    uint256[] public daftarNIM;
    
    event MahasiswaEnrolled(uint256 nim, string nama);
    event NilaiAdded(uint256 nim, uint256 nilai);
    
    modifier onlyAuthorized() {
        require(authorized[msg.sender], "Tidak memiliki akses");
        _;
    }
    
    constructor() {
        authorized[msg.sender] = true;
    }
    
    // TODO: Implementasikan enrollment function
    function enrollment(string memory _nama, uint256 _nim, string memory _jurusan) public onlyAuthorized {
        Mahasiswa storage mhs = mahasiswa[_nim];
        require(mhs.nim == 0, "mhs sudah terdaftar");
        mhs.nim = _nim;
        mhs.nama = _nama;
        mhs.jurusan = _jurusan;
        mhs.isActive = true;

        daftarNIM.push(_nim);
        emit MahasiswaEnrolled(_nim, _nama);
    }
    // TODO: Implementasikan add grade function
    function addGrade(uint256 _nim, uint256 _nilai) public onlyAuthorized{
        Mahasiswa storage mhs = mahasiswa[_nim];
        require(mhs.isActive, "Mahasiswa tidak aktif");
        mhs.nilai.push(_nilai);

        emit NilaiAdded(mhs.nim, _nilai);
    }
    // TODO: Implementasikan get student info function

    function getStudentInfo(uint256 _nim) public view returns(
            string memory,
            string memory,
            uint256[] memory,
            bool
        ) {
        Mahasiswa storage mhs = mahasiswa[_nim];
        require(mhs.nim != 0, "Mahasiswa tidak ditemukan");
        return (mhs.nama, mhs.jurusan, mhs.nilai, mhs.isActive);

    }
}