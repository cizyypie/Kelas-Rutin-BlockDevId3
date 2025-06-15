// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract DigitalWalletKampus {
    mapping(address => uint256) public balances;
    address public admin;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount); 
    
    constructor() payable  {
        admin = msg.sender;
    }
    // TODO: Tambahkan access control, 
    modifier onlyAdmin() {
        require(msg.sender == admin, "Anda tidak punya akses");
        _;
    }

    function deposit() public payable {
        require(msg.value > 0, "Amount harus lebih dari 0");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    // TODO: Implementasikan withdraw function
    function withdraw(uint256 _amount) public onlyAdmin {
        // saldo cukup
        require((balances[msg.sender]>= _amount), "Saldo tidak cukup");
        // withdraw != 0
        require(_amount>0);
        balances[msg.sender] -= _amount;
        payable (msg.sender).transfer(_amount);
        emit Withdrawal(msg.sender, _amount); 

    }
    // TODO: Implementasikan transfer function
    function transfer(address _to , uint256 _amount) public {
        // pastikan saldo ckp
        require(balances[msg.sender]>=_amount, "Saldo tidak cukup");
        require(_amount>0, "Amount harus lebih besar dari 0");
        require(_to != msg.sender, "Tidak bisa menerima uang ke diri sendiri");

        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
    }
    
}