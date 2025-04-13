// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../lib/forge-std/src/Test.sol";
import "../../src/KipuBank.sol";

contract KipuBankTest is Test {
    KipuBank public kipuBank;

    uint256 bankCap = 1000 ether;
    address user = address(0x123);

    // Runs before each test
    function setUp() public {
        kipuBank = new KipuBank(bankCap);
        vm.deal(user, 100 ether); // Allocate 100 ether to the test user
    }

    // Tests that deposit correctly updates the balances
    function testDepositShouldIncreaseBalance() public {
        uint256 depositAmount = 1 ether;

        vm.prank(user); // Simulate user as msg.sender
        kipuBank.deposit{value: depositAmount}();

        assertEq(kipuBank.getBankBalance(), depositAmount);
        assertEq(kipuBank.getUserBalance(user), depositAmount);
    }

    // Tests that a successful withdrawal decreases balances accordingly
    function testWithdrawShouldDecreaseBalance() public {
        uint256 depositAmount = 5 ether;
        uint256 withdrawAmount = 1 ether;

        vm.prank(user);
        kipuBank.deposit{value: depositAmount}();

        vm.prank(user);
        kipuBank.withdraw(withdrawAmount);

        assertEq(kipuBank.getBankBalance(), depositAmount - withdrawAmount);
        assertEq(kipuBank.getUserBalance(user), depositAmount - withdrawAmount);
    }

    // Tests that a deposit exceeding the bank cap will revert
    function testDepositExceedsBankCapShouldFail() public {
        KipuBank lowCapBank = new KipuBank(1); // Cap set to 1 ether
        vm.deal(user, 2 ether);

        vm.prank(user);
        vm.expectRevert(); // No need for error data; revert is expected

        lowCapBank.deposit{value: 2 ether}();
    }

    // Tests that depositing zero ether will revert with the correct error
    function testDepositZeroShouldRevert() public {
        vm.prank(user);
        vm.expectRevert(KipuBank.KipuBank_DepositAmountMustBeGreaterThanZero.selector);
        kipuBank.deposit{value: 0}();
    }

    // Tests that withdrawing more than the limit reverts with proper error
    function testWithdrawExceedsLimitShouldFail() public {
        uint256 depositAmount = 10.01 ether;
        vm.deal(user, depositAmount);

        vm.prank(user);
        kipuBank.deposit{value: depositAmount}();
        assertEq(kipuBank.getUserBalance(user), depositAmount);

        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                KipuBank.KipuBank_WithdrawAmountExceedsLimit.selector,
                kipuBank.WITHDRAW_LIMIT(),
                depositAmount
            )
        );
        kipuBank.withdraw(depositAmount);
    }

    // Tests that withdrawing more than the user's balance will revert with correct error
    function testWithdrawMoreThanBalanceShouldRevert() public {
        uint256 depositAmount = 1 ether;
        uint256 withdrawAmount = 2 ether;

        vm.deal(user, depositAmount);
        vm.prank(user);
        kipuBank.deposit{value: depositAmount}();

        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                KipuBank.KipuBank_WithdrawAmountExceedsBalance.selector,
                depositAmount,
                withdrawAmount
            )
        );
        kipuBank.withdraw(withdrawAmount);
    }

    // Tests full withdrawal of a user’s balance
    function testWithdrawAll() public {
        uint256 depositAmount = 10 ether;

        vm.prank(user);
        kipuBank.deposit{value: depositAmount}();

        vm.prank(user);
        kipuBank.withdraw(depositAmount);

        assertEq(kipuBank.getUserBalance(user), 0);
        assertEq(kipuBank.getBankBalance(), 0);
    }

    // Tests withdrawAll with zero balance reverts with correct error
    function testWithdrawAllWithZeroBalanceShouldRevert() public {
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                KipuBank.KipuBank_WithdrawAmountExceedsBalance.selector,
                0,
                0
            )
        );
        kipuBank.withdrawAll();
    }

    // Tests that contract deployment with zero cap should revert
    function testConstructorWithZeroCapShouldRevert() public {
        vm.expectRevert(KipuBank.KipuBank_InvalidBankCap.selector);
        new KipuBank(0);
    }

    // Tests that sending ether directly via `receive()` reverts
    function testReceiveShouldRevert() public {
        vm.expectRevert(bytes("Use the deposit function"));
        (bool success, ) = address(kipuBank).call{value: 1 ether}("");
        require(success, "call failed");
    }

    // Tests that calling a non-existent function triggers the fallback and reverts
    function testFallbackShouldRevert() public {
        vm.expectRevert(bytes("Function does not exist"));
        (bool success, ) = address(kipuBank).call{value: 0.1 ether, gas: 100_000}(abi.encodeWithSignature("nonExistentFunction()"));
        success;
    }
}
