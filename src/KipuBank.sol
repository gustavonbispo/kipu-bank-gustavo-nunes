/**
 *Submitted for verification at Etherscan.io on 2025-04-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KipuBank {
    /*///////////////////////////////////
                Variables
    ///////////////////////////////////*/
    uint256 public immutable i_bankCap;
    uint256 public constant WITHDRAW_LIMIT = 10 ether;
    mapping(address => uint256) private s_userBalance;

    /*///////////////////////////////////
                Events
    ///////////////////////////////////*/
    event KipuBank_DepositSuccessful(address indexed sender, uint256 amount);
    event KipuBank_WithdrawSuccessful(address indexed user, uint256 amount);

    /*///////////////////////////////////
                Errors
    ///////////////////////////////////*/
    error KipuBank_BankCapExceeded(uint256 currentBalance, uint256 depositAmount, uint256 bankCap);
    error KipuBank_DepositAmountMustBeGreaterThanZero();
    error KipuBank_WithdrawAmountExceedsBalance(uint256 userBalance, uint256 requestedAmount);
    error KipuBank_WithdrawAmountExceedsLimit(uint256 withdrawLimit, uint256 requestedAmount);
    error KipuBank_TransferFailed();
    error KipuBank_InvalidBankCap();

    /*///////////////////////////////////
                Modifiers
    ///////////////////////////////////*/
    modifier validDeposit(uint256 amount) {
        if (amount == 0) {
            revert KipuBank_DepositAmountMustBeGreaterThanZero();
        }
        if (address(this).balance > i_bankCap) {
            revert KipuBank_BankCapExceeded(
                address(this).balance,
                amount,
                i_bankCap
            );
        }
        _;
    }

    /*///////////////////////////////////
                Constructor
    ///////////////////////////////////*/
    constructor(uint256 _bankCap) {
        if (_bankCap == 0) {
            revert KipuBank_InvalidBankCap();
        }
        i_bankCap = _bankCap * 1 ether;
    }

    /*///////////////////////////////////
                Public
    ///////////////////////////////////*/
    function deposit() public payable validDeposit(msg.value) {
        s_userBalance[msg.sender] += msg.value;
        emit KipuBank_DepositSuccessful(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public {
        if (amount > WITHDRAW_LIMIT) {
            revert KipuBank_WithdrawAmountExceedsLimit(WITHDRAW_LIMIT, amount);
        }

        if (amount > s_userBalance[msg.sender]) {
            revert KipuBank_WithdrawAmountExceedsBalance(s_userBalance[msg.sender], amount);
        }

        s_userBalance[msg.sender] -= amount;
        _transferEther(payable(msg.sender), amount);

        emit KipuBank_WithdrawSuccessful(msg.sender, amount);
    }


    function withdrawAll() public {
        uint256 balance = s_userBalance[msg.sender];
        if (balance == 0) {
            revert KipuBank_WithdrawAmountExceedsBalance(0, 0);
        }

        s_userBalance[msg.sender] = 0;
        _transferEther(payable(msg.sender), balance);

        emit KipuBank_WithdrawSuccessful(msg.sender, balance);
    }

    /*///////////////////////////////////
                Private
    ///////////////////////////////////*/
    function _transferEther(address payable recipient, uint256 amount) private {
        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert KipuBank_TransferFailed();
        }
    }

    /*///////////////////////////////////
            View & Pure
    ///////////////////////////////////*/
    function getBankBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getUserBalance(address user) public view returns (uint256) {
        return s_userBalance[user];
    }

    /*///////////////////////////////////
                Fallbacks
    ///////////////////////////////////*/
    receive() external payable {
        revert("Use the deposit function");
    }

    fallback() external payable {
        revert("Function does not exist");
    }
}