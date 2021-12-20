//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./InkSacs.sol";

contract InkSacsFactory is Ownable {
    InkSacs [] public inkSacs;

    event NewInkSacs (address _inkSacs);

    function createInkSacs () public {
        inkSacs.push (new InkSacs ());
        emit NewInkSacs (address (inkSacs [inkSacs.length - 1]));
    }

    function getInkSacs (uint _index) public view returns (address) {
        return address (inkSacs [_index]);
    }

    function getNumInkSacs () public view returns (uint) {
        return inkSacs.length;
    }

    function getAllInkSacs () public view returns (address [] memory) {
        address [] memory _inkSacs = new address [] (inkSacs.length);
        for (uint i = 0; i < inkSacs.length; i++) {
            _inkSacs [i] = address (inkSacs [i]);
        }
        return _inkSacs;
    }
}