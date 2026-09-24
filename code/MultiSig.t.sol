// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Tokenizer} from "@code/Tokenizer.sol";
import {MultiSig} from "@code/MultiSig.sol";

contract MultiSigTest is Test {
    Tokenizer public token;
    MultiSig public multisig;

    address public alice = address(0x1);
    address public bob = address(0x2);
    address public carol = address(0x3);
    address public mallory = address(0x4);

    function setUp() public {
        address[] memory signers = new address[](3);
        signers[0] = alice;
        signers[1] = bob;
        signers[2] = carol;

        token = new Tokenizer("Token42", "T42", 1000);
        multisig = new MultiSig(signers, 2);

        token.transfer(address(multisig), token.totalSupply());
        token.transferOwnership(address(multisig));
    }

    function _submit(bytes memory data) internal returns (uint256) {
        vm.prank(alice);
        return multisig.submitTransaction(address(token), data);
    }

    function _mintData() internal view returns (bytes memory) {
        return abi.encodeCall(Tokenizer.mint, (carol, 100));
    }

    // Constructor

    function test_Constructor() public view {
        address[] memory signers = multisig.signers();

        assertEq(signers.length, 3);
        assertEq(signers[0], alice);
        assertTrue(multisig.isSigner(bob));
        assertFalse(multisig.isSigner(mallory));
        assertEq(multisig.required(), 2);
    }

    function test_RevertWhen_ConstructorNoSigners() public {
        vm.expectRevert("Signers required");
        new MultiSig(new address[](0), 1);
    }

    function test_RevertWhen_ConstructorInvalidRequired() public {
        address[] memory signers = new address[](1);
        signers[0] = alice;

        vm.expectRevert("Invalid number of required signatures");
        new MultiSig(signers, 2);
    }

    function test_RevertWhen_ConstructorZeroAddressSigner() public {
        vm.expectRevert("Invalid signer");
        new MultiSig(new address[](1), 1);
    }

    function test_RevertWhen_ConstructorDuplicateSigner() public {
        address[] memory signers = new address[](2);
        signers[0] = alice;
        signers[1] = alice;

        vm.expectRevert("Duplicate signer");
        new MultiSig(signers, 1);
    }

    // Parcours complet : submit -> confirm -> execute

    function test_SubmitConfirmExecute() public {
        bytes memory data = _mintData();
        uint256 txId = _submit(data);

        assertTrue(multisig.isConfirmed(txId, alice));

        vm.prank(bob);
        multisig.confirmTransaction(txId);

        vm.prank(carol);
        multisig.executeTransaction(txId);

        MultiSig.Transaction memory transaction = multisig.transaction(txId);
        assertEq(transaction.target, address(token));
        assertEq(transaction.data, data);
        assertTrue(transaction.executed);
        assertEq(transaction.confirmations, 2);
        assertEq(token.balanceOf(carol), 100);

        // Une transaction exécutée ne peut pas l'être une deuxième fois
        vm.prank(carol);
        vm.expectRevert("Transaction already executed");
        multisig.executeTransaction(txId);
    }

    function test_Revoke() public {
        uint256 txId = _submit(_mintData());

        vm.prank(alice);
        multisig.revokeConfirmation(txId);

        assertFalse(multisig.isConfirmed(txId, alice));
        assertEq(multisig.transaction(txId).confirmations, 0);
    }

    // Reverts

    function test_RevertWhen_NotSigner() public {
        vm.prank(mallory);
        vm.expectRevert("Not a signer");
        multisig.executeTransaction(0);
    }

    function test_RevertWhen_SubmitZeroTarget() public {
        vm.prank(alice);
        vm.expectRevert("Invalid target");
        multisig.submitTransaction(address(0), "");
    }

    function test_RevertWhen_TransactionDoesNotExist() public {
        vm.prank(alice);
        vm.expectRevert("Transaction does not exist");
        multisig.executeTransaction(0);
    }

    function test_RevertWhen_ConfirmTwice() public {
        uint256 txId = _submit(_mintData());

        vm.prank(alice);
        vm.expectRevert("Transaction already confirmed");
        multisig.confirmTransaction(txId);
    }

    function test_RevertWhen_RevokeNotConfirmed() public {
        uint256 txId = _submit(_mintData());

        vm.prank(bob);
        vm.expectRevert("Transaction not confirmed");
        multisig.revokeConfirmation(txId);
    }

    function test_RevertWhen_NotEnoughConfirmations() public {
        uint256 txId = _submit(_mintData());

        vm.prank(alice);
        vm.expectRevert("Not enough confirmations");
        multisig.executeTransaction(txId);
    }

    function test_RevertWhen_ExecuteFailingCall() public {
        // Le multisig ne détient que 1000 tokens : ce transfert échoue dans le token
        uint256 txId = _submit(abi.encodeCall(Tokenizer.transfer, (carol, 1001 * 10 ** 18)));

        vm.prank(bob);
        multisig.confirmTransaction(txId);

        vm.prank(bob);
        vm.expectRevert("Transaction failed");
        multisig.executeTransaction(txId);
    }
}
