# Tokenizer

Tokenizer est un projet de l'École 42 dont l'objectif est de concevoir, tester et déployer un smart contract d'un jeton en respectant la norme **ERC-20** sur la blockchain **Ethereum**.

## Status

* Success
* Grade: 120/100

## Choix techniques et plateforme

### Blockchain : Ethereum (Réseau de test Sepolia)
* **Pourquoi Ethereum ?** C'est le standard de l'industrie pour la programmation de smart contracts via l'EVM (*Ethereum Virtual Machine*).
* **Pourquoi Sepolia ?** C'est le réseau de test (*testnet*) officiel recommandé pour Ethereum, permettant de simuler un déploiement réel sans dépenser de vrais Ether.

### Langage : Solidity
* **Pourquoi Solidity ?** C'est le langage orienté objet officiel et le plus répandu pour le développement de smart contracts sur l'EVM.

### Framework de développement : Foundry
Pour la réalisation de ce projet, le choix s'est porté sur **Foundry** plutôt que Hardhat pour les raisons suivantes :
* **Performance et Vitesse :** Développé en Rust, Foundry compile et exécute la suite de tests automatisés de manière ultra rapide.
* **Langage unique :** Les scripts de déploiement et les tests unitaires sont rédigés directement en **Solidity**, évitant le besoin de jongler avec JavaScript/TypeScript.
* **Outils intégrés :**
  * `forge` pour la compilation, la gestion des dépendances et les tests.
  * `anvil` pour lancer un nœud Ethereum local instantané.
  * `cast` pour interagir en ligne de commande directement avec la blockchain.

## Usage

Je vous laisse aller voir le dossier documentation.

***
Made by:
* Thibaut Charpentier: <thibaut.charpentier42@gmail.com>
