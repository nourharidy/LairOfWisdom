// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "./Lair.sol";
import "./Egg.sol";

contract Dragon {

    uint constant UPGRADE_COOLDOWN = 1 hours;
    uint constant INIT_BREED_COOLDOWN = 12 hours;
    uint constant BREED_PROPOSAL_TIMEOUT = 7 days;
    uint constant UPGRADE_FACTOR = 0.01 ether; // 1%
    uint constant UPGRADE_COST = 5;
    uint constant HEAL_COST = 1;
    uint constant ATTACK_COST = 5; 
    uint constant BREED_COST = 10;
    uint constant STATS_TIME_DECAY_DENOM = 5 minutes; // stats decay by 1% every 5 minutes

    address public egg;
    Lair public lair;
    address[2] public parents;
    string public name;
    uint public breedCount;
    uint lastUpgradeTimestamp;
    uint lastAttackTimestamp;
    uint lastBreedTimestamp;
    uint lastPlayTimestamp;
    uint lastFeedTimestamp;
    uint lastCleanTimestamp;
    uint lastSleepTimestamp;
    uint public health = 1000000;
    uint public maxHealth = 1000000;
    uint public damage = 20000;
    uint public attackCooldown = 1 hours;
    uint public healthRegeneration = 2000;
    uint8 hunger;
    uint8 uncleanliness;
    uint8 boredom;
    uint8 sleepiness;
    mapping (address => uint) public trust;
    mapping (Dragon => mapping (string => uint)) public breedProposals;

    constructor(address _egg, Lair _lair, address[2] memory _parents, string memory _name) {
        egg = _egg;
        lair = _lair;
        parents = _parents;
        name = _name;
        lastUpgradeTimestamp = block.timestamp;
        lastAttackTimestamp = block.timestamp;
        lastPlayTimestamp = block.timestamp;
        lastFeedTimestamp = block.timestamp;
        lastCleanTimestamp = block.timestamp;
        lastSleepTimestamp = block.timestamp;
        lastBreedTimestamp = block.timestamp;
    }

    modifier IfAlive {
        if(
            getHunger() > 100 &&
            getUncleanliness() > 100 &&
            getBoredom() > 100 &&
            getSleepiness() > 100) {
                selfdestruct(payable(0)); // die
            }
        _;
    }

    modifier earnsTrust {
        trust[msg.sender]++;
        _;
    } 

    modifier consumesTrust {
        trust[msg.sender] -= UPGRADE_COST;
        _;
    }

    /*
        Healing
    */

    function heal() public IfAlive {
        trust[msg.sender] -= HEAL_COST;
        health = min(health + healthRegeneration, maxHealth);
        emit Heal(msg.sender);
    }

    /*
        Attack
    */
    function canAttack() public view returns (bool) {
        return block.timestamp > lastAttackTimestamp + attackCooldown;
    }

    function secondsUntilAttack() public view returns (uint) {
        if(canAttack()) return 0;
        return block.timestamp - lastAttackTimestamp + attackCooldown;
    }

    function attack(Dragon target) public IfAlive {
        require(canAttack(), "i can only attack every so often");
        require(target != this, "i can't attack myself");
        trust[msg.sender] -= ATTACK_COST;
        require(lair.isDragon(target), "target is not a dragon");
        require(isContract(address(target)), "target dragon is dead");
        if(target.health() <= damage) { // target will die
            maxHealth = target.maxHealth() / 4; // consume 1/4 maxHealth
            damage = target.damage() / 4; // consume 1/4 damage
        }
        lastAttackTimestamp = block.timestamp;
        target.onAttack();
        emit Attack(msg.sender, address(target));
    }

    function onAttack() public {
        Dragon attacker = Dragon(msg.sender);
        require(lair.isDragon(attacker), "attacker is not a dragon");
        if(health <= attacker.damage()) {
            selfdestruct(payable(0)); // die
        }
        health -= attacker.damage();
        emit Damaged(msg.sender);
    }

    /*
        Breeding
    */

    function proposeBreeding(Dragon parent, string memory childName) public IfAlive {
        trust[msg.sender] -= BREED_COST; // proposals also have cost
        require(lair.isDragon(parent), "parent is not a dragon");
        require(isContract(address(parent)), "parent dragon is dead");
        require(parent != this, "i can't breed with myself");
        require(bytes(childName).length > 0, "my child must have a name");
        parent.onBreedProposal(childName);
        emit ProposeBreed(msg.sender, address(parent), childName);
    }

    function onBreedProposal(string memory childName) public {
        Dragon parent = Dragon(msg.sender);
        require(lair.isDragon(parent), "parent is not a dragon");
        breedProposals[parent][childName] = block.timestamp;
        emit ReceiveBreedProposal(msg.sender, childName);
    }

    function canBreed() public view returns (bool) {
        return block.timestamp > lastBreedTimestamp + (INIT_BREED_COOLDOWN * (2**(breedCount + 1)));
    }

    function secondsUntilBreed() public view returns (uint) {
        if(canBreed()) return 0;
        return block.timestamp - lastBreedTimestamp + (INIT_BREED_COOLDOWN * (2**(breedCount + 1)));
    }

    function breed(Dragon parent, string memory childName) public IfAlive returns (Egg _egg) {
        trust[msg.sender] -= BREED_COST; // proposals also have cost
        uint proposalTimestamp = breedProposals[parent][childName];
        require(proposalTimestamp > 0, "breed proposal does not exist");
        require(block.timestamp < proposalTimestamp + BREED_PROPOSAL_TIMEOUT, "breed proposal expired");
        require(canBreed(), "I can't breed yet");
        address[2] memory _parents = [address(this), address(parent)];
        _egg = lair.fileEggCertificate(_parents, childName);
        lastBreedTimestamp = block.timestamp;
        breedProposals[parent][childName] = 0;
        breedCount++;
        emit Breed(msg.sender, address(parent), address(_egg), childName);
    }

    /*
        Upgrades
    */

    function canUpgrade() public view returns (bool) {
        return block.timestamp > lastUpgradeTimestamp + UPGRADE_COOLDOWN;
    }

    function secondsUntilUpgrade() public view returns (uint) {
        if(canUpgrade()) return 0;
        return block.timestamp - lastUpgradeTimestamp + UPGRADE_COOLDOWN;
    }

    function upgradeMaxHealth() public consumesTrust IfAlive {
        require(canUpgrade(), "i can only upgrade every so often");
        uint extraMaxHealth = maxHealth * UPGRADE_FACTOR / 1 ether;
        maxHealth = maxHealth + extraMaxHealth;
        lastUpgradeTimestamp = block.timestamp;
        emit UpgradeMaxHealth(msg.sender);
    }

    function upgradeHealing() public consumesTrust IfAlive {
        require(canUpgrade(), "i can only upgrade every so often");
        uint extraHealPoints = healthRegeneration * UPGRADE_FACTOR / 1 ether;
        healthRegeneration = healthRegeneration + extraHealPoints;
        lastUpgradeTimestamp = block.timestamp;
        emit UpgradeHealing(msg.sender);
    }

    function upgradeDamage() public consumesTrust IfAlive {
        require(canUpgrade(), "i can only upgrade every so often");
        uint addedDamage = damage * UPGRADE_FACTOR / 1 ether;
        damage = damage + addedDamage;
        lastUpgradeTimestamp = block.timestamp;
        emit UpgradeDamage(msg.sender);
    }

    function upgradeAttackCooldown() public consumesTrust IfAlive {
        require(canUpgrade(), "i can only upgrade every so often");
        uint removedAttackCooldown = attackCooldown * UPGRADE_FACTOR / 1 ether;
        attackCooldown = attackCooldown - removedAttackCooldown;
        lastUpgradeTimestamp = block.timestamp;
        emit UpgradeAttackCooldown(msg.sender);
    }

    /*
        Caretaking
    */

    function feed() public earnsTrust IfAlive {
        require(getHunger() > 5, "i dont need to eat");
        require(getBoredom() < 80, "im too tired to eat");
        require(getUncleanliness() < 80, "im feeling too gross to eat");
        lastFeedTimestamp = block.timestamp;
        
        hunger = 0;
        boredom += 10;
        uncleanliness += 3;
        emit Feed(msg.sender);
    }

    function clean() public earnsTrust IfAlive {
        require(getUncleanliness() > 5, "i dont need a bath");
        lastCleanTimestamp = block.timestamp;
        
        uncleanliness = 0;
        emit Clean(msg.sender);
    }

    function play() public earnsTrust IfAlive {
        require(getBoredom() > 5, "i dont wanna play");
        require(getHunger() < 80, "im too hungry to play");
        require(getSleepiness() < 80, "im too sleepy to play");
        require(getUncleanliness() < 80, "im feeling too gross to play");
        lastPlayTimestamp = block.timestamp;
        
        boredom = 0;
        hunger += 10;
        sleepiness += 10;
        uncleanliness += 5;
        emit Play(msg.sender);
    }

    function sleep() public earnsTrust IfAlive {
        require(getSleepiness() > 5, "im not feeling sleepy");
        require(getUncleanliness() < 80, "im feeling too gross to sleep");
        
        lastSleepTimestamp = block.timestamp;
        
        sleepiness = 0;
        uncleanliness += 5;
        emit Sleep(msg.sender);
    }

    function getHunger() public view returns (uint256) {
        return hunger + ((block.timestamp - lastFeedTimestamp) / STATS_TIME_DECAY_DENOM);
    }
    
    function getUncleanliness() public view returns (uint256) {
        return uncleanliness + ((block.timestamp - lastCleanTimestamp) / STATS_TIME_DECAY_DENOM);
    }
    
    function getBoredom() public view returns (uint256) {
        return boredom + ((block.timestamp - lastPlayTimestamp) / STATS_TIME_DECAY_DENOM);
    }
    
    function getSleepiness() public view returns (uint256) {
        return sleepiness + ((block.timestamp - lastSleepTimestamp) / STATS_TIME_DECAY_DENOM);
    }

    /*
        Utils
    */

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    event Play(address indexed trainer);
    event Feed(address indexed trainer);
    event Sleep(address indexed trainer);
    event Clean(address indexed trainer);
    event Heal(address indexed trainer);
    event UpgradeDamage(address indexed trainer);
    event UpgradeAttackCooldown(address indexed trainer);
    event UpgradeMaxHealth(address indexed trainer);
    event UpgradeHealing(address indexed trainer);
    event Attack(address indexed trainer, address indexed target);
    event Damaged(address indexed attacker);
    event ProposeBreed(address indexed trainer, address indexed parent, string childName);
    event ReceiveBreedProposal(address indexed parent, string childName);
    event Breed(address indexed trainer, address indexed parent, address egg, string childName);
}
