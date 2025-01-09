# MultiSigWallet – Projet Foundry

Ce dépôt contient une implémentation d’un **wallet multisignature** (multisig) en Solidity, utilisant **Foundry** pour le développement et les tests.  
Le contrat exige **3 signataires minimum** et **2 confirmations** pour exécuter une transaction.  
Il permet :

- De soumettre, confirmer, révoquer et exécuter des transactions,
- D’ajouter ou de retirer des signataires (sans descendre sous 3),
- D’assurer une sécurité renforcée via le contrôle multisignature.

---

## Sommaire
1. [Caractéristiques clés](#caractéristiques-clés)  
2. [Structure du projet](#structure-du-projet)  
3. [Prérequis](#prérequis)  
4. [Installation](#installation)  
5. [Compilation et tests](#compilation-et-tests)  
6. [Couverture des tests](#couverture-des-tests)  
7. [Script de déploiement](#script-de-déploiement)  
8. [Interagir avec le contrat](#interagir-avec-le-contrat)  
9. [Licence](#licence)  

---

## Caractéristiques clés

- **Multisig** : Au moins **2 confirmations** requises pour valider une transaction.  
- **3 signataires minimum** : le contrat ne peut être réduit à moins de 3 signataires.  
- **Actions principales** :  
  - `submitTransaction` : soumettre une transaction,  
  - `confirmTransaction` : confirmer la transaction,  
  - `revokeConfirmation` : révoquer sa confirmation,  
  - `executeTransaction` : exécuter la transaction,  
  - `addSigner` / `removeSigner` : gestion dynamique des signataires.  
- **NatSpec** : documentation intégrée au code.  

---

## Structure du projet

my-multisig-foundry/
├── foundry.toml
├── script/
│    └── DeployMultiSig.s.sol       # Script de déploiement
├── src/
│    └── MultiSigWallet.sol         # Contrat multisig principal
├── test/
│    └── MultiSigWallet.t.sol       # Tests Foundry
└── README.md                       # Documentation

---

## Prérequis

- **Git** pour cloner le dépôt.
- **Foundry** :  
  - Installation via [foundry.sh](https://book.getfoundry.sh/getting-started/installation).
  - Principales commandes : `forge build`, `forge test`, `forge coverage`.
- **Solidity 0.8.19** (géré par Foundry).
- (Optionnel) **Node.js**, si vous souhaitez d’autres scripts, mais non nécessaire ici.

---

## Installation

1. **Cloner** le dépôt :
   ```bash
   git clone https://github.com/VOTRE-REPO-ICI/my-multisig-foundry.git
   cd my-multisig-foundry
    ```
	
2.	Installer Foundry (si pas déjà fait) :

curl -L https://foundry.paradigm.xyz | bash
foundryup


	3.	Compiler le contrat :

forge build

Compilation et tests
	•	Compiler :

forge build


	•	Lancer les tests :

forge test

Les tests se trouvent dans test/MultiSigWallet.t.sol, et couvrent :
	•	La soumission/exécution de transaction,
	•	La confirmation/révocation,
	•	Les ajouts et retraits de signataires,
	•	Les scénarios de revert.

Couverture des tests

Pour générer un rapport de couverture :

forge coverage

	Astuce : Certaines branches conditionnelles (ex. un require(...)) nécessitent de tester à la fois le succès et l’échec pour atteindre 100 % de couverture.

Script de déploiement
	•	Le script script/DeployMultiSig.s.sol automatise le déploiement sur un réseau local (Anvil) ou un testnet :

# Sur un réseau local Anvil
anvil
forge script script/DeployMultiSig.s.sol --fork-url http://localhost:8545 --broadcast

Pour un testnet (Sepolia, etc.), configurez vos variables (--rpc-url et --private-key) puis lancez :

forge script script/DeployMultiSig.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast

Interagir avec le contrat

Une fois déployé, vous pouvez appeler ses fonctions via cast, ou tout autre outil :
	•	Ajouter un signataire :

multiSig.addSigner(0xNouvelleAdresse);


	•	Soumettre une transaction :

multiSig.submitTransaction(
    0xDestination,
    1000000000000000000, // 1 ETH
    "0x"                 // Données (payload)
);


	•	Confirmer :

multiSig.confirmTransaction(0);

(où 0 est l’index de la transaction dans transactions).

	•	Exécuter :

multiSig.executeTransaction(0);

(nécessite ≥ 2 confirmations).

Licence

Ce projet est sous licence MIT. Vous êtes libre de l’utiliser, de le modifier et de le distribuer. Veuillez conserver la mention de la licence si vous le réutilisez.

Merci d’avoir consulté ce projet !
N’hésitez pas à ouvrir une issue ou à faire une PR si vous avez des suggestions ou corrections.

