// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract MultiSig {
    struct Transaction {
        address target;
        bytes data;
        bool executed;
        uint256 confirmations;
    }

    address[] private _signers;
    mapping(address => bool) private _isSigner;
    Transaction[] private _transactions;
    mapping(uint256 => mapping(address => bool)) private _isConfirmed;
    uint256 private immutable REQUIRED;

    event SubmitTransaction(uint256 indexed txId, address indexed signer, address indexed target, bytes data);
    event ConfirmTransaction(uint256 indexed txId, address indexed signer);
    event RevokeConfirmation(uint256 indexed txId, address indexed signer);
    event ExecuteTransaction(uint256 indexed txId, address indexed signer);

    modifier onlySigner() {
        require(_isSigner[msg.sender], "Not a signer");
        _;
    }

    modifier txExists(uint256 txId) {
        require(txId < _transactions.length, "Transaction does not exist");
        _;
    }

    modifier notExecuted(uint256 txId) {
        require(!_transactions[txId].executed, "Transaction already executed");
        _;
    }

    constructor(address[] memory signers_, uint256 required_) {
        require(signers_.length > 0, "Signers required");
        require(required_ > 0 && required_ <= signers_.length, "Invalid number of required signatures");

        for (uint256 i = 0; i < signers_.length; i++) {
            address signer = signers_[i];

            require(signer != address(0), "Invalid signer");
            require(!_isSigner[signer], "Duplicate signer");

            _isSigner[signer] = true;
            _signers.push(signer);
        }
        REQUIRED = required_;
    }

    function signers() public view returns (address[] memory) {
        return _signers;
    }

    function isSigner(address account) public view returns (bool) {
        return _isSigner[account];
    }

    function transaction(uint256 txId) public view txExists(txId) returns (Transaction memory) {
        return _transactions[txId];
    }

    function isConfirmed(uint256 txId, address signer) public view returns (bool) {
        return _isConfirmed[txId][signer];
    }

    function required() public view returns (uint256) {
        return REQUIRED;
    }

    function submitTransaction(address target, bytes calldata data) public onlySigner returns (uint256) {
        require(target != address(0), "Invalid target");

        uint256 txId = _transactions.length;
        _transactions.push(Transaction({target: target, data: data, executed: false, confirmations: 0}));

        emit SubmitTransaction(txId, msg.sender, target, data);

        confirmTransaction(txId);

        return txId;
    }

    function confirmTransaction(uint256 txId) public onlySigner txExists(txId) notExecuted(txId) {
        require(!_isConfirmed[txId][msg.sender], "Transaction already confirmed");

        _isConfirmed[txId][msg.sender] = true;
        _transactions[txId].confirmations += 1;

        emit ConfirmTransaction(txId, msg.sender);
    }

    function revokeConfirmation(uint256 txId) public onlySigner txExists(txId) notExecuted(txId) {
        require(_isConfirmed[txId][msg.sender], "Transaction not confirmed");

        _isConfirmed[txId][msg.sender] = false;
        _transactions[txId].confirmations -= 1;

        emit RevokeConfirmation(txId, msg.sender);
    }

    function executeTransaction(uint256 txId) public onlySigner txExists(txId) notExecuted(txId) {
        Transaction storage pickedTransaction = _transactions[txId];
        require(pickedTransaction.confirmations >= REQUIRED, "Not enough confirmations");

        pickedTransaction.executed = true;
        (bool success,) = pickedTransaction.target.call(pickedTransaction.data);
        require(success, "Transaction failed");

        emit ExecuteTransaction(txId, msg.sender);
    }
}
