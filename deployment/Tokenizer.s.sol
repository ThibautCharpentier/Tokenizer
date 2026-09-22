// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Tokenizer} from "@code/Tokenizer.sol";

contract TokenizerScript is Script {
    function run() external returns (Tokenizer) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        Tokenizer token = new Tokenizer("Token42", "T42", 1000);

        vm.stopBroadcast();

        return token;
    }
}
