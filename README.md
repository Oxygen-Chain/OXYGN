# OXYGN
TBD - opensourced code for Proof of Recycle (more to come)


# Initial Setup
.. most operations are inside the "mainContracts" directory.
## INSTALLATION  (**supporting deployments at bottom of page)
First run the command below to get `foundryup`, the Foundry toolchain installer:

```sh
curl -L https://foundry.paradigm.xyz | bash
```
#### then install
```sh
forge init --force --no-commit
forge install Openzeppelin/openzeppelin-contracts --no-commit
forge install Openzeppelin/openzeppelin-contracts-upgradeable --no-commit
forge install smartcontractkit/chainlink-brownie-contracts --no-commit
forge install transmission11/solmate --no-commit
```
#### then build
```sh
forge build --via-ir
forge clean
forge inspect
```

#### then test ( use fuzzing, cheats and more!!)
```sh
forge test
```
#### then Deploy
```sh
forge create
forge verify-contract
forge verify-check
forge flatten
```
### deploy example
```sh
forge create src/Contract.sol:ContractWithNoConstructor
## or with arguments
forge create src/Contract.sol:MyToken --constructor-args "My Token" "MT"
## verify
forge verify-contract <address> SomeContract --watch
## flatten to Contract.flattened.sol
forge flatten --output src/Contract.flattened.sol src/Contract.sol
```

# Oxygen Chain

#### OxygenChain.sol(OXGN) - main contract to recieve edge transactions and allow HealingCredit.sol(HC) to issue OXGN based on health of HC pool

#### HealingCredit.sol(HC) - contract factory for DefaultSystem.sol...facilitates new systems/registration that start using oxygenchain for rewards. will get called from system contract to validate rewards
### medianReward to facilitate a more decentralized signiture for historical analysis
#### DefaultSystem.sol - Contract directly associated with the system Owners raspberry pi, also allows sponsorship to support maintenance and other needs directly.


## DEPLOY API based contracts.
#### CD into the test directory "/oxygencontracts_v2/mainContracts/test"
### run python command:
```sh
	python reafirm.py -deployed reafirm_deployed.yaml -method cloud_deploy
```
- Above command creates a zip file at the root of the project called "contracts.zip"
- within the zip contains the contracts abi and the yaml file with address found during deployment
- Be careful as the private keys are also included here in NOT to be used in Production

# Event Listener/Aggregator
## related projects:
- oxygencontracts_v2 - include the abi's and the reafirm_deployment.yaml file (*required to decript contract events)
- OG-EventEC2Listener - has code to connect to nodes using web3 and send to SQS
- OG-EventAggregator - consumes the SQS and updates each record as needed
- OG-EventListener - Lambda version which is partially in use only to spawn EC2 instance
    - Spawns an ec2 instances with userdata related to  OG-EventEC2Listener
    - will be triggered on a 3-5min schedule and set a 50second window for termination of EC2


## Uses a combination of SQS, S3 and Dynamo in the following way:
Keep in mind that deployments will need to:
- Deploy contracts found in oxygencontracts_v2 and reafirm_deployment.yaml to S3 at:
    - data/miner/initialization/latest/contracts.zip
- Deploy changes to each of the lambdas above
- ensure the SQS fifo queue exists currently arn:aws:sqs:us-east-1:*:OG-contract-events.fifo


## Future setup will be tied to a chainlink keeper or similar:
 - keeper contract will need to be deployed to OXGN network.
 - Keeper will trigger Another contract via CCP  to another chain like arweave/filecoin.
 - data can then be consumed on one of those sources

