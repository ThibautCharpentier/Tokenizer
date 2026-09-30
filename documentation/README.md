# Documentation Technique & Guide d'Utilisation - Tokenizer

Cette documentation détaille le fonctionnement du contrat `Tokenizer.sol` et `MultiSig.sol`, la suite de tests automatisés, ainsi que la méthode étape par étape pour déployer et interagir avec le token sur un réseau local (`Anvil`) ou sur le réseau de test officiel (`Sepolia`).

## Fonctionnement du Smart Contract Tokenizer

Le contrat `Tokenizer.sol` est un jeton respectant la norme **ERC-20**. Il permet de gérer la création de tokens, les transferts de solde de pair à pair, la délégation de pouvoir de dépense (procurations) et le contrôle de la masse monétaire.

### Métadonnées et caractéristiques
* **Nom (`name`) :** Défini à l'initialisation du contrat (ex: `"Token42"`). Ne peut être vide.
* **Symbole (`symbol`) :** Défini à l'initialisation du contrat (ex: `"T42"`). Ne peut être vide.
* **Décimales (`decimals`) :** `18` (standard d'Ethereum pour gérer les fractions de jetons), déclaré en `constant`.
* **Offre Totale (`totalSupply`) :** Quantité totale de tokens en circulation.
* **Propriétaire (`owner`) :** Adresse administrateur possédant des droits exclusifs sur la création de nouveaux tokens. Après le déploiement, ce rôle est confié au contrat **MultiSig**.

## Architecture et Norme ERC-20

### Fonctions de Lecture (View)
* `name() public view returns (string memory)` : Renvoie le nom du token.
* `symbol() public view returns (string memory)` : Renvoie le symbole.
* `decimals() public view returns (uint8)` : Renvoie le nombre de décimales (`18`).
* `totalSupply() public view returns (uint256)` : Renvoie la masse monétaire globale.
* `balanceOf(address account) public view returns (uint256)` : Renvoie le solde du compte spécifié.
* `allowance(address owner, address spender) public view returns (uint256)` : Renvoie le montant restant qu'un tiers (`spender`) est autorisé à prélever sur le compte de `owner`.
* `owner() public view returns (address)` : Renvoie l'adresse du propriétaire actuel du contrat.

### Fonctions de Transaction (State-Changing)
* `transfer(address to, uint256 amount) public returns (bool)` : Transfère `amount` tokens de l'appelant (`msg.sender`) vers le compte `to`.
* `approve(address spender, uint256 amount) public returns (bool)` : Autorise le compte `spender` à utiliser jusqu'à `amount` tokens appartenant à `msg.sender`.
* `transferFrom(address from, address to, uint256 amount) public returns (bool)` : Transfère `amount` tokens du compte `from` vers le compte `to` en utilisant le solde d'autorisation préalable de `msg.sender`.
* `mint(address to, uint256 amount) public onlyOwner returns (bool)` : **[Restreint au Owner]** Crée `amount` nouveaux tokens et les crédite au compte `to`. Augmente le `totalSupply`.
* `burn(uint256 amount) public returns (bool)` : Détruit `amount` tokens du compte de `msg.sender`. Réduit le `totalSupply`.
* `transferOwnership(address newOwner) public onlyOwner returns (bool)` : **[Restreint au Owner]** Transfère la propriété du contrat à `newOwner`. Utilisée lors du déploiement pour confier les droits de mint au MultiSig.

### Événements (Events)
* `event Transfer(address indexed from, address indexed to, uint256 value)` : Émis lors de chaque transfert, émission (`from == address(0)`) ou destruction (`to == address(0)`).
* `event Approval(address indexed owner, address indexed spender, uint256 value)` : Émis lors de chaque modification de la procuration via `approve`.
* `event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)` : Émis lors de l'attribution initiale du propriétaire dans le constructeur, puis à chaque appel de `transferOwnership`.

## Bonus : le Multisignature

Le contrat `MultiSig.sol` exige que plusieurs signataires valident une action avant qu'elle puisse être exécutée. lors du déploiement, il devient :
* le propriétaire du token : plus personne ne peut minter seul ;
* le détenteur de la trésorerie : les 1000 tokens initiaux lui sont transférés et chaque dépense nécessite le seuil de signatures.
* La configuration retenue est **2 signatures sur 3** : la perte d'une clef ne bloque pas les fonds, et le vol d'une seule clef ne suffit pas à les dépenser.

### Déroulement d'une transaction
* Proposition (`submitTransaction`) : un signataire propose un appel et le confirme automatiquement.
* Confirmation (`confirmTransaction`) : les autres signataires valident. Chacun peut retirer sa validation (`revokeConfirmation`) tant que la transaction n'est pas exécutée.
* Exécution (`executeTransaction`) : dès que le seuil de signatures est atteint, n'importe quel signataire l'exécute. Le multisig appelle alors le token: `msg.sender` vaut l'adresse du multisig, qui est owner, donc le `onlyOwner` est satisfait.

### Fonctions de Lecture
* `signers() public view returns (address[] memory)` : Renvoie la liste des signataires.
* `isSigner(address account) public view returns (bool)` : Indique si une adresse est signataire.
* `required() public view returns (uint256)` : Renvoie le nombre de signatures requises.
* `transaction(uint256 txId) public view returns (Transaction memory)` : Renvoie une transaction.
* `isConfirmed(uint256 txId, address signer) public view returns (bool)` : Indique si un signataire a confirmé une transaction.

### Fonctions de Transaction
* `constructor(address[] memory signers_, uint256 required_)` : Définit les signataires et le seuil, qui ne peuvent plus être modifiés ensuite. Refuse une liste vide, un seuil nul ou supérieur au nombre de signataires, l'adresse zéro et les doublons.
* `submitTransaction(address target, bytes calldata data) public returns (uint256)` : **[Signataires]** propose un appel vers `target` avec les données encodées `data`.
* `confirmTransaction(uint256 txId) public` : **[Signataires]** confirme une transaction. Un signataire ne peut confirmer qu'une seule fois.
* `revokeConfirmation(uint256 txId) public` : **[Signataires]** retire sa confirmation.
* `executeTransaction(uint256 txId) public` : **[Signataires]** exécute une transaction ayant atteint le seuil. Une transaction ne peut être exécutée qu'une seule fois.

### Événements (Events)
* `event SubmitTransaction(uint256 indexed txId, address indexed signer, address indexed target, bytes data)`
* `event ConfirmTransaction(uint256 indexed txId, address indexed signer)`
* `event RevokeConfirmation(uint256 indexed txId, address indexed signer)`
* `event ExecuteTransaction(uint256 indexed txId, address indexed signer)`
Chaque proposition, vote et exécution laisse une trace publique consultable.

## Tests Automatisés (Foundry)

Les tests unitaires sont rédigés en Solidity dans les fichiers `Tokenizer.t.sol` et `MultiSig.t.sol`. La suite de tests valide **100 % des fonctions** ainsi que les cas d'erreur (*reverts*).

### Exécuter les tests
```
forge test
```

## Configuration

Dans le fichier `.env` à la racine du projet :
```
SEPOLIA_URL=https://eth-sepolia.g.alchemy.com/v2/VOTRE_CLE_ALCHEMY
ETHERSCAN_API_KEY=VOTRE_CLE_API_ETHERSCAN
PRIVATE_KEY=0xCLE_PRIVEE_DU_DEPLOYEUR
ANVIL_URL=http://127.0.0.1:8545
MULTISIG_SIGNERS=0xSignataire1,0xSignataire2,0xSignataire3
MULTISIG_REQUIRED=2
```

## Déploiement et Interaction en Local (Anvil)

Anvil est le simulateur local fourni par Foundry.

### Démarrer le réseau local
Ouvre un premier terminal et exécute :
```
anvil
```
Anvil démarre sur http://127.0.0.1:8545 et met à disposition 10 comptes de test avec des clées privées prédéfinies.
On peut définir une variable d'environnement :
```
$ANVIL_URL=http://127.0.0.1:8545
```

### Déployer les contrats sur Anvil
Dans le `.env` :
```
PRIVATE_KEY=<CLE_ANVIL_0>
MULTISIG_SIGNERS=<ADDRESSE_ANVIL_1>,<ADDRESSE_ANVIL_2>,<ADDRESSE_ANVIL_3>
```
Dans un second terminal, exécute le script de déploiement :
```
forge script deployment/Tokenizer.s.sol:TokenizerScript --rpc-url $ANVIL_URL --broadcast
```

### Interagir avec les contrats en local
Lire le nom du token :
```
cast call <ADRESSE_DU_CONTRAT> "name()(string)" --rpc-url $ANVIL_URL
```
Consulter le solde d'un compte :
```
cast call <ADRESSE_DU_CONTRAT> "balanceOf(address)(uint256)" <ADRESSE_PUBLIC> --rpc-url $ANVIL_URL
```
Effectuer un transfert de 100 tokens (avec 18 décimales) :
```
cast send <ADRESSE_DU_CONTRAT> "transfer(address,uint256)" <ADRESSE_DESTINATAIRE> 100000000000000000000 --private-key <CLE_PRIVEE_ANVIL> --rpc-url $ANVIL_URL
```
Accorder une autorisation de dépense à un tiers :
```
cast send <ADRESSE_DU_CONTRAT> "approve(address,uint256)" <ADRESSE_SPENDER> 50000000000000000000 --private-key <CLE_PRIVEE_ANVIL> --rpc-url $ANVIL_URL
```
Consulter le montant autorisé (allowance) :
```
cast call <ADRESSE_DU_CONTRAT> "allowance(address,address)(uint256)" <ADRESSE_PROPRIETAIRE> <ADRESSE_SPENDER> --rpc-url $ANVIL_URL
```

### Minter via le multisig
```
DATA=$(cast calldata "mint(address,uint256)" <ADRESSE_CIBLE> 100000000000000000000)
```
Le signataire 1 propose la transaction et la confirme automatiquement :
```
cast send <ADRESSE_DU_MULTISIG> "submitTransaction(address,bytes)" <ADRESSE_DU_TOKEN> $DATA --private-key <CLE_ANVIL_1> --rpc-url $ANVIL_URL
```
Le signataire 2 confirme, le seuil de signatures est atteint :
```
cast send <ADRESSE_DU_MULTISIG> "confirmTransaction(uint256)" 0 --private-key <CLE_ANVIL_2> --rpc-url $ANVIL_URL
```
N'importe quel signataire exécute :
```
cast send <ADRESSE_DU_MULTISIG> "executeTransaction(uint256)" 0 --private-key <CLE_ANVIL_3> --rpc-url $ANVIL_URL
```

## Déploiement et Vérification sur Sepolia

Cette étape permet de déployer le contrat sur le réseau de test public Ethereum Sepolia et de le vérifier sur Etherscan.

### Prérequis et variables d'environnement
Dans le fichier `.env` à la racine du projet, ajoute les variables suivantes :
```env
SEPOLIA_URL=https://eth-sepolia.g.alchemy.com/v2/VOTRE_CLE_ALCHEMY
PRIVATE_KEY=0xVOTRE_CLE_PRIVEE_METAMASK
ETHERSCAN_API_KEY=VOTRE_CLE_API_ETHERSCAN
MULTISIG_SIGNERS=<ADRESSE_METAMASK_0>,<ADRESSE_METAMASK_1>,<ADRESSE_METAMASK_2>
MULTISIG_REQUIRED=2
```

### Déploiement sur Sepolia
```
forge script deployment/Tokenizer.s.sol:TokenizerScript --rpc-url $SEPOLIA_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY --slow
```
Une fois le contrat déployé, on peut cnsulter le contrat directement sur l'explorateur :
```
https://sepolia.etherscan.io/address/<ADRESSE_DU_CONTRAT>#code
```
