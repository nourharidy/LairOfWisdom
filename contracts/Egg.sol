// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "./Lair.sol";
import "./Dragon.sol";

contract Egg {

    string public name;
    uint constant BIRTH_DURATION = 24 hours;
    address[2] public parents;
    uint public creationTimestamp;
    bool public born;
    Lair public lair;
    uint tributes;

    constructor(Lair _lair, address[2] memory _parents, string memory _name) {
        name = _name;
        parents = _parents;
        lair = _lair;
        creationTimestamp = block.timestamp;
    }

    function isHatched() public view returns (bool) {
        return block.timestamp > creationTimestamp + BIRTH_DURATION - tributes;
    }

    function secondsUntilHatched() public view returns (uint) {
        if(isHatched()) {
            return 0;
        }

        return block.timestamp - creationTimestamp + BIRTH_DURATION - tributes;
    }

    function getTributes() public view returns (uint) {
        return tributes / 100;
    }

    function giveTribute() public {
        require(!isHatched(), "im already hatched");
        if(tributes + 100 <= BIRTH_DURATION) {
            tributes += 100;
            emit Tribute(msg.sender);
        }
    }

    function giveBirth() public returns (Dragon dragon) {
        if(!born && isHatched()) {
            dragon = lair.fileDragonCertificate(parents, name);
            born = true;
            emit Birth(msg.sender);
        }
    }

    event Tribute(address indexed trainer);
    event Birth(address indexed trainer);


}