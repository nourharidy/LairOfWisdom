// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "./Dragon.sol";
import "./Egg.sol";

contract Lair {

    Dragon[] dragons;
    mapping (Dragon => bool) public isDragon;

    Egg[] eggs;
    mapping (Egg => bool) public isEgg;

    constructor() {
        address[2] memory parents = [address(0), address(0)];
        Dragon leshner = new Dragon(address(0), this, parents, "Leshner");
        dragons.push(leshner);
        isDragon[leshner] = true;
        emit DragonBirth(address(leshner), parents[0], parents[1]);
        Dragon pleasr = new Dragon(address(0), this, parents, "Pleasr");
        dragons.push(pleasr);
        isDragon[pleasr] = true;
        emit DragonBirth(address(pleasr), parents[0], parents[1]);
    }

    function fileDragonCertificate(address[2] memory parents, string memory name) external returns (Dragon dragon) {
        require(isEgg[Egg(msg.sender)]);
        dragon = new Dragon(msg.sender, this, parents, name);
        dragons.push(dragon);
        isDragon[dragon] = true;
        emit DragonBirth(address(dragon), parents[0], parents[1]);
    }

    function fileEggCertificate(address[2] memory parents, string memory name) external returns (Egg egg)  {
        require(isDragon[Dragon(msg.sender)]);
        egg = new Egg(this, parents, name);
        eggs.push(egg);
        isEgg[egg] = true;
        emit EggBirth(address(egg), parents[0], parents[1]);
    }

    function allDragons() public view returns (Dragon[] memory) {
        return dragons;
    }

    function allEggs() public view returns (Egg[] memory) {
        return eggs;
    }

    event DragonBirth(address indexed dragon, address indexed parent1, address indexed parent2);
    event EggBirth(address indexed egg, address indexed parent1, address indexed parent2);
}