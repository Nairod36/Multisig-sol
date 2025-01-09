// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MultiSigWallet} from "../src/multisig.sol";
import {console} from "forge-std/console.sol";

/**
 * @title DeployMultiSig
 * @notice Script de déploiement pour MultiSigWallet avec Foundry.
 */
contract DeployMultiSig is Script {

    function testA()public {}

    function run() external {
        // 1. On démarre la broadcast, ce qui signifiera que tout tx sera envoyé sur le réseau
        vm.startBroadcast();

        // 2. Adresses signataires (exemple fictif, à adapter)
        address[] memory initSigners = new address[](3);
        initSigners[0] = 0x1111111111111111111111111111111111111111;
        initSigners[1] = 0x2222222222222222222222222222222222222222;
        initSigners[2] = 0x3333333333333333333333333333333333333333;

        // 3. Déploiement du contrat
        MultiSigWallet multisig = new MultiSigWallet(initSigners);

        // 4. Affichage de l'adresse
        console.log("Multisig deploye a:", address(multisig));

        vm.stopBroadcast();
    }
}