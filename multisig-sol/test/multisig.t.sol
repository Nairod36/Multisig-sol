// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/multisig.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet public multiSig;

    address owner1;
    address owner2;
    address owner3;
    address user;

    event SubmitTransaction(
        address indexed signer,
        uint256 indexed txIndex,
        address indexed destination,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction(address indexed signer, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed signer, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed signer, uint256 indexed txIndex);
    event SignerAdded(address indexed newSigner);
    event SignerRemoved(address indexed oldSigner);

    function setUp() public {
        owner1 = makeAddr("Owner1");
        owner2 = makeAddr("Owner2");
        owner3 = makeAddr("Owner3");
        user = makeAddr("User");

        address[] memory initSigners = new address[](3);
        initSigners[0] = owner1;
        initSigners[1] = owner2;
        initSigners[2] = owner3;

        multiSig = new MultiSigWallet(initSigners);
        vm.deal(address(multiSig), 10 ether);
    }

    function testConstructorRequirements() public {
        // Test minimum signers requirement
        address[] memory twoSigners = new address[](2);
        twoSigners[0] = owner1;
        twoSigners[1] = owner2;
        
        vm.expectRevert(bytes("au moins 3 signataires."));
        new MultiSigWallet(twoSigners);

        // Test duplicate signer requirement
        address[] memory duplicateSigners = new address[](3);
        duplicateSigners[0] = owner1;
        duplicateSigners[1] = owner1; // duplicate
        duplicateSigners[2] = owner2;
        
        vm.expectRevert(bytes("Signataire duplique."));
        new MultiSigWallet(duplicateSigners);

        // Test zero address requirement
        address[] memory zeroAddressSigners = new address[](3);
        zeroAddressSigners[0] = owner1;
        zeroAddressSigners[1] = owner2;
        zeroAddressSigners[2] = address(0);
        
        vm.expectRevert(bytes("Adresse invalide."));
        new MultiSigWallet(zeroAddressSigners);
    }

    function testInitialSigners() public {
        address[] memory s = multiSig.getSigners();
        assertEq(s.length, 3, "Should have 3 signers");
        assertTrue(multiSig.isSigner(owner1));
        assertTrue(multiSig.isSigner(owner2));
        assertTrue(multiSig.isSigner(owner3));
    }

    function testSubmitTransaction() public {
        vm.expectEmit(true, true, true, true);
        emit SubmitTransaction(owner1, 0, user, 1 ether, "");
        
        vm.prank(owner1);
        multiSig.submitTransaction(user, 1 ether, "");

        uint256 txCount = multiSig.getTransactionCount();
        assertEq(txCount, 1, "Tx count should be 1");
        
        // Test non-signer submission
        vm.prank(user);
        vm.expectRevert(bytes("Vous n'etes pas un signataire."));
        multiSig.submitTransaction(user, 1 ether, "");
    }

    function testConfirmAndExecute() public {
        vm.prank(owner1);
        multiSig.submitTransaction(user, 1 ether, "");
        uint256 txIndex = 0;

        vm.expectEmit(true, true, false, false);
        emit ConfirmTransaction(owner1, txIndex);
        
        vm.prank(owner1);
        multiSig.confirmTransaction(txIndex);

        vm.prank(owner2);
        multiSig.confirmTransaction(txIndex);

        uint256 initialBalance = user.balance;
        
        vm.expectEmit(true, true, false, false);
        emit ExecuteTransaction(owner3, txIndex);
        
        vm.prank(owner3);
        multiSig.executeTransaction(txIndex);

        assertEq(user.balance - initialBalance, 1 ether, "User should have received 1 ETH");
    }

    function testRevokeConfirmation() public {
        vm.prank(owner1);
        multiSig.submitTransaction(user, 1 ether, "");
        uint256 txIndex = 0;

        vm.prank(owner1);
        multiSig.confirmTransaction(txIndex);

        vm.expectEmit(true, true, false, false);
        emit RevokeConfirmation(owner1, txIndex);
        
        vm.prank(owner1);
        multiSig.revokeConfirmation(txIndex);

        vm.prank(owner2);
        vm.expectRevert(bytes("Pas assez de confirmations."));
        multiSig.executeTransaction(txIndex);

        // Test revoking non-existent confirmation
        vm.prank(owner2);
        vm.expectRevert(bytes("Aucune confirmation a revoquer."));
        multiSig.revokeConfirmation(txIndex);
    }

    function testRemoveSigner() public {
        // D'abord on ajoute un 4ème signataire pour pouvoir en retirer un
        address newSigner = makeAddr("Signer4");
        vm.prank(owner1);
        multiSig.addSigner(newSigner);
        
        // Maintenant on peut retirer owner3
        vm.expectEmit(true, false, false, false);
        emit SignerRemoved(owner3);
        
        vm.prank(owner1);
        multiSig.removeSigner(owner3);

        address[] memory s = multiSig.getSigners();
        assertEq(s.length, 3, "Should have 3 signers");
        
        // Test removing when only 3 signers left
        vm.expectRevert(bytes("On ne peut pas descendre en dessous de 3."));
        vm.prank(owner1);
        multiSig.removeSigner(owner2);
    }

    function testAddSigner() public {
        address newSigner = makeAddr("Signer4");
        
        vm.expectEmit(true, false, false, false);
        emit SignerAdded(newSigner);
        
        vm.prank(owner1);
        multiSig.addSigner(newSigner);

        address[] memory s = multiSig.getSigners();
        assertEq(s.length, 4, "Should have 4 signers");
        assertTrue(multiSig.isSigner(newSigner));

        // Test adding zero address
        vm.prank(owner1);
        vm.expectRevert(bytes("Adresse invalide."));
        multiSig.addSigner(address(0));

        // Test adding duplicate signer
        vm.prank(owner1);
        vm.expectRevert(bytes("Deja signataire."));
        multiSig.addSigner(newSigner);
    }

    function testFailedExecution() public {
    // Déployer le contrat qui va rejeter les Ether
    FailingContract failingContract = new FailingContract();
    
    // Soumettre la transaction
    vm.prank(owner1);
    multiSig.submitTransaction(address(failingContract), 1 ether, "");
    uint256 txIndex = 0;

    // Confirmer avec owner1 et owner2
    vm.prank(owner1);
    multiSig.confirmTransaction(txIndex);
    
    vm.prank(owner2);
    multiSig.confirmTransaction(txIndex);

    // La transaction devrait échouer car le contrat rejette l'ETH
    vm.prank(owner3);
    vm.expectRevert(abi.encodeWithSignature("Error(string)", "Transaction rejetee"));
    multiSig.executeTransaction(txIndex);
}

// Test attempting to execute with insufficient confirmations
function testExecuteWithInsufficientConfirmations() public {
    vm.prank(owner1);
    multiSig.submitTransaction(user, 1 ether, "");
    
    // Only one confirmation instead of required two
    vm.prank(owner1);
    multiSig.confirmTransaction(0);
    
    vm.prank(owner2);
    vm.expectRevert(bytes("Pas assez de confirmations."));
    multiSig.executeTransaction(0);
}

// Test confirming an already executed transaction
function testConfirmExecutedTransaction() public {
    vm.prank(owner1);
    multiSig.submitTransaction(user, 1 ether, "");
    
    vm.prank(owner1);
    multiSig.confirmTransaction(0);
    
    vm.prank(owner2);
    multiSig.confirmTransaction(0);
    
    vm.prank(owner3);
    multiSig.executeTransaction(0);
    
    // Try to confirm after execution
    vm.prank(owner3);
    vm.expectRevert(bytes("Transaction deja executee."));
    multiSig.confirmTransaction(0);
}

// Test confirming a non-existent transaction
function testConfirmNonExistentTransaction() public {
    vm.prank(owner1);
    vm.expectRevert(bytes("Transaction inexistante."));
    multiSig.confirmTransaction(0);
}

// Test edge case in removeSigner where signer is not found
function testRemoveNonExistentSigner() public {
    address nonExistentSigner = makeAddr("NonExistent");
    
    vm.prank(owner1);
    vm.expectRevert(bytes("N'est pas signataire."));
    multiSig.removeSigner(nonExistentSigner);
}

function testModifierFailures() public {
    // Test onlySigner modifier failure path
    // Try to submit transaction as non-signer
    vm.prank(user);
    vm.expectRevert(bytes("Vous n'etes pas un signataire."));
    multiSig.submitTransaction(address(0), 0, "");
    
    // Test txExists modifier failure path
    // Try to confirm non-existent transaction
    vm.prank(owner1);
    vm.expectRevert(bytes("Transaction inexistante."));
    multiSig.confirmTransaction(99);
    
    // Test notExecuted modifier failure path
    // Submit and execute a transaction, then try to confirm it again
    vm.prank(owner1);
    multiSig.submitTransaction(user, 1 ether, "");
    
    vm.prank(owner1);
    multiSig.confirmTransaction(0);
    vm.prank(owner2);
    multiSig.confirmTransaction(0);
    vm.prank(owner1);
    multiSig.executeTransaction(0);
    
    // Try to confirm already executed transaction
    vm.prank(owner3);
    vm.expectRevert(bytes("Transaction deja executee."));
    multiSig.confirmTransaction(0);
    
    // Test notConfirmed modifier failure path
    // Submit new transaction and try to confirm twice with same signer
    vm.prank(owner1);
    multiSig.submitTransaction(user, 1 ether, "");
    
    vm.prank(owner1);
    multiSig.confirmTransaction(1);
    
    // Try to confirm again with same signer
    vm.prank(owner1);
    vm.expectRevert(bytes("Deja confirme."));
    multiSig.confirmTransaction(1);
}

function testExecuteTransactionTwiceSameSignerAndNonSigner() public {
    // 1) Owner1 soumet une transaction
    vm.prank(owner1);
    multiSig.submitTransaction(user, 1 ether, "");

    // 2) On confirme avec owner1 et owner2 pour avoir 2 signatures
    vm.prank(owner1);
    multiSig.confirmTransaction(0);
    vm.prank(owner2);
    multiSig.confirmTransaction(0);

    // 3) Execution par owner3 => réussite
    vm.prank(owner3);
    multiSig.executeTransaction(0);

    // 4) Tenter de re-executer la même TX avec owner1 => "Transaction deja executee."
    vm.prank(owner1);
    vm.expectRevert(bytes("Transaction deja executee."));
    multiSig.executeTransaction(0);

    // 5) Tenter d’exécuter avec user (non-signer) => "Vous n'etes pas un signataire."
    vm.prank(user);
    vm.expectRevert(bytes("Vous n'etes pas un signataire."));
    multiSig.executeTransaction(0);
}

}

// Contrat qui va toujours rejeter les transactions entrantes
contract FailingContract {
    // Fonction fallback qui rejette toujours
    fallback() external payable {
        revert("Transaction rejetee");
    }

    // Fonction receive qui rejette aussi
    receive() external payable {
        revert("Transaction rejetee");
    }
}