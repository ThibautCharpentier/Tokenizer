// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Tokenizer} from "@code/Tokenizer.sol";
import {MultiSig} from "@code/MultiSig.sol";

contract TokenizerScript is Script {
    function run() external returns (Tokenizer, MultiSig) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address[] memory signers = vm.envAddress("MULTISIG_SIGNERS", ",");
        uint256 required = vm.envUint("MULTISIG_REQUIRED");

        vm.startBroadcast(deployerPrivateKey);

        Tokenizer token = new Tokenizer("Token42", "T42", 1000);
        MultiSig multisig = new MultiSig(signers, required);

        token.transfer(address(multisig), token.totalSupply());
        token.transferOwnership(address(multisig));

        vm.stopBroadcast();

        return (token, multisig);
    }
}
