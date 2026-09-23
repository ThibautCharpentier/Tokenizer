# Documentation Technique & Guide d'Utilisation - Tokenizer

Cette documentation détaille le fonctionnement du contrat `Tokenizer.sol`, la suite de tests automatisés, ainsi que la méthode étape par étape pour déployer et interagir avec le token sur un réseau local (`Anvil`) ou sur le réseau de test officiel (`Sepolia`).

## Fonctionnement du Smart Contract

Le contrat `Tokenizer.sol` est un jeton respectant la norme **ERC-20**. Il permet de gérer la création de tokens, les transferts de solde de pair à pair, la délégation de pouvoir de dépense (procurations) et le contrôle de la masse monétaire.

### Métadonnées et caractéristiques
* **Nom (`name`) :** Défini à l'initialisation du contrat (ex: `"Token42"`).
* **Symbole (`symbol`) :** Défini à l'initialisation du contrat (ex: `"T42"`).
* **Décimales (`decimals`) :** `18` (standard d'Ethereum pour gérer les fractions de jetons).
* **Offre Totale (`totalSupply`) :** Quantité totale de tokens en circulation.
* **Propriétaire (`owner`) :** Adresse administrateur possédant des droits exclusifs sur la création de nouveaux tokens.

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

### Événements (Events)
* `event Transfer(address indexed from, address indexed to, uint256 value)` : Émis lors de chaque transfert, émission (`from == address(0)`) ou destruction (`to == address(0)`).
* `event Approval(address indexed owner, address indexed spender, uint256 value)` : Émis lors de chaque modification de la procuration via `approve`.
* `event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)` : Émis lors de l'attribution initiale du propriétaire dans le constructeur.

## Tests Automatisés (Foundry)

Les tests unitaires sont rédigés en Solidity dans le fichier `Tokenizer.t.sol`. La suite de tests valide **100 % des fonctions** ainsi que les cas d'erreur (*reverts*).

### Exécuter les tests
```
forge test
```

## Déploiement et Interaction en Local (Anvil)

Anvil est le simulateur local fourni par Foundry.

### Démarrer le réseau local
Ouvre un premier terminal et exécute :
```
anvil
```
Anvil démarre sur http://127.0.0.1:8545 et met à disposition 10 comptes de test avec des clées privées prédéfinies.

### Déployer le contrat sur Anvil
Dans un second terminal, exécute le script de déploiement :
```
forge script deployment/Tokenizer.s.sol:TokenizerScript --rpc-url $ANVIL_URL --broadcast
```

### Interagir avec le contrat local
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

## Déploiement et Vérification sur Sepolia

Cette étape permet de déployer le contrat sur le réseau de test public Ethereum Sepolia et de le vérifier sur Etherscan.

### Prérequis et variables d'environnement
Dans le fichier `.env` à la racine du projet, ajoute les variables suivantes :
```env
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/VOTRE_CLE_ALCHEMY
PRIVATE_KEY=0xVOTRE_CLE_PRIVEE_METAMASK
ETHERSCAN_API_KEY=VOTRE_CLE_API_ETHERSCAN
```

### Déploiement sur Sepolia
```
forge script deployment/Tokenizer.s.sol:TokenizerScript --rpc-url $SEPOLIA_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
```
Une fois le contrat déployé, on peut cnsulter le contrat directement sur l'explorateur :
```
https://sepolia.etherscan.io/address/<ADRESSE_DU_CONTRAT>#code
```
