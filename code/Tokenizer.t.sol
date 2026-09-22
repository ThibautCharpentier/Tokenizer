// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Tokenizer} from "@code/Tokenizer.sol";

contract TokenizerTest is Test {
    Tokenizer public token;

    address public owner = address(this);
    address public alice = address(0x1);
    address public bob = address(0x2);

    uint256 public constant INITIAL_SUPPLY = 1000;

    function setUp() public {
        token = new Tokenizer("Token42", "T42", INITIAL_SUPPLY);
    }

    function test_Getters() public {
        uint256 amount = 200 * 10 ** 18;

        token.approve(alice, amount);

        assertEq(token.name(), "Token42");
        assertEq(token.symbol(), "T42");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), INITIAL_SUPPLY * 10 ** 18);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY * 10 ** 18);
        assertEq(token.owner(), owner);
        assertEq(token.allowance(owner, alice), amount);
    }

    function test_Transfer() public {
        uint256 amount = 100 * 10 ** 18;

        bool success = token.transfer(alice, amount);

        assertTrue(success);
        assertEq(token.balanceOf(alice), amount);
        assertEq(token.balanceOf(owner), (INITIAL_SUPPLY * 10 ** 18) - amount);
    }

    function test_RevertWhen_TransferInsufficientBalance() public {
        vm.prank(alice);
        vm.expectRevert("Insufficient balance");
        token.transfer(bob, 50 * 10 ** 18);
    }

    function test_ApproveAndTransferFrom() public {
        uint256 amount = 200 * 10 ** 18;

        token.approve(alice, amount);
        assertEq(token.allowance(owner, alice), amount);

        vm.prank(alice);
        token.transferFrom(owner, bob, amount);
        assertEq(token.balanceOf(bob), amount);
        assertEq(token.allowance(owner, alice), 0);
    }

    function test_RevertWhen_TransferFromInsufficientBalance() public {
        uint256 amount = 200 * 10 ** 18;

        token.approve(alice, amount);
        vm.expectRevert("Insufficient balance");
        token.transferFrom(owner, bob, (INITIAL_SUPPLY * 10 ** 18) + 1);
    }

    function test_RevertWhen_TransferFromInsufficientPowerOfAttorney() public {
        uint256 amount = 200 * 10 ** 18;

        token.approve(alice, amount);
        vm.expectRevert("Insufficient power of attorney");
        token.transferFrom(owner, bob, amount + 1);
    }

    function test_MintAsOwner() public {
        uint256 mintAmount = 500 * 10 ** 18;

        token.mint(alice, mintAmount);

        assertEq(token.balanceOf(alice), mintAmount);
        assertEq(token.totalSupply(), (INITIAL_SUPPLY * 10 ** 18) + mintAmount);
    }

    function test_RevertWhen_MintAsNonOwner() public {
        vm.prank(alice);
        vm.expectRevert("Only owner can call this function");
        token.mint(alice, 100);
    }

    function test_Burn() public {
        uint256 burnAmount = 100 * 10 ** 18;

        token.burn(burnAmount);

        assertEq(token.balanceOf(owner), (INITIAL_SUPPLY * 10 ** 18) - burnAmount);
        assertEq(token.totalSupply(), (INITIAL_SUPPLY * 10 ** 18) - burnAmount);
    }

    function test_RevertWhen_BurnExceedsBalance() public {
        vm.expectRevert("Burn amount exceeds balance");
        token.burn((INITIAL_SUPPLY * 10 ** 18) + 1);
    }
}
