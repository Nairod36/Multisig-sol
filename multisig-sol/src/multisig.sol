// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title MultiSigWallet
 * @notice Implémentation d'un multisig wallet avec au moins deux signatures
 *         et garantissant au moins trois signataires.
 * @dev no lib
 */
contract MultiSigWallet {
    address[] public signers;

    // Mapping, vérifier si une adresse est signataire.
    mapping(address => bool) public isSigner;

    /// Nombre de signatures requis pour exécuter une transaction.
    uint256 public required;

    struct Transaction {
        address destination;   
        uint256 value;         
        bytes data;            
        bool executed;         
        uint256 numConfirmations; 
    }

    // Tableau de toutes les transactions soumises.
    Transaction[] public transactions;

    // confirmations[txIndex][signer] indique si un signataire a confirmé la transaction.
    mapping(uint256 => mapping(address => bool)) public confirmations;

    // =============================================================
    //                         ÉVÉNEMENTS
    // =============================================================

    /**
     * @notice Émis lorsque qu'une nouvelle transaction est soumise.
     * @param signer L'adresse qui a soumis la transaction.
     * @param txIndex L'index de la transaction dans le tableau.
     * @param destination L'adresse de destination de la transaction.
     * @param value Le montant (en wei) envoyé.
     * @param data Les données (payload) envoyées à la destination.
     */
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

    // =============================================================
    //                      CONSTRUCTEUR
    // =============================================================

    /**
     * @notice Initialise le multisig avec un tableau de 3 adresses minimum et fixe à 2 le nombre de signatures requises.
     * @param _signers Tableau d'adresses signataires.
     */
    constructor(address[] memory _signers) {
        require(_signers.length >= 3, "au moins 3 signataires.");
        for (uint256 i = 0; i < _signers.length; i++) {
            address s = _signers[i];
            require(s != address(0), "Adresse invalide.");
            require(!isSigner[s], "Signataire duplique.");
            isSigner[s] = true;
            signers.push(s);
        }
        // On fixe le nombre requis de signatures a 2
        required = 2;
    }

    // =============================================================
    //                      MODIFICATEURS
    // =============================================================

    //l'appelant est un signataire du multisig.
    modifier onlySigner() {
        require(isSigner[msg.sender], "Vous n'etes pas un signataire.");
        _;
    }

    //'index de la transaction est valide.
    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "Transaction inexistante.");
        _;
    }

    //la transaction n'est pas déjà exécutée.
    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "Transaction deja executee.");
        _;
    }

    //l'appelant n'a pas déjà confirmé cette transaction.
    modifier notConfirmed(uint256 _txIndex) {
        require(!confirmations[_txIndex][msg.sender], "Deja confirme.");
        _;
    }

    // =============================================================
    //               FONCTIONS DE GESTION DE TRANSACTIONS
    // =============================================================

    /**
     * @notice Soumet une nouvelle transaction.
     * @dev L'appelant doit être un signataire. Ne nécessite pas plusieurs confirmations à ce stade.
     * @param _destination L'adresse de destination (le receveur).
     * @param _value Le montant en wei à envoyer.
     * @param _data Les données à appeler sur l'adresse de destination.
     */
    function submitTransaction(
        address _destination,
        uint256 _value,
        bytes calldata _data
    ) 
        external
        onlySigner
    {
        uint256 txIndex = transactions.length;

        transactions.push(
            Transaction({
                destination: _destination,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _destination, _value, _data);
    }

    /**
     * @notice Confirme une transaction en attente.
     * @param _txIndex L'index de la transaction à confirmer.
     */
    function confirmTransaction(uint256 _txIndex)
        external
        onlySigner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage txn = transactions[_txIndex];
        txn.numConfirmations += 1;
        confirmations[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    /**
     * @notice Révoque la confirmation pour une transaction non exécutée.
     * @param _txIndex L'index de la transaction à révoquer.
     */
    function revokeConfirmation(uint256 _txIndex)
        external
        onlySigner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        require(confirmations[_txIndex][msg.sender], "Aucune confirmation a revoquer.");
        Transaction storage txn = transactions[_txIndex];
        txn.numConfirmations -= 1;
        confirmations[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    /**
     * @notice Exécute la transaction si le nombre de confirmations requis est atteint.
     * @param _txIndex L'index de la transaction à exécuter.
     */
    function executeTransaction(uint256 _txIndex)
        external
        onlySigner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage txn = transactions[_txIndex];
        require(txn.numConfirmations >= required, "Pas assez de confirmations.");

        txn.executed = true;

        (bool success, ) = txn.destination.call{value: txn.value}(txn.data);
        require(success, "Echec de la transaction.");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    // =============================================================
    //             FONCTIONS POUR GÉRER LES SIGNATAIRES
    // =============================================================

    /**
     * @notice Ajoute un nouveau signataire (doit garder au moins 3 signataires).
     * @param _newSigner L'adresse du nouveau signataire.
     */
    function addSigner(address _newSigner) external onlySigner {
        require(_newSigner != address(0), "Adresse invalide.");
        require(!isSigner[_newSigner], "Deja signataire.");

        signers.push(_newSigner);
        isSigner[_newSigner] = true;

        emit SignerAdded(_newSigner);
    }

    /**
     * @notice Retire un signataire existant tout en veillant à garder au moins 3 signataires.
     * @param _signerToRemove L'adresse du signataire à retirer.
     */
    function removeSigner(address _signerToRemove) external onlySigner {
        require(isSigner[_signerToRemove], "N'est pas signataire.");
        require(signers.length > 3, "On ne peut pas descendre en dessous de 3.");

        isSigner[_signerToRemove] = false;

        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == _signerToRemove) {
                signers[i] = signers[signers.length - 1];
                signers.pop();
                break;
            }
        }

        emit SignerRemoved(_signerToRemove);
    }

    // =============================================================
    //                     FONCTIONS DE LECTURE
    // =============================================================

    /**
     * @notice Retourne le nombre total de transactions.
     */
    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }

    /**
     * @notice Retourne la liste complète des signataires actuels.
     */
    function getSigners() external view returns (address[] memory) {
        return signers;
    }

}